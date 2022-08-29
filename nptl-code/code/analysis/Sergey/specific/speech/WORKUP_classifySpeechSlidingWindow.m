% Performs a leave-one-trial-out classification on the data.
%
% This script variant compares a smaller set of labels, and slides the analysis window,
% generating plots of the resulting classifcation accuracy as a function of window end. 
% This is used to show that certain sounds/words with similar starts but different ends
% (or vice versa) have different confusion time courses.
%
% Sergey Stavisky, September 26 2017
clear
rng(1); % consistent random seed


% R struct has already been prepared by WORKUP_prepareSpeechBlocks.m, which built off of
% WORKUP_labelSpeechExptData.m
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-words.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-phonemes.mat';

saveResultsTo = [ResultsRoot '/NPTL/speech/slidingWindows/'];
if ~isdir( saveResultsTo )
    mkdir( saveResultsTo );
end

%% Analysis Parameters
params.thresholdRMS = -3.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinned_1ms'; % spike counts binned every 1ms. Makes for easier dividing into features later




% Will try anova when taking mean rate across this whole epoch.
% note that start event should be pushed forward to account for the binning window
% 0 to 500 ms after cue speech
% params.alignEvent = 'cueEvent';
% params.startEvent = 'cueEvent';
% params.endEvent = 'cueEvent + 0.500';
% params.divideIntoNtimeBins = 10;


% -500 to 500 ms around start of response speech
% Will run a classification test using just these labels. Multiple comparisons can be run
% and plots for each will be shown.
% params.compareLabels = {...
%     {'push', 'pull'}...
%     {'push', 'arm'};
%     };



% Make the comparison across all permutations
% uniqueLabels = {'ba', 'ga', 'da', 'oo', 'sh'};
uniqueLabels = {'arm', 'tree', 'beach' 'push', 'pull'};

params.compareLabels = {};
for i = 1 : numel( uniqueLabels ) - 1
    for j = i + 1 : numel( uniqueLabels )
        params.compareLabels{end+1} = {uniqueLabels{i}, uniqueLabels{j}};
    end
end


% params.compareLabels = {...
%     {'ba', 'ga'};
%     {'ba', 'da'};
%     {'ba', 'oo'};
%     {'ba', 'sh'};
%     };

% params.compareLabels = {...
%     {'ba', 'ga'};
%     {'ba', 'da'};
%     {'ba', 'oo'};
%     {'ba', 'sh'};
%     };
params.divideIntoNtimeBins = 1;

params.alignEvent = 'speechEvent';
% Sliding window parameters. These are all relative to align event above,
% and all are in milliseconds.
params.slidingWindowStart = -700;
params.slidingWindowWidth = 200;
params.slidingWindowStep = 5;
params.slidingWindowEnd = 1500;




% how many time bins to divide the neural data into
% More potentially helps discriminate based on time course, but causes feature
% counts to increase.
% SVM parameters
params.outlierFraction = 0.05; 

params.numShuffles = 21; % would allow for at least p <  0.05
% params.numShuffles = 0;

% PCA across electrodes, on trial-averaged data
params.numPCs = [];


% These channels are excised. Numbers > 96 are on array2
burstChans = [67, 68, 69, 73, 77, 78, 82];
smallBurstChans = [2, 46. 66, 76, 83, 85, 86, 94, 95, 96]; % just to be super careful

% params.excludeChannels = []; % keep everything
params.excludeChannels = sort( [burstChans, smallBurstChans ] );

myFilename = [saveResultsTo, 'slidingResults_ ', regexprep( pathToLastFilesep( Rfile, 1 ), '.mat', '' ) '_' structToFilename( params ) ];


%% Does it already exist?
try 
    in = load( myFilename );
    error('Results %s appear to already exist. Delete if you want to run this analysis to overrwite\n', myFilename )
catch
    
end



%% Load the data
in = load( Rfile );
R = in.R;
% no support for > 2 arrays since that won't happen
if isfield( R, 'minAcausSpikeBand2' )     
    numArrays = 2;
else
    numArrays = 1;
end


% Scan for whether event labels files exist for these blocks. 
allLabels = arrayfun( @(x) x.label, R, 'UniformOutput', false );
uniqueLabels = unique( allLabels );
blocksPresent = unique( [R.blockNumber] );

fprintf('Loaded %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
results.uniqueLabels = uniqueLabels;
results.blocksPresent = blocksPresent;
results.params = params;




%% apply RMS thresholding
fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
for iTrial = 1 : numel( R )
    for iArray = 1 : numArrays
        switch iArray
            case 1
                rasterField = 'spikeRaster';
            otherwise
                rasterField = sprintf( 'spikeRaster%i', iArray );
        end
        ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
        myACB = R(iTrial).(ACBfield);
        RMSfield = sprintf( 'RMSarray%i', iArray );
        
        % Hack until I fix this in the data loading
        if size( myACB, 2 ) > size( R(iTrial).(rasterField),2 )
            myACB(:,end) = [];
        elseif size( myACB, 2 ) < size( R(iTrial).(rasterField),2 )
            myACB(:,end+1)=inf;
        end
        
        R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
    end
end




%% Organize data
% alignment cues for silent trials
for iTrial = 1 : numel( R )
    if strcmp( R(iTrial).label, 'silence' )
        R(iTrial).cueEvent = R(iTrial).timeCueStart + 500; % not very precise, this should be improved later
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart+ 500;
    elseif strfind( Rfile, 'thought' )
        % this is for the 'thoughtSpeak' experiment in which there's no overt sound during
        % response. Therefore, the timeSpeechStart annotation marker is aligned to start of second
        % response chime. For now I'll just advance by 500 ms to when the participant may be
        % responding.
        R(iTrial).cueEvent = R(iTrial).timeCueStart;
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart + 500;
    else
        R(iTrial).cueEvent = R(iTrial).timeCueStart;
        R(iTrial).speechEvent = R(iTrial).timeSpeechStart;
    end  
end

% Add neural feature
R = AddFeature( R, params.neuralFeature );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end



%% Do the loop across comparisons and windows

% Calculate what all the windows will be
windowEnds = params.slidingWindowStart + params.slidingWindowWidth : params.slidingWindowStep : params.slidingWindowEnd;
windowStarts = windowEnds - params.slidingWindowWidth;

% Loop across comparions
classifyResults = {};
for iComparison = 1 : numel( params.compareLabels )
    myLabels = params.compareLabels{iComparison};
    myName = [];
    for i = 1 : numel( myLabels )
        if i > 1
            myName = [myName, 'vs. '];
        end
        myName = [myName, myLabels{i} ' '];
    end
    comparisonNames{iComparison} = myName;
    
    keepTrials = ismember( allLabels, myLabels );

    fprintf('Comparing %s (%i Trials)\n', comparisonNames{iComparison}, nnz( keepTrials ) );
    
    myParams = params;
    fprintf('Will classify in %i different sliding windows...     ', numel( windowEnds ) );
    for iWindow = 1 : numel( windowEnds )
        % Loop across time windows
        fprintf('\b\b\b\b%3i', iWindow)
        % Construct the sliding window string
        myParams.startEvent = sprintf('%s %+.3f', params.alignEvent, windowStarts(iWindow)/1000 );
        myParams.endEvent = sprintf('%s %+.3f', params.alignEvent, windowEnds(iWindow)/1000 );

        % Do the leave-one-out SVM classification
        classifyResults{iComparison,iWindow} = classifySpeech( R(keepTrials), myParams, 'verbose', false );

    end
end

save( myFilename, 'classifyResults', 'params', 'windowStarts', 'windowEnds', 'Rfile' );
fprintf('Saved results to %s', myFilename );



%% Plot
successRatesAllComparisons = 100.*cellfun( @(x) x.classificationSuccessRate, classifyResults); % in %
figh = figure; figh.Color = 'w';
axh = axes; hold on;
figh.Name = sprintf('Multiple comparisons sliding %ims window', params.slidingWindowWidth);
title( sprintf('Sliding %ims Window',params.slidingWindowWidth), 'FontSize', 8 );
for iComparison = 1 :  numel( params.compareLabels )
    ploth(iComparison) = plot( windowEnds, successRatesAllComparisons(iComparison,:) );
end
ylim([0 100]);
xlabel( sprintf( 'Window End Relative to %s (ms)', params.alignEvent ) );
legh = legend( comparisonNames );
ylabel('Classification Accuracy (%)')