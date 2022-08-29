%%
movTypes = {[1 2 3 4 5 6 7 8 9 10],'armAndLeg'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

excludeChannels = [];
sessionName = 't5.2018.12.05';
folderName = 'Fig3';

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1200 3200];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep folderName];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, blockList );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 0.5;

allSpikes(:,tooLow) = [];
%allSpikes = gaussSmooth_fast(allSpikes, 30);

globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
baselineMatrix = zeros(length(trlCodes), size(allSpikes,2));
blockRows = zeros(nBins, 1);
validTrl = false(length(trlCodes),1);
globalIdx = 1;

for t=1:length(trlCodes)
    disp(t);
    loopIdx = (alignEvents(t,1)+timeWindow(1)):(alignEvents(t,1)+timeWindow(2));

    if loopIdx(1)<1 || loopIdx(end)>size(allSpikes,1)
        loopIdx(loopIdx<1)=[];
        loopIdx(loopIdx>size(allSpikes,1))=[];
    else
        validTrl(t) = true;
    end
        
    newRow = zeros(nBins, size(allSpikes,2));
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    snippetMatrix(newIdx,:) = newRow;
    
    %baselineIdx = (alignEvents(t,2)-200):(alignEvents(t,2)+200);
    baselineIdx = (alignEvents(t,2)+0):(alignEvents(t,2)+400);
    baselineIdx(baselineIdx<1) = [];
    baselineMatrix(t,:) = mean(allSpikes(baselineIdx,:)*binMS);
end

%%
bNumPerTrial = [R.blockNum];
for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+200)];
    end
    
    binIdx = find(blockRows==blockList(b));
    baselineMatrix(blockTrl,:) = baselineMatrix(blockTrl,:) - mean(snippetMatrix(binIdx,:));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;

baselineMatrix = bsxfun(@times, baselineMatrix, 1./std(snippetMatrix));
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);

%%
clear R allSpikes
pack;

%%
%effector & laterality marginalizations
timeWindow = [-1000 3000];
movWindow = [20, 60];

codeSets = {
    [131 132 134 136 138 139 177 178],...
    [122 123 125 127 129 130 175 176],...
    [148 149 150 152 154 155],...
    [140 141 142 144 146 147],...
    };

reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
movSets = {[122 123 125 127 129 130],[131 132 134 136 138 139]
    [140 141 142 144 146 147],[148 149 150 152 154 155]};
factorMap = [
    122 2 1 1;
    123 2 1 2;
    125 2 1 3;
    127 2 1 4;
    129 2 1 5;
    130 2 1 6;
    175 2 1 7;
    176 2 1 8;
    
    131 1 1 1;
    132 1 1 2;
    134 1 1 3;
    136 1 1 4;
    138 1 1 5;
    139 1 1 6;
    177 1 1 7;
    178 1 1 8;
    
    140 2 2 9;
    141 2 2 10;
    142 2 2 11;
    144 2 2 12;
    146 2 2 13;
    147 2 2 14;
    
    148 1 2 9;
    149 1 2 10;
    150 1 2 11;
    152 1 2 12;
    154 1 2 13;
    155 1 2 14;
    ];

newFactors = nan(length(trlCodes),3);
for t=1:length(trlCodes)
    tableIdx = find(trlCodes(t)==factorMap(:,1));
    if isempty(tableIdx)
        continue;
    end
    newFactors(t,:) = factorMap(tableIdx,2:end);
end

trlIdx = find(~isnan(newFactors(:,1)));

%%
%mPCA for a full overview
margGroupings = {{1, [1 4]}, ...
    {2, [2 4]}, ...
    {[1 2] ,[1 2 4]}, ...
    {4}, ...
    {3, [1 3], [2 3], [3 4], [1 3 4], [2 3 4], [1 2 3], [1 2 3 4]}};
margNames = {'Laterality','Effector','L x E','Time','Movement'};

opts_m.margNames = margNames;
opts_m.margGroupings = margGroupings;
opts_m.nCompsPerMarg = 5;
opts_m.makePlots = true;
opts_m.nFolds = 10;
opts_m.readoutMode = 'singleTrial';
opts_m.alignMode = 'rotation';
opts_m.plotCI = true;

apply_mPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
    newFactors(trlIdx,:), [-100,300], 0.010, opts_m);
    
%%
%cross-validated effector & laterality dimensions; holding out movement
%conditions
cvResults_movHoldOut = cell(2,2);
for outerFactorIdx = 1:2
    for innerFactorIdx = 1:2
        
        if outerFactorIdx==1
            %keep laterality
            trlIdx = find(~isnan(newFactors(:,1)) & newFactors(:,2)==innerFactorIdx);
            reducedFactors = newFactors(trlIdx,[1 3]);
            factorName = 'Laterality';
        else
            %keep effector
            trlIdx = find(~isnan(newFactors(:,1)) & newFactors(:,1)==innerFactorIdx);
            reducedFactors = newFactors(trlIdx,[2 3]);
            factorName = 'Effector';
        end
        [~,~,reducedFactors(:,2)] = unique(reducedFactors(:,2));
        
        margGroupings = {{2, [2 3], [1 2], [1 2 3]}, {1, [1 3]}, {3}};
        margNames = {'Movement',factorName,'Time'};
    
        opts.margNames = margNames;
        opts.margGroupings = margGroupings;
        opts.maxDim = [5 5 5];
        opts.CIMode = 'none';
        opts.orthoMode = 'standard_dpca';
        opts.useCNoise = true;

        dPCA_full = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
            reducedFactors, timeWindow/binMS, binMS/1000, opts);
        close(gcf);
        
        Z = dPCA_full.Z;
        cvComp = zeros(size(Z,2), size(Z,3), size(Z, 4));
        nMov = size(Z,3);
        
        for movIdx=1:nMov
            disp(movIdx);

            trainMov = setdiff(1:nMov, movIdx);
            trlIdx_inner = find(ismember(reducedFactors(:,2), trainMov));

            relabelCodes = reducedFactors(trlIdx_inner,:);
            [~,~,relabelCodes(:,2)] = unique(relabelCodes(:,2));

            dPCA_x = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx(trlIdx_inner)), relabelCodes, [-100,300], 0.010, opts);
            close(gcf);

            latAx = find(dPCA_x.whichMarg==2);
            tmpFA = squeeze(dPCA_full.featureAverages(:,:,movIdx,:));
            cvProj = dPCA_x.W(:,latAx(1))'*tmpFA(:,:);

            sz = size(tmpFA);
            cvProj = reshape(cvProj, sz(2:end));
            cvComp(:,movIdx,:) = cvProj;
        end

        %plot result
        colors = jet(nMov)*0.8;
        ls = {'--','-'};

        figure;
        hold on;
        for fIdx=1:2
            for movIdx=1:nMov
                plot(squeeze(cvComp(fIdx,movIdx,:)),'Color',colors(movIdx,:),'LineStyle',ls{fIdx},'LineWidth',2);
            end
        end
        
        cvResults_movHoldOut{outerFactorIdx, innerFactorIdx} = cvComp;
    end
end

%%
%cross-validated effector & laterality dimensions; holding out effector
%or laterality conditions
cvResult_factorHoldOut = cell(2,2);
for outerFactorIdx = 1:2
    for innerFactorIdx = 1:2
        
        if outerFactorIdx==1
            %keep laterality
            trlIdx = find(~isnan(newFactors(:,1)) & newFactors(:,2)==innerFactorIdx);
            reducedFactors = newFactors(trlIdx,[1 3]);
            factorName = 'Laterality';
            
            if innerFactorIdx==1
                holdOutIdx = 2;
            else
                holdOutIdx = 1;
            end
            trlIdx_holdOut = find(~isnan(newFactors(:,1)) & newFactors(:,2)==holdOutIdx);
            reducedFactors_holdOut = newFactors(trlIdx_holdOut,[1 3]);
        else
            %keep effector
            trlIdx = find(~isnan(newFactors(:,1)) & newFactors(:,1)==innerFactorIdx);
            reducedFactors = newFactors(trlIdx,[2 3]);
            factorName = 'Effector';
            
            if innerFactorIdx==1
                holdOutIdx = 2;
            else
                holdOutIdx = 1;
            end
            trlIdx_holdOut = find(~isnan(newFactors(:,1)) & newFactors(:,1)==holdOutIdx);
            reducedFactors_holdOut = newFactors(trlIdx_holdOut,[2 3]);
        end
        [~,~,reducedFactors(:,2)] = unique(reducedFactors(:,2));
        [~,~,reducedFactors_holdOut(:,2)] = unique(reducedFactors_holdOut(:,2));
        
        margGroupings = {{2, [2 3], [1 2], [1 2 3]}, {1, [1 3]}, {3}};
        margNames = {'Movement',factorName,'Time'};
    
        opts.margNames = margNames;
        opts.margGroupings = margGroupings;
        opts.maxDim = [5 5 5];
        opts.CIMode = 'none';
        opts.orthoMode = 'standard_dpca';
        opts.useCNoise = true;

        %dPCA on the training condition
        dPCA_full = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx), ...
            reducedFactors, timeWindow/binMS, binMS/1000, opts);
        close(gcf);
                
        %dPCA on the hold out condition
        dPCA_full_holdOut = apply_dPCA_general( smoothSnippetMatrix, eventIdx(trlIdx_holdOut), ...
            reducedFactors_holdOut, timeWindow/binMS, binMS/1000, opts);
        close(gcf);
        
        Z = dPCA_full_holdOut.Z;
        cvComp = zeros(size(Z,2), size(Z,3), size(Z, 4));
        nMov = size(Z,3);
        
        %apply training condition axes to held out firing rates
        for fIdx=1:2
            disp(fIdx);

            factorAx = find(dPCA_full.whichMarg==2);
            tmpFA = squeeze(dPCA_full_holdOut.featureAverages(:,fIdx,:,:));
            cvProj = dPCA_full.W(:,factorAx(1))'*tmpFA(:,:);

            sz = size(tmpFA);
            cvProj = reshape(cvProj, sz(2:end));
            cvComp(fIdx,:,:) = cvProj;
        end
        
        %plot result
        colors = jet(nMov)*0.8;
        ls = {'--','-'};

        figure;
        hold on;
        for fIdx=1:2
            for movIdx=1:nMov
                plot(squeeze(cvComp(fIdx,movIdx,:)),'Color',colors(movIdx,:),'LineStyle',ls{fIdx},'LineWidth',2);
            end
        end
        
        cvResult_factorHoldOut{outerFactorIdx, innerFactorIdx} = cvComp;
    end
end

%%
%plot laterality & effector dimension squares
%row: fitting condition
%column: testing condition
timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))/100;
yLimits = {[-1.7, 2.7],[-0.75, 1.65]};
legendLabels = {{'Contra.','Ipsi.'},{'Arm','Leg'}};
figNames = {'laterality_xval','eff_xval'};

for outerFactorIdx=1:2
    figure('Position',[680   821   390   277]);
    for rowIdx = 1:2
        for colIdx = 1:2
            %plot
            if rowIdx==colIdx
                useDat = cvResults_movHoldOut{outerFactorIdx,rowIdx};
            else
                useDat = cvResult_factorHoldOut{outerFactorIdx,rowIdx};
            end

            subtightplot(2,2,(rowIdx-1)*2 + colIdx, [0.03 0.03], [0.18 0.03],[0.16 0.01]);
            hold on;
            
            lHandles = zeros(2,1);
            for fIdx=1:2
                for movIdx=1:size(useDat,2)
                    if outerFactorIdx==1
                        %laterality
                        colors = lines(2);
                        lHandles(fIdx)=plot(timeAxis,squeeze(useDat(fIdx,movIdx,:)),'Color',colors(fIdx,:),'LineStyle','-','LineWidth',2);
                    else
                        %effector
                        colors = lines(4);
                        colors = colors(3:4,:);
                        lHandles(fIdx)=plot(timeAxis,squeeze(useDat(fIdx,movIdx,:)),'Color',colors(fIdx,:),'LineStyle','-','LineWidth',2);
                    end
                end
            end
            ylim(yLimits{outerFactorIdx});
            xlim([timeAxis(1), timeAxis(end)]);
            
            if colIdx==2
                set(gca,'YTickLabels',[]);
            else
                ylabel('Rate (SD)');
            end
            if rowIdx==1
                set(gca,'XTickLabels',[]);
            else
                xlabel('Time (s)');
            end
            if rowIdx==1 && colIdx==1
                legend(lHandles, legendLabels{outerFactorIdx}, 'Box', 'off','AutoUpdate','off');
            end
            set(gca,'FontSize',16,'LineWidth',2);
            
            plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
            plot([1.5,1.5],get(gca,'YLim'),'--k','LineWidth',2);
        end
    end
    
    saveas(gcf,[outDir filesep figNames{outerFactorIdx} '.png'],'png');
    saveas(gcf,[outDir filesep figNames{outerFactorIdx} '.svg'],'svg');
end

%%
%similarity matrix across movements using correlation
dPCA_all = apply_dPCA_simple( snippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

nCon = size(dPCA_all.featureAverages,2);
analysisWindows = {70:110, 70:150, 1:50};
windowNames = {'move1','move2','prep'};

for windowIdx=1:length(analysisWindows)
    effSets = {[1:6, 25:26], [7:12, 27:28], 13:18, 19:24, 29};
    cWindow = analysisWindows{windowIdx};

    simMatrix = plotCorrMat_cv( dPCA_all.featureVals(:,:,:,1:30), cWindow, [], effSets, [] );

%     simMatrix = zeros(nCon, nCon);
%     fa = dPCA_all.featureAverages(:,:,cWindow);
%     fa = fa(:,:)';
%     fa = mean(fa);
% 
%     subractEffMean = true;
%     setIdx = {[1:6, 25:26], [7:12, 27:28], 13:18, 19:24, 29};
%     effMeans = zeros(length(fa), length(setIdx));
%     setMemberships = zeros(29,1);
% 
%     for s=1:length(setIdx)
%         tmp = dPCA_all.featureAverages(:,setIdx{s},cWindow);
%         tmp = tmp(:,:);
% 
%         effMeans(:,s) = mean(tmp');
%         setMemberships(setIdx{s}) = s;
%     end
% 
%     for x=1:nCon
%         avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
%         avgTraj = mean(avgTraj(cWindow,:)); %-fa;
%         if subractEffMean
%             avgTraj = avgTraj - effMeans(:,setMemberships(x))';
%         else
%             avgTraj = avgTraj - fa;
%         end
% 
%         for y=1:nCon
%             avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
%             avgTraj_y = mean(avgTraj_y(cWindow,:)); %-fa;
%             if subractEffMean
%                 avgTraj_y = avgTraj_y - effMeans(:,setMemberships(y))';
%             else
%                 avgTraj_y = avgTraj_y - fa;
%             end
% 
%             simMatrix(x,y) = corr(avgTraj', avgTraj_y');
%         end
%     end

    reorderIdx = [1:6, 25:26, 7:12, 27:28, 13:24];
    simMatrix = simMatrix(reorderIdx,reorderIdx);

    figure('Position',[680   866   391   232]);
    crossMats = {simMatrix(1:8,9:16), simMatrix(17:22,23:28)};
    titles = {'Arm','Leg'};
    for c=1:length(crossMats)
        cMat = crossMats{c};
        diagEntries = 1:(size(cMat,1)+1):numel(cMat);
        otherEntries = setdiff(1:numel(cMat), diagEntries);    

        subplot(1,2,c);
        hold on
        plot((rand(length(diagEntries),1)-0.5)*0.55, cMat(diagEntries), 'o');
        plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, cMat(otherEntries), 'ro');
        set(gca,'XTick',[0 1],'XTickLabel',{'Same','Different'},'XTickLabelRotation',45);
        ylim([-1.0,1.0]);
        ylabel('Correlation');
        set(gca,'FontSize',20,'LineWidth',2);
        xlim([-0.5,1.5]);
        title(titles{c});
    end 
    saveas(gcf,[outDir filesep 'corrDots_' windowNames{windowIdx} '.png'],'png');
    saveas(gcf,[outDir filesep 'corrDots_' windowNames{windowIdx} '.svg'],'svg');

    crossMat1 = simMatrix(1:8, 9:16);
    diagEntries = 1:9:numel(crossMat1);
    otherEntries = setdiff(1:numel(crossMat1), diagEntries);
    anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
        [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);
    disp(mean(crossMat1(diagEntries)'));
    disp(mean(crossMat1(otherEntries)'));

    crossMat1 = simMatrix(17:22, 23:28);
    diagEntries = 1:7:numel(crossMat1);
    otherEntries = setdiff(1:numel(crossMat1), diagEntries);
    anova1([crossMat1(diagEntries)'; crossMat1(otherEntries)'], ...
        [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);
    disp(mean(crossMat1(diagEntries)'));
    disp(mean(crossMat1(otherEntries)'));

    movLabels = {'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
        'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen','IndexRaise','ThumbRaise',...
        'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen',...
        'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen'};
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    plotSets = {1:16, 17:28, [1:6, 19 20 17 18 21 22]};
    fPos = {[680   678   560   420],[721   767   406   302],[680   678   560   420]};
    for plotIdx=1:length(plotSets)
        figure('Position',fPos{plotIdx});
        imagesc(simMatrix(plotSets{plotIdx},plotSets{plotIdx}),[-1 1]);
        set(gca,'XTick',1:nCon,'XTickLabel',movLabels(plotSets{plotIdx}),'XTickLabelRotation',45);
        set(gca,'YTick',1:nCon,'YTickLabel',movLabels(plotSets{plotIdx}));
        set(gca,'FontSize',16);
        set(gca,'YDir','normal');
        colormap(cMap);
        colorbar;

        if plotIdx==1
            colors = [173,150,61;
                119,122,205;]/255;
            idxSets = {1:8, 9:16}; 
        elseif plotIdx==2
            colors = [91,169,101;
                197,90,159;]/255;
            idxSets = {1:6,7:12}; 
        else
            colors = [91,169,101;
                197,90,159;]/255;
            idxSets = {1:6,7:12};         
        end

        for setIdx = 1:length(idxSets)
            newIdx = idxSets{setIdx};
            rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
        end
        axis tight;

        saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '_' windowNames{windowIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '_' windowNames{windowIdx} '.svg'],'svg');
    end
end