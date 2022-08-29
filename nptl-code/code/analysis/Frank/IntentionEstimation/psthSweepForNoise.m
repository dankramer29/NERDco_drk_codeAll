function psthSweepForNoise(resultsDir, sessions)
    mkdir([resultsDir filesep 'decoderBuilding']);

    %for s=10:15
    for s=1:length(sessions)
        disp(sessions(s).name{1});
        pFile = load([resultsDir filesep 'prefitFiles' filesep 'prefit_' sessions(s).name{1} '.mat']);
        prefitFile = pFile.prefitFile;
        

        internalFunction(prefitFile, resultsDir, sessions(s));
    end
end

function internalFunction(prefitFile, resultsDir, session)
    %compare cartesian cVec model to cMag, cMag far field, and
    %refit

    
    rtSteps = round(prefitFile.reactionTimeIntervalForFitting(1) / prefitFile.loopTime(1));
    reachEpochs = prefitFile.trl.reaches;
    reachEpochs(:,1) = reachEpochs(:,1) + rtSteps;

    outlierIdx = false(size(reachEpochs,1),1);
    for t=1:size(reachEpochs,1)
       loopIdx =reachEpochs(t,1):reachEpochs(t,2);
       if all(prefitFile.loopMat.targDist(loopIdx)>(prefitFile.ffDistInterval(1)/2))
           outlierIdx(t)=true;
       end
    end
    sigma = 1.4826 * median(abs(prefitFile.perfTable(:,2) - median(prefitFile.perfTable(:,2))));
    allOutliers = outlierIdx | (prefitFile.perfTable(:,2) > (mean(prefitFile.perfTable(:,2)) + sigma*3));
    
    lineArgs = cell(8,1);
    colors = hsv(8)*0.8;
    for l=1:length(lineArgs)
        lineArgs{l} = {'LineWidth',1,'Color',colors(l,:)};
    end

    useIdx = find(~prefitFile.trl.isOuterReach & prefitFile.trl.targNums~=0);
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 1.5;
    psthOpts.neuralData = {prefitFile.loopMat.featureMatrix(:,1:192)};
    psthOpts.timeWindow = [-25 100];
    psthOpts.trialEvents = prefitFile.trl.reaches(useIdx,1);
    psthOpts.trialConditions = prefitFile.trl.targNums(useIdx);
    psthOpts.conditionGrouping = {1:8};
    psthOpts.lineArgs = lineArgs;

    psthOpts.plotsPerPage = 10;
    saveDir = [resultsDir filesep 'psthNoiseSweep' filesep session.name{1}];
    mkdir(saveDir);
    psthOpts.plotDir = saveDir;

    featLabels = cell(192*2,1);
    for f=1:192
        featLabels{f} = ['TX ' num2str(f)];
    end
    for f=1:192
        featLabels{f+192} = ['SP ' num2str(f)];
    end
    psthOpts.featLabels = featLabels;

    psthOpts.prefix = 'all';
    pOut = makePSTH_simple(psthOpts);
    close all;

end