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
        loopIdx = find(dataset.blockIdx==blockList(b));
        firstGoCue = find(dataset.goCueIdx>loopIdx(1),1,'first');
        loopIdx = loopIdx(loopIdx>dataset.goCueIdx(firstGoCue));
        
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
        %neuralFeatures = gaussSmooth_fast(dataset.features.nsp_tx2, 3);
        %neuralFeatures = gaussSmooth_fast(dataset.features.nsp_tx1, 3);
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
    timeWindow = [0, 100];
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
    effSets = {1:12, 13:16, 17:20, 21:24, 25:28};
    boxSets = {1:12, 13:16, 17:20, 21:24, 25:28};
    
    simMatrix = plotCorrMat( dPCA_out.featureAverages, 10:80, dataset.cueLabels, effSets, boxSets );
    
    %%
    %resampled CIs
    nResample = 200;
    allSimMat = zeros(size(simMatrix,1), size(simMatrix,2), nResample);
    
    for n=1:nResample
        disp(n);
        
        fv = dPCA_out.featureVals;
        newFeatureAverages = zeros(size(dPCA_out.featureAverages));
        for c=1:size(dPCA_out.featureAverages,2)
            tmp = squeeze(fv(:,c,:,:));
            
            goodTrl = all(~isnan(squeeze(tmp(1,:,:))),1);
            tmp = tmp(:,:,goodTrl);
            
            resampleIdx = randi(size(tmp,3),size(tmp,3),1);
            newFeatureAverages(:,c,:) = mean(tmp(:,:,resampleIdx),3);
        end
        
        simMatrix = plotCorrMat( newFeatureAverages, 10:80, dataset.cueLabels, effSets, boxSets );
        close(gcf);
        
        allSimMat(:,:,n) = simMatrix;
    end
    
    simMat_ci = prctile(allSimMat,[2.5 97.5],3);
    
    %%
    testEntries = [9,10,3,4,25,26,27,28];   
    cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

    figure
    imagesc(simMatrix(testEntries,testEntries),[-1 1]);
    colormap(cMap);
    set(gca,'XTick',1:length(testEntries),'XTickLabel',dataset.cueLabels(testEntries),'XTickLabelRotation',45);
    set(gca,'YTick',1:length(testEntries),'YTickLabel',dataset.cueLabels(testEntries));
    set(gca,'FontSize',16);
    set(gca,'YDir','normal');
    colorbar;

    reducedMat = simMatrix(testEntries,testEntries);
    reducedMat = reducedMat(1:4,5:end);
    
    diagEntries = 1:(size(reducedMat,1)+1):numel(reducedMat);
    otherEntries = setdiff(1:numel(reducedMat), diagEntries);    
    
    anova1([reducedMat(diagEntries)'; reducedMat(otherEntries)'], ...
        [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);
    
    figure('Position',[680   866   391   232]);
    subplot(1,2,1);
    hold on
    plot((rand(length(diagEntries),1)-0.5)*0.55, reducedMat(diagEntries), 'o');
    plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, reducedMat(otherEntries), 'ro');
    set(gca,'XTick',[0 1],'XTickLabel',{'Matched','Different'},'XTickLabelRotation',45);
    ylim([-1.0,1.0]);
    ylabel('Correlation');
    set(gca,'FontSize',20,'LineWidth',2);
    xlim([-0.5,1.5]);
    title('Arm vs. Leg','FontSize',18);

    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrDots.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'corrDots.svg'],'svg');
    
    %%
    %paired set PCA
    timeWindow = [0,100];
    cVar = zeros(length(cueSets),5);
    rawProjPoints = cell(length(cueSets),2);
    cVar_proj = zeros(length(cueSets),8);

    for setIdx=1:14
        trlIdx = find(ismember(dataset.movCues, cueSets{setIdx}));
        trlIdx = trlIdx(randperm(length(trlIdx)));

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

        oneFactor_dPCA_plot_pretty( dPCA_out.cval,  timeWindow(1):timeWindow(2), ...
            lineArgs, {'CD','CI'}, 'sameAxes', [], [], dPCA_out.cval.dimCI, colors);

        cueList = unique(dataset.movCues);
        [~,cueRemapIdx] = ismember(cueSets{setIdx}, cueList);
        text(0,0.6,[dataset.cueLabels{cueRemapIdx(1)} ' vs ' dataset.cueLabels{cueRemapIdx(2)}],'Units','normalized','FontSize',14);
        saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'dPCA_set' num2str(setIdx) '.png'],'png');
        close(gcf);

        %modulation size
        cdIdx = find(dPCA_out.cval.whichMarg==1);
        cdIdx = cdIdx(1:3);
        nTrials = size(dPCA_out.cval.Z_singleTrial,1);
        
        movWindow = 10:80;
        timeOffset = -timeWindow(1);
        
        f1 = squeeze(dPCA_out.featureVals(:,1,timeOffset+movWindow,:));
        f2 = squeeze(dPCA_out.featureVals(:,2,timeOffset+movWindow,:));
        mov1Activity = permute(f1,[3 2 1]);
        mov2Activity = permute(f2,[3 2 1]);
        
        mov1Activity_u = squeeze(nanmean(mov1Activity,2));
        mov2Activity_u = squeeze(nanmean(mov2Activity,2));

        pcaDat = [mov1Activity_u; mov2Activity_u];
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(pcaDat);
        
        m1Reduced = zeros(size(mov1Activity,1), size(mov1Activity,2), 5);
        m2Reduced = zeros(size(mov2Activity,1), size(mov2Activity,2), 5);
        for t=1:size(m1Reduced,1)
            m1Reduced(t,:,:) = squeeze(mov1Activity(t,:,:))*COEFF(:,1:5);
        end
        for t=1:size(m2Reduced,1)
            m2Reduced(t,:,:) = squeeze(mov2Activity(t,:,:))*COEFF(:,1:5);
        end
        
        %dataMatrix = [nanmean(mov1Activity,3); nanmean(mov2Activity,3)];
        dataMatrix = [m1Reduced(:,:); m2Reduced(:,:)];
        
        dataLabels = zeros(nTrials*2,1);
        dataLabels(1:nTrials) = 1;
        dataLabels((nTrials+1):end) = 2;

        badIdx = find(any(isnan(dataMatrix),2));
        dataMatrix(badIdx,:) = [];
        dataLabels(badIdx,:) = [];

        dm1 = dataMatrix(dataLabels==1,:);
        dm2 = dataMatrix(dataLabels==2,:);
        minLen = min(size(dm1,1), size(dm2,1));
        dm1 = dm1(1:minLen,:);
        dm2 = dm2(1:minLen,:);

        %single trial projection metric       
        dataMatrix_to = squeeze(dPCA_out.cval.Z_trialOrder(:,cdIdx,timeOffset+movWindow));
        dataMatrix_to = dataMatrix_to(:,:);
        %dataMatrix_to = nanmean(dataMatrix_to,3);
        
        [~,~,dataLabels_to] = unique(mc);
        [cVar_proj(setIdx,1), rpp] = projStat_cv_2(dataMatrix, dataLabels);
        rawProjPoints{setIdx, 1} = rpp(dataLabels==1);
        rawProjPoints{setIdx, 2} = rpp(dataLabels==2);

        nResample = 10000;

        %[D,P,STATS] = manova1(dataMatrix_to, dataLabels_to);
        %cVar_proj(setIdx,8) = P;

        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels_to(randperm(length(dataLabels_to)));
            resampleVec(resampleIdx) = projStat_cv_2(dataMatrix_to, shuffLabels);
        end
        
        %ci = bootci(nResample, {@projStat_cv, dm1, dm2}, 'type','per');
        cVar_proj(setIdx,2) = prctile(resampleVec,99);
        cVar_proj(setIdx,3) = mean(resampleVec);
        %cVar_proj(setIdx,4:5) = ci;    
        
        [H,P,CI] = ttest2(rawProjPoints{setIdx, 2}, rawProjPoints{setIdx, 1});
        cVar_proj(setIdx,6:7) = CI;

        %population norm metric
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        %resampleVec_mvn = zeros(nResample,1);
        %mn = mean(dataMatrix);
        %cv = cov(dataMatrix);
        %for resampleIdx=1:nResample
        %    resampleData = mvnrnd(mn, cv, size(dataMatrix,1));
        %    resampleVec_mvn(resampleIdx) = norm(mean(resampleData(dataLabels==2,:)) - mean(resampleData(dataLabels==1,:)));
        %end
    
        cVar(setIdx,1) = testStat;
        cVar(setIdx,2) = prctile(resampleVec,99);
        %cVar(setIdx,3) = prctile(resampleVec_mvn,99);
        
        ci = bootci(nResample, {@normStat, dm1, dm2}, 'type','per');
        cVar(setIdx,4:5) = ci;    
    end
    
    close all;
    save([outDirRoot sessionList{sessIdx} filesep 'pair_barData'],'cVar','cVar_proj', 'dPCA_out','rawProjPoints');
    
    %%
    %dPCA by effector
    effectorSets = {17:20, 13:16, 1:12, 25:28};
    dPCA_out = cell(length(effectorSets),1);
    timeWindow = [0,100];
    
    effTrlIdx = cell(length(effectorSets),1);
    for setIdx=1:length(effectorSets)
        trlIdx = find(ismember(dataset.movCues, effectorSets{setIdx}));
        mc = dataset.movCues(trlIdx);
        effTrlIdx{setIdx} = trlIdx;
        
        dPCA_out{setIdx} = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mc, timeWindow, 0.02, {'CD','CI'}, 20, 'xval' );
        close(gcf);
        
        lineArgs = cell(length(unique(dataset.movCues(trlIdx))),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end

        oneFactor_dPCA_plot_pretty( dPCA_out{setIdx}.cval,  timeWindow(1):timeWindow(2), ...
            lineArgs, {'CD','CI'}, 'sameAxes', [], [], dPCA_out{setIdx}.cval.dimCI, colors);
    end
    
    cVar = zeros(length(cueSets),5);
    rawProjPoints = cell(length(cueSets),2);
    cVar_proj = zeros(length(cueSets),8);
    
    effectorMembership = [3 3 3 3 3 3 2 2 1 1 4 4];
    validSets = [1:10, 13:14];
    
    for setIterator=1:length(validSets)
        setIdx = validSets(setIterator);
        effIdx = effectorMembership(setIterator);
        
        disp(setIdx);
        
        %modulation size
        cdIdx = find(dPCA_out{effIdx}.cval.whichMarg==1);
        cdIdx = cdIdx(1:6);
        nTrials = size(dPCA_out{effIdx}.cval.Z_singleTrial,1);

        movWindow = 10:80;
        timeOffset = -timeWindow(1);
        [~,movIdx] = ismember(cueSets{setIdx}, effectorSets{effIdx});
        
        mov1Activity = squeeze(dPCA_out{effIdx}.cval.Z_singleTrial(:,cdIdx,movIdx(1),timeOffset+movWindow));
        mov2Activity = squeeze(dPCA_out{effIdx}.cval.Z_singleTrial(:,cdIdx,movIdx(2),timeOffset+movWindow));

        dataMatrix = [nanmean(mov1Activity,3); nanmean(mov2Activity,3)];
        dataLabels = zeros(nTrials*2,1);
        dataLabels(1:nTrials) = 1;
        dataLabels((nTrials+1):end) = 2;

        badIdx = find(any(isnan(dataMatrix),2));
        dataMatrix(badIdx,:) = [];
        dataLabels(badIdx,:) = [];

        dm1 = dataMatrix(dataLabels==1,:);
        dm2 = dataMatrix(dataLabels==2,:);
        minLen = min(size(dm1,1), size(dm2,1));
        dm1 = dm1(1:minLen,:);
        dm2 = dm2(1:minLen,:);

        %single trial projection metric       
        mc = dataset.movCues(effTrlIdx{effIdx});
        innerIdx = find(ismember(mc, cueSets{setIdx}));
        
        dataMatrix_to = squeeze(dPCA_out{effIdx}.cval.Z_trialOrder(innerIdx,cdIdx,timeOffset+movWindow));
        dataMatrix_to = nanmean(dataMatrix_to,3);
        [~,~,dataLabels_to] = unique(mc(innerIdx));
        [cVar_proj(setIdx,1), rpp] = projStat_cv_2(dataMatrix_to, dataLabels_to);
        rawProjPoints{setIdx, 1} = rpp(dataLabels_to==1);
        rawProjPoints{setIdx, 2} = rpp(dataLabels_to==2);

        nResample = 10000;

        [D,P,STATS] = manova1(dataMatrix_to, dataLabels_to);
        cVar_proj(setIdx,8) = P;

        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels_to(randperm(length(dataLabels_to)));
            resampleVec(resampleIdx) = projStat_cv_2(dataMatrix_to, shuffLabels);
        end
        
        ci = bootci(nResample, {@projStat_cv, dm1, dm2}, 'type','per');
        cVar_proj(setIdx,2) = prctile(resampleVec,99);
        cVar_proj(setIdx,3) = mean(resampleVec);
        cVar_proj(setIdx,4:5) = ci;    
        
        [H,P,CI] = ttest2(rawProjPoints{setIdx, 2}, rawProjPoints{setIdx, 1});
        cVar_proj(setIdx,6:7) = CI;

        %population norm metric
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        resampleVec_mvn = zeros(nResample,1);
        mn = mean(dataMatrix);
        cv = cov(dataMatrix);
        for resampleIdx=1:nResample
            resampleData = mvnrnd(mn, cv, size(dataMatrix,1));
            resampleVec_mvn(resampleIdx) = norm(mean(resampleData(dataLabels==2,:)) - mean(resampleData(dataLabels==1,:)));
        end
    
        cVar(setIdx,1) = testStat;
        cVar(setIdx,2) = prctile(resampleVec,99);
        cVar(setIdx,3) = prctile(resampleVec_mvn,99);
        
        ci = bootci(nResample, {@normStat, dm1, dm2}, 'type','per');
        cVar(setIdx,4:5) = ci;    
    end
    
    close all;
    save([outDirRoot sessionList{sessIdx} filesep 'eff_barData'],'cVar','cVar_proj', 'dPCA_out', 'rawProjPoints');

    %%
    %bar plot
    cueSets_large = {[9:10], [7:8], [1:6], [13:14]};
    movLabels = {'Hand Open/Close','Wrist Flex/Ext','Wrist Pro/Sup','Elbow Flex/Ext',...
        'Sho Flex/Ext','Sho Ab/Add','Head Down/Up','Head Left/Right',...
        'Smile/Frown','Tongue Out/In','Eyes Up/Down','Eyes Left/Right',...
        'Hip Ext/Flex','Ankle Ext/Flex'};
    allCues = horzcat(cueSets_large{:});
    
    colors = [173,150,61;
    119,122,205;
    91,169,101;
    197,90,159;
    202,94,74]/255;

    figure('Position',[164   751   989   338]);
    plotIdx = 1;
    colorIdx = 1;

    hold on
    for pIdx=1:length(cueSets_large)
        dat = cVar(cueSets_large{pIdx},1); % - cVar(cueSets_large{pIdx},2);
        CI = cVar(cueSets_large{pIdx},4:5); % - cVar(cueSets_large{pIdx},2);

        xAxis = (plotIdx):(plotIdx + length(dat) - 1);
        bar(xAxis, dat, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);
        %for x=1:length(dat)
        %    plot([plotIdx+x-1, plotIdx+x-1], CI(x,:), '-k','LineWidth',1);
        %end
        errorbar(xAxis, dat, dat-CI(:,1), CI(:,2)-dat, '.k','LineWidth',1);

        plotIdx = plotIdx + length(dat);
        colorIdx = colorIdx + 1;
    end
    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    set(gca,'XTick',1:length(allCues),'XTickLabel',movLabels(allCues),'XTickLabelRotation',45);

    axis tight;
    xlim([0.5, length(allCues)+0.5]);
    ylabel('\Delta Neural Activity\newlinein Separating Dimensions\newline(a.u.)','FontSize',22);
    set(gca,'TickLength',[0 0]);

    saveas(gcf,[outDir filesep 'bar_dPCA.png'],'png');
    saveas(gcf,[outDir filesep 'bar_dPCA.svg'],'svg');
    saveas(gcf,[outDir filesep 'bar_dPCA.pdf'],'pdf');
    
    %%
    %bar plot, raw points
    cueSets_large = {[9:10], [7:8], [1:6], [13:14]};
    movLabels = {'Hand Open/Close','Wrist Flex/Ext','Wrist Pro/Sup','Elbow Flex/Ext',...
        'Sho Flex/Ext','Sho Ab/Add','Head Down/Up','Head Left/Right',...
        'Smile/Frown','Tongue Out/In','Eyes Up/Down','Eyes Left/Right',...
        'Hip Ext/Flex','Ankle Ext/Flex'};
    allCues = horzcat(cueSets_large{:});
    
    colors = [173,150,61;
    119,122,205;
    91,169,101;
    197,90,159;
    202,94,74]/255;

    figure('Position',[164   771   623   318]);
    plotIdx = 1;

    hold on
    for pIdx=1:length(cueSets_large)
        lightColor = colors(pIdx,:)*0.7 + ones(1,3)*0.3;
        darkColor = colors(pIdx,:)*0.7 + zeros(1,3)*0.3;
        for movIdx=1:length(cueSets_large{pIdx})
            mIdx = cueSets_large{pIdx}(movIdx);
            
            base = mean(rawProjPoints{mIdx,1});
            bar(plotIdx, mean(rawProjPoints{mIdx,2})-base, 'FaceColor', colors(pIdx,:), 'LineWidth', 1);

            jitterX = rand(length(rawProjPoints{mIdx,1}),1)*0.5-0.25;
            plot(plotIdx+jitterX, rawProjPoints{mIdx,1}-base, 's', 'Color', lightColor, 'MarkerSize', 2);            

            jitterX = rand(length(rawProjPoints{mIdx,2}),1)*0.5-0.25;
            plot(plotIdx+jitterX, rawProjPoints{mIdx,2}-base, 'o', 'Color', darkColor, 'MarkerSize', 2);

            height = mean(rawProjPoints{mIdx,2})-base;
            CI = cVar_proj(mIdx,4:5)-cVar_proj(mIdx,1);
            errorbar(plotIdx, height, CI(1), CI(2), '.k','LineWidth',1);
            
            plotIdx = plotIdx + 1;
        end
    end
    set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
    set(gca,'XTick',1:length(allCues),'XTickLabel',movLabels(allCues),'XTickLabelRotation',45);

    axis tight;
    xlim([0.5, length(allCues)+0.5]);
    plot(get(gca,'XLim'),[0 0],'--k','LineWidth',1);
    ylabel('\Delta Neural Activity (SD)','FontSize',22);
    set(gca,'TickLength',[0 0]);

    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'bar_dPCA.png'],'png');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep  'bar_dPCA.svg'],'svg');
    saveas(gcf,[outDirRoot sessionList{sessIdx} filesep  'bar_dPCA.pdf'],'pdf');
    
    %%
    %dPCA by effector sets
    cueSets_large = {[17:20], [13:16], [1:12], [25:28]};
    
    timeWindow = [-50,100];
    for setIdx=1:length(cueSets_large)
        trlIdx = find(ismember(dataset.movCues, cueSets_large{setIdx}));
        
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
        [~,cueRemapIdx] = ismember(cueSets_large{setIdx}, cueList);
        text(0,0.6,[dataset.cueLabels{cueRemapIdx(1)} ' vs ' dataset.cueLabels{cueRemapIdx(2)}],'Units','normalized','FontSize',14);
        saveas(gcf,[outDirRoot sessionList{sessIdx} filesep 'dPCA_set' num2str(setIdx) '.png'],'png');
    end
    
    close all;
    
    %%
    %multi-dims
    cueSets_large = {[17:20], [13:16], [1:12], [25:28]};
    
    dPCA_out = cell(length(cueSets_large),1);
    timeWindow = [0, 150];
    for pIdx=1:length(cueSets_large)
        trlIdx = find(ismember(dataset.movCues, cueSets_large{pIdx}));
        
        mc = dataset.movCues(trlIdx);
        %mc = mc(randperm(length(mc)));
        dPCA_out{pIdx} = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mc, timeWindow, 0.02, {'CD','CI'}, 20, 'xval' );
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca( dPCA_out{pIdx}.featureAverages(:,:)');
        
        fv = dPCA_out{pIdx}.featureVals;

        dPCA_out{pIdx}.pca_z = zeros(size(fv,1),size(fv,2),size(fv,3));
        dPCA_out{pIdx}.pca_z_ci = zeros(size(fv,1),size(fv,2),size(fv,3),2);
        
        for conIdx=1:size(fv,2)
            for timeIdx=1:size(fv,3)
                tmp_fv = squeeze(fv(:,conIdx,timeIdx,:));
                tmp_reduced = (tmp_fv' - MU)*COEFF;
                dPCA_out{pIdx}.pca_z(:,conIdx,timeIdx) = mean(tmp_reduced);
                
                [~,~,CIs] = normfit(tmp_reduced);
                dPCA_out{pIdx}.pca_z_ci(:,conIdx,timeIdx,:) = CIs';
            end
        end
    end
    
    axHandles = zeros(3,length(cueSets_large));
    yLims = cell(3,length(cueSets_large));
    movTypeText = {'Face','Head','Arm','Leg'};
    timeAxis = (timeWindow(1)/100):(binMS/1000):(timeWindow(2)/100);
    
    figure('Position',[71   418   831   510]);
    for pIdx=1:length(cueSets_large)
        for axIdx=1:3
            cdIdx = find(dPCA_out{pIdx}.cval.whichMarg==1);
            ax = subtightplot(3,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
            axHandles(axIdx, pIdx) = ax;
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            lineHandles = zeros(size(dPCA_out{pIdx}.Z,2),1);
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                lineHandles(conIdx) = plot(timeAxis, squeeze(dPCA_out{pIdx}.cval.Z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                errorPatch( timeAxis', squeeze(dPCA_out{pIdx}.cval.dimCI(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
                
                %lineHandles(conIdx) = plot(timeAxis, squeeze(dPCA_out{pIdx}.pca_z(cdIdx(axIdx),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                %errorPatch( timeAxis', squeeze(dPCA_out{pIdx}.pca_z_ci(cdIdx(axIdx),conIdx,:,:)), colors(conIdx,:), 0.2 );
            end

            %plot(timeAxis, nothingAvg{pIdx}(:,axIdx),'LineWidth',2,'Color','k');
            %errorPatch( timeAxis', squeeze(nothingCI{pIdx}(:,axIdx,:)), [0 0 0], 0.2 );

            axis tight;
            yLims{axIdx, pIdx} = get(gca,'YLim');

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k','LineWidth',2);
            plot([1.5, 1.5],[-100, 100],'--k','LineWidth',2);

            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

            if pIdx==length(movTypeText)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end

            if axIdx==3
                text(0.7,0.8,'Return','Units','Normalized','FontSize',16);
                text(0.37,0.8,'Go','Units','Normalized','FontSize',16);
            end

            if axIdx==3
                plot([0,1.0]+0.2,[-1,-1],'-k','LineWidth',2);
            end

            if axIdx==1
                title(movTypeText{pIdx},'FontSize',22);
                lHandle = legend(lineHandles, dataset.cueLabels(cueSets_large{pIdx}),'Location','West','box','off','FontSize',16);
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
            axis off;
        end
    end

    for pIdx=1:length(cueSets_large)
        yl = vertcat(yLims{:,pIdx});
        finalLimits = [min(yl(:,1)), max(yl(:,2))];
        for axIdx=1:3
            set(axHandles(axIdx,pIdx), 'YLim', finalLimits);
        end
    end

%     finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
%     for p=1:length(axHandles)
%         set(axHandles(p), 'YLim', finalLimits);
%     end

    saveas(gcf,[outDir filesep 'dPCA_exampleDims_eff.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_exampleDims_eff.svg'],'svg');
    
    %%
    %multi-dims
    cueSets_large = {[17:20], [13:16], [1:12], [25:28]};
    dPCA_out = cell(length(cueSets),1);
    timeWindow = [0,150];
    
    for pIdx=1:14
        trlIdx = find(ismember(dataset.movCues, cueSets{pIdx}));
        trlIdx = trlIdx(randperm(length(trlIdx)));
        
        mc = dataset.movCues(trlIdx);
        %mc = mc(randperm(length(mc)));
        dPCA_out{pIdx} = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mc, timeWindow, 0.02, {'CD','CI'}, 20, 'xval' );
        close(gcf);
        
        lineArgs = cell(length(unique(dataset.movCues(trlIdx))),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end

        oneFactor_dPCA_plot_pretty( dPCA_out{pIdx}.cval,  timeWindow(1):timeWindow(2), ...
            lineArgs, {'CD','CI'}, 'sameAxes', [], [], dPCA_out{pIdx}.cval.dimCI, colors);
    end
    
    axHandles = [];
    yLims = [];
    movTypeText = {'Face','Head','Arm','Leg'};
    timeAxis = (timeWindow(1)/100):(binMS/1000):(timeWindow(2)/100);
    pairOrder = {[9 10 nan],[7 8 nan],[1 2 3],[13 14 nan]};
    
    figure('Position',[71   418   831   510]);
    for pIdx=1:length(pairOrder)
        for axIdx=1:length(pairOrder{pIdx})
            innerIdx = pairOrder{pIdx}(axIdx);
            if isnan(innerIdx)
                continue;
            end
            
            cdIdx = find(dPCA_out{innerIdx}.cval.whichMarg==1);
            ax = subtightplot(3,length(movTypeText),length(movTypeText)*(axIdx-1) + pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
            axHandles = [axHandles; ax];
            hold on

            colors = jet(size(dPCA_out{innerIdx}.Z,2))*0.8;
            lineHandles = zeros(size(dPCA_out{innerIdx}.Z,2),1);
            for conIdx=1:size(dPCA_out{innerIdx}.Z,2)
                lineHandles(conIdx) = plot(timeAxis, squeeze(dPCA_out{innerIdx}.cval.Z(cdIdx(1),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                errorPatch( timeAxis', squeeze(dPCA_out{innerIdx}.cval.dimCI(cdIdx(1),conIdx,:,:)), colors(conIdx,:), 0.2 );
            end

            %plot(timeAxis, nothingAvg{pIdx}(:,axIdx),'LineWidth',2,'Color','k');
            %errorPatch( timeAxis', squeeze(nothingCI{pIdx}(:,axIdx,:)), [0 0 0], 0.2 );

            axis tight;
            yLims = [yLims; get(gca,'YLim')];

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k','LineWidth',2);
            plot([1.5, 1.5],[-100, 100],'--k','LineWidth',2);

            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

            if pIdx==length(movTypeText)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end

            if axIdx==3
                text(0.7,0.8,'Return','Units','Normalized','FontSize',16);
                text(0.37,0.8,'Go','Units','Normalized','FontSize',16);
            end

            if axIdx==3
                plot([0,1.0]+0.2,[-1,-1],'-k','LineWidth',2);
            end

            if axIdx==1
                title(movTypeText{pIdx},'FontSize',22);
                lHandle = legend(lineHandles, dataset.cueLabels(cueSets_large{pIdx}),'Location','West','box','off','FontSize',16);
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
            axis off;
        end
    end

    finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_exampleDims.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_exampleDims.svg'],'svg');

    
    %%
    %single unit counting
    movTypeText = {'Face','Neck','Arm','Leg'};
    codeSetsReduced = cueSets_large;
    binMS = 20;

    dPCA_out = cell(length(movTypeText),1);
    for pIdx=1:length(movTypeText)
        trlIdx = find(ismember(dataset.movCues, cueSets_large{pIdx}));
        dPCA_out{pIdx} = apply_dPCA_simple( neuralFeatures, dataset.goCueIdx(trlIdx), ...
            mc, timeWindow, 0.02, {'CD','CI'}, 20);
        close(gcf);
    end

    nUnits = size(dPCA_out{1}.featureAverages,1);
    pVal = zeros(length(codeSetsReduced), nUnits);
    modSD = zeros(length(codeSetsReduced), nUnits);
    codes = cell(size(codeSetsReduced,1),2);

    timeOffset = -timeWindow(1);
    movWindow = (10:40);

    for pIdx = 1:length(codeSetsReduced)    
        for unitIdx=1:size(dPCA_out{pIdx}.featureAverages,1)
            unitAct = squeeze(dPCA_out{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
            meanAcrossTrial = squeeze(nanmean(unitAct,3))';
            meanAct = squeeze(nanmean(unitAct,2))';

            pVal(pIdx, unitIdx) = anova1(meanAct,[],'off');

            modSD(pIdx, unitIdx) = nanstd(mean(meanAcrossTrial));
        end
    end    

    sigUnit = find(any(pVal<0.001));

    %num tuned
    disp(mean(pVal'<0.001));

    %categorize mixed tuning
    isTuned = pVal<0.001;
    numCategories = sum(isTuned);
      
    %%
    eVar = zeros(length(codeSetsReduced),1);
    for pIdx = 1:length(codeSetsReduced)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        cdIdx = cdIdx(1:6);

        totalVar = sum(dPCA_out{pIdx}.explVar.margVar(1,cdIdx))*dPCA_out{pIdx}.explVar.totalMarginalizedVar(1);
        totalVar = totalVar / size(dPCA_out{pIdx}.featureAverages,2);
        eVar(pIdx) = totalVar;
    end

    figure; 
    plot(sqrt(eVar)/max(sqrt(eVar)));

    %%
    %PSTHs for each feature
    %get code sets for each movement type

    %PSTHS
    cueList = unique(dataset.movCues);
    movTypes = {'Face','Head','Arm','Leg'};
    lineArgs = cell(length(cueList),1);
    for pIdx = 1:length(movTypes)
        colors = hsv(length(codeSetsReduced{pIdx}))*0.8;
        for x=1:length(codeSetsReduced{pIdx})
            lineArgs{codeSetsReduced{pIdx}(x)} = {'LineWidth',1,'Color',colors(x,:)};
        end
    end

    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 0;
    psthOpts.neuralData = {neuralFeatures};
    psthOpts.timeWindow = [0, 150];
    psthOpts.trialEvents = dataset.goCueIdx;
    psthOpts.trialConditions = dataset.movCues;
    psthOpts.conditionGrouping = codeSetsReduced;
    psthOpts.lineArgs = lineArgs;

    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = [outDirRoot sessionList{sessIdx}];
    psthOpts.plotCI = 1;
    psthOpts.CIColors = jet(28)*0.8;
    
    featLabels = cell(size(neuralFeatures,2),1);
    for f=1:size(neuralFeatures,2)
        featLabels{f} = num2str(f);
    end
    psthOpts.featLabels = featLabels;

    psthOpts.prefix = 'TX';
    makePSTH_simple(psthOpts);
    
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
    cueSets_large = {[9:10], [7:8], [1:6], [13:14]};
    movLabels = {'Hand Open/Close','Wrist Flex/Ext','Wrist Pro/Sup','Elbow Flex/Ext',...
        'Sho Flex/Ext','Sho Ab/Add','Head Down/Up','Head Left/Right',...
        'Smile/Frown','Tongue Out/In','Eyes Up/Down','Eyes Left/Right',...
        'Hip Ext/Flex','Ankle Ext/Flex'};
    
    if strcmp(sessionList{sessIdx}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        windowIdx = 10:40;
        windowIdx2 = 41:80;
        decDataset = dataset;
        eyeTrials = find(ismember(dataset.movCues, 21:24));
        decDataset.goCueIdx(eyeTrials) = [];
        decDataset.movCues(eyeTrials) = [];
        decDataset.cueLabels = {'HandOpen','HandClose','WristFlex','WristExt','WristPro','WristSup',...
            'ElbowFlex','ElbowExt','ShoFlex','ShoExt','ShoAb','ShoAdd','HeadDown','HeadUp',...
            'HeadLeft','HeadRight','Smile','Frown','TongueOut','TongueIn','EyesUp','EyesDown','EyesLeft',...
            'EyesRight','HipExt','HipFlex','AnkleExt','AnkleFlex'};
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
        colorSetIdx = {1:4, 5:8, 9:20, 21:24};
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

