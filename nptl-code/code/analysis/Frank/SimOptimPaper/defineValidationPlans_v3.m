function vPlans = defineValidationPlans_v3(sessions, resultsDir, valMode)
    %defines model types to be validated, plus 

    %constant magnitude
    mTypes(1).name = 'splineModel';
    mTypes(1).stateEstimation = 'fbDelay';
    mTypes(1).noiseSignalDependence = true;
    mTypes(1).noiseFitting = 'point';
    mTypes(1).noiseModel = 'autoregressive';
    mTypes(1).refitStop = false;
    mTypes(1).modelMode = 'constantMag';
    mTypes(1).sbControlModel = false;
    mTypes(1).avgControlModel = false;
    mTypes(1).avgNoiseModel = false;
    
    mTypes(2).name = 'splineModel';
    mTypes(2).stateEstimation = 'fbDelay';
    mTypes(2).noiseSignalDependence = true;
    mTypes(2).noiseFitting = 'matching';
    mTypes(2).noiseModel = 'autoregressive';
    mTypes(2).refitStop = false;
    mTypes(2).modelMode = 'constantMag';
    mTypes(2).sbControlModel = false;
    mTypes(2).avgControlModel = false;
    mTypes(2).avgNoiseModel = false;
    
    %linear model
    mTypes(3).name = 'splineModel';
    mTypes(3).stateEstimation = 'fbDelay';
    mTypes(3).noiseSignalDependence = true;
    mTypes(3).noiseFitting = 'point';
    mTypes(3).noiseModel = 'autoregressive';
    mTypes(3).refitStop = false;
    mTypes(3).modelMode = 'linear';
    mTypes(3).sbControlModel = false;
    mTypes(3).avgControlModel = false;
    mTypes(3).avgNoiseModel = false;
    
    mTypes(4).name = 'splineModel';
    mTypes(4).stateEstimation = 'fbDelay';
    mTypes(4).noiseSignalDependence = true;
    mTypes(4).noiseFitting = 'matching';
    mTypes(4).noiseModel = 'autoregressive';
    mTypes(4).refitStop = false;
    mTypes(4).modelMode = 'linear';
    mTypes(4).sbControlModel = false;
    mTypes(4).avgControlModel = false;
    mTypes(4).avgNoiseModel = false;
    
    %predictive models
    mTypes(5).name = 'predictiveStopping';
    mTypes(5).stateEstimation = 'fbDelay';
    mTypes(5).noiseSignalDependence = true;
    mTypes(5).noiseFitting = 'point';
    mTypes(5).noiseModel = 'autoregressive';
    mTypes(5).refitStop = false;
    mTypes(5).sbControlModel = false;
    mTypes(5).avgControlModel = false;
    mTypes(5).avgNoiseModel = false;
    
    mTypes(6).name = 'predictiveOptimalController';
    mTypes(6).stateEstimation = 'fbDelay';
    mTypes(6).noiseSignalDependence = true;
    mTypes(6).noiseFitting = 'point';
    mTypes(6).noiseModel = 'autoregressive';
    mTypes(6).refitStop = false;
    mTypes(6).sbControlModel = false;
    mTypes(6).avgControlModel = false;
    mTypes(6).avgNoiseModel = false;
    
    %--piecewise continuous models--
    mTypes(7).name = 'pointModel';
    mTypes(7).stateEstimation = 'fbDelay';
    mTypes(7).noiseSignalDependence = true;
    mTypes(7).noiseFitting = 'matching';
    mTypes(7).noiseModel = 'autoregressive';
    mTypes(7).refitStop = false;
    mTypes(7).modelMode = '';
    mTypes(7).sbControlModel = false;
    mTypes(7).avgControlModel = false;
    mTypes(7).avgNoiseModel = false;
    
    %deadzone 
    mTypes(8).name = 'pointModel';
    mTypes(8).stateEstimation = 'fbDelay';
    mTypes(8).noiseSignalDependence = true;
    mTypes(8).noiseFitting = 'matching';
    mTypes(8).noiseModel = 'autoregressive';
    mTypes(8).refitStop = true;
    mTypes(8).modelMode = 'refit';
    mTypes(8).sbControlModel = false;
    mTypes(8).avgControlModel = false;
    mTypes(8).avgNoiseModel = false;
    
    %no fb delay
    mTypes(9).name = 'pointModel';
    mTypes(9).stateEstimation = 'none';
    mTypes(9).noiseSignalDependence = true;
    mTypes(9).noiseFitting = 'matching';
    mTypes(9).noiseModel = 'autoregressive';
    mTypes(9).refitStop = false;
    mTypes(9).modelMode = '';
    mTypes(9).sbControlModel = false;
    mTypes(9).avgControlModel = false;
    mTypes(9).avgNoiseModel = false;
    
    %no signal dependent noise
    mTypes(10).name = 'pointModel';
    mTypes(10).stateEstimation = 'fbDelay';
    mTypes(10).noiseSignalDependence = false;
    mTypes(10).noiseFitting = 'matching';
    mTypes(10).noiseModel = 'autoregressive';
    mTypes(10).refitStop = false;
    mTypes(10).modelMode = '';
    mTypes(10).sbControlModel = false;
    mTypes(10).avgControlModel = false;
    mTypes(10).avgNoiseModel = false;
    
    %white noise
    mTypes(11).name = 'pointModel';
    mTypes(11).stateEstimation = 'fbDelay';
    mTypes(11).noiseSignalDependence = true;
    mTypes(11).noiseFitting = 'matching';
    mTypes(11).noiseModel = 'white';
    mTypes(11).refitStop = false;
    mTypes(11).modelMode = '';
    mTypes(11).sbControlModel = false;
    mTypes(11).avgControlModel = false;
    mTypes(11).avgNoiseModel = false;
    
    %no velocity control dependence
    mTypes(12).name = 'pointModel';
    mTypes(12).stateEstimation = 'fbDelay';
    mTypes(12).noiseSignalDependence = true;
    mTypes(12).noiseFitting = 'matching';
    mTypes(12).noiseModel = 'autoregressive';
    mTypes(12).refitStop = false;
    mTypes(12).modelMode = 'noVel';
    mTypes(12).sbControlModel = false;
    mTypes(12).avgControlModel = false;
    mTypes(12).avgNoiseModel = false;
        
    %avg control model
    mTypes(13).name = 'pointModel';
    mTypes(13).stateEstimation = 'fbDelay';
    mTypes(13).noiseSignalDependence = true;
    mTypes(13).noiseFitting = 'matching';
    mTypes(13).noiseModel = 'autoregressive';
    mTypes(13).refitStop = false;
    mTypes(13).modelMode = '';
    mTypes(13).sbControlModel = false;
    mTypes(13).avgControlModel = true;
    mTypes(13).avgNoiseModel = false;
    
    %avg noise model
    mTypes(14).name = 'pointModel';
    mTypes(14).stateEstimation = 'fbDelay';
    mTypes(14).noiseSignalDependence = true;
    mTypes(14).noiseFitting = 'matching';
    mTypes(14).noiseModel = 'autoregressive';
    mTypes(14).refitStop = false;
    mTypes(14).modelMode = '';
    mTypes(14).sbControlModel = false;
    mTypes(14).avgControlModel = false;
    mTypes(14).avgNoiseModel = true;
    
    %noise models starting from piecewise point
    %deadzone 
    mTypes(15).name = 'pointModel';
    mTypes(15).stateEstimation = 'fbDelay';
    mTypes(15).noiseSignalDependence = true;
    mTypes(15).noiseFitting = 'point';
    mTypes(15).noiseModel = 'autoregressive';
    mTypes(15).refitStop = true;
    mTypes(15).modelMode = 'refit';
    mTypes(15).sbControlModel = false;
    mTypes(15).avgControlModel = false;
    mTypes(15).avgNoiseModel = false;
    
    %no fb delay
    mTypes(16).name = 'pointModel';
    mTypes(16).stateEstimation = 'none';
    mTypes(16).noiseSignalDependence = true;
    mTypes(16).noiseFitting = 'point';
    mTypes(16).noiseModel = 'autoregressive';
    mTypes(16).refitStop = false;
    mTypes(16).modelMode = '';
    mTypes(16).sbControlModel = false;
    mTypes(16).avgControlModel = false;
    mTypes(16).avgNoiseModel = false;
    
    %use slow block control model
    mTypes(17).name = 'pointModel';
    mTypes(17).stateEstimation = 'fbDelay';
    mTypes(17).noiseSignalDependence = true;
    mTypes(17).noiseFitting = 'matching';
    mTypes(17).noiseModel = 'autoregressive';
    mTypes(17).refitStop = false;
    mTypes(17).modelMode = '';
    mTypes(17).sbControlModel = true;
    mTypes(17).avgControlModel = false;
    mTypes(17).avgNoiseModel = false;
    
    %no feedback corrections
    mTypes(18).name = 'pointModel';
    mTypes(18).stateEstimation = 'infDelay';
    mTypes(18).noiseSignalDependence = true;
    mTypes(18).noiseFitting = 'matching';
    mTypes(18).noiseModel = 'autoregressive';
    mTypes(18).refitStop = false;
    mTypes(18).modelMode = '';
    mTypes(18).sbControlModel = false;
    mTypes(18).avgControlModel = false;
    mTypes(18).avgNoiseModel = false;
    
    %simplified no vel
    mTypes(19).name = 'pointModel';
    mTypes(19).stateEstimation = 'none';
    mTypes(19).noiseSignalDependence = true;
    mTypes(19).noiseFitting = 'matching';
    mTypes(19).noiseModel = 'autoregressive';
    mTypes(19).refitStop = false;
    mTypes(19).modelMode = 'noVel';
    mTypes(19).sbControlModel = false;
    mTypes(19).avgControlModel = false;
    mTypes(19).avgNoiseModel = false;
    
    %make a validation plan for each session, which inclides train/test
    %condition subset pairs and model types to be validated
    vPlans = struct();
    for s=1:length(sessions)
        load([resultsDir filesep 'prefitFiles' filesep 'prefit_' sessions(s).name{1} '.mat']);
        if strcmp(sessions(s).conditionTypes{1},'fittsLaw')
            %do by block, not dwell/speed condition. Block to block
            %differences in control strategy can be significant. 
            prefitFile.conditions = makeConditionTableForPrefitFile('gainSmoothing', prefitFile);
            nConditions = length(prefitFile.conditions.trialNumbers);
        else    
            nConditions = length(prefitFile.conditions.trialNumbers);
        end
        vPlans(s).name = sessions(s).name{1};
        if strcmp(valMode, 'predictive')
            %train on cl calibration condition, test on all other conditions
            if strcmp(prefitFile.session.subject,'T6')
               %take from fastest block
               [~,conIdxNoise] = max(prefitFile.conditions.alphaBeta(:,2));
               conIdxFTarg = 1;
            else
                %take from slowest block
                [~,conIdxNoise] = min(prefitFile.conditions.alphaBeta(2:end,2));
                conIdxNoise = conIdxNoise + 1;
                conIdxFTarg = conIdxNoise;
            end
            vPlans(s).vPairs{1} = {conIdxNoise, 2:nConditions, conIdxFTarg};
            
            if strcmp(sessions(s).name{1},'t8.2016.02.01_Fitts_and_2D_Smoothing')
                %special - take from low smoothing conditions (lowest gain
                %is undefined - all conditions have same gain)
                %vPlans(s).vPairs{1} = {[6 9], 2:nConditions, [6 9]};
                vPlans(s).vPairs{1} = {[2 10], 2:nConditions, [2 10]};
            end
            
        elseif strcmp(valMode, 'predictive_fast')
           %train on cl calibration condition, test on all other
           %conditions
           %take from fastest block
           [~,conIdxNoise] = max(prefitFile.conditions.alphaBeta(:,2));
           conIdxFTarg = 1;

           vPlans(s).vPairs{1} = {conIdxNoise, 2:nConditions, conIdxFTarg};
           
           if strcmp(sessions(s).name{1},'t8.2016.02.01_Fitts_and_2D_Smoothing')
                vPlans(s).vPairs{1} = {[2 10], 2:nConditions, [2 10]};
            end
        elseif strcmp(valMode, 'predictive_slow')
            %take from slowest block
            [~,conIdxNoise] = min(prefitFile.conditions.alphaBeta(2:end,2));
            conIdxNoise = conIdxNoise + 1;
            conIdxFTarg = conIdxNoise;
                        
            vPlans(s).vPairs{1} = {conIdxNoise, 2:nConditions, conIdxFTarg};
            
            if strcmp(sessions(s).name{1},'t8.2016.02.01_Fitts_and_2D_Smoothing')
                vPlans(s).vPairs{1} = {[2 10], 2:nConditions, [2 10]};
            end
        elseif strcmp(valMode, 'predictive_medium')
            %take from medium speed block
            [~,sortIdx] = sort(prefitFile.conditions.alphaBeta(2:end,2));
            
            mediumIdx = sortIdx(round(length(sortIdx)/2));
            conIdxNoise = mediumIdx + 1;
            conIdxFTarg = conIdxNoise;
            
            vPlans(s).vPairs{1} = {conIdxNoise, 2:nConditions, conIdxFTarg};
            
            if strcmp(sessions(s).name{1},'t8.2016.02.01_Fitts_and_2D_Smoothing')
                vPlans(s).vPairs{1} = {[2 10], 2:nConditions, [2 10]};
            end
        elseif strcmp(valMode, 'explanatory')
            %skip calibration condition (n=1)
            vPlans(s).vPairs = cell(nConditions-1,1);
            for n=2:nConditions
                vPlans(s).vPairs{n-1} = {n,n};
            end
        else
            error('Incorrect mode');
        end
        vPlans(s).mTypes = mTypes;
    end
end