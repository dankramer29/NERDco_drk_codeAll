% Does some basic kinematic workups of 
% 4.0 DOF RAYS (discretized selection) task data. Currently written to just
% load each block and get metrics for that block and print that out in a
% format that makes it easy to populate a table. I'm not sure yet how I'll
% actually use these data.
%
% Sergey Stavisky July 2017


%% Data to analyze
%%
datalist = 't5_RAYS_4D';
datasetFunction = @datasets_4D;
streamsPathRoot = ['/net/experiments/'];
RAYStaskValue = 8; % how I coded the RAYS task in my datasetFunction.
R80taskValue = 1; % how I coded the regular R80 task in my datasetFunction.

params.resultsPath = '/net/derivative/user/sstavisk/Results/RAYS/'; % processed data goes here 
params.figuresPath = ['/net/derivative/user/sstavisk/Figures/RAYS/' datalist '/' ];
params.discardFirstTrial = true; % seems prudent to do given unpause weirdness and such
params.plotExampleBlocks = true; % very slow to save as .fig because it's a lot of points
params.plotRotationEveryNms = 45;
% R80 path efficiency
params.R80endDistance = 0.055; % detect end of trial as this; matched to mode of RAYS blocks


%% Generate the single-dataset results

datasets = datasetFunction( datalist );
fprintf('=======================\n   %s\n=========================\n', datalist)



results = {}; % will fill these in for each dataset
for iDataset = 1 : numel( datasets )  
    dataset = datasets{iDataset};
    fprintf('Dataset %i/%i: %s...', iDataset, numel( datasets ), dataset );
   
    [dataset,condition] = datasetFunction( dataset );
    % restrict to R80 or RAYS task.
    analyzeBlocks = condition.blocks( ismember( condition.task, [R80taskValue, RAYStaskValue] ) );
  
    result.blocks = analyzeBlocks;
    result.condition = condition;
    result.dataset = dataset;    
    participant = dataset(1:2);
    
    for iBlock = 1 : numel( result.blocks )    
        % Load stream and make R struct for each block
        streamsPath= [streamsPathRoot  participant '/' dataset '/Data/FileLogger/'];
        myBlock = result.blocks(iBlock);
        stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, myBlock ), {'neural'} ); % note excluding neural, which I don't need here
        Rin = onlineR( stream );
        if params.discardFirstTrial
            Rin(1) = [];
        end
        
        % Verify that this task type is what my lookup table says it is
        myCondition = result.condition.task(iBlock);
        STtask = Rin(1).startTrialParams.taskType;
        if myCondition ~= STtask
            error('lookup says this is task %i, but ST says it is %i\n', ...
                myCondition, STtask );
        end
        
        switch myCondition
            case R80taskValue
                fprintf('%i (R80) ', myBlock);
                fprintf(' %i trials.', numel( Rin ) );
                result.stats{iBlock} = CursorTaskSimplePerformanceMetrics( Rin, 'radiusCounts', false );
                % special forms of path efficiency to match ti to the RAYS
                % path efficiency
                % First, compute crossing the same distance from origin 
                startNorm = [];
                Rin = AddTimesTargetEntry( Rin ); % will need below

                for i = 1 : numel( Rin )
                    distFromOrigin = norms( Rin(i).cursorPosition );
                    if ~any( Rin(i).posTarget )
                        % center target, so don't compute RAYS-like PE for
                        % this
                        Rin(i).pathEfficiencyRAYSlike = nan;
                    elseif Rin(i).isSuccessful == false 
                        % also don't return this for failure trials (these
                        % are very rare and indicate something weird was
                        % happening)
                        Rin(i).pathEfficiencyRAYSlike = nan;
                    else
                        Rin(i).timeLastTargetEntry = Rin(i).timesTargetEntry(end);
                        startPos = Rin(i).cursorPosition(:,Rin(i).timeTargetOn );
                        startNorm(end+1) = norm( startPos );                        
                        % Calculate vector from start location towards
                        % target center.
                        tv = Rin(i).posTarget - startPos;
                        tv = tv./ norm( tv ); % unit vector;
                        
                        fullTraj = Rin(i).cursorPosition(:,Rin(i).timeTargetOn : Rin(i).timeLastTargetEntry);                        
                        % offset coordinate so starting point is 0,0, which
                        % allows projection onto target vector to measure
                        % progress (from 0) towards target
                        fullTrajOffset = fullTraj - repmat( startPos, 1, size( fullTraj, 2 ) );
                        % project the full trajectory onto the target
                        % vector
                        tvProjectionEachMS = fullTrajOffset'*tv;         
                         % when did it go far enough towards target?
                        timeFauxSelection = find( tvProjectionEachMS >= params.R80endDistance, 1, 'first');
                        % what was the distance traveled until this point
                        relevantTraj = fullTraj(:,1:timeFauxSelection);
                        trajDistance = sum( sqrt( sum( diff(relevantTraj,1,2).^2, 1 ) ) ); % this will be numerator
                        Rin(i).pathEfficiencyRAYSlike = params.R80endDistance / trajDistance;
                    end
                end
                % record only valid RAYS-like PE (so outward going
                % successful trials)
                myRAYSlikePE = [Rin.pathEfficiencyRAYSlike];
                myRAYSlikePE(isnan( myRAYSlikePE )) = [];
                result.stats{iBlock}.pathEfficiencyRAYSlike = myRAYSlikePE;
                
                
                
                fprintf('%i/%i success (%.2f%%); %.2fsuc/min, PE=%.4f (RAYS-like), PE=%.4f (all succ trials)\n', ...
                    result.stats{iBlock}.numSuccess, result.stats{iBlock}.numTrials, 100*result.stats{iBlock}.numSuccess/ result.stats{iBlock}.numTrials, ...
                    result.stats{iBlock}.successPerMinute, mean(result.stats{iBlock}.pathEfficiencyRAYSlike ), mean( result.stats{iBlock}.pathEfficiency ) );
                
                
            case RAYStaskValue
                % main RAYS task
                fprintf('%i ', myBlock);
                fprintf(' %i trials.', numel( Rin ) );
                result.stats{iBlock} = CursorTaskSimplePerformanceMetrics( Rin, 'radiusCounts', false );
                fprintf('%i/%i success (%.2f%%); %.3fbps, %.2fsuc/min, PE=%.4f (all trials); ', ...
                    result.stats{iBlock}.numSuccess, result.stats{iBlock}.numTrials, 100*result.stats{iBlock}.numSuccess/ result.stats{iBlock}.numTrials, ...
                    result.stats{iBlock}.bitRate, result.stats{iBlock}.successPerMinute, mean( result.stats{iBlock}.pathEfficiency ) );
                % report some relevant task configuration details
                result.taskParameters{iBlock}.lockedTime = Rin(end).startTrialParams.recenterDelay;
                result.taskParameters{iBlock}.feedbackDuration = Rin(end).timeGoCue - result.taskParameters{iBlock}.lockedTime - 3; % 3 ms due to state recording jitters.
                result.taskParameters{iBlock}.selectionDistance = Rin(end).startTrialParams.targetRotDiameter/2;
                fprintf( 'feedback,locked durations = %i,%i ms; select at %.2fcm\n', ...
                    result.taskParameters{iBlock}.feedbackDuration, result.taskParameters{iBlock}.lockedTime, 100*result.taskParameters{iBlock}.selectionDistance );
        end
   
    
    
        %--------------------------------------------------------
        % Plot Example Block
        % -------------------------------------------------------
        if params.plotExampleBlocks && any( myBlock == condition.examplePlotBlock )
            figh = figure;
            Rplot = Rin;
            % Isometric view
            axh(1) = subplot(1,4,1);
            Plot4Dtrajectories( Rplot, 'showTarget', false, ...
                'plotRodEveryNms', params.plotRotationEveryNms, 'cursorDrawnRadius', 0.002, 'axh', axh(1));
            axh(1).GridLineStyle = 'none';
            
            % XY view
            axh(2) = subplot(1,4,2);
            Plot4Dtrajectories( Rplot, 'showTarget', false, ...
                'plotRodEveryNms', params.plotRotationEveryNms, 'cursorDrawnRadius', 0.002, 'axh', axh(2));
            axh(2).CameraPosition = [0 0 -0.6];
            
            % ZY view
            axh(3) = subplot(1,4,3);
            Plot4Dtrajectories( Rplot, 'showTarget', false, ...
                'plotRodEveryNms', params.plotRotationEveryNms, 'cursorDrawnRadius', 0.002, 'axh', axh(3));
            axh(3).CameraPosition = [-0.6 0 0];
            axh(3).CameraUpVector = [0 -1 0];
            axh(3).ZDir = 'normal'; % makes out (towards screen) on right
            
            % XZ view
            axh(4) = subplot(1,4,4);
            Plot4Dtrajectories( Rplot, 'showTarget', false, ...
                'plotRodEveryNms', params.plotRotationEveryNms, 'cursorDrawnRadius', 0.002, 'axh', axh(4));
            axh(4).CameraPosition = [0 0.6 0];
            axh(4).CameraUpVector = [0 0 -1];
            axh(4).ZDir = 'reverse'; % makes out (towards screen) on bottom
            
            titlestr = sprintf('%sB%i', dataset, myBlock );
            figh.Name = titlestr;
            if ~isdir( params.figuresPath )
                mkdir( params.figuresPath )
            end
            saveas( figh, [params.figuresPath titlestr '_3views.fig'] );

            
            
        end
     end
    
    results{iDataset} = result;
end
Nsessions = numel( results );

%% Get things I'm interested in from all the trials
fprintf('Finished for now, there''s more code below for aggregating that needs fixin''\n');
% keyboard; % below is old code I can bring up to date to compute various aggregate measures.


agg.pathEfficiencyRAYS = [];
agg.pathEfficiencyR80RAYSlike = []; % only metric that is R80, all others are RAYS
agg.numSuccess = 0;
agg.numFailure = 0;
agg.blockDuration = 0;

% most metrics are just for RAYS, the R80 is 
for iDataset = 1 : Nsessions
    for iBlock = 1 : numel( results{iDataset}.condition.task )
        if results{iDataset}.condition.task(iBlock) == R80taskValue
            agg.pathEfficiencyR80RAYSlike = [agg.pathEfficiencyR80RAYSlike; results{iDataset}.stats{iBlock}.pathEfficiencyRAYSlike'];
        elseif results{iDataset}.condition.task(iBlock) == RAYStaskValue
            agg.numSuccess = agg.numSuccess + results{iDataset}.stats{iBlock}.numSuccess;            
            agg.numFailure = agg.numFailure + results{iDataset}.stats{iBlock}.numFailure;
            agg.blockDuration = agg.blockDuration + results{iDataset}.stats{iBlock}.blockDuration;
            agg.pathEfficiencyRAYS = [agg.pathEfficiencyRAYS; results{iDataset}.stats{iBlock}.pathEfficiency];
        end
    end
end



%% Some aggregate statistics across these blocks

fprintf('\nRAYS success rate over %i total trials (%.2f minutes) is %.2f%%\n', ...
    agg.numSuccess+agg.numFailure, agg.blockDuration /60,  100*agg.numSuccess/(agg.numSuccess+agg.numFailure) );
fprintf('Mean PE is %.3f +- %.3fms (s.d.), %.5f (s.e.). \n', ...
    mean( agg.pathEfficiencyRAYS ), std( agg.pathEfficiencyRAYS ), sem( agg.pathEfficiencyRAYS ) );

fprintf('\nR80 path efficiency (RAYS-like) over %i total trials is %.3f, +- %.3f (s.d.), %.5f (s.e.) \n', ...
    numel( agg.pathEfficiencyR80RAYSlike ), mean( agg.pathEfficiencyR80RAYSlike ), std( agg.pathEfficiencyR80RAYSlike ), sem( agg.pathEfficiencyR80RAYSlike ) );

[p,h] = ranksum( agg.pathEfficiencyR80RAYSlike, agg.pathEfficiencyRAYS  );
fprintf('difference between R80 and RAYS path efficiencies have p = %f (rank-sum test)\n', p );

