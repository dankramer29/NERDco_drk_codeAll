%%
datasets = {
    't5.2018.04.16',[3 4 5 6 7 8 17 18 19 20]
};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'decisionMaking' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load, bin and concatenate streams
    bNums = datasets{d,2};
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 3.5, bNums(1), filtOpts );
    
    binMS = 20;
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','stimCondMatrix','activeTargets','successPoints','state','windowsMousePosition_speed'};
    
    allOut = [];
    for x = 1:length(stream)
        disp(x);
        out = binStream( stream{x}, binMS, smoothWidth, datFields );
        if isempty(allOut)
            allOut = out;
        else
            fNames = fieldnames(out);
            for f=1:length(fNames)
                allOut.(fNames{f}) = [allOut.(fNames{f}); out.(fNames{f})];
            end
        end
    end
    
    %compile information by trial
    movEpochs = logicalToEpochs(allOut.state==3);
    stimEpochs = logicalToEpochs(allOut.state==17);
    isSucc = (allOut.successPoints(movEpochs(:,2)+3) - allOut.successPoints(movEpochs(:,1))) > 0;
    stimCon = allOut.stimCondMatrix(movEpochs(:,1),4);
    activeTargs = allOut.activeTargets(movEpochs(:,1),:);
    decisionTarg = zeros(size(movEpochs,1),1);
    rt = zeros(size(movEpochs,1),1);
    
    %compute RT
    vel = diff(allOut.rigidBodyPosXYZ);
    for t=1:length(decisionTarg)
        [~,maxIdx] = max(abs(vel(movEpochs(t,1),1:2)));
        sgn = sign(vel(movEpochs(t,1),maxIdx));
        
        decisionTarg(t) = (maxIdx-1)*2 + (sgn==1);
        tmp_RT = movEpochs(t,1)-stimEpochs(:,1);
        tmp_RT(tmp_RT<0) = [];
        rt(t) = min(tmp_RT);
    end
    
    %rt binning
    nBins = 4;
    [rtCounts, rtIdx] = histc(rt,linspace(30,70,nBins+1));
    rtIdx(rtIdx==(nBins+1) | rtIdx==0) = nan;
    
    %neural data smoothing
    zScoreSpikes = zscore(allOut.rawSpikes);
    smoothSpikes = gaussSmooth_fast(zScoreSpikes,1.5);
%     nonMovAndStimEpochs = (allOut.state~=17) & (allOut.state~=3);
%     nonMovAndStimEpochs = filtfilt(ones(8,1)/8,1,double(nonMovAndStimEpochs));
%     nonMovAndStimEpochs(nonMovAndStimEpochs>0) = 1;
%     nonMovAndStimEpochs = logical(nonMovAndStimEpochs);
%     smoothSpikes(nonMovAndStimEpochs,:) = NaN;
    
    %condition coding
    [~,~,targConfigIdx] = unique(activeTargs,'rows');
    
    codeList = unique(stimCon);
    flippedCon = stimCon;
    flipTrl = find(targConfigIdx==2 | targConfigIdx==4);
    for x=1:length(flipTrl)
        tmpIdx = find(codeList==stimCon(flipTrl(x)));
        newIdx = 12-tmpIdx+1;
        flippedCon(flipTrl(x)) = codeList(newIdx);
    end
   
    %targConfigIdx should be [3,4] or [1,2]
    %decision targ should be (2 or 3) or (0 or 1)

    %%
    %single-factor plot for one choice, with RT as a factor
    trlIdx = find(ismember(targConfigIdx,[3 4]) & decisionTarg==2 & ~isnan(rtIdx));
    timeWindow = [-75,0];
    dPCA_out = apply_dPCA_simple( smoothSpikes, movEpochs(trlIdx,1), ...
        rtIdx(trlIdx), timeWindow, 0.02, {'CD','CI'} );
   
    %compute mean speed profile
    spd = [0; matVecMag(diff(allOut.rigidBodyPosXYZ),2)];
    concatDat = triggeredAvg( spd, movEpochs(trlIdx,1), timeWindow );
    meanSpeed = mean(concatDat);
    
    lineArgs = cell(nBins,1);
    colors = jet(nBins)*0.8;
    for l=1:nBins
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
    end
    oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1):timeWindow(2))*(binMS/1000), ...
        lineArgs, {'CD','CI'}, 'sameAxes', meanSpeed');
    saveas(gcf, [outDir 'oneFactor_RT.png'], 'png');
    
    %%
    %single-factor plot for all RT, with choice factor
    trlIdx = find(ismember(targConfigIdx,[3 4]) & (decisionTarg==2 | decisionTarg==3) & ~isnan(rtIdx));
    timeWindow = [-75,-20];
    dPCA_out = apply_dPCA_simple( smoothSpikes, movEpochs(trlIdx,1), ...
        decisionTarg(trlIdx), timeWindow, 0.02, {'CD','CI'} );
    
    %compute mean speed profile
    spd = [0; matVecMag(diff(allOut.rigidBodyPosXYZ),2)];
    concatDat = triggeredAvg( spd, movEpochs(trlIdx,1), timeWindow );
    meanSpeed = mean(concatDat);
    
    lineArgs = cell(nBins,1);
    colors = jet(nBins)*0.8;
    for l=1:nBins
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
    end
    oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1):timeWindow(2))*(binMS/1000), ...
        lineArgs, {'CD','CI'}, 'sameAxes', meanSpeed');
    saveas(gcf, [outDir 'oneFactor_choice.png'], 'png');
    
    %%
    %two factor (choice & RT)
    trlIdx = find(ismember(targConfigIdx,[3 4]) & (decisionTarg==2 | decisionTarg==3) & ~isnan(rtIdx));
    timeWindow = [-75,10];
    
    %compute mean speed profile
    allMS = [];
    for x=1:nBins
        spd = [0; matVecMag(diff(allOut.rigidBodyPosXYZ),2)];
        concatDat = triggeredAvg( spd, movEpochs(intersect(trlIdx, find(rtIdx==x)),1), timeWindow );
        meanSpeed = mean(concatDat);
        allMS = [allMS, meanSpeed'];
    end
    
    lineArgs = cell(nBins,2);
    colors = jet(nBins)*0.8;
    for l=1:nBins
        lineArgs{l,1} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
        lineArgs{l,2} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','--'};
    end
    
    dPCA_out = apply_dPCA_simple( smoothSpikes, movEpochs(trlIdx,1), ...
        [rtIdx(trlIdx), decisionTarg(trlIdx)], timeWindow, 0.02, {'RT','Choice','CI','RT x Choice'}, 20, 'xval' );
    
    [yAxesFinal, allHandles, allYAxes] = twoFactor_dPCA_plot_pretty( dPCA_out.cval, (timeWindow(1):timeWindow(2))*(binMS/1000), lineArgs, ...
        {'RT','Choice','CI','RT x Choice'}, 'sameAxes', mean(allMS,2), [], dPCA_out.cval.dimCI, colors, [-0.4,-0.2] );
    saveas(gcf, [outDir '/twoFactor_RT_x_Choice_CI.png'], 'png');
    
    [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1):timeWindow(2))*(binMS/1000), ...
        lineArgs, {'RT','Choice','CI','RT x Choice'}, 'sameAxes', mean(allMS,2));
    saveas(gcf, [outDir '/twoFactor_RT_x_Choice.png'], 'png');
    
    %%
    %two factor (choice & RT)
    trlIdx = find(ismember(targConfigIdx,[3 4]) & (decisionTarg==2 | decisionTarg==3) & ~isnan(rtIdx));
    timeWindow = [-75,-20];
    
    %compute mean speed profile
    allMS = [];
    for x=1:nBins
        spd = [0; matVecMag(diff(allOut.rigidBodyPosXYZ),2)];
        concatDat = triggeredAvg( spd, movEpochs(intersect(trlIdx, find(rtIdx==x)),1), timeWindow );
        meanSpeed = mean(concatDat);
        allMS = [allMS, meanSpeed'];
    end
    
    lineArgs = cell(nBins,2);
    colors = jet(nBins)*0.8;
    for l=1:nBins
        lineArgs{l,1} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
        lineArgs{l,2} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','--'};
    end
    
    dPCA_out = apply_dPCA_simple( smoothSpikes, movEpochs(trlIdx,1), ...
        [rtIdx(trlIdx), decisionTarg(trlIdx)], timeWindow, 0.02, {'RT','Choice','CI','RT x Choice'} );
    
    [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1):timeWindow(2))*(binMS/1000), ...
        lineArgs, {'RT','Choice','CI','RT x Choice'}, 'sameAxes', allMS);
    saveas(gcf, [outDir '/twoFactor_RT_x_Choice_preMove.png'], 'png');
end
