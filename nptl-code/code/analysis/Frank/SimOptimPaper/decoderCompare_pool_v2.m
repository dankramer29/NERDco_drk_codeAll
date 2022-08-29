function decoderCompare_pool_v2( sessions, cTable, cSets, decLabels, fileDir, figDir )

    for s=1:length(sessions)
        %%
        files = loadBG2Files( [fileDir filesep sessions(s).name{1}], sessions(s).allBlockNumbers{1} );
        if s==1
            prefit = bg2EastFilesToPrefit( files, sessions(s) );
            prefit.session = sessions(s);
            prefit.conditions = makeConditionTableForPrefitFile('gainSmoothing', prefit);
            prefit.trl.reaches(:,2) = prefit.trl.reaches(:,2)-1;
            cTableAll = cTable{s,1};
        else
            tmp = bg2EastFilesToPrefit( files, sessions(s) );
            tmp.session = sessions(s);
            tmp.conditions =  makeConditionTableForPrefitFile('gainSmoothing', tmp);
                        
            nLoops = size(prefit.loopMat.positions,1);
            nTrials = size(prefit.trl.reaches,1);
            nCons = size(cTableAll,1);
            
            fNames = fieldnames(prefit.loopMat);
            for f=1:length(fNames)
                prefit.loopMat.(fNames{f}) = [prefit.loopMat.(fNames{f}); tmp.loopMat.(fNames{f})];
            end
            prefit.perfTable = [prefit.perfTable; tmp.perfTable];
            
            for c=1:length(tmp.conditions.trialNumbers)
                tmp.conditions.trialNumbers{c} = tmp.conditions.trialNumbers{c} + nTrials;
            end
            tmp.trl.reaches = tmp.trl.reaches + nLoops;
            
            prefit.trl.reaches = [prefit.trl.reaches; tmp.trl.reaches];
            prefit.conditions.trialNumbers = [prefit.conditions.trialNumbers; tmp.conditions.trialNumbers];
            
            cTable{s,1}(:,1) = cTable{s,1}(:,1) + nCons;
            cTableAll = [cTableAll; cTable{s,1}];
        end
    end
    
    mkdir([figDir filesep 'pool']);
    decoderCompare_sub_v2( prefit, 'pool', cTableAll, cSets, decLabels, figDir );
end

