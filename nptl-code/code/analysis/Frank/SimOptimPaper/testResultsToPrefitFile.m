function [ prefitFile ] = testResultsToPrefitFile( testCell, sessionIdx, tableMode, prefitOriginal )
    if strcmp(prefitOriginal.session.conditionTypes{1},'fittsLaw')
        prefitFile = prefitOriginal;
        prefitFile.conditions = makeConditionTableForPrefitFile('gainSmoothing', prefitFile);
        
        nonCalConditions = find(~prefitFile.conditions.calCondition);       
        
        if strcmp(tableMode, 'explain') || strcmp(tableMode, 'fittsExplain')
            testResults = [];
            tableIdx = find(testCell.runArgs(:,1)==sessionIdx);
            testResults.sim{1} = [];
            testResults.simOpts{1} = [];
            for r=1:length(tableIdx)
                testResults.sim{r+1} = testCell.testResultsCell{tableIdx(r)}.sim{1};
                testResults.simOpts{r+1} = testCell.testResultsCell{tableIdx(r)}.simOpts{1};
            end
        elseif strcmp(tableMode, 'predict') || strcmp(tableMode, 'fittsPredict') 
            tableIdx = testCell.runArgs(:,1)==sessionIdx;
            testResults = testCell.testResultsCell{tableIdx};
            testResults.sim = [{[]}; testResults.sim];
            testResults.simOpts = [{[]}; testResults.simOpts];
        end
        prefitSim = simResultsToPrefitFile(testResults, prefitFile);
        
        firstTestBlock = find(strcmp('closed loop',prefitOriginal.calCodes),1);
        newBlockNums = prefitSim.trl.blockNums;
        for c=1:length(nonCalConditions)
            replaceIdx = prefitSim.trl.blockNums==(c+1);
            newBlockNums(replaceIdx)=prefitSim.blockList(firstTestBlock+c-1);
        end
        prefitSim.trl.blockNums = newBlockNums;
        for b=1:length(prefitSim.blockList)
            prefitSim.decoder{b}.mat = eye(2);
            prefitSim.decoder{b}.featureNorms = [1 1];
        end
        prefitSim.conditions = makeConditionTableForPrefitFile('fittsLaw', prefitSim);
        prefitFile = prefitSim;
    else
        if strcmp(tableMode, 'explain') || strcmp(tableMode, 'gsExplain')
            testResults = [];
            tableIdx = find(testCell.runArgs(:,1)==sessionIdx);
            testResults.sim{1} = [];
            testResults.simOpts{1} = [];
            for r=1:length(tableIdx)
                testResults.sim{r+1} = testCell.testResultsCell{tableIdx(r)}.sim{1};
                testResults.simOpts{r+1} = testCell.testResultsCell{tableIdx(r)}.simOpts{1};
            end
            prefitFile = simResultsToPrefitFile(testResults, prefitOriginal);
        elseif any(strcmp(tableMode, {'predict','gsPredict','gsPredict_slow','gsPredict_medium','gsPredict_fast','gsPredict_sciRep'}))
            tableIdx = testCell.runArgs(:,1)==sessionIdx;
            testResults = testCell.testResultsCell{tableIdx};
            testResults.sim = [{[]}; testResults.sim];
            testResults.simOpts = [{[]}; testResults.simOpts];
            prefitFile = simResultsToPrefitFile(testResults, prefitOriginal);
        end
    end
end

