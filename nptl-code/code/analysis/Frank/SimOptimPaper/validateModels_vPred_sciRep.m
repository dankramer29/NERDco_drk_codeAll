function validateModels_vPred_sciRep(sessions, vPlans, resultsDir, modelNum, tableName)

    mkdir([resultsDir '\fitFiles\']);
    mkdir([resultsDir '\testFiles\']);
    
    runArgs = zeros(0,3);
    for s=1:length(sessions)
        for v=1:length(vPlans(s).vPairs)
            runArgs = [runArgs; [s,v,modelNum]];
        end
    end
    
    %special control conditions
    if vPlans(1).mTypes(modelNum).sbControlModel
        %prepare slow block control models
        testResultsOriginal = load([resultsDir filesep 'testFiles' filesep 'testCell_7_' tableName '.mat']);
        slowModels = cell(length(sessions),1);
        sbIdx = zeros(length(sessions),1);
        for s=1:length(sessions)
            load([resultsDir filesep 'prefitFiles' filesep 'prefit_' sessions(s).name{1} '.mat']);
            
            nonCalCon = find(strcmp(prefitFile.calCodes,'closed loop'));
            [~,slowBlockIdx] = min(prefitFile.optControlParams(nonCalCon,4) + prefitFile.optControlParams(nonCalCon,2));
            
            tableIdx = find(runArgs(:,1)==s);
            modelCell = cell(length(tableIdx),1);
            for t=1:length(tableIdx)
                modelCell{t} = testResultsOriginal.testResultsCell{tableIdx(t)}.fit.fitModel.bestMRule.piecewisePointModel;
            end
            slowModels{s} = modelCell{slowBlockIdx};
            slowModels{s}.modelOpts = modelCell{1}.modelOpts;
            slowModels{s}.type = modelCell{1}.type;
            sbIdx(s) = slowBlockIdx;
        end
        figure
        hold on
        for t=1:length(slowModels)
            plot(slowModels{t}.distEdges, slowModels{t}.distCoef);
        end
        save([resultsDir filesep 'testFiles' filesep 'slowBlockIdx_' tableName '.mat'],'slowModels','sessions','sbIdx');
        save([resultsDir filesep 'testFiles' filesep 'testCell_7_sbControlModels.mat'],'slowModels','sessions','sbIdx');
        close all;
    end
    if vPlans(1).mTypes(modelNum).avgControlModel
        %prepare control strategy averages
        testResultsOriginal = load([resultsDir filesep 'testFiles' filesep 'testCell_7_' tableName '.mat']);
        avgModels = cell(length(sessions),1);
        for s=1:length(sessions)
            tableIdx = find(runArgs(:,1)==s);
            modelCell = cell(length(tableIdx),1);
            for t=1:length(tableIdx)
                modelCell{t} = testResultsOriginal.testResultsCell{tableIdx(t)}.fit.fitModel.bestMRule.piecewisePointModel;
            end
            avgModels{s} = avgPiecewiseModels( modelCell );
            avgModels{s}.modelOpts = modelCell{1}.modelOpts;
            avgModels{s}.type = modelCell{1}.type;
            
            figure
            hold on
            for t=1:length(modelCell)
                plot(modelCell{t}.distEdges*modelCell{t}.distRange(2), modelCell{t}.distCoef);
            end
            plot(avgModels{s}.distEdges*avgModels{s}.distRange(2),avgModels{s}.distCoef,'k','LineWidth',2);
        end
        save([resultsDir filesep 'testFiles' filesep 'testCell_7_avgControlModels.mat'],'avgModels','sessions');
        close all;
    end
    if vPlans(1).mTypes(modelNum).avgNoiseModel
        %prepare noise model averages
        testResultsOriginal = load([resultsDir filesep 'testFiles' filesep 'testCell_7_' tableName '.mat']);
        modelCell = cell(length(testResultsOriginal.testResultsCell),1);
        for t=1:length(modelCell)
            modelCell{t} = testResultsOriginal.testResultsCell{t}.fit.fitModel.bestARModel;
        end
        avgModel = avgARModels( modelCell );
        save([resultsDir filesep 'testFiles' filesep 'testCell_7_avgNoiseModel.mat'],'avgModel');
    end
    
    testResultsCell = cell(length(runArgs),1);
    resampleTraj = false;

    if resampleTraj
        %T6 figure
        nBoot = 200;
        testResultsCell = cell(nBoot,1);
        parfor r=1:nBoot
            testResultsCell{r} = internalFunction(sessions, vPlans, resultsDir, runArgs(7,:), resampleTraj);
        end
        
        allCurvess = zeros(nBoot, size(testResultsCell{1}.predictionCurve,1), size(testResultsCell{1}.predictionCurve,2));
        for r=1:nBoot
            allCurves(r,:,:) = testResultsCell{r}.predictionCurve;
        end
        
        [~,sortIdx] = sort(testResultsCell{1}.allAB(:,2));
        
        figure
        hold on;
        for r=1:nBoot
            plot(squeeze(allCurves(r,sortIdx,4)));
        end
        save([resultsDir filesep 'testFiles_sciRep' filesep 'bootCellT6_' num2str(modelNum) '_' tableName],...
            'allCurves','-v7.3'); 
        
        %T8 figure
        nBoot = 200;
        testResultsCell_t8 = cell(nBoot,1);
        parfor r=1:nBoot
            testResultsCell_t8{r} = internalFunction(sessions, vPlans, resultsDir, runArgs(14,:), resampleTraj);
        end
        
        allCurves_t8 = zeros(nBoot, size(testResultsCell_t8{1}.predictionCurve,1), size(testResultsCell_t8{1}.predictionCurve,2));
        for r=1:nBoot
            allCurves_t8(r,:,:) = testResultsCell_t8{r}.predictionCurve;
        end
        
        [~,sortIdx] = sort(testResultsCell_t8{1}.allAB(:,1));
        
        figure
        hold on;
        for r=1:nBoot
            plot(squeeze(allCurves_t8(r,sortIdx,2)));
        end
        for c=1:4
            figure
            hold on;
            
            CI = prctile(squeeze(allCurves_t8(:,sortIdx,c)), [2.5, 97.5]);
            plot(nanmean(squeeze(allCurves_t8(:,sortIdx,c))));
            plot(CI');
        end
            
        save([resultsDir filesep 'testFiles_sciRep' filesep 'bootCellT8_2_' num2str(modelNum) '_' tableName],...
            'allCurves_t8','-v7.3'); 
    else
        parfor r=1:size(runArgs,1)
            testResultsCell{r} = internalFunction(sessions, vPlans, resultsDir, runArgs(r,:), resampleTraj);
        end        
        save([resultsDir filesep 'testFiles_sciRep' filesep 'testCell_' num2str(modelNum) '_' tableName],...
            'testResultsCell','sessions','vPlans','modelNum','runArgs','-v7.3'); 
    end
end

function testResults = internalFunction(sessions, vPlans, resultsDir, runArgs, resampleTraj)
    tic;
    rng('shuffle');
    load([resultsDir filesep 'prefitFiles' filesep 'prefit_' sessions(runArgs(1)).name{1} '.mat']);
    
    %if bootstrap resampling, resample the trajs
    if resampleTraj
        for c=1:length(prefitFile.conditions.trialNumbers)
            trlIdx = prefitFile.conditions.trialNumbers{c};
            trlIdxResample = trlIdx(randi(length(trlIdx),length(trlIdx),1));
            
            prefitFile.perfTable(trlIdx,:) = prefitFile.perfTable(trlIdxResample,:);
            prefitFile.trl.reaches(trlIdx,:) = prefitFile.trl.reaches(trlIdxResample,:);
            prefitFile.trl.targNums(trlIdx) = prefitFile.trl.targNums(trlIdxResample);
            prefitFile.trl.isOuterReach(trlIdx) = prefitFile.trl.isOuterReach(trlIdxResample);
            prefitFile.trl.blockNums(trlIdx) = prefitFile.trl.blockNums(trlIdxResample);
            prefitFile.trl.isSuccessful(trlIdx) = prefitFile.trl.isSuccessful(trlIdxResample);
        end
    end

    if strcmp(sessions(runArgs(1)).conditionTypes{1},'fittsLaw')
        testBlocks = prefitFile.blockList(strcmp(prefitFile.calCodes,'closed loop'));
        testResults.cVecNorm = [];
        testResults.sim = cell(length(testBlocks),1);
        testResults.simOpts = cell(length(testBlocks),1);
        testResults.modelType = vPlans(runArgs(1)).mTypes(runArgs(3));
        testResults.testConditions = 2:(length(testBlocks)+1);
        testResults.fitLenS = zeros(length(prefitFile.conditions.trialNumbers),1);
        
        for c=2:length(prefitFile.conditions.trialNumbers)
            trlIdx = prefitFile.conditions.trialNumbers{c};
            blockNums = prefitFile.trl.blockNums(trlIdx);
            blockNums = unique(blockNums);
            [~,innerBlockIdx] = ismember(blockNums, testBlocks);

            tRad = prefitFile.loopMat.targetRad(prefitFile.trl.reaches(trlIdx,1));
            tDist = prefitFile.loopMat.targDist(prefitFile.trl.reaches(trlIdx,1));
            tList = unique(tRad);

            goodIdx = tRad==tList(1) & tDist > prefitFile.ffDistInterval(end)*0.75;
            prefitFile.conditions.trialNumbers{c} = prefitFile.conditions.trialNumbers{c}(goodIdx);

            fitResults = fitModelOnConditions_v6_sciRep(prefitFile, c, vPlans(runArgs(1)).mTypes(runArgs(3)), resultsDir);
            testResults.fitLenS(c) = length(expandEpochIdx(fitResults.fitReaches{1}))/50;
            
            for b=1:length(blockNums)
                %250 reaches originally
                tmpResults = testModelOnConditions_v3(prefitFile, c, vPlans(runArgs(1)).mTypes(runArgs(3)), fitResults, 2000, 'fitts');
                testResults.sim{innerBlockIdx(b)} = tmpResults.sim{1};
                testResults.simOpts{innerBlockIdx(b)} = tmpResults.simOpts{1};
            end
        end
    else
        %use only last block of cal 
        calIdx = find(prefitFile.conditions.calCondition);
        bnList = unique(prefitFile.trl.blockNums(prefitFile.conditions.trialNumbers{calIdx}));
        remIdx = prefitFile.trl.blockNums(prefitFile.conditions.trialNumbers{calIdx})~=bnList(end);
        prefitFile.conditions.trialNumbers{calIdx}(remIdx) = [];

        fitResults = fitModelOnConditions_v6_sciRep(prefitFile, vPlans(runArgs(1)).vPairs{runArgs(2)}{1}, vPlans(runArgs(1)).mTypes(runArgs(3)), resultsDir);
        if any(vPlans(runArgs(1)).vPairs{runArgs(2)}{1}~=vPlans(runArgs(1)).vPairs{runArgs(2)}{3})
            fitResultsCal = fitModelOnConditions_v6_sciRep(prefitFile, vPlans(runArgs(1)).vPairs{runArgs(2)}{3}, vPlans(runArgs(1)).mTypes(runArgs(3)), resultsDir);
            fitResults.fitModel.bestMRule.piecewisePointModel = fitResultsCal.fitModel.bestMRule.piecewisePointModel;
        end
        
        %250 reaches originally
        testResults = testModelOnConditions_v3(prefitFile, vPlans(runArgs(1)).vPairs{runArgs(2)}{2}, vPlans(runArgs(1)).mTypes(runArgs(3)), fitResults, 1000, 'gainSmooth');
    end
    
    fitResults = rmfield(fitResults, {'outlierReachIdx','fitTrlNumbers','fitConditions','fitReaches','fitSimOpts','modelType'});
    testResults.fit = fitResults;
    timeElapsed = toc;
    disp([num2str(runArgs(1)) ' - ' num2str(runArgs(2)) ' - ' num2str(runArgs(3)) ', ' num2str(timeElapsed)]);
    close all;
    
    %if bootstrap resampling, only return bare minimum statistics
    if resampleTraj
        predictionCurve = zeros(length(testResults.sim),4);
        allAB = zeros(length(testResults.sim),2);

        for c=1:length(testResults.sim)
            predictionCurve(c,1) = nanmean(testResults.sim{c}.exDialTime);
            predictionCurve(c,2) = nanmean(testResults.sim{c}.translateTime);
            predictionCurve(c,3) = nanmean(testResults.sim{c}.ttt);
            predictionCurve(c,4) = nanmean(testResults.sim{c}.pathEff);
            allAB(c,1) = testResults.simOpts{c}.plant.alpha;
            allAB(c,2) = testResults.simOpts{c}.plant.beta;
        end  
        
        newOutput.predictionCurve = predictionCurve;
        newOutput.allAB = allAB;
        testResults = newOutput;
    end
end
