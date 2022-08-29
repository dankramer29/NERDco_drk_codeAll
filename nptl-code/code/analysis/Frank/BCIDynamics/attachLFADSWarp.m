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
for d=7:8
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
    rawNeural = zeros(size(tmp,1)*size(tmp,2),96);
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        rawNeural(stackIdx,:) = gaussSmooth_fast(squeeze(predata.allNeural{1,1}(t,:,:)),5);
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
    lfadsCIS = zeros(size(lfadsNeural,1), size(lfadsNeural,2));
    for t=1:size(lfadsNeural,1)
        lfadsCIS(t,:) = neuralStack(binIdx,1:96) * dPCA_out.W(:,1);
        binIdx = binIdx + size(lfadsNeural,2);
    end
    
    %simple dPCA, raw
%     dPCA_out = apply_dPCA_simple( rawNeural(:,1:96), eventIdx, trialCodes, timeWindow, timeStep, margNames );
%     
%     binIdx = 1:size(lfadsNeural,2);
%     lfadsCIS = zeros(size(lfadsNeural,1), size(lfadsNeural,2));
%     for t=1:size(lfadsNeural,1)
%         lfadsCIS(t,:) = rawNeural(binIdx,1:96) * dPCA_out.W(:,1);
%         binIdx = binIdx + size(lfadsNeural,2);
%     end
    
    %%     
    lfadsCIS = lfadsCIS - mean(lfadsCIS(:));
    lfadsCIS = lfadsCIS/std(lfadsCIS(:));
    
    figure
    plot(lfadsCIS');
    ylim([-4 4]);

    [B,A] = butter(3, 5/50,'low');
    for t=1:size(lfadsCIS,1)
        lfadsCIS(t,:) = filtfilt(B,A,lfadsCIS(t,:));
    end
    
    figure
    plot(lfadsCIS');
    ylim([-4 4]);
    
    %%
    allAvg = zeros(10, size(lfadsCIS,2));
    cAvg = mean(lfadsCIS);
    warpedCurves = zeros(size(lfadsCIS));
    warpFunctions = zeros(size(lfadsCIS));
    
    tAxis = 1:length(cAvg);
    knots = linspace(1,length(tAxis),8);
    coefStart = ones(length(knots),1);
    
    opts = optimoptions('fmincon');
    opts.Display = 'none';
    
    nIter = 1;
    
    for k=1:nIter
        disp(['---' num2str(k) '---']);
        allAvg(k,:) = cAvg;
        
        for t=1:size(lfadsCIS,1)
            disp(t);
            
            %register curve to average
            objFun = @(coef)warpObj_v2( lfadsCIS(t,:), cAvg, 1, knots, coef );
            newCoef = fmincon(objFun, coefStart, [], [], [], [], zeros(1,length(coefStart)), inf(1,length(coefStart)), [], opts);
            
            %save result
            [~, warpedCurves(t,:), warpFunctions(t,:)] = warpObj_v2( lfadsCIS(t,:), cAvg, 1, knots, newCoef );
        end
        
        figure
        hold on
        plot(warpedCurves');
        plot(cAvg,'LineWidth',2,'Color','k');
        
        cAvg = mean(warpedCurves);
    end
    
    colors = jet(10)*0.8;
    figure
    hold on
    for k=1:10
        plot(allAvg(k,:),'LineWidth',1.5);
    end
     
    %%
    %remove outliers
    mn = nanmean(warpedCurves);
    sd = nanstd(warpedCurves);
    
    outlierIdx = false(size(warpedCurves,1),1);
    for t=1:size(warpedCurves,1)
        outlierIdx(t) = any(warpedCurves(t,:)<mn-3*sd | warpedCurves(t,:)>mn+3*sd);
    end
    
    figure
    hold on
    for t=1:size(lfadsCIS,1)
        if outlierIdx(t)
            plot(warpedCurves(t,:),'r');
        else
            plot(warpedCurves(t,:),'b');
        end
    end
    plot(mn,'k','LineWidth',2);
    
    
    %%
    figure('Position',[680   328   413   770]);
    ax1 = subplot(3,1,1);
    plot(predata.timeAxis{1}, lfadsCIS');
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('CIS');
    title('Original');
    
    ax2 = subplot(3,1,2);
    plot(predata.timeAxis{1}, warpedCurves');
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('CIS');
    title('Time Warped');
    
    ax3 = subplot(3,1,3);
    plot(predata.timeAxis{1}, warpedCurves(~outlierIdx,:)');
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('CIS');
    title('Outliers Removed');
    
    linkaxes([ax1, ax2, ax3]);
    axis tight;
    
    saveas(gcf,[dataDir filesep datasets{d} '_neuralWarp1.png'],'png');
    saveas(gcf,[dataDir filesep datasets{d} '_neuralWarp1.svg'],'svg');

    figure('Position',[680   326   415   772]);
    subplot(2,1,1);
    plot(linspace(0,1,size(warpFunctions,2)), warpFunctions');
    xlabel('Time In');
    ylabel('Time Out');
    set(gca,'LineWidth',1.5,'FontSize',16);
    title('Time Warp Functions');
    
    subplot(2,1,2);
    plot(linspace(0,1,size(warpFunctions,2)), warpFunctions(~outlierIdx,:)');
    xlabel('Time In');
    ylabel('Time Out');
    set(gca,'LineWidth',1.5,'FontSize',16);
    title('Outliers Removed');
    
    saveas(gcf,[dataDir filesep datasets{d} '_neuralWarp2.png'],'png');
    saveas(gcf,[dataDir filesep datasets{d} '_neuralWarp2.svg'],'svg');
    
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
    predata.timeWindows{4} = predata.timeWindows{1};
    
    save(fileName, '-struct', 'predata');
    
%     %%
%     %try getting CIS to detect neural onset
%     tmp = newNeural;
%     alignIdx = 4;
% 
%     %stack
%     eventIdx = [];
%     [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));
% 
%     stackIdx = 1:size(tmp,2);
%     neuralStack_warp = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
%     for t = 1:size(tmp,1)
%         neuralStack_warp(stackIdx,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
%         eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
%         stackIdx = stackIdx + size(tmp,2);
%     end
% 
%     %normalize
%     neuralStack_warp = zscore(neuralStack_warp);
% 
%     %information needed for unrolling functions
%     timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
%     trialCodes = predata.allCon{alignIdx};
%     timeStep = predata.binMS/1000;
%     margNames = {'CD', 'CI'};
% 
%     %simple dPCA
%     dPCA_out = apply_dPCA_simple( neuralStack_warp(:,1:96), eventIdx, trialCodes, timeWindow, timeStep, margNames );
% 
%     binIdx = 1:size(lfadsNeural,2);
%     lfadsCIS = zeros(size(lfadsNeural,1), size(lfadsNeural,2));
%     for t=1:size(lfadsNeural,1)
%         lfadsCIS(t,:) = neuralStack(binIdx,1:96) * dPCA_out.W(:,1);
%         binIdx = binIdx + size(lfadsNeural,2);
%     end
%     %simple dPCA
%     dPCA_out = apply_dPCA_simple( neuralStack(:,1:96), eventIdx, trialCodes, timeWindow, timeStep, margNames );
% 
%     nTop = 8;
%     binIdx = 1:size(lfadsNeural,2);
%     lfadsTop = zeros(size(lfadsNeural,1), size(lfadsNeural,2),nTop);
%     for t=1:size(lfadsNeural,1)
%         lfadsTop(t,:,:) = neuralStack(binIdx,1:96) * dPCA_out.W(:,1:nTop);
%         binIdx = binIdx + size(lfadsNeural,2);
%     end
% 
%     %%
%     %single trial
%     codeList = unique(trialCodes);
%     figure('Position',[106         101         731        1004]);
%     for codeIdx = 1:4
%         trlIdx = find(trialCodes==codeList(codeIdx));
%         colors = jet(nTop)*0.8;
%         
%         subplot(4,2,(codeIdx-1)*2+1);
%         hold on
%         for t=1:min(length(trlIdx),20)
%             for dimIdx=1:nTop
%                 plot(squeeze(lfadsTop(trlIdx(t),:,dimIdx)),'Color',colors(dimIdx,:),'LineWidth',1);
%             end
%         end
%         
%         subplot(4,2,(codeIdx-1)*2+2);
%         hold on
%         for t=1:min(length(trlIdx),20)
%             for dimIdx=1:nTop
%                 originalData = squeeze(lfadsTop(trlIdx(t),:,dimIdx));
%                 warpData = interp1(linspace(0,1,nBins), originalData, warpFunctions(trlIdx(t),:));
%                 plot(warpData,'Color',colors(dimIdx,:),'LineWidth',1);
%             end
%         end
%     end     
%     
%     %averages
%     trialCodes = predata.allCon{1};
%     figure('Position',[106         374        1285         731]);
%     for codeIdx = 1:4
%         
%         colors = jet(nTop)*0.8;
%         
%         trlIdx = find(trialCodes==codeList(codeIdx));
%         cAvg = squeeze(mean(lfadsTop(trlIdx,:,:),1));
%         
%         trlIdx = find(trialCodes==codeList(codeIdx) & ~outlierIdx);
%         originalData = lfadsTop(trlIdx,:,:);
%         cAvgWarp = zeros(size(cAvg));
%         for t=1:length(trlIdx)
%             cAvgWarp = cAvgWarp + interp1(linspace(0,1,nBins), squeeze(originalData(t,:,:)), ...
%                 warpFunctions(trlIdx(t),:));
%         end
%         cAvgWarp = cAvgWarp / length(trlIdx);
%         
%         subplot(2,2,codeIdx);
%         hold on
%         for dimIdx=1:nTop
%             plot(cAvg(:,dimIdx),'Color',colors(dimIdx,:),'LineWidth',2);
%             plot(cAvgWarp(:,dimIdx),':','Color',colors(dimIdx,:),'LineWidth',2);
%         end
%     end  
end