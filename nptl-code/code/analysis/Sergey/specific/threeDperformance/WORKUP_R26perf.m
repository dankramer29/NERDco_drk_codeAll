% Does some basic kinematic workups of recently collected 3D Radial 26-target blocks.
%
% Sergey Stavisky March 2017


%% Data to analyze
clear
% datalist = 't5_3D_early2017';
% datalist = 't5_3D_early2017_dwell';

datalist = 't5_3D_lowGain';
params.maxGain = 0.7; % makes sense for this 3D day

params.resultsPath = '/net/derivative/user/sstavisk/Results/threeDandClick/'; % processed data goes here 

% Aggregate analysis parameters - will not force regenerate results 

% These only apply to the dimensionality-specific analyses, not to the TTT,
% success rate, targets/m
includeOutward = true; % whether to include outward-going trials
includeInward = true; % whether to include inward-going trials
figuresPath = ['/net/derivative/user/sstavisk/Figures/threeDandClick/' datalist '/' ];

% ExampleBlock
% used to get a bunch of parameters
experiment = 't5.2017.02.15';
trajectoryPlotBlock = 6; % will make a plot of this block.



YLim_TTT = [0 5000];
YLim_SPEED = [ 0 5]; % leave empty for auto
%% Generate the single-dataset results

datasets = datasets_3D( datalist );
fprintf('=======================\n   %s\n=========================\n', datalist)

% Go through each dataset and load or generate its results
if ~isdir( params.resultsPath )
    mkdir( params.resultsPath );
end


results = {}; % will fill these in for each dataset
for iDataset = 1 : numel( datasets )  
    fprintf('Dataset %i/%i: %s...', iDataset, numel( datasets ), datasets{iDataset} );

    % RUN ANALYSIS FOR BOTH DECODER NULL & POTENT
    resultsFilename = MakeValidFilename([params.resultsPath  datasets{iDataset} '_' structToFilename( params, ...
        'forceHash', true, 'maxLength', 200 ) ]);
    try
        loaded = load( resultsFilename );
        myres = loaded.myres;
        results{iDataset} = myres; % unpacking anoyance
        fprintf(' LOADED\n')
    catch
        fprintf(' ready result not found. Analyzing...\n');
        myres =  hypersphereKinematicsOneDataset( datasets{iDataset}, params );
        fprintf('     saving %s...\n', resultsFilename );
        save( resultsFilename, 'myres' );
        results{iDataset} = myres; % unpacking anoyance
        fprintf(' OK\n')
    end
    
    % Report each block's performance
    for iBlock = 1 : numel( results{iDataset}.blocks )
        myPE = nanmean( results{iDataset}.stats{iBlock}.pathEfficiency );
        myTPM = results{iDataset}.stats{iBlock}.successPerMinute;
        fprintf(' block%i: PE=%g, %.2f TPM\n', ...
            results{iDataset}.blocks(iBlock), myPE, myTPM );
    end
    
end
Nsessions = numel( results );

%% Get things I'm interested in from all the trials


uniqueTargets = results{1}.uniqueTargets;
uniquePrevTargets = results{1}.uniquePrevTargets;

agg.numSuccess = 0;
agg.numFailure = 0;
agg.blockDuration = 0;
agg.targetIdx = [];
agg.prevTargetIdx = [];
agg.peakSpeed = [];
agg.peakSpeedEachDim = [];
agg.TTT = [];
agg.dialIn = [];
agg.pathEfficiency = [];
agg.pathEfficiencyEachDim = [];
agg.isSuccessful = [];
agg.cuedDistanceToTarget = [];
agg.targetDiameter = [];
for iDataset = 1 : Nsessions
    agg.numSuccess = agg.numSuccess + results{iDataset}.wholeDatasetStats.numSuccess;
    agg.numFailure = agg.numFailure + results{iDataset}.wholeDatasetStats.numFailure;
    agg.blockDuration = agg.blockDuration + results{iDataset}.wholeDatasetStats.blockDuration;
    
    % Verify that the target set is the same
    if norm( uniqueTargets - results{iDataset}.uniqueTargets ) > eps
        error('uniqueTargets not the same.on datset %i', iDataset );
    end
    if norm( uniquePrevTargets - results{iDataset}.uniquePrevTargets ) > eps
        error('uniqueTargets not the same.on datset %i', iDataset );
    end
    agg.targetIdx = [agg.targetIdx; results{iDataset}.targetIdx];
    agg.prevTargetIdx = [agg.prevTargetIdx; results{iDataset}.prevTargetIdx];
    agg.peakSpeed = [agg.peakSpeed; results{iDataset}.peakSpeed];
    agg.peakSpeedEachDim = [agg.peakSpeedEachDim; results{iDataset}.peakSpeedEachDim];
    agg.TTT = [agg.TTT; results{iDataset}.wholeDatasetStats.TTT];
    agg.dialIn = [agg.dialIn; results{iDataset}.wholeDatasetStats.dialIn];
   
    agg.pathEfficiency = [agg.pathEfficiency; results{iDataset}.wholeDatasetStats.pathEfficiency];
    agg.pathEfficiencyEachDim = [agg.pathEfficiencyEachDim; results{iDataset}.wholeDatasetStats.pathEfficiencyEachDim];

    agg.isSuccessful = [agg.isSuccessful; results{iDataset}.isSuccessful'];  
    agg.cuedDistanceToTarget = [agg.cuedDistanceToTarget; results{iDataset}.wholeDatasetStats.cuedDistanceToTarget'];
    agg.targetDiameter = [agg.targetDiameter; results{iDataset}.wholeDatasetStats.targetDiameter];

    
     
    % give block by block breakdown
    for iBlock = 1 : numel( results{iDataset}.blocks )
        myStr = sprintf('  block %i: %i trials (%.1f success rate), %.2f suc/min, PE = %.4f', ...
            results{iDataset}.blocks(iBlock), results{iDataset}.stats{iBlock}.numTrials, ...
            100* results{iDataset}.stats{iBlock}.numSuccess / results{iDataset}.stats{iBlock}.numTrials,...
            results{iDataset}.stats{iBlock}.successPerMinute,  ...
            nanmean( results{iDataset}.stats{iBlock}. pathEfficiency ) );
        if isfield(  results{iDataset}.stats{iBlock}, 'numIncorrectClicks' )
            myStr = [myStr, sprintf(', %.2f incorrect clicks/trial', nanmean( results{iDataset}.stats{iBlock}.numIncorrectClicks ))];
        end
        fprintf('%s\n', myStr )
    end
end



%% Some aggregate statistics across these blocks

fprintf('\nSuccess rate over %i total trials (%.2f minutes) is %.2f%%\n', ...
    agg.numSuccess+agg.numFailure, agg.blockDuration /60,  100*agg.numSuccess/(agg.numSuccess+agg.numFailure) );
fprintf('%.2f targets per minute\n', agg.numSuccess/(agg.blockDuration /60) );
fprintf('Mean TTT is %.1fms. Mean Dial-in time is %.1fms.\n', ...
    nanmean( agg.TTT ), nanmean( agg.dialIn ) );




%% Report a bunch of metrics broken down by target set
for iSet = 7 : -1: 1 % backwards looks better
    switch iSet
        case 4
            % 1 D, all 3 dims
            setName = 'ALL 1D TARGETS';
            fprintf('\n--------------\n%s\n--------------\n', setName )
            
            targDims = sum( logical( uniqueTargets ),2);
            prevTargDims = sum( logical( uniquePrevTargets ),2);
            
            useTrials = false( size( agg.targetIdx ) );
            if includeOutward
                acceptableTargs = find( targDims == 1 );
                fprintf('%i outward targets permitted\n', ...
                    numel( acceptableTargs ) );
                useTrials = useTrials | ismember( agg.targetIdx, acceptableTargs );
            end
            if includeInward
                acceptablePrevTargs = find( prevTargDims == 1 );
                fprintf('%i inward previous targets permitted\n', ...
                    numel( acceptablePrevTargs ) );
                useTrials = useTrials | ismember( agg.prevTargetIdx, acceptablePrevTargs );
            end
            useTrialsSuccessful = useTrials &  agg.isSuccessful;
        case {1,2,3}
            % 1 D, one dimension at a time.
            thisDim = 4-iSet;
            setName = sprintf('DIM %i ONLY TARGETS', thisDim );
            fprintf('\n--------------\n%s\n--------------\n', setName )
            
            targDims = sum( logical( uniqueTargets ),2);
            prevTargDims = sum( logical( uniquePrevTargets ),2);
            useTrials = false( size( agg.targetIdx ) );
            if includeOutward
                acceptableTargs = find( targDims == 1 & logical( uniqueTargets(:,thisDim) ) );
                fprintf('%i outward targets permitted\n', ...
                    numel( acceptableTargs ) );
                useTrials = useTrials | ismember( agg.targetIdx, acceptableTargs );
            end
            if includeInward
                acceptablePrevTargs = find( prevTargDims == 1 & logical( uniquePrevTargets(:,thisDim) ) );
                fprintf('%i inward previous targets permitted\n', ...
                    numel( acceptablePrevTargs ) );
                useTrials = useTrials | ismember( agg.prevTargetIdx, acceptablePrevTargs );
            end
            useTrialsSuccessful = useTrials &  agg.isSuccessful;
        case {5,6}
            % 2D or 3D
            thisNumDims = 8-iSet;
            setName = sprintf('%i DIMS ONLY TARGETS', thisNumDims );
            fprintf('\n--------------\n%s\n--------------\n', setName )
            
            targDims = sum( logical( uniqueTargets ),2);
            prevTargDims = sum( logical( uniquePrevTargets ),2);
            
            useTrials = false( size( agg.targetIdx ) );
            if includeOutward
                acceptableTargs = find( targDims == thisNumDims );
                fprintf('%i outward targets permitted\n', ...
                    numel( acceptableTargs ) );
                useTrials = useTrials | ismember( agg.targetIdx, acceptableTargs );
            end
            if includeInward
                acceptablePrevTargs = find( prevTargDims == thisNumDims );
                fprintf('%i inward previous targets permitted\n', ...
                    numel( acceptablePrevTargs ) );
                useTrials = useTrials | ismember( agg.prevTargetIdx, acceptablePrevTargs );
            end
            useTrialsSuccessful = useTrials &  agg.isSuccessful;
            
        case 7
            % All Trials
            setName = 'ALL TARGETS';
            fprintf('\n--------------\n%s\n--------------\n', setName )

            useTrials = false( size( agg.targetIdx ) );
            if includeOutward
                targDims = sum( logical( uniqueTargets ),2);
                acceptableTargs = find( targDims > 0 );
                fprintf('%i outward targets permitted\n', ...
                    numel( acceptableTargs ) );
                useTrials = useTrials | ismember( agg.targetIdx, acceptableTargs );
            end
            if includeInward
                prevTargDims = sum( logical( uniquePrevTargets ),2);
                acceptablePrevTargs = find( prevTargDims > 0 );
                fprintf('%i inward previous targets permitted\n', ...
                    numel( acceptablePrevTargs ) );
                useTrials = useTrials | ismember( agg.prevTargetIdx, acceptablePrevTargs );
            end
            useTrialsSuccessful = useTrials &  agg.isSuccessful;
        otherwise
            % nothing
            continue
    end
    fprintf('%i trials\n', nnz( useTrialsSuccessful ) );
    fprintf('Path Efficiency is %.3f\n', mean(  agg.pathEfficiency(useTrialsSuccessful) ) );
    fprintf('Path Efficiency each dimension is: %s\n', mat2str( mean( agg.pathEfficiencyEachDim(useTrialsSuccessful,:), 1 ), 3 ) );
    fprintf('Peak Speed is %.2f cm/s\n', 100000*mean( agg.peakSpeed(useTrialsSuccessful) ) );
    fprintf('Peak Speed each dim is %s cm/s\n', mat2str( 100000.*mean( agg.peakSpeedEachDim(useTrialsSuccessful,:), 1 ), 4) )
    fprintf('TTT is %.3fms\n', mean( agg.TTT(useTrialsSuccessful) ) );
    
    % Record all of these metrics into a cell array so I can do stats
    targetSets.setName{iSet} = setName;
    targetSets.pathEfficiency{iSet} = agg.pathEfficiency(useTrialsSuccessful);
    targetSets.peakSpeed{iSet} = 100000.*agg.peakSpeed(useTrialsSuccessful); % already cm/s
    targetSets.TTT{iSet} = agg.TTT(useTrialsSuccessful);
end

%% Generate some plots about simultaneity
figh = figure;
theseSets =[4,6,5,7]; %1dim, 2dims, 3dims, all together

% TIME TO TARGET
axh_TTT = subplot(3,1,1);
datMat = cell2matIrregular( targetSets.TTT(theseSets) );
stats = MultipointComparisonBarplots( datMat, 'axish', axh_TTT, 'SEM', false, ...
    'conditionNames', targetSets.setName(theseSets), 'bridges', '', 'numericMean', true, 'YLim', YLim_TTT );
ylabel('Acquire Time (ms)');

fprintf('\nTTT\n--------\n')
% do all the comparisons
for i = 1 : numel( theseSets )
    for j = i+1 : numel( theseSets )
        [p,h] = ranksum( targetSets.TTT{theseSets(i)},targetSets.TTT{theseSets(j)} );
        mean_i = mean( targetSets.TTT{theseSets(i)} );
        mean_j = mean( targetSets.TTT{theseSets(j)} );
        fprintf('%s (%.2f) vs %s (%.2f): p = %g (rank-sum)\n', ...
            targetSets.setName{theseSets(i)}, mean_i, targetSets.setName{theseSets(j) }, mean_j, p )
    end
end


% PEAK SPEED
axh_TTT = subplot(3,1,2);
datMat = cell2matIrregular( targetSets.peakSpeed(theseSets) );
stats = MultipointComparisonBarplots( datMat, 'axish', axh_TTT, 'SEM', false, ...
    'conditionNames', targetSets.setName(theseSets), 'bridges', '', 'numericMean', true, 'YLim', YLim_SPEED );
ylabel('Peak Speed (cm/s)');


fprintf('\nPeak Speed\n--------\n')
% do all the comparisons
for i = 1 : numel( theseSets )
    for j = i+1 : numel( theseSets )
        [p,h] = ranksum( targetSets.peakSpeed{theseSets(i)},targetSets.peakSpeed{theseSets(j)} );
        mean_i = mean( targetSets.peakSpeed{theseSets(i)} );
        mean_j = mean( targetSets.peakSpeed{theseSets(j)} );
        fprintf('%s (%.2f) vs %s (%.2f): p = %g (rank-sum)\n', ...
            targetSets.setName{theseSets(i)}, mean_i, targetSets.setName{theseSets(j) }, mean_j, p )
    end
end


% PATH EFFICIENCY
axh_TTT = subplot(3,1,3);
datMat = cell2matIrregular( targetSets.pathEfficiency(theseSets) );
stats = MultipointComparisonBarplots( datMat, 'axish', axh_TTT, 'SEM', false, ...
    'conditionNames', targetSets.setName(theseSets), 'bridges', '', 'numericMean', true );
ylabel('Path Efficiency');

fprintf('\nPath Efficiency\n--------\n')
% do all the comparisons
for i = 1 : numel( theseSets )
    for j = i+1 : numel( theseSets )
        [p,h] = ranksum( targetSets.pathEfficiency{theseSets(i)},targetSets.pathEfficiency{theseSets(j)} );
        mean_i = mean( targetSets.pathEfficiency{theseSets(i)} );
        mean_j = mean( targetSets.pathEfficiency{theseSets(j)} );
        fprintf('%s (%.2f) vs %s (%.2f): p = %g (rank-sum)\n', ...
            targetSets.setName{theseSets(i)}, mean_i, targetSets.setName{theseSets(j) }, mean_j, p )
    end
end


titlestr = sprintf('Independence and Sim %s', datalist );
figh.Name = titlestr;
if ~isdir( figuresPath )
    mkdir( figuresPath )
end
saveas( figh, [figuresPath titlestr '.fig'] );
fprintf('Saved %s\n', [figuresPath titlestr '.fig'])

%% Plot the target set

% load an example block to get workspace bounds from.
participant = experiment(1:2);
streamsPathRoot = ['/net/experiments/' participant '/'];
streamsPath = [streamsPathRoot experiment '/Data/FileLogger/']; 
stream = parseDataDirectoryBlock(sprintf('%s%i', streamsPath, trajectoryPlotBlock ), {'neural'} ); % note excluding neural, which I don't need here
R = onlineR( stream );



radialTargets = uniqueTargets( logical( sum(abs(uniqueTargets), 2) ),: );
figh = figure;
titlestr = 'Target Layout';
figh.Name = titlestr;
figh.Color = 'w';

% ISOMETRIC VIEW
axh(1) = subplot(1,2,1);
axh(1) = SetAxesToNPTLconventions( axh(1) ); % convert this axes into NPTL coordinate conventions
hold on;
workspaceh = Draw3Dworkspace('axh', axh(1), ...
    'workspaceX', R(1).startTrialParams.workspaceX, ...
    'workspaceY', R(1).startTrialParams.workspacey, ... % due to stupid typo..
    'workspaceZ', R(1).startTrialParams.workspaceZ);

vary1 = sum( logical( radialTargets ), 2 ) == 1;
hTargets = scatter3( radialTargets(vary1,1), radialTargets(vary1,2), radialTargets(vary1,3), 8^2, ... 
    'b',  'o', 'filled');   

vary2 = sum( logical( radialTargets ), 2 ) == 2;
hTargets = scatter3( radialTargets(vary2,1), radialTargets(vary2,2), radialTargets(vary2,3), 8^2, ... 
    [0, 1, 1],  'o', 'filled');   

vary3 = sum( logical( radialTargets ), 2 ) == 3;
hTargets = scatter3( radialTargets(vary3,1), radialTargets(vary3,2), radialTargets(vary3,3), 8^2, ... 
    'y',  'o', 'filled');   

% draw axes
lh = line( [R(1).startTrialParams.workspaceX(1) R(1).startTrialParams.workspaceX(2)], [0 0], [0 0], ...
    'Color', 'k', 'LineWidth',  2 );
lh = line( [0 0], [R(1).startTrialParams.workspacey(1) R(1).startTrialParams.workspacey(2)], [0 0], ...
    'Color', 'k', 'LineWidth',  2 );
lh = line( [0 0], [0 0], [R(1).startTrialParams.workspaceZ(1) R(1).startTrialParams.workspaceZ(2)], ...
    'Color', 'k', 'LineWidth',  2 );

% FRONT VIEW
axh(2) = subplot(1,2,2);
axh(2) = SetAxesToNPTLconventions( axh(2) ); % convert this axes into NPTL coordinate conventions
hold on;
workspaceh = Draw3Dworkspace('axh', axh(2), ...
    'workspaceX', R(1).startTrialParams.workspaceX, ...
    'workspaceY', R(1).startTrialParams.workspacey, ... % due to stupid typo..
    'workspaceZ', R(1).startTrialParams.workspaceZ);
axh(2).CameraPosition = [0 0 -0.6];

hTargets = scatter3( radialTargets(vary1,1), radialTargets(vary1,2), radialTargets(vary1,3), 8^2, ... 
    'b',  'o', 'filled');   
hTargets = scatter3( radialTargets(vary2,1), radialTargets(vary2,2), radialTargets(vary2,3), 8^2, ... 
    [0, 1, 1],  'o', 'filled');   
hTargets = scatter3( radialTargets(vary3,1), radialTargets(vary3,2), radialTargets(vary3,3), 8^2, ... 
    'y',  'o', 'filled');   

% draw axes
lh = line( [R(1).startTrialParams.workspaceX(1) R(1).startTrialParams.workspaceX(2)], [0 0], [0 0], ...
    'Color', 'k', 'LineWidth',  2 );
lh = line( [0 0], [R(1).startTrialParams.workspacey(1) R(1).startTrialParams.workspacey(2)], [0 0], ...
    'Color', 'k', 'LineWidth',  2 );
lh = line( [0 0], [0 0], [R(1).startTrialParams.workspaceZ(1) R(1).startTrialParams.workspaceZ(2)], ...
    'Color', 'k', 'LineWidth',  2 );
%Save figure
saveas( figh, [figuresPath titlestr '.fig'] );
fprintf('Saved %s\n', [figuresPath titlestr '.fig'])