%%
%see movementTypes.m for code definitions
allMovTypes = {
    {[1 2],'head'
    [3],'bci_ol'
    [4 5 6],'bci_cl'}
    
    {[1 2],'head'
    [6],'bci_ol_1'
    [8],'bci_cl_1'
    [10],'bci_ol_2'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [13],'bci_cl_4'
    [14],'bci_cl_5'
    }

    {[2 3],'head'
    [4],'bci_ol_1'
    [5],'bci_ol_2'
    [6],'bci_ol_3'
    [7],'bci_cl_1'
    [8],'bci_cl_free'
    [11],'bci_cl_2'
    [12],'bci_cl_3'
    [14],'bci_cl_4'
    }
    
    {[10],'head'
    [11],'eye'
    [12],'bci_ol'
    [15],'bci_cl_1'
    [16],'bci_cl_2'
    [17],'bci_cl_3'
    }
    
    {[7],'head'
    [8],'bci_ol'
    [9],'bci_cl_1'
    [10],'bci_cl_2'
    [12],'bci_cl_iFix'
    }
    
    };

allFilterNames = {'011-blocks013_014-thresh-4.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks013_014-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'009-blocks011_012_014-thresh-3.5-ch80-bin15ms-smooth25ms-delay0ms.mat'
'008-blocks016_017-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
'003-blocks010-thresh-3.5-ch60-bin15ms-smooth25ms-delay0ms.mat'
};

allSessionNames = {'t5.2017.12.27','t5.2018.01.08','t5.2018.01.17','t5.2018.01.19','t5.2018.01.22'};

allCrossCon = {[1 2 3],[1 2 4 5 8],[1 4 9],[1 2 3 4 5 6],[1 2 3 4 5]};
allCrossPostfix = {{'_within','_crossHead','_crossOL','_crossCL'},
    {'_within','_crossHead','_crossOL1','_crossOL2','_crossCL2','_crossCL5'};
    {'_within','_crossHead','_crossOL3','_crossCL4'}
    {'_within','_crossHea','_crossEye','_crossOL','_crossCL1','_crossCL2','_crossCL3'}
    {'_within','_crossHead','_crossOL','_crossCL1','_crossCL2','_crossCLiF'}};
allMoveTypeText = {{'Head','OL','CL'},{'Head','OL 1','CL 1','OL 2','CL 2','CL 3','CL 4','CL 5'},...
    {'Head','OL 1','OL 2','OL 3','CL 1','CL F','CL 2','CL 3','CL 4'},...
    {'Head','Eye','OL','CL 1','CL 2','CL 3'},...
    {'Head','OL','CL 1','CL 2','CL iF'}};

for outerSessIdx = 1:length(allSessionNames)
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    sessionName = allSessionNames{outerSessIdx};
    filterName = allFilterNames{outerSessIdx};
    movTypes = allMovTypes{outerSessIdx};
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'head_vs_bci_oDec' filesep allSessionNames{outerSessIdx}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

    %%
    %load cursor filter for threshold values, use these across all movement types
    model = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
        filterName]);
    
    filts = dir([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters']);
    remIdx = false(length(filts),1);
    for t=1:length(filts)
        tmp = strfind(filts(t).name,'.mat');
        remIdx(t) = isempty(tmp);
    end
    filts(remIdx) = [];
    
    allFilts = cell(length(filts),1);
    for t=1:length(allFilts)
        allFilts{t} = load([paths.dataPath filesep 'BG Datasets' filesep sessionName filesep 'Data' filesep 'Filters' filesep ...
            filts(t).name]);
    end
    
    %%
    %load cued movement dataset
    R = getSTanfordBG_RStruct( sessionPath, horzcat(movTypes{:,1}), model.model );

    smoothWidth = 0;
    if outerSessIdx>=4
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget','xk'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget','xk'};
    end
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    alignFields = {'timeGoCue'};
    smoothWidth = 30;
    if outerSessIdx>=4
        datFields = {'windowsPC1LeftEye','windowsMousePosition','cursorPosition','currentTarget'};
    else
        datFields = {'windowsMousePosition','cursorPosition','currentTarget'};
    end
    timeWindow = [-100, 1000];
    binMS = 20;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    %%
    %decoding accuracy
    for decIdx=1:length(allFilts)
        timeStart = 0:30;
        decAcc = zeros(size(movTypes,1),length(timeStart),2);
        currentDec = allFilts{decIdx}.model;
        centeredSpike = bsxfun(@times, unrollDat.meanSubtractSpikes, currentDec.invSoftNormVals(1:192)');
        
        for x=1:size(movTypes,1)
            isc = [R.isSuccessful];
            ns = find(~isc);
            isc(ns-1) = false;
            isc(ns+1) = false;

            trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{x,1}) & isc');

            decVectors = centeredSpike * currentDec.K([2 4],1:192)';
            posErr = unrollDat.currentTarget(:,1:2) - unrollDat.cursorPosition(:,1:2);

            tmpC = zeros(length(timeStart),1);
            for t=1:length(timeStart)
                %corr
                re = [unrollDat.trialEpochs(trlIdx,1)+timeStart(t), unrollDat.trialEpochs(trlIdx,1)+timeStart(t)+10];
                loopIdxBeginning = expandEpochIdx(re);

                cMat = corr(decVectors(loopIdxBeginning,:), posErr(loopIdxBeginning,:));
                decAcc(x,t,1) = mean(diag(cMat));

                %SNR
                unitVec = bsxfun(@times, posErr(loopIdxBeginning,:), 1./matVecMag(posErr(loopIdxBeginning,:),2));
                [B_x,B_xint,~,~,STATS_x] = regress(decVectors(loopIdxBeginning,1), [ones(size(unitVec,1),1), unitVec(:,1)]);
                [B_y,B_yint,~,~,STATS_y] = regress(decVectors(loopIdxBeginning,2), [ones(size(unitVec,1),1), unitVec(:,2)]);
                SNR = [B_x(2)/sqrt(STATS_x(end)), B_y(2)/sqrt(STATS_y(end))];
                decAcc(x,t,2) = mean(SNR);
            end
        end

        figure('Position',[680   838   772   260]);
        subplot(1,2,1);
        bar(max(squeeze(decAcc(:,:,1))'),'LineWidth',2);
        set(gca,'XTickLabel',allMoveTypeText{outerSessIdx},'XTickLabelRotation',45,'FontSize',16);
        ylabel('R');

        subplot(1,2,2);
        bar(max(squeeze(decAcc(:,:,2))'),'LineWidth',2);
        set(gca,'XTickLabel',allMoveTypeText{outerSessIdx},'XTickLabelRotation',45,'FontSize',16);
        ylabel('SNR');

        saveas(gcf,[outDir filesep 'decAcc_bar_' num2str(decIdx) '.png'],'png');
        saveas(gcf,[outDir filesep 'decAcc_bar_' num2str(decIdx) '.svg'],'svg');

        figure('Position',[680   838   772   260]);
        subplot(1,2,1);
        plot(timeStart*0.02,squeeze(decAcc(:,:,1))','LineWidth',2);
        legend(allMoveTypeText{outerSessIdx},'Location','SouthEast');
        ylabel('R');

        subplot(1,2,2);
        plot(timeStart*0.02,squeeze(decAcc(:,:,2))','LineWidth',2);
        legend(allMoveTypeText{outerSessIdx},'Location','SouthEast');
        ylabel('SNR');

        saveas(gcf,[outDir filesep 'decAcc_' num2str(decIdx) '.png'],'png');
        saveas(gcf,[outDir filesep 'decAcc_' num2str(decIdx) '.svg'],'svg');
        
        mText = allMoveTypeText{outerSessIdx};
        save([outDir filesep 'decAcc_pd_' num2str(decIdx) '.mat'],'decAcc','pdCMat','mText');
    end
    
    %%
%     %cross decoding
%     decVec = cell(length(allFilts),1);
%     for x=1:length(allFilts)
%         currentDec = allFilts{x}.model;
%         decVec{x} = zeros(size(alignDat.meanSubtractSpikes,1),2);
%         coef = bsxfun(@times, currentDec.K([2 4],1:192), currentDec.invSoftNormVals(1:192)')';
%         
%         for y=1:size(movTypes,1)
%             trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{y,1})); 
%             loopIdx = expandEpochIdx([alignDat.eventIdx(trlIdx,1)+timeWindow(1)/binMS, ...
%                 alignDat.eventIdx(trlIdx,1)+timeWindow(2)/binMS]);
%             loopIdx(loopIdx<1) = [];
%             loopIdx(loopIdx>length(alignDat.meanSubtractSpikes)) = [];
%             decVec{x}(loopIdx,:) = alignDat.meanSubtractSpikes(loopIdx,:) * coef;
%         end
%     end
%     
%     colors = hsv(8)*0.8;
%     nCon = size(movTypes,1);
%     nDec = length(decVec);
%     yLimsAll = zeros(nDec, nCon, 2);
%     axIdx = zeros(nDec,nCon);
%     dimNames = {'X','Y'};
%     
%     for dimIdx = 1:2
%         figure('Position',[46         116        1064         989]);
%         for x=1:nDec
%             yLims = [];
%             for y=1:nCon
%                 axIdx(x,y) = subtightplot(nDec, nCon, (x-1)*nCon + y);
%                 hold on;
%                 
%                 trlIdx = find(ismember(alignDat.bNumPerTrial,movTypes{y,1}));     
%                 isSucc = [R(trlIdx).isSuccessful];
%                 trlIdx(~isSucc) = [];
%                 
%                 posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
%                 dirCodes = dirTrialBin( posErr, 8 );
%                 
%                 for dirIdx=1:8
%                     cDat = triggeredAvg(decVec{x}(:,dimIdx), alignDat.eventIdx(trlIdx(dirCodes==dirIdx)), timeWindow/binMS);
%                     mn = mean(cDat);
%                     plot(mn,'Color',colors(dirIdx,:),'LineWidth',2);
%                 end
%                 
%                 xlim([1 length(mn)]);
%                 set(gca,'XTick',[],'YTick',[],'FontSize',16);
%                 axis tight;
%                 yLims = [yLims; get(gca,'YLim')];
%                 if y==1
%                     ylabel(['Dec ' num2str(x)]);
%                 end
%                 if x==nDec
%                     xlabel(allMoveTypeText{outerSessIdx}{y});
%                 end
%                 yLimsAll(x,y,:) = get(gca,'YLim');
%             end
%             
%             %for t=1:length(axIdx)
%             %    set(axIdx(t),'YLim',yLims(x,:));
%             %end
%         end
%         
%         finalLims = zeros(1,2);
%         finalLims(1) = min(yLimsAll(:));
%         finalLims(2) = max(yLimsAll(:));
%         for x=1:nDec
%             for y=1:nCon
%                 set(axIdx(x,y),'YLim',finalLims);
%             end
%         end
%         
%         saveas(gcf,[outDir filesep 'CrossDec_' dimNames{dimIdx} '.png'],'png');
%         saveas(gcf,[outDir filesep 'CrossDec_' dimNames{dimIdx} '.svg'],'svg');
%     end
%     
    %%
    close all;
end