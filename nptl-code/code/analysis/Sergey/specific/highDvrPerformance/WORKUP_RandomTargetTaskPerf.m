% Does some basic kinematic workups of recently collected 4 and 5D Random
% Target Task.
%
% Sergey Stavisky April 2017


%% Data to analyze
clear
RANDOM_TARGET_TASK_CONDITION = 7; % lookup in e.g. datasets_4D
%%
datalist = 't5_4_0D';
datasetFunction = @datasets_4D;
params.resultsPath = '/net/derivative/user/sstavisk/Results/fourD/randomTarget/'; % processed data goes here 
figuresPath = ['/net/derivative/user/sstavisk/Figures/fourD/randomTarget/' datalist '/' ];

% datalist = 't5_4_1D';
% datasetFunction = @datasets_4D;
% params.resultsPath = '/net/derivative/user/sstavisk/Results/fourD/randomTarget/'; % processed data goes here 
% figuresPath = ['/net/derivative/user/sstavisk/Figures/fourD/randomTarget/' datalist '/' ];


%%
% datalist = 't5_5_1D_earlySpherical';
% datasetFunction = @datasets_5D;
% params.resultsPath = '/net/derivative/user/sstavisk/Results/fiveDspherical/randomTarget/'; % processed data goes here 
% figuresPath = ['/net/derivative/user/sstavisk/Figures/fiveDspherical/randomTarget/' datalist '/' ];

%%
% datalist = 't5_5_0D_earlySpherical';
% datasetFunction = @datasets_5D;
% params.resultsPath = '/net/derivative/user/sstavisk/Results/fiveDspherical/randomTarget/'; % processed data goes here 
% figuresPath = ['/net/derivative/user/sstavisk/Figures/fiveDspherical/randomTarget/' datalist '/' ];

%% Aggregate analysis parameters - will not force regenerate results 



%% Generate the single-dataset results

datasets = datasetFunction( datalist );
fprintf('=======================\n   %s\n=========================\n', datalist)

% Go through each dataset and load or generate its results
if ~isdir( params.resultsPath )
    mkdir( params.resultsPath );
end

% Remove datasets that don't have Random Target Task
removeDS = false( numel( datasets, 1 ) );
for iDataset = 1 : numel( datasets )  
    [~, condition] = datasetFunction( datasets{iDataset} );
    if ~any( condition.task == RANDOM_TARGET_TASK_CONDITION )
        removeDS(iDataset) = true;
        fprintf( 'Dataset %s has no Random Target Task conditions. Removing.\n', datasets{iDataset}  )
    end
end
datasets(removeDS) = [];

results = {}; % will fill these in for each dataset
for iDataset = 1 : numel( datasets )  
    fprintf('Dataset %i/%i: %s...', iDataset, numel( datasets ), datasets{iDataset} );

    %% RUN ANALYSIS FOR BOTH DECODER NULL & POTENT
    resultsFilename = MakeValidFilename([params.resultsPath  datasets{iDataset} '_' structToFilename( params, 'forceHash', true ) ]);
    try
        loaded = load( resultsFilename );
        myres = loaded.myres;
        results{iDataset} = myres; % unpacking anoyance
        fprintf(' LOADED\n')
    catch
        fprintf(' ready result not found. Analyzing...\n');
        myres =  randomTargetTaskKinematicsOneDataset( datasets{iDataset}, params, ...
            'datasetFunction', datasetFunction);
        fprintf('     saving %s...\n', resultsFilename );
        save( resultsFilename, 'myres' );
        results{iDataset} = myres; % unpacking anoyance
        fprintf(' OK\n')
    end
end
Nsessions = numel( results );

%% Get things I'm interested in from all the trials



agg.numSuccess = 0;
agg.numFailure = 0;
agg.blockDuration = 0;
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
    
    agg.peakSpeed = [agg.peakSpeed; results{iDataset}.peakSpeed];
    agg.peakSpeedEachDim = [agg.peakSpeedEachDim; results{iDataset}.peakSpeedEachDim];
    agg.TTT = [agg.TTT; results{iDataset}.wholeDatasetStats.TTT];
    agg.dialIn = [agg.dialIn; results{iDataset}.wholeDatasetStats.dialIn];
   
    agg.pathEfficiency = [agg.pathEfficiency; results{iDataset}.wholeDatasetStats.pathEfficiency];
    agg.pathEfficiencyEachDim = [agg.pathEfficiencyEachDim; results{iDataset}.wholeDatasetStats.pathEfficiencyEachDim];

    agg.isSuccessful = [agg.isSuccessful; results{iDataset}.isSuccessful'];  
    agg.cuedDistanceToTarget = [agg.cuedDistanceToTarget; results{iDataset}.wholeDatasetStats.cuedDistanceToTarget'];
    agg.targetDiameter = [agg.targetDiameter; results{iDataset}.wholeDatasetStats.targetDiameter];
 
    fprintf('Dataset %i/%i (%s):,%i trials, %.3f succ/min, PE = %.4f\n',  ...
        iDataset, Nsessions, datasets{iDataset}, results{iDataset}.wholeDatasetStats.numTrials, ...
        results{iDataset}.wholeDatasetStats.successPerMinute, ...
        nanmean( results{iDataset}.wholeDatasetStats.pathEfficiency ) );
    
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
fprintf('Unique target diameters were: %s\n', mat2str( unique( agg.targetDiameter ), 4 ) );



%% Some aggregate statistics across these blocks

fprintf('\nSuccess rate over %i total trials (%.2f minutes) is %.2f%%\n', ...
    agg.numSuccess+agg.numFailure, agg.blockDuration /60,  100*agg.numSuccess/(agg.numSuccess+agg.numFailure) );
fprintf('%.2f targets per minute\n', agg.numSuccess/(agg.blockDuration /60) );
fprintf('Mean TTT is %.1fms. Mean Dial-in time is %.1fms.\n', ...
    nanmean( agg.TTT ), nanmean( agg.dialIn ) );
fprintf('Path Efficiency is %.3f\n', nanmean(  agg.pathEfficiency ) );
