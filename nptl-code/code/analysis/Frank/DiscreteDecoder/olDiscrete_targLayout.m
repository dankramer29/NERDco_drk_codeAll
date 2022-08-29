%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[3],[7 8 9],[14],[17 18]},{'Radial8_650','Radial8_1000','Radial8_800','DualJoystick_800'};
    't5.2018.08.27',{[1 3 5]},{'DualJoystick_800'};
    't5.2018.09.05',{[3],[5],[6]},{'Radial8_OL1','Radial8_CL1','Radial8_OL2'};
};

%%
for d=3:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding_targSweep' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    for blockSetIdx=1:length(datasets{d,2})
    %for blockSetIdx=7
        clear allR;
        
        bNums = horzcat(datasets{d,2}{blockSetIdx});
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{blockSetIdx}), 3.5, datasets{d,2}{blockSetIdx}(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).tPosLoop = repmat(R{x}(t).posTarget(1:2),1,length(R{x}(t).stateTimer));
            end
            allR = [allR, R{x}];
        end
        clear R;

        targPos = horzcat(allR.posTarget)';
        [targList, ~, targCodes] = unique(targPos, 'rows');

        centerCode = find(all(targList==0,2) | targList(:,4)~=0);
        if ~isempty(centerCode)
            useTrl = find(targCodes~=centerCode);
        else
            useTrl = 1:length(targCodes);
        end
        
        %%        
        alignFields = {'timeGoCue'};
        smoothWidth = 0;
        datFields = {'windowsMousePosition','windowsMousePosition_speed'};
        timeWindow = [-1000,2000];
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];
        
        smoothSpikes = gaussSmooth_fast(alignDat.zScoreSpikes, 3);
        
        %%
        %single-factor
        dPCA_out = apply_dPCA_simple( smoothSpikes, alignDat.eventIdx(useTrl), ...
            targCodes(useTrl), timeWindow/binMS, binMS/1000, {'CD','CI'} );
        
        codeList = unique(targCodes(useTrl));
        lineArgs = cell(length(codeList),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        
        %legIdx = [2,5,6,8,10,13,14,15];
        %for l=1:length(legIdx)
        %    lineArgs{legIdx(l)}{end+1}='LineStyle';
        %    lineArgs{legIdx(l)}{end+1}=':';
        %end
        
        oneFactor_dPCA_plot( dPCA_out,  0.02*((timeWindow(1)/binMS):(timeWindow(2)/binMS)), ...
            lineArgs, {'CD','CI'}, 'sameAxes');
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.png'],'png');
        saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA.svg'],'svg');

        %%
        %save neural cube
        windowIdx = -25:100;
        dataCube = zeros(length(useTrl),length(windowIdx),192);
        for t=1:length(useTrl)
            loopIdx = windowIdx+alignDat.eventIdx(useTrl(t));
            dataCube(t,:,:) = alignDat.zScoreSpikes(loopIdx,:);
        end
        
        %save('joystickDataCube_OL.mat','dataCube');
        
        %%
        tList = unique(targCodes(useTrl));
        figure
        hold on
        for x=1:length(tList)
            text(targList(tList(x),1), targList(tList(x),2), num2str(tList(x)));
        end
        xlim([-700,700]);
        ylim([-700,700]);
        
        if strcmp(datasets{d,3}{blockSetIdx}(1:7), 'Radial8')
            targLayout = targList(:,1:2)./matVecMag(targList(:,1:2),2);

            codeSets = {[1,2,3,4,6,7,8,9]};
        elseif strfind(datasets{d,3}{blockSetIdx}, 'DualJoystick')
            targLayout = targList(:,1:2);
            targLayout(1:8,:) = targLayout(1:8,:) - mean(targLayout(1:8,:));
            targLayout(1:8,:) = targLayout(1:8,:)./matVecMag(targLayout(1:8,:),2);
            targLayout(9:16,:) = targLayout(9:16,:) - mean(targLayout(9:16,:));
            targLayout(9:16,:) = targLayout(9:16,:)./matVecMag(targLayout(9:16,:),2);
            
            codeSets = {1:8, 9:16};
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial8')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 8 12 15 11 7 3],[2 6 10 14 16 13 9 5],[19 23 27 30 33 31 26 22],[18 21 25 29 32 28 24 20]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial4')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 7 3],[2 6 8 5],[11 15 17 14],[10 13 16 12]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
        end
            
        %%  
        %single bin classifier
        trialLens = zeros(length(useTrl),1);
        for x=1:length(useTrl)
            trialLens(x) = allR(useTrl(x)).trialLength;
        end
        avgTrialLen = mean(trialLens)/1000;
       
        targNumsToUse = 3:10;
        topAccuracy = zeros(length(targNumsToUse),1);
        topBitRate = zeros(length(targNumsToUse),1);
        
        for targNumIdx=1:length(targNumsToUse)
            
            targNum = targNumsToUse(targNumIdx);
            theta = linspace(0,2*pi,targNum+1);
            theta = theta(1:(end-1));
            simTargLayout = [cos(theta)', sin(theta)'];
            
            windowBinList = 5:5:50;
            skipBinList = 0:5:35;
            bitrate = nan(length(windowBinList), length(skipBinList));
            accuracy = nan(length(windowBinList), length(skipBinList));

            for windowIdx=1:length(windowBinList)
                disp(windowIdx);
                for skipIdx=1:length(skipBinList)
                    disp(skipIdx);

                    allFeatures = [];
                    allCodes = [];
                    nBins = windowBinList(windowIdx);
                    skipBins = skipBinList(skipIdx);
                    if nBins+skipBins>(ceil(avgTrialLen/0.02)+1)
                        continue
                    end

                    for outerIdx = 1:length(useTrl)
                        trlIdx = useTrl(outerIdx);
                        loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
                        loopIdx(loopIdx<1) = [];

                        newData = mean(alignDat.meanSubtractSpikes(loopIdx,:));

                        allFeatures = [allFeatures; newData];
                        allCodes = [allCodes; targCodes(trlIdx)];
                    end

                    allSimData = [];
                    allSimCodes = [];
                    for tSetIdx=1:length(codeSets)
                        tSetTrl = find(ismember(allCodes, codeSets{tSetIdx}));
                        tSetCodes = allCodes(tSetTrl,:);
                        tSetFeatures = allFeatures(tSetTrl,:);
                        
                        %fit tuning model: allFeatures = E*targs
                        targs = [ones(length(tSetCodes),1), targLayout(tSetCodes,:)]';
                        E = tSetFeatures'/targs;
                        Q = cov((E*targs - tSetFeatures')');

                        %simulate new data with a different target layout
                        nTrials = size(tSetFeatures,1);
                        nFeatures = size(tSetFeatures,2);
                        newTargCodes = randi(targNum, nTrials, 1);
                        newTargLocs = simTargLayout(newTargCodes,:)';
                        simData = (E*[ones(1, nTrials); newTargLocs])' + mvnrnd(zeros(1,nFeatures), Q, nTrials);
                        
                        allSimData = [allSimData; simData];
                        allSimCodes = [allSimCodes; newTargCodes+(tSetIdx-1)*targNum];
                    end
                    
                    nClasses = length(unique(allSimCodes));
                    obj = fitcdiscr(simData,newTargCodes,'DiscrimType','diaglinear');
                    cvmodel = crossval(obj);
                    L = kfoldLoss(cvmodel);
                    predLabels = kfoldPredict(cvmodel);

                    nTrials = length(allCodes);
                    bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);
                    %bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins+skipBins)/50);
                    %bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*(nBins)/50);
                    accuracy(windowIdx, skipIdx) = 1-L;
                end
            end

            windowBinList_str = cell(size(windowBinList));
            for x=1:length(windowBinList_str)
                windowBinList_str{x} = num2str(windowBinList(x)*0.02);
            end

            skipBinList_str = cell(size(skipBinList));
            for x=1:length(skipBinList)
                skipBinList_str{x} = num2str(skipBinList(x)*0.02);
            end

            [topBitRate(targNumIdx), maxIdx] = max(bitrate(:));
            [bestWindowIdx, bestSkipIdx] = ind2sub(size(bitrate), maxIdx);
    
            figure('Position',[153         526        1602         415]);
            subplot(1,2,1);
            hold on;
            imagesc(bitrate');
            plot(bestWindowIdx, bestSkipIdx, 'kx', 'MarkerSize', 12, 'LineWidth', 2);
            set(gca,'XTick',1:length(windowBinList_str),'XTickLabel',windowBinList_str,'XTickLabelRotation',45);
            set(gca,'YTick',1:length(skipBinList_str),'YTickLabel',skipBinList_str);
            colorbar;
            xlabel('Window Length');
            ylabel('Skip Interval');
            set(gca,'FontSize',16);
            title(['Achieved Bit Rate (max=' num2str(max(bitrate(:))) ')']);
            axis tight;

            [topAccuracy(targNumIdx), maxIdx] = max(accuracy(:));
            [bestWindowIdx, bestSkipIdx] = ind2sub(size(accuracy), maxIdx);

            subplot(1,2,2);
            hold on;
            imagesc(accuracy');
            plot(bestWindowIdx, bestSkipIdx, 'kx', 'MarkerSize', 12, 'LineWidth', 2);
            set(gca,'XTick',1:length(windowBinList_str),'XTickLabel',windowBinList_str,'XTickLabelRotation',45);
            set(gca,'YTick',1:length(skipBinList_str),'YTickLabel',skipBinList_str);
            colorbar;
            xlabel('Window Length');
            ylabel('Skip Interval');
            set(gca,'FontSize',16);
            title(['Accuracy (max=' num2str(max(accuracy(:))) ')']);
            axis tight;

            saveas(gcf,[outDir filesep 'linearClassifier_sweep_' datasets{d,3}{blockSetIdx} '_targNum' num2str(targNum) '.png'],'png');
            saveas(gcf,[outDir filesep 'linearClassifier_sweep_' datasets{d,3}{blockSetIdx} '_targNum' num2str(targNum) '.svg'],'svg');
            
            close all;
        end
        
        figure;
        subplot(1,2,1);
        plot(targNumsToUse, topAccuracy, '-o', 'LineWidth', 2);
        xlabel('# of Targets');
        ylabel('Accuracy');
        title(['Trial Length = ' num2str(avgTrialLen)]);
        
        subplot(1,2,2);
        plot(targNumsToUse, topBitRate, '-o', 'LineWidth', 2);
        xlabel('# of Targets');
        ylabel('Bit Rate');
        title(['Trial Length = ' num2str(avgTrialLen)]);
        
        saveas(gcf,[outDir filesep 'numTargetSweep_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'numTargetSweep_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        close all;
        
    end %blockIdx
end %dataset