%%
datasets = {
    't5.2019.03.27',[23 24 25 26 27 28 29 30]
};
comparisonSets = {{[23],[24]},{[25],[26]},{[27 29],[28 30]}};
comparisonNames = {'OL','Refit','CL'};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'discreteDecoding' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    bNums = horzcat(datasets{d,2});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}), 4.5, datasets{d,2}(1), filtOpts );

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
    targCodeRemap = [5 4 6 3 0 7 2 8 1];
    circleTargCodes = targCodes;
    
    for x=1:length(targCodeRemap)
        circleTargCodes(targCodes==x) = targCodeRemap(x);
    end
    
    targList(:,2) = -targList(:,2);
    
    theta = linspace(0,2*pi,9);
    theta = theta(1:8);
    targTemplate = [cos(theta)', sin(theta)'];

    %%        
    alignFields = {'timeGoCue'};
    smoothWidth = 0;
    datFields = {'windowsMousePosition','windowsMousePosition_speed'};
    timeWindow = [-1000,2000];
    binMS = 10;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];
    alignDat.rawSpikes = alignDat.rawSpikes * (1000/binMS);
    
    smoothSnippetMatrix = gaussSmooth_fast(alignDat.zScoreSpikes,2.5);
    smoothSpikes = gaussSmooth_fast(alignDat.meanSubtractSpikes*(1000/binMS),2.5);
    
    %%
    for compSetIdx = 1:length(comparisonSets)
        cSet = comparisonSets{compSetIdx};
        con1_trials = find(ismember(alignDat.bNumPerTrial, cSet{1}) & circleTargCodes~=0);
        con2_trials = find(ismember(alignDat.bNumPerTrial, cSet{2}) & circleTargCodes~=0);
        
        twoFactorCodes = [[circleTargCodes(con1_trials), ones(length(con1_trials),1)]; ...
            [circleTargCodes(con2_trials), ones(length(con2_trials),1)+1]];
        
        margGroupings = {{1, [1 3]}, ...
            {2, [2 3]}, ...
            {[1 2] ,[1 2 3]}, ...
            {3}};
        margNames = {'Target','Condition','Targ x Con','Time'};

        opts_m.margNames = margNames;
        opts_m.margGroupings = margGroupings;
        opts_m.nCompsPerMarg = 5;
        opts_m.makePlots = true;
        opts_m.nFolds = 10;
        opts_m.readoutMode = 'singleTrial';
        opts_m.alignMode = 'rotation';
        opts_m.plotCI = true;

        trlIdx = [con1_trials; con2_trials];
        mPCA_out = apply_mPCA_general( smoothSnippetMatrix, alignDat.eventIdx(trlIdx), ...
            twoFactorCodes, [-100,200], 0.10, opts_m);
        
        %%
        %separately
        margGroupings = {{1, [1 2]}, ...
            {2}};
        margNames = {'Target','Time'};

        opts_m.margNames = margNames;
        opts_m.margGroupings = margGroupings;
        opts_m.nCompsPerMarg = 5;
        opts_m.makePlots = true;
        opts_m.nFolds = 10;
        opts_m.readoutMode = 'singleTrial';
        opts_m.alignMode = 'rotation';
        opts_m.plotCI = true;

        trlIdxCell = {con1_trials, con2_trials};
        all_mPCA = cell(2,1);
        for conPtr=1:2
            trlIdx = trlIdxCell{conPtr};
            all_mPCA{conPtr} = apply_mPCA_general( smoothSnippetMatrix, alignDat.eventIdx(trlIdx), ...
                circleTargCodes(trlIdx), [0,100], 0.010, opts_m);
        end
        
        figure
        hold on;
        for conPtr=1:2
            cdIdx = find(all_mPCA{conPtr}.whichMarg==1);
            axIdx = cdIdx(1:2);
            
            xPoints = squeeze(all_mPCA{conPtr}.Z(axIdx(1),:,35));
            yPoints = squeeze(all_mPCA{conPtr}.Z(axIdx(2),:,35));
            X = [xPoints', yPoints'];
            
            [D, Z, TRANSFORM] = procrustes(targTemplate, X, 'Scaling', true);
            transmat = TRANSFORM.T;
            X = transmat*X';
            X = X';
                
            plot(X(:,1), X(:,2), 'o');
            for x=1:length(xPoints)
                text(X(x,1), X(x,2), num2str(x),'FontSize',16);
            end
        end
        axis equal;
        
        %%
        %head movement magnitude
        opts_w = opts_m;
        opts_w.nCompsPerMarg = 3;
        opts_w.readoutMode = 'pcaAxes';
        all_mPCA_head = cell(2,1);

        headVel = [0 0; diff(alignDat.windowsMousePosition)*100];
        headSpeed = matVecMag(headVel,2);
            
        for conPtr=1:2
            trlIdx = trlIdxCell{conPtr};
            all_mPCA_head{conPtr} = apply_mPCA_general( [headVel, headSpeed], ...
                alignDat.eventIdx(trlIdx), circleTargCodes(trlIdx), [0,100], 0.010, opts_w);
        end
        
        figure
        for conPtr=1:2
            subplot(2,1,conPtr);
            hold on;
            
            trlIdx = trlIdxCell{conPtr};
            xPoints = headVel(alignDat.eventIdx(trlIdx)+35,1);
            yPoints = headVel(alignDat.eventIdx(trlIdx)+35,2);
            X = [xPoints, yPoints];
            
            colors = hsv(8)*0.8;
            for x=1:8
                targTrl = find(circleTargCodes(trlIdx)==x);
                plot(X(targTrl,1), X(targTrl,2), 'o', 'Color', colors(x,:), 'MarkerFaceColor', colors(x,:));
                plot(mean(X(targTrl,1)), mean(X(targTrl,2)), 'o', 'Color', colors(x,:), 'MarkerFaceColor', colors(x,:), 'MarkerSize', 20);
            end
            
            axis equal;
        end
        
        %%
        %unbiased standard deviations
        all_mPCA_hz = cell(2,1);
        for conPtr=1:2
            trlIdx = trlIdxCell{conPtr};
            all_mPCA_hz{conPtr} = apply_mPCA_general( smoothSpikes, alignDat.eventIdx(trlIdx), ...
                circleTargCodes(trlIdx), [0,100], 0.010, opts_m);
        end
        close all;
        
        stdMetrics = cell(2,1);
        for conPtr=1:2
            fa = all_mPCA_hz{conPtr}.featureAverages;
            fv = all_mPCA_hz{conPtr}.featureVals;
            
            stdMetrics{conPtr} = zeros(size(fa,1),2);
            stdMetrics{conPtr}(:,1) = std(squeeze(fa(:,:,35))');
            
            nTrials = 22;
            normEst = zeros(size(fa,1), nTrials);
            for x=1:nTrials
                trainIdx = setdiff(1:nTrials,x);
                testIdx = x;
                
                tmp_train = (mean(squeeze(fv(:,:,35,trainIdx)),3));
                tmp_test = (squeeze(fv(:,:,35,testIdx)));
                
                for f=1:size(tmp_train,1)
                    normEst(f,x) = ((tmp_train(f,:)-mean(tmp_train(f,:)))*(tmp_test(f,:)-mean(tmp_test(f,:)))')/(8-1);
                end
            end
            
            meanNorm = mean(normEst,2);
            cvNorm = sign(meanNorm).*sqrt(abs(meanNorm));
            stdMetrics{conPtr}(:,2) = cvNorm;
        end
        
        %%
        %unbiased vector distances from center
        distMetrics = zeros(2,2);
        for conPtr=1:2
            fa = all_mPCA{conPtr}.featureAverages;
            fv = all_mPCA{conPtr}.featureVals;
            
            f_avg = mean(squeeze(fa(:,:,35)),2);  
            f_dist = matVecMag(squeeze(fa(:,:,35)) - f_avg,1);
            distMetrics(conPtr,1) = mean(f_dist);
            
            nTrials = 22;
            normEst = zeros(nTrials,1);
            for x=1:nTrials
                trainIdx = setdiff(1:nTrials,x);
                testIdx = x;
                
                tmp_train = (mean(squeeze(fv(:,:,35,trainIdx)),3));
                tmp_test = (squeeze(fv(:,:,35,testIdx)));
                
                f_avg_train = mean(tmp_train,2);
                f_diff_train = tmp_train-f_avg_train;
                
                f_avg_test = mean(tmp_test,2);
                f_diff_test = tmp_test-f_avg_test;
                
                normEst(x) = mean(diag(f_diff_train'*f_diff_test));
            end
            
            meanNorm = mean(normEst);
            cvNorm = sign(meanNorm).*sqrt(abs(meanNorm));
            distMetrics(conPtr,2) = cvNorm;
        end
        
        %%
        trlIdx = [con1_trials; con2_trials];
        tmpCodes = [circleTargCodes(con1_trials); circleTargCodes(con2_trials)+8];

        movWindow = [20 60];
        baselineWindow = [-10 10];
        codeSets = {1:8. 9:16};
        
        [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( tmpCodes, smoothSnippetMatrix, ...
            alignDat.eventIdx(trlIdx), movWindow, baselineWindow, codeSets, 'raw' );
        singleTrialBarPlot( codeSets, rawProjPoints_marg, cVar_marg, {'Free1','Free2','Free3','Free4','Free5','Free6','Free7','Free8',...
            'Restrained1','Restrained2','Restrained3','Restrained4','Restrained5','Restrained6','Restrained7','Restrained8'} );
                 
        saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.png'],'png');
        saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_raw.svg'],'svg');

        %%
        %channel TX PSTHs        
        nTargs = 8;
        allColors = zeros(nTargs,3);
        lineArgs = cell(nTargs,1);
        colors = jet(nTargs)*0.8;
        for x=1:nTargs
            lineArgs{x} = {'LineWidth',2,'Color',colors(x,:)};
            allColors(x,:) = colors(x,:);
        end

        psthOpts = makePSTHOpts();
        psthOpts.timeStep = binMS/1000;
        psthOpts.gaussSmoothWidth = 0;
        psthOpts.neuralData = {smoothSpikes};
        psthOpts.timeWindow = timeWindow/binMS;
        psthOpts.trialEvents = alignDat.eventIdx([con1_trials; con2_trials]);
        
        psthOpts.trialConditions = [circleTargCodes(con1_trials); circleTargCodes(con2_trials)+8];
        psthOpts.conditionGrouping = {1:8, 9:16};
        psthOpts.lineArgs = [lineArgs, lineArgs];

        psthOpts.verticalLineEvents = [0];
        psthOpts.plotsPerPage = 10;
        psthOpts.plotDir = outDir;

        txChanNum = find(~tooLow);
        featLabels = cell(size(smoothSnippetMatrix,2),1);
        for f=1:size(smoothSnippetMatrix,2)
            featLabels{f} = num2str(txChanNum(f));
        end
        psthOpts.featLabels = featLabels;

        psthOpts.prefix = 'TX';
        psthOpts.plotCI = 1;
        psthOpts.CIColors = [allColors; allColors];
        psthOpts.doPlot = false;
        
        out = makePSTH_simple(psthOpts);
        
        nFeat = size(out.psth{1},2);
        modDep = zeros(nFeat,8,2);
        for n=1:nFeat
            for t=1:8
                tmp = squeeze(out.psth{t}(:,n,1));
                tmp2 = squeeze(out.psth{t+8}(:,n,1));
                tmp = tmp(1:150);
                tmp2 = tmp2(1:150);
                
                modDep(n,t,1) = max(tmp)-min(tmp);
                modDep(n,t,2) = max(tmp2)-min(tmp2);
            end
        end
        
        mn1 = mean(mean(squeeze(modDep(:,:,1))));
        mn2 = mean(mean(squeeze(modDep(:,:,2))));
        
        set1 = cat(4,out.psth{1:8});
        set1 = squeeze(set1(135,:,1,:));
        
        set2 = cat(4,out.psth{9:16});
        set2 = squeeze(set2(135,:,1,:));
        
        disp(mean(max(set1')-min(set1')));
        disp(mean(max(set2')-min(set2')));
        
    end
end %datasets