datasets = {'R_2016-02-02_1', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    't5-2017-09-20', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=1:length(datasets)
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
        
    %%
    lfadsData = load([lfadsResultDir filesep datasets{d} '_Go.mat']);

    lfadsNeural1 = zeros(size(predata.allNeural{1,1}));
    lfadsNeural2 = zeros(size(predata.allNeural{1,2}));
    
    lfadsNeural1(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{2,1}(1:96,:,:)),[3 2 1]);
    lfadsNeural1(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{2,2}(1:96,:,:)),[3 2 1]);

    lfadsNeural2(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{2,1}(97:end,:,:)),[3 2 1]);
    lfadsNeural2(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{2,2}(97:end,:,:)),[3 2 1]);
    
    lfadsNeural = cat(3, lfadsNeural1, lfadsNeural2);
    
    %%
    %try getting CIS to detect neural onset
    tmp = lfadsNeural;
    alignIdx = 1;

    %stack
    eventIdx = [];
    [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

    stackIdx = 1:size(tmp,2);
    neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
        stackIdx = stackIdx + size(tmp,2);
    end

    %normalize
    neuralStack = zscore(neuralStack);

    %information needed for unrolling functions
    timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
    trialCodes = predata.allCon{alignIdx};
    timeStep = predata.binMS/1000;
    margNames = {'CD', 'CI'};

    %simple dPCA
    dPCA_out = apply_dPCA_simple( neuralStack(:,1:96), eventIdx, trialCodes, timeWindow, timeStep, margNames );
    
    binIdx = 1:size(lfadsNeural,2);
    lfadsTop6 = zeros(size(lfadsNeural,1), size(lfadsNeural,2),6);
    for t=1:size(lfadsNeural,1)
        lfadsTop6(t,:,:) = neuralStack(binIdx,1:96) * dPCA_out.W(:,1:6);
        binIdx = binIdx + size(lfadsNeural,2);
    end
    
    %%
    %single-trial PCA
%     [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(neuralStack(:,1:96));
%     binIdx = 1:size(lfadsNeural,2);
%     lfadsTop6 = zeros(size(lfadsNeural,1), size(lfadsNeural,2),6);
%     for t=1:size(lfadsNeural,1)
%         lfadsTop6(t,:,:) = SCORE(binIdx,1:6);
%         binIdx = binIdx + size(lfadsNeural,2);
%     end
    
    %% 
    figure
    plot(lfadsTop6(:,:,1)');

    [B,A] = butter(3, 7/50,'low');
    for t=1:size(lfadsTop6,1)
        lfadsTop6(t,:,:) = filtfilt(B,A,squeeze(lfadsTop6(t,:,:)));
    end
    
    figure
    plot(lfadsTop6(:,:,1)');
        
    %%
    %are single trial-observations consistent?
    codeList = unique(trialCodes);
    figure('Position',[680         272        1104         826]);
    for codeIdx = 1:4
        trlIdx = find(trialCodes==codeList(codeIdx));
        cAvg = squeeze(mean(lfadsTop6(trlIdx,:,:),1));
        
        colors = jet(6)*0.8;
        
        subplot(2,2,codeIdx);
        hold on
        for t=1:min(length(trlIdx),10)
            for dimIdx=1:6
                plot(squeeze(lfadsTop6(trlIdx(t),:,dimIdx)),'Color',colors(dimIdx,:),'LineWidth',1);
                plot(cAvg(:,dimIdx),'Color','w','LineWidth',5);
                plot(cAvg(:,dimIdx),':','Color',colors(dimIdx,:),'LineWidth',3);
            end
        end
    end     
    
    %%
    codeList = unique(trialCodes);
    warpFunctions = zeros(length(trialCodes),size(lfadsTop6,2));
    outlierIdx = false(length(codeList),1);
    
    for codeIdx = 1:length(codeList)
        trlIdx = find(trialCodes==codeList(codeIdx));
        nIter = 10; %co-refine registration & average, WITH REGULARIZATION
        
        allAvg = zeros(nIter, size(lfadsTop6,2), size(lfadsTop6,3));
        cAvg = squeeze(mean(lfadsTop6(trlIdx,:,:),1));
        
        colors = jet(6)*0.8;
        figure('Position',[680   171   560   927]);
        subplot(2,1,1);
        hold on
        for t=1:length(trlIdx)
            for dimIdx=1:6
                plot(squeeze(lfadsTop6(trlIdx(t),:,dimIdx)),'Color',colors(dimIdx,:));
                plot(cAvg(:,dimIdx),'Color',colors(dimIdx,:),'LineWidth',2);
            end
        end
        
        warpedCurves = zeros(size(lfadsTop6(trlIdx,:,:)));

        tAxis = 1:length(cAvg);
        knots = linspace(1,length(tAxis),10);
        coefStart = ones(length(knots),1);

        opts = optimoptions('fmincon');
        opts.Display = 'none';

        for k=1:nIter
            disp(['---' num2str(k) '---']);
            allAvg(k,:,:) = cAvg;

            for t=1:length(trlIdx)
                disp(t);

                %register curve to average
                objFun = @(coef)warpObj_v2( squeeze(lfadsTop6(trlIdx(t),:,:)), cAvg, 10, knots, coef );
                newCoef = fmincon(objFun, coefStart, [], [], [], [], zeros(1,length(coefStart)), inf(1,length(coefStart)), [], opts);

                %save result
                [~, warpedCurves(t,:,:), warpFunctions(trlIdx(t),:)] = warpObj_v2( squeeze(lfadsTop6(trlIdx(t),:,:)), cAvg, 10, knots, newCoef );
            end
                
            cAvg = squeeze(mean(warpedCurves,1));
        end
        
        subplot(2,1,2);
        hold on
        for dimIdx=1:6
            for t=1:length(trlIdx)
                plot(squeeze(warpedCurves(t,:,dimIdx)),'-','Color',colors(dimIdx,:));
            end
            plot(cAvg(:,dimIdx),'Color',colors(dimIdx,:),'LineWidth',2);
        end
 
        colors = jet(nIter)*0.8;
        figure
        hold on
        for k=1:nIter
            for dimIdx=1:6
                plot(squeeze(allAvg(k,:,dimIdx)),'LineWidth',1.5,'Color',colors(k,:));
            end
        end
        
%         lambda = logspace(-3,0,10);
%         wc = cell(length(lambda),1);
%         wf = cell(length(lambda),1);
%         for l=1:length(lambda)
%             disp(l);
%             
%             %register curve to average
%             objFun = @(coef)warpObj_v2( squeeze(lfadsTop6(trlIdx(t),:,:)), cAvg, lambda(l), knots, coef );
%             newCoef = fmincon(objFun, coefStart, [], [], [], [], zeros(1,length(coefStart)), inf(1,length(coefStart)), [], opts);
% 
%             %save result
%             [~, wc{l}, wf{l}] = warpObj_v2( squeeze(lfadsTop6(trlIdx(t),:,:)), cAvg, lambda(l), knots, newCoef );
%         end
%         
%         colors = jet(length(wf))*0.8;
%         figure
%         hold on
%         for f=1:length(wf)
%             plot(wf{f},'Color',colors(f,:),'LineWidth',1);
%         end
        
        %%
        %remove outliers
        mn = squeeze(nanmean(warpedCurves,1));
        sd = squeeze(nanstd(warpedCurves,1));

        for t=1:size(warpedCurves,1)
            outlierIdx(trlIdx(t)) = any(any(squeeze(warpedCurves(t,:,:))<mn-3*sd | squeeze(warpedCurves(t,:,:))>mn+3*sd));
        end

        figure
        hold on
        for t=1:size(warpedCurves,1)
            if outlierIdx(trlIdx(t))
                plot(squeeze(warpedCurves(t,:,:)),'r');
            else
                plot(squeeze(warpedCurves(t,:,:)),'b');
            end
        end
        plot(mn,'k','LineWidth',2);
        
        close all;
    end

    %%
    useTrlIdx = find(~outlierIdx);
    nTrl = length(useTrlIdx);
    nBins = size(predata.allNeural{1,1},2);
    newNeural = zeros(nTrl, nBins, size(lfadsNeural,3));
    newKin = zeros(nTrl, nBins, 5);
    
    for t=1:nTrl
        trlIdx = useTrlIdx(t);
        
        originalNeural = squeeze(cat(3, predata.allNeural{1,1}(trlIdx,:,:), predata.allNeural{1,2}(trlIdx,:,:)));
        originalKin = squeeze(predata.allKin{1}(trlIdx,:,:));
        
        warpNeural = interp1(linspace(0,1,nBins), originalNeural, warpFunctions(trlIdx,:));
        warpKin = interp1(linspace(0,1,nBins), originalKin, warpFunctions(trlIdx,:));
        
        newNeural(t,:,:) = warpNeural;
        newKin(t,:,:) = warpKin;
    end
    
    conList = unique(predata.allCon{1});
    kinAvg = zeros(length(conList), nBins, size(predata.kinAvg{1},3));
    neuralAvg = zeros(length(conList), nBins, size(newNeural,3));
    for c=1:length(conList)
        trlIdx = find(predata.allCon{1}(useTrlIdx)==conList(c));
        kinAvg(c,:,:) = mean(squeeze(newKin(trlIdx,:,:)),1);
        neuralAvg(c,:,:) = mean(squeeze(newNeural(trlIdx,:,:)),1);
    end
    
    %%
    predata.alignTypes = {'Go','MovStart','TargEnter','NeuralWarp'};
    predata.allCon{4} = predata.allCon{1}(useTrlIdx);
    predata.allKin{4} = newKin;
    predata.kinAvg{4} = kinAvg;
    
    predata.allNeural{4,1} = newNeural(:,:,1:96);
    predata.allNeural{4,2} = newNeural(:,:,97:end);
    predata.neuralAvg{4,1} = neuralAvg(:,:,1:96);
    predata.neuralAvg{4,2} = neuralAvg(:,:,97:end);
    
    predata.timeAxis{4} = predata.timeAxis{1};
    predata.timeWindows{4} = predata.timeWindows{4};
    
    save(fileName, '-struct', 'predata');
end