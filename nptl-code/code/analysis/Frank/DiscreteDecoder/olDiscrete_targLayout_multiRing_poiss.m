%%
%'t5.2018.08.20',{[2 3 4 8 9 10 11 12 13]},{'QuadCardinal'},[2];
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[3],[7 8 9],[14],[17 18]},{'Radial8_650','Radial8_1000','Radial8_800','DualJoystick_800'};
    't5.2018.08.27',{[1 3 5]},{'DualJoystick_800'};
    't5.2018.09.05',{[3],[5],[6]},{'Radial8_OL1','Radial8_CL1','Radial8_OL2'};
};

%%
for d=1:1
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding_targSweep' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    for blockSetIdx=1:length(datasets{d,2})
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
        %find best skip bin for the decoded data
        trialLens = zeros(length(useTrl),1);
        for x=1:length(useTrl)
            trialLens(x) = allR(useTrl(x)).trialLength;
        end
        avgTrialLen = mean(trialLens)/1000;
        
        windowBinList = 5:5:50;
        skipBinList = 0:5:35;
        bitrate = zeros(length(windowBinList), length(skipBinList));
        accuracy = zeros(length(windowBinList), length(skipBinList));

        for windowIdx=1:length(windowBinList)
            disp(windowIdx);
            for skipIdx=1:length(skipBinList)
                disp(skipIdx);

                allFeatures = [];
                allCodes = [];
                nBins = windowBinList(windowIdx);
                skipBins = skipBinList(skipIdx);
                
                if nBins+skipBins>(avgTrialLen*50)
                    continue;
                end

                for outerIdx = 1:length(useTrl)
                    trlIdx = useTrl(outerIdx);
                    loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
                    loopIdx(loopIdx<1) = [];
                    
                    newData = mean(alignDat.meanSubtractSpikes(loopIdx,:));

                    allFeatures = [allFeatures; newData];
                    allCodes = [allCodes; targCodes(trlIdx)];
                end

                nClasses = length(unique(allCodes));

                obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                cvmodel = crossval(obj);
                L = kfoldLoss(cvmodel);
                predLabels = kfoldPredict(cvmodel);

                nTrials = length(allCodes);
                bitrate(windowIdx, skipIdx) = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);
                accuracy(windowIdx, skipIdx) = 1-L;
                
            end
        end
        
        [realBitRate, maxIdx] = max(bitrate(:));
        [realAccuracy, accuracyMaxIdx] = max(accuracy(:));
        [bestWindowIdx, bestSkipIdx] = ind2sub(size(bitrate), accuracyMaxIdx);
        bestWindowBins = windowBinList(bestWindowIdx);
        bestSkipBins = skipBinList(bestSkipIdx);
        
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
            nRealTargs = 8;
        elseif strfind(datasets{d,3}{blockSetIdx}, 'DualJoystick')
            targLayout = targList(:,1:2);
            targLayout(1:8,:) = targLayout(1:8,:) - mean(targLayout(1:8,:));
            targLayout(1:8,:) = targLayout(1:8,:)./matVecMag(targLayout(1:8,:),2);
            targLayout(9:16,:) = targLayout(9:16,:) - mean(targLayout(9:16,:));
            targLayout(9:16,:) = targLayout(9:16,:)./matVecMag(targLayout(9:16,:),2);
            
            codeSets = {1:8, 9:16};
            nRealTargs = 8;
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial8')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 8 12 15 11 7 3],[2 6 10 14 16 13 9 5],[19 23 27 30 33 31 26 22],[18 21 25 29 32 28 24 20]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            nRealTargs = 8;
        elseif strfind(datasets{d,3}{blockSetIdx}, 'Quad_Radial4')
            targLayout = targList(:,1:2);
            
            idxSets = {[1 4 7 3],[2 6 8 5],[11 15 17 14],[10 13 16 12]};
            for setIdx=1:length(idxSets)
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:) - mean(targLayout(idxSets{setIdx},:));
                targLayout(idxSets{setIdx},:) = targLayout(idxSets{setIdx},:)./matVecMag(targLayout(idxSets{setIdx},:),2);
            end
            
            codeSets = idxSets;
            nRealTargs=4;
        end
            
        %%          
        targNumsToUse = 3:8;
        
        if length(codeSets)==1
            targNumCombination = targNumsToUse';
        elseif length(codeSets)==2
            targNumCombination = zeros(length(targNumsToUse)^2,2);
            currIdx = 1;
            for x1=1:length(targNumsToUse)
                for x2=1:length(targNumsToUse)
                    targNumCombination(currIdx,:) = [targNumsToUse(x1), targNumsToUse(x2)];
                    currIdx = currIdx + 1;
                end
            end
        elseif length(codeSets)==4
            targNumCombination = zeros(length(targNumsToUse)^4,4);
            currIdx = 1;
            for x1=1:length(targNumsToUse)
                for x2=1:length(targNumsToUse)
                    for x3=1:length(targNumsToUse)
                        for x4=1:length(targNumsToUse)
                            targNumCombination(currIdx,:) = [targNumsToUse(x1), targNumsToUse(x2), targNumsToUse(x3), targNumsToUse(x4)];
                            currIdx = currIdx + 1;
                        end
                    end
                end
            end
        end
        
        %%
        %first figure out the fudge factor needed to match decoding
        %performance on real data for the condition tested
        fudgeFactors = linspace(0.2,1.0,50);
        accuracies = zeros(length(fudgeFactors),1);
        bitRates = zeros(length(fudgeFactors),1);
        
        for fudgeIdx=1:length(fudgeFactors)
            disp(fudgeIdx);
            
            simTargLayouts = {};
            for setIdx=1:length(codeSets)
                theta = linspace(0,2*pi,nRealTargs+1);
                theta = theta(1:(end-1));
                simTargLayouts{setIdx} = [cos(theta)', sin(theta)'];
            end
            
            allFeatures = [];
            allCodes = [];
            nBins = bestWindowBins;
            skipBins = bestSkipBins;

            for outerIdx = 1:length(useTrl)
                trlIdx = useTrl(outerIdx);
                loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
                loopIdx(loopIdx<1) = [];

                newData = sum(alignDat.rawSpikes(loopIdx,:));

                allFeatures = [allFeatures; newData];
                allCodes = [allCodes; targCodes(trlIdx)];
            end

            allSimData = [];
            allSimCodes = [];
            codeOffset = 0;
            for tSetIdx=1:length(codeSets)
                tSetTrl = find(ismember(allCodes, codeSets{tSetIdx}));
                tSetCodes = allCodes(tSetTrl,:);
                tSetFeatures = allFeatures(tSetTrl,:);

                %fit tuning model: allFeatures = E*targs
                %targs = [ones(length(tSetCodes),1), targLayout(tSetCodes,:)]';
                %E = tSetFeatures'/targs;
                %E(:,2:3) = E(:,2:3)*fudgeFactors(fudgeIdx);
                
                tscList = unique(tSetCodes);
                nt = length(unique(tSetCodes));
                
                targs = [ones(length(tSetCodes),1), targLayout(tSetCodes,:)]';
                targMeans = zeros(nt,192);
                targLocMeans = zeros(nt,3);
                for x1=1:nt
                    targMeans(x1,:) = mean(tSetFeatures(tSetCodes==tscList(x1),:));
                    targLocMeans(x1,:) = mean(targs(:,tSetCodes==tscList(x1))');
                end
                
                E = targMeans'/targLocMeans';
                E(:,2:3) = E(:,2:3)*fudgeFactors(fudgeIdx);

                %simulate new data with a different target layout
                nTrials = size(tSetFeatures,1);
                nFeatures = size(tSetFeatures,2);
                newTargCodes = randi(size(simTargLayouts{tSetIdx},1), nTrials, 1);
                newTargLocs = simTargLayouts{tSetIdx}(newTargCodes,:)';
                simData = poissrnd((E*[ones(1, nTrials); newTargLocs])');

                allSimData = [allSimData; simData];
                allSimCodes = [allSimCodes; newTargCodes+codeOffset];
                codeOffset = codeOffset + size(simTargLayouts{tSetIdx},1);
            end

            allSimData(isnan(allSimData)) = 0;
            shuffIdx = randperm(size(allSimData,1));
            allSimData = allSimData(shuffIdx,:);
            allSimCodes = allSimCodes(shuffIdx,:);
            
            nClasses = length(unique(allSimCodes));
            obj = fitcdiscr(allSimData,allSimCodes,'DiscrimType','diaglinear');
            cvmodel = crossval(obj);
            L = kfoldLoss(cvmodel);
            predLabels = kfoldPredict(cvmodel);

            nTrials = length(allCodes);
            bitrate = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);
            accuracy = 1-L;

            bitRates(fudgeIdx) = bitrate;
            accuracies(fudgeIdx) = accuracy;
        end
        
        figure
        hold on
        plot(fudgeFactors, accuracies,'LineWidth',2);
        plot(get(gca,'XLim'),[realAccuracy, realAccuracy],'--k','LineWidth',2);
        set(gca,'FontSize',16,'LineWidth',1);
        xlabel('Fudge Factor');
        ylabel('Accuracy');
        
        saveas(gcf,[outDir filesep 'fudgeFactors_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'fudgeFactors_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        [~,minIdx] = min(abs(accuracies-realAccuracy));
        fudgeFactorToUse = fudgeFactors(minIdx);
        
        %%
        topAccuracy = zeros(length(targNumCombination),1);
        topBitRate = zeros(length(targNumCombination),1);
        
        for targCombIdx=1:size(targNumCombination,1)
            disp(targCombIdx);
            
            simTargLayouts = {};
            for setIdx=1:length(codeSets)
                targNum = targNumCombination(targCombIdx,setIdx);
                theta = linspace(0,2*pi,targNum+1);
                theta = theta(1:(end-1));
                simTargLayouts{setIdx} = [cos(theta)', sin(theta)'];
            end
            
            allFeatures = [];
            allCodes = [];
            nBins = bestWindowBins;
            skipBins = bestSkipBins;

            for outerIdx = 1:length(useTrl)
                trlIdx = useTrl(outerIdx);
                loopIdx = (alignDat.eventIdx(trlIdx)+skipBins):((alignDat.eventIdx(trlIdx)+skipBins+nBins));
                loopIdx(loopIdx<1) = [];

                newData = sum(alignDat.rawSpikes(loopIdx,:));

                allFeatures = [allFeatures; newData];
                allCodes = [allCodes; targCodes(trlIdx)];
            end

            allSimData = [];
            allSimCodes = [];
            codeOffset = 0;
            for tSetIdx=1:length(codeSets)
                tSetTrl = find(ismember(allCodes, codeSets{tSetIdx}));
                tSetCodes = allCodes(tSetTrl,:);
                tSetFeatures = allFeatures(tSetTrl,:);

                %[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(tSetFeatures,'Centered','off');
                %reducedFeatures = SCORE(:,1:20);
                %targs = [ones(length(tSetCodes),1), targLayout(tSetCodes,:)]';
                %E = reducedFeatures'/targs;
                %Q = cov((E*targs - reducedFeatures')');
                
                %fit tuning model: allFeatures = E*targs
                tscList = unique(tSetCodes);
                nt = length(unique(tSetCodes));
                
                targs = [ones(length(tSetCodes),1), targLayout(tSetCodes,:)]';
                targMeans = zeros(nt,192);
                targLocMeans = zeros(nt,2);
                for x1=1:nt
                    targMeans(x1,:) = mean(tSetFeatures(tSetCodes==tscList(x1),:));
                    targLocMeans(x1,:) = mean(targs(:,tSetCodes==tscList(x1)
                end
                
                %E = tSetFeatures'/targs;
                E = targMeans'/targs;
                E(:,2:3) = E(:,2:3)*fudgeFactorToUse;
                
                %Q = eye(size(alignDat.zScoreSpikes,2))/nBins;
                %Q = cov(alignDat.meanSubtractSpikes)/nBins;
                %Q = cov((E*targs - tSetFeatures')');
                
                %diagQ = eye(size(Q,1));
                %for x=1:length(Q)
                %    diagQ(x,x) = Q(x,x);
                %end
                %diagQ = diagQ * 1.5;

                %simulate new data with a different target layout
                nTrials = size(tSetFeatures,1);
                nFeatures = size(tSetFeatures,2);
                newTargCodes = randi(size(simTargLayouts{tSetIdx},1), nTrials, 1);
                newTargLocs = simTargLayouts{tSetIdx}(newTargCodes,:)';
                %simData = (E*[ones(1, nTrials); newTargLocs])' + mvnrnd(zeros(1,size(Q,1)), Q, nTrials);
                %simData = simData * COEFF(:,1:20)';
               
                simData = poissrnd((E*[ones(1, nTrials); newTargLocs])');
                %simData = (E*[ones(1, nTrials); newTargLocs])' + mvnrnd(zeros(1,nFeatures), diagQ, nTrials);

                allSimData = [allSimData; simData];
                allSimCodes = [allSimCodes; newTargCodes+codeOffset];
                codeOffset = codeOffset + size(simTargLayouts{tSetIdx},1);
            end

            allSimData(isnan(allSimData)) = 0;
            shuffIdx = randperm(size(allSimData,1));
            allSimData = allSimData(shuffIdx,:);
            allSimCodes = allSimCodes(shuffIdx,:);
            
            nClasses = length(unique(allSimCodes));
            obj = fitcdiscr(allSimData,allSimCodes,'DiscrimType','diaglinear');
            cvmodel = crossval(obj);
            L = kfoldLoss(cvmodel);
            predLabels = kfoldPredict(cvmodel);

            nTrials = length(allCodes);
            bitrate = (log2(nClasses-1)*max(nTrials-2*(nTrials*L),0))/(length(allCodes)*avgTrialLen);
            accuracy = 1-L;

            topBitRate(targCombIdx) = bitrate;
            topAccuracy(targCombIdx) = accuracy;
        end
        
        if length(codeSets)==1
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
        elseif length(codeSets)==2
            accMat = zeros(length(targNumsToUse));
            bitMat = zeros(length(targNumsToUse));
            
            accMat(:) = topAccuracy;
            bitMat(:) = topBitRate;
            
            figure('Position',[680         793        1114         305]);
            subplot(1,2,1);
            imagesc(targNumsToUse, targNumsToUse, accMat);
            colorbar;
            xlabel('# of Targets for Set 1');
            ylabel('# of Targets for Set 2');
            title(['Trial Length = ' num2str(avgTrialLen)]);
            set(gca,'FontSize',16,'LineWidth',1);

            subplot(1,2,2);
            imagesc(targNumsToUse, targNumsToUse, bitMat);
            colorbar;
            xlabel('# of Targets for Set 1');
            ylabel('# of Targets for Set 2');
            title(['Trial Length = ' num2str(avgTrialLen)]);
            set(gca,'FontSize',16,'LineWidth',1);
        else
            [maxRate,maxIdx] = max(topBitRate);
            disp(targNumCombination(maxIdx,:));
            
            diagIdx = [];
            for x=1:length(targNumCombination)
                if all(targNumCombination(x,:)==mean(targNumCombination(x,:)))
                    diagIdx = [diagIdx; x];
                end
            end
            
            figure;
            subplot(1,2,1);
            plot(targNumsToUse, topAccuracy(diagIdx), '-o', 'LineWidth', 2);
            xlabel('# of Targets');
            ylabel('Accuracy');
            title(['Trial Length = ' num2str(avgTrialLen)]);

            subplot(1,2,2);
            plot(targNumsToUse, topBitRate(diagIdx), '-o', 'LineWidth', 2);
            xlabel('# of Targets');
            ylabel('Bit Rate');
            title(['Trial Length = ' num2str(avgTrialLen)]);
        end
        
        saveas(gcf,[outDir filesep 'numTargetSweep_' datasets{d,3}{blockSetIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'numTargetSweep_' datasets{d,3}{blockSetIdx} '.svg'],'svg');
        
        close all;
        
        %%
        %save table entry
        [maxRate,maxIdx] = max(topBitRate);
        
        bestTargComb = zeros(1,4);
        bestTargComb(1:length(targNumCombination(maxIdx,:))) = targNumCombination(maxIdx,:);
        
        diagIdx = [];
        for x=1:length(targNumCombination)
            if all(targNumCombination(x,:)==mean(targNumCombination(x,:)))
                diagIdx = [diagIdx; x];
            end
        end
        diagRates = topBitRate(diagIdx);
        [maxRateDiag, maxIdxDiag] = max(diagRates);
        bestDiagTargNum = targNumsToUse(maxIdxDiag);
        
        tableRow = [realBitRate, realAccuracy, maxRate, topAccuracy(maxIdx), maxRateDiag, topAccuracy(diagIdx(maxIdxDiag)), bestSkipBins/50, bestWindowBins/50, avgTrialLen, nRealTargs, bestTargComb, bestDiagTargNum];

        header = {'Bit Rate','Accuracy','Opt Bit Rate (all combinations)','Opt Accuracy (all combinations)','Opt Bit Rate (equal target numbers)','Opt Accuracy (equal target numbers)',...
            'Skip Time','Integration Time','Trial Length','Number of Actual Targets','Best Target Combination','Best Equal Target Number'};
        save([outDir filesep datasets{d,3}{blockSetIdx} '_table.mat'],'tableRow','header');
        
    end %blockIdx
end %dataset

%%
%table
datasets = {
    't5.2018.08.20',{[11 12 13],[15],[18 19 20],[21,22,23]},{'Quad_Radial4_Slow','Quad_Radial4_Fast','Quad_Radial8_Slow','Quad_Radial8_Fast'};
    't5.2018.08.22',{[3],[7 8 9],[14],[17 18]},{'Radial8_650','Radial8_1000','Radial8_800','DualJoystick_800'};
    't5.2018.08.27',{[1 3 5]},{'DualJoystick_800'};
    't5.2018.09.05',{[3],[5],[6]},{'Radial8_OL1','Radial8_CL1','Radial8_OL2'};
};

allDat = [];
allRowNames = [];

for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding_targSweep' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    for blockSetIdx=1:length(datasets{d,2})
        if ~exist([outDir filesep datasets{d,3}{blockSetIdx} '_table.mat'],'file')
            continue;
        end
        load([outDir filesep datasets{d,3}{blockSetIdx} '_table.mat'],'tableRow');
        allDat = [allDat; tableRow];
        allRowNames = [allRowNames; {[datasets{d,1} '_' datasets{d,3}{blockSetIdx}]}];
    end
end

csvwrite('DiscreteDecodingTable.csv',allDat);