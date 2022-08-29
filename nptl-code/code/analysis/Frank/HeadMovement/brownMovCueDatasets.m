%t10 - cued different types of arm/hand movement only
%t9 - has arm plus tongue and ankle (Imagery: Cues: Tongue, Ankle,
%Shoulder, Elbow, Wrist, R. Fist, Fingers, Palm, L. Fist)
%t7 - has multiple leg, head and face cues
%t6 - cued different arm/hand movement plus tongue
%t3 - has torso, head, face, & leg cues
%t1 - has head and leg movements, but it is unclear from the session log if
%t1 was properly paying attention / executing the task correctly
%s3 - hand/arm cues only

%s2 - examined the "imagined movement" sessions, seemed to be only
%arm-related
%s1 and a1 - extracted documents but they are unlabeled; appear to have
%assesed foot-based modulation and compared to hand and arm, but data
%format is unknown and session flow is unclear. 

%t9, t7, t3, t1

%%
rootDir = '/Users/frankwillett/Data/BG Datasets/movementSweepDatasets';
saveDir = [rootDir filesep 'processedDatasets'];
outDirRoot = '/Users/frankwillett/Data/Derived/movementSweepBrown/';

sessionList = {'t7.2013.08.23 Whole body cued movts, new cable (TOUCH)','t9.2015.03.30 Cued Movements','t3.2011.07.20 Cued Movements',...
    't1.2010.03.15 imagined cued movements','t1.2010.05.10 Cued Movements v2','t1.2010.05.13 Cued Movements v2'};
for sessIdx=1
    load([saveDir filesep sessionList{sessIdx} '.mat']);
    
    %remove trials with no neural data
    remIdx = [];
    for t=1:length(dataset.goCueIdx)
        loopIdx = (-200:200)+dataset.goCueIdx(t);
        loopIdx(loopIdx<1) = [];
        loopIdx(loopIdx>length(dataset.features.nsp_sp))=[];
        if any(all(dataset.features.nsp_sp(loopIdx,:)==0,2))
            remIdx = [remIdx, t];
        end
    end
    dataset.goCueIdx(remIdx) = [];
    dataset.movCues(remIdx) = [];
    
    %make cue sets 
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        cueSets = {[1,2],[3,4],[5,6],[7,8],[9,10],[11,12],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [13,14,15,16,17,18,19,20,25,26,27,28],[13,15,17,19,25,28],[1,2,3,4,5,6,7,8,9,10,11,12]};
        psthSets = [18,16];
    elseif strcmp(sessionList{sessIdx}, 't9.2015.03.30 Cued Movements')
        cueSets = {[-20, 20],[-19, 19],[-18, 18],[-17, 17],[-16, 16],[-15, 15],[-14, 14],[-13, 13],[-12, 12],...
            [-12, 12, -13, 13],[-20, 20, -19, 19, -18, 18, -17, 17, -16, 16, -15, 15, -14, 14]};
        psthSets = [10,11];
    elseif strcmp(sessionList{sessIdx}, 't3.2011.07.20 Cued Movements')
        cueSets = {[1,2],[3,4],[4,5],[6,7],[8,9],[10,11],[11,12],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [29,30],[31,32],[33,34],[35,36],[37,38],[39,40]};
    elseif strcmp(sessionList{sessIdx}, 't1.2010.03.15 imagined cued movements')
        cueSets = {[1,2],[3,4],[4,5],[6,7],[8,9],[10,11],[11,12],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [29,30],[31,32],[33,34],[35,36],[37,38]};
    elseif strcmp(sessionList{sessIdx}, 't1.2010.05.10 Cued Movements v2')
        cueSets = {[1,2],[3,4],[5,6],[7,8],[9,10],[11,2],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [29,30],[31,32],[33,34],[35,36],[37,38],[39,40],[41,42],[43,44]};
    elseif strcmp(sessionList{sessIdx}, 't1.2010.05.13 Cued Movements v3')
        cueSets = {[1,2],[3,4],[5,6],[7,8],[9,10],[11,2],[13,14],[15,16],[17,18],[19,20],[21,22],[23,24],[25,26],[27,28],...
            [29,30],[31,32],[33,34],[35,36],[37,38],[39,40],[41,42],[43,44]};
    end
    
    %convert all features to double precision
    featNames = fieldnames(dataset.features);
    for f=1:length(featNames)
        dataset.features.(featNames{f}) = double(dataset.features.(featNames{f}));
    end
    
    %mean-subract for each block
    blockList = unique(dataset.blockIdx);
    for b=1:length(blockList)
        loopIdx = dataset.blockIdx==blockList(b);
        for f=1:length(featNames)
            dataset.features.(featNames{f})(loopIdx,:) = dataset.features.(featNames{f})(loopIdx,:)-mean(dataset.features.(featNames{f})(loopIdx,:));
        end
    end
    
    %z-score all features
    for f=1:length(featNames)
        dataset.features.(featNames{f}) = zscore(dataset.features.(featNames{f}));
    end
    
    %smooth features
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        neuralFeatures = gaussSmooth_fast([dataset.features.nsp_tx2, dataset.features.nsp_sp], 3);
    elseif strcmp(sessionList{sessIdx}, 't9.2015.03.30 Cued Movements')
        neuralFeatures = gaussSmooth_fast(dataset.features.slcSP, 3);
    elseif strcmp(sessionList{sessIdx}, 't3.2011.07.20 Cued Movements')
        neuralFeatures = gaussSmooth_fast(dataset.features.slcSP, 1.5);
    elseif strcmp(sessionList{sessIdx}, 't1.2010.03.15 imagined cued movements')
        neuralFeatures = gaussSmooth_fast(dataset.features.nsp_tx2, 3);
    elseif strcmp(sessionList{sessIdx}, 't1.2010.05.10 Cued Movements v2')
        neuralFeatures = gaussSmooth_fast(dataset.features.nsp_tx2, 3);
    elseif strcmp(sessionList{sessIdx}, 't1.2010.05.13 Cued Movements v2')
        neuralFeatures = gaussSmooth_fast(dataset.features.nsp_tx2, 3);
    end
    
    %dPCA all
    timeWindow = [-200, 200];
    dPCA_out = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx, ...
        dataset.movCues, timeWindow, 0.02, {'CD','CI'} );

    lineArgs = cell(length(unique(dataset.movCues)),1);
    colors = jet(length(lineArgs))*0.8;
    for l=1:length(lineArgs)
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
    end

    oneFactor_dPCA_plot( dPCA_out,  timeWindow(1):timeWindow(2), ...
        lineArgs, {'CD','CI'}, 'sameAxes');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'dPCA_all.png'],'png');
    
    %%
    nCon = size(dPCA_out.featureAverages,2);
    simMatrix = zeros(nCon, nCon);

%     for x=1:nCon
%         %get the top dimensions this movement lives in
%         avgTraj = squeeze(dPCA_out.featureAverages(:,x,:))';
%         avgTraj = mean(avgTraj(110:150,:));
% 
%         for y=1:nCon
%             avgTraj_y = squeeze(dPCA_out.featureAverages(:,y,:))';
%             avgTraj_y = mean(avgTraj_y(110:150,:));
% 
%             simMatrix(x,y) = corr(avgTraj', avgTraj_y');
%         end
%     end

    for x=1:nCon
        %get the top dimensions this movement lives in
        avgTraj = squeeze(dPCA_out.featureAverages(:,x,:))';
        avgTraj = avgTraj - mean(avgTraj);
        %avgTraj = avgTraj - mean(avgTraj,2);

        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
        topDim = COEFF(:,1:4);

        for y=1:nCon
            avgTraj_y = squeeze(dPCA_out.featureAverages(:,y,:))';
            avgTraj_y = avgTraj_y - mean(avgTraj_y);
            %avgTraj_y = avgTraj_y - mean(avgTraj_y,2);

            reconTraj = (avgTraj_y*topDim)*topDim';
            errTraj = avgTraj_y - reconTraj;

            SSTOT = sum(avgTraj_y(:).^2);
            SSERR = sum(errTraj(:).^2);

            simMatrix(x,y) = 1 - SSERR/SSTOT;
        end
    end

    reorderIdx = [17:20, 13:16, 1:12, 25:28];
    
    figure
    imagesc(simMatrix(reorderIdx,reorderIdx));
    set(gca,'FontSize',16);
    set(gca,'XTick',1:size(simMatrix,1),'XTickLabels',dataset.cueLabels(reorderIdx),'XTickLabelRotation',45);
    set(gca,'YTick',1:size(simMatrix,1),'YTickLabels',dataset.cueLabels(reorderIdx));
    set(gca,'YDir','normal');

    %%
    %dPCA by paried sets
    timeWindow = [0,100];
    cVar = zeros(length(cueSets),4);
    for setIdx=1:14
        trlIdx = find(ismember(dataset.movCues, cueSets{setIdx}));
        
        mc = dataset.movCues(trlIdx);
        %mc = mc(randperm(length(mc)));
        dPCA_out = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mc, timeWindow, 0.02, {'CD','CI'}, 20, 'xval' );
        close(gcf);
        
        lineArgs = cell(length(unique(dataset.movCues(trlIdx))),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end

        oneFactor_dPCA_plot_pretty( dPCA_out,  timeWindow(1):timeWindow(2), ...
            lineArgs, {'CD','CI'}, 'sameAxes', [], [], dPCA_out.dimCI, colors);
        
        cueList = unique(dataset.movCues);
        [~,cueRemapIdx] = ismember(cueSets{setIdx}, cueList);
        text(0,0.6,[dataset.cueLabels{cueRemapIdx(1)} ' vs ' dataset.cueLabels{cueRemapIdx(2)}],'Units','normalized','FontSize',14);
        saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'dPCA_set' num2str(setIdx) '.png'],'png');
        
        %modulation size
        cdIdx = find(dPCA_out.cval.whichMarg==1);
        cdIdx = cdIdx(1:3);
        nTrials = size(dPCA_out.cval.Z_singleTrial,1);
    
        movWindow = 10:50;
        timeOffset = -timeWindow(1);
        mov1Activity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,1,timeOffset+movWindow));
        mov2Activity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,2,timeOffset+movWindow));
        
        dataMatrix = [nanmean(mov1Activity,3); nanmean(mov2Activity,3)];
        dataLabels = zeros(nTrials*2,1);
        dataLabels(1:nTrials) = 1;
        dataLabels((nTrials+1):end) = 2;
        
        badIdx = find(any(isnan(dataMatrix),2));
        dataMatrix(badIdx,:) = [];
        dataLabels(badIdx,:) = [];

        nResample = 10000;
        
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)));
        end
    
        cVar(setIdx,1) = testStat;
        cVar(setIdx,2) = prctile(resampleVec,99);
        
        dm1 = dataMatrix(dataLabels==1,:);
        dm2 = dataMatrix(dataLabels==2,:);
        minLen = min(size(dm1,1), size(dm2,1));
        dm1 = dm1(1:minLen,:);
        dm2 = dm2(1:minLen,:);
        
        ci = bootci(nResample, {@normStat, dm1, dm2});
        cVar(setIdx,3:4) = ci;    
    end
    
    close all;
    
    %%
    figure;
    plot(cVar(1:14,:),'LineWidth',2);
    set(gca,'XTick',1:14,'XTickLabel',dataset.cueLabels(1:2:end),'XTickLabelRotation',45,'FontSize',14,'LineWidth',2);
    
    mean(cVar(1:6,1))
    mean(cVar(7:8,1))
    mean(cVar(9:10,1))
    mean(cVar(13:14,1))
    
    %%
    %PSTHS
    cueList = unique(dataset.movCues);
    lineArgs = cell(length(cueList),1);
    colors = hsv(length(cueList))*0.8;
    colors = colors(randperm(length(colors)),:);
    for x=1:length(cueList)
        lineArgs{x} = {'LineWidth',1,'Color',colors(x,:)};
    end
    
    [a,b,remapCues]=unique(dataset.movCues);
    remapSets = cueSets(psthSets);
    for setIdx=1:length(remapSets)
        for x=1:length(remapSets{setIdx})
            remapSets{setIdx}(x) = find(remapSets{setIdx}(x)==a);
        end
    end

    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {neuralFeatures};
    psthOpts.timeWindow = [-100,100];
    psthOpts.trialEvents = dataset.goCueIdx;
    psthOpts.trialConditions = remapCues;
    psthOpts.conditionGrouping = remapSets;
    psthOpts.lineArgs = lineArgs;

    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = [outDirRoot sessionList{sessIdx}];

    featLabels = cell(size(neuralFeatures,2),1);
    for f=1:length(featLabels)
        featLabels{f} = num2str(f);
    end
    psthOpts.featLabels = featLabels;

    psthOpts.prefix = 'all';
    psthOpts.plotCI = 1;
    psthOpts.CIColors = colors;
    makePSTH_simple(psthOpts);
    
    close all;
    
    figure
    hold on
    for x=1:size(colors,1)
        plot(randn(2,1), randn(2,1), 'Color', colors(x,:), 'LineWidth', 2);
    end
    legend(dataset.cueLabels);
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'psthLegend.png'],'png');

    %%
    %decoding
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        windowIdx = 10:40;
        windowIdx2 = 41:80;
        decDataset = dataset;
        eyeTrials = find(ismember(dataset.movCues, 21:24));
        decDataset.goCueIdx(eyeTrials) = [];
        decDataset.movCues(eyeTrials) = [];
        decDataset.cueLabels(21:24) = [];
        decDataset.cueOrdering = [17:20, 13:16, 1:12, 21:24];
    else
        windowIdx = 10:50;
        decDataset = dataset;
        decDataset.cueLabels = {'LeftHandOpen','Pronate','FingersIn','RightHandOpen','WristFlex','ElbowExt','ArmLower','AnkleDown',...
            'TongueIn','TongueOut','AnkleUp','ArmRaise','ElbowFlex','WristExt','RightHandClose','FingersSpread','Supinate','LeftHandClose'};
         decDataset.cueOrdering = [9 10 1 18 2 17 3 16 4 15 5 14 6 13 7 12 8 11];
    end
    
    allFeatures = [];
    allCodes = [];
    for trlIdx=1:length(decDataset.goCueIdx)
        loopIdx = windowIdx + decDataset.goCueIdx(trlIdx);
        loopIdx2 = windowIdx2 + decDataset.goCueIdx(trlIdx);
        loopIdx3 = windowIdx3 + decDataset.goCueIdx(trlIdx);
        allFeatures = [allFeatures; mean(neuralFeatures(loopIdx,:)), mean(neuralFeatures(loopIdx2,:))];
        allCodes = [allCodes; decDataset.movCues(trlIdx)];
    end
    
    %armIdx = find(~ismember(allCodes, cueSets{15}));
    %allFeatures(armIdx,:) = [];
    %allCodes(armIdx,:)=[];

    %obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear','Prior','uniform','OptimizeHyperparameters','all');
    %obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear','Prior','uniform');
    %obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','linear','Prior','uniform','Delta',0.005,'Gamma',0.27);
    %if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
    %    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diagQuadratic','Prior','uniform','Gamma',0);
    %else
    %    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','linear','Prior','uniform','Delta',0.005,'Gamma',0.27);
    %end
    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
    
    cvmodel = crossval(obj);
    L = kfoldLoss(cvmodel);
    predLabels = kfoldPredict(cvmodel);

    C = confusionmat(allCodes, predLabels);
    C_counts = C;
    for rowIdx=1:size(C,1)
        C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
    end
    
    for r=1:size(C_counts,1)
        [PHAT, PCI] = binofit(C_counts(r,r),sum(C_counts(r,:)),0.05); 
        disp(decDataset.cueLabels(r));
        disp(PCI);
    end
    
    figure('Position',[680   616   642   482]); 
    imagesc(C(decDataset.cueOrdering, decDataset.cueOrdering));
    set(gca,'XTick',1:length(C),'XTickLabel',decDataset.cueLabels(decDataset.cueOrdering),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(C),'YTickLabel',decDataset.cueLabels(decDataset.cueOrdering));
    title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colormap(parula);
    colorbar;
        
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        colorSetIdx = {1:2, 3:4, 5:8, 9:20, 21:24};
        colors = [173,150,61;
        119,122,205;
        91,169,101;
        197,90,159;
        202,94,74]/255;
    else
        colorSetIdx = {1:2, 3:16, 17:18};
        colors = [119,122,205;
        197,90,159;
        202,94,74]/255;        
    end

    currentColor = 1;
    for c=1:length(colorSetIdx)
        newIdx = colorSetIdx{c};
        rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(c,:));
    end
    axis tight;
    
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.svg'],'svg');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecodeAll.pdf'],'pdf');
    
    cueList = unique(dataset.movCues);
    
    %figure('Position',[680   181   912   917]);
    for setIdx=1:length(cueSets)
        setTrlIdx = find(ismember(dataset.movCues, cueSets{setIdx}));
        
        allFeatures = [];
        allCodes = [];
        allLoopIdx = [];
        for trlIdx=1:length(setTrlIdx)
            loopIdx = windowIdx + dataset.goCueIdx(setTrlIdx(trlIdx));
            allFeatures = [allFeatures; mean(neuralFeatures(loopIdx,:))];
            allCodes = [allCodes; dataset.movCues(setTrlIdx(trlIdx))];
            allLoopIdx = [allLoopIdx, loopIdx];
        end

        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear','Prior','uniform');
        %if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        %    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diagQuadratic','Prior','uniform','Gamma',0);
        %else
        %    %obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','linear','Prior','uniform','Delta',0.005,'Gamma',0.27);
        %    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear','Prior','uniform');
        %end
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        predLabels = kfoldPredict(cvmodel);

        C = confusionmat(allCodes, predLabels);
        [~,cueIdx]=ismember(cueSets{setIdx}, cueList);

        %subplot(4,4,setIdx);
        figure;
        imagesc(C);
        set(gca,'XTick',1:length(C),'XTickLabel',dataset.cueLabels(cueIdx),'XTickLabelRotation',45);
        set(gca,'YTick',1:length(C),'YTickLabel',dataset.cueLabels(cueIdx));
        title(['Accuracy=' num2str(1-L)]);
        set(gca,'FontSize',16);
        colormap(jet);    
        saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'discreteDecode_set' num2str(setIdx) '.png'],'png');
        
        [PHAT, PCI] = binofit(sum(predLabels==allCodes),length(allCodes),0.01); 
        disp(dataset.cueLabels(cueIdx));
        disp(PCI);
    end
    
    close all;
    
    %%
    %correlation
    featAvg = zeros(length(dataset.goCueIdx),size(neuralFeatures,2));
    for trlIdx=1:length(dataset.goCueIdx)
        windowIdx = (0:99)+dataset.goCueIdx(trlIdx);
        featAvg(trlIdx,:) = mean(neuralFeatures(windowIdx,:));
    end
    
    for setIdx=1:length(cueSets)
        if length(cueSets{setIdx})>2
            continue
        end
        trlIdx = find(ismember(dataset.movCues, cueSets{setIdx}));
        mc = dataset.movCues(trlIdx);
        %mc = mc(randperm(length(mc)));
        
        %single feature
        pVec = zeros(size(featAvg,2),1);
        rVec = zeros(size(featAvg,2),1);
        for featIdx=1:size(featAvg,2)
            [rVec(featIdx), pVec(featIdx)] = corr(featAvg(trlIdx,featIdx), mc);
        end
        
        %decoder
        allFeat = zeros(100*length(trlIdx),size(neuralFeatures,2));
        allCues = zeros(100*length(trlIdx),1);
        currIdx = 1:100;
        for t=1:length(trlIdx)
            windowIdx = (0:99)+dataset.goCueIdx(trlIdx(t));

            allFeat(currIdx,:) = neuralFeatures(windowIdx,:);
            allCues(currIdx,:) = dataset.movCues(trlIdx(t));
            currIdx = currIdx + length(windowIdx);
        end
    
        trainFun = @(pred, resp)(buildTopNDecoder( pred, resp, 10, 'standard' ));
        testFun = @(pred, truth)getDecoderPerformance(pred, truth, 'R');
        decoderFun = @applyTopNDecoder;
        nFolds = 10;
        
        [ perf, decoder, predVals, respVals, allTestIdx] = crossVal( allFeat, allCues, trainFun, testFun, decoderFun, nFolds, []);

    end
end

