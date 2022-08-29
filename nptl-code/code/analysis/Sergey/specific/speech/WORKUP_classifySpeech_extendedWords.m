% Performs a leave-one-trial-each-class-out classification on the 
% extended words data.
% NOTE: No HLFP is available yet because the .HLFP that comes from the R struct is emptuy
%
% Sergey Stavisky, April 15 2019
clear
rng(1); % consistent random seed


%% Analysis results saving
% Since some of these analysis runs take a long time, I save the results in
% a mat file whose name is based on the R file and a hash of the params
% (which isn't interpretable just by reading). Thus, if an analysis has
% already been run (based on having a shared params), it'll warn the user that 
% this results file already exists and that therefore this run is probably
% unnecessary (it'll run anyway and then overwrite at the end if it
% finished -- user can cancel midway to avoid this). The idea is that
% downstream figure making / metananalysis scripts can just point to a
% bunch of these results files, load them, and plot them.
saveResultsRoot = [ResultsRootNPTL '/speech/classification/'];


%% t5.2019.01.23 Slutzky Extended Words List
% already prepared by prepareExtendedWordsRStruct
datasetName = 't5.2019.01.23_extendedWords';
blockFiles = {...
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B1.mat'; % set 1
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B2.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B3.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B4.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B5.mat'; % set 2
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B6.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B7.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B8.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B9.mat';  % set 3
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B10.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B11.mat'; 
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B12.mat'; 
};


%% 
participant = 't5';
params.acceptWrongResponse = 'false';
params.excludeChannels = [];


params.divideIntoNtimeBins = 10;

% -500 to 500 ms around start of response speech
params.alignEvent = 'timeSpeech';
params.startEvent = 'timeSpeech - 0.500';
params.endEvent = 'timeSpeech + 0.500';



%% Analysis Parameters
% params.thresholdRMS = -4.5; % spikes happen below this RMS
params.thresholdRMS = -3.5; % spikes happen below this RMS

% Note: put even singular features in a cell array to simplify code reuse
% for combinations of features.
params.neuralFeature = {'spikesBinned_1ms'}; params.CARlfp = {false}; 

% params.neuralFeature = {'spikesBinned_1ms', 'lfpPow_125to5000_50ms'}; params.CARlfp = {false, false}; 

params.CARafterChannelRemoval = true; % if true, will remove channels BEFORE doing CAR

% SVM parameters
params.outlierFraction = 0.05; 

% Random selection folds
% Picks a random subset of trials as test trials and the rest as train
% trials. This is repeated a specified number of times. This provides a
% distribution of performance results and gives some sense of the
% how consistent a given performance is across variations in training and
% testing data.
% note: it never does pick-with-replacement, as otherwise a duplicate of the
% test trial could appear in the training trial, which could unduly inflate
% performance.
% params
params.trialsEachClassEachFold = 0; % if 0, does leave-one-out testing. Otherwise, has this many 
                                    % test trials from each class per fold.
                                    % DO THIS FOR MAIN PERFORMANCE AND
                                    % STATS VS CHANCE
% params.trialsEachClassEachFold = 1; % if 0, does leave-one-out testing. Otherwise, has this many 
%                                     % test trials from each class per
%                                     fold. DO THIS FOR FEATURE COMPARISON
params.numResamples = 1001; % irrelevant if above is empty, as it then just goes through every trial (this is the standard mode)


% Shuffle labels (to compute chance levels)
% params.numShuffles = 101;
params.numShuffles = 3;
% params.numShuffles = 0;





%% Prepare filename from these parameters and warn if it already exists.

resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '.mat'];
try 
    in = load( resultsFilename );
    classifyResult = in.classifyResult;
    beep;
    fprintf( 'This analysis appears to have already been run and was loaded from %s\n', resultsFilename )
    fprintf( 'You can abort now, or let it run and overwrite\n');
    keyboard
catch
    % (empty)
end
    


%% Load the data

R = [];
for i = 1 : numel( blockFiles )
    fprintf('(%i/%i) Loading %s', i, numel( blockFiles ), blockFiles{i} );
    
    if i > 8
        thisSet = 3;
    elseif i > 4
        thisSet = 2;
    else
        thisSet = 1;
    end
    
    
    in = load( blockFiles{i} );
    fprintf(' %i trials\n', numel( in.R ) );
    
    RMS{i} = channelRMS( in.R ); % compute rms of the block
    in.R = RastersFromMinAcausSpikeBand( in.R, params.thresholdRMS .*RMS{i} );
    
    in.R = RastersFromMinAcausSpikeBand( in.R, -4.5 .*RMS{i}, 'newFieldName', 'spikeRaster45' );
    
    % to save memory, just copy over key fields
    
    tmpR = struct();
    for i2 = 1 : numel( in.R )
        tmpR(i2).clock = in.R(i2).clock;
%         tmpR(i2).HLFP = in.R(i2).HLFP;
        tmpR(i2).spikeRaster = in.R(i2).spikeRaster;
        tmpR(i2).spikeRaster45 = in.R(i2).spikeRaster45;


        tmpR(i2).startTrialParams = in.R(i2).startTrialParams;
        tmpR(i2).trialStart = in.R(i2).trialStart;
        
        tmpR(i2).goCue = in.R(i2).goCue;
        tmpR(i2).holdCue = in.R(i2).holdCue;
        tmpR(i2).returnCue = in.R(i2).returnCue;
        tmpR(i2).label = in.R(i2).speechLabel; % use name consistent with old code
        tmpR(i2).timeCue = in.R(i2).timeCue;
        tmpR(i2).timeSpeech = in.R(i2).timeSpeech;
        tmpR(i2).set = thisSet;
    end
    clear( 'in' );
    R = [R,tmpR];
end

% There's a trial with no label; remove it
emptyInd = find( arrayfun(@(x) isempty( x.label ), R ) );
fprintf('Removing %i trial for having no speechLabel\n', numel( emptyInd ) );
R(emptyInd) = [];

fprintf('Total %i trials left\n', numel( R ) );

numArrays = 2;
%% Annotate the data


allLabels = {R.label};
uniqueLabels = unique( allLabels );
fprintf('%i unique labels\n', numel( uniqueLabels ) );

% report trial counts for each condition
% for iLabel = 1 : numel( uniqueLabels )
%     fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.speechLabel, uniqueLabels{iLabel} ), R ) ) )
% end
results.uniqueLabels = uniqueLabels;
results.params = params;


%% Remove low firing rate channels (using -4.5 RMS)
allX = [R.spikeRaster45];
alltimeFR = sum( allX, 2 )./size( allX, 2 );
alltimeFR = alltimeFR .* 1000; % Hz
lowFRchans = find( alltimeFR < 1 );
fprintf('\n%i channels have FR < 1 Hz at -4.5 RMS, will be removed\n', numel( lowFRchans ))
params.excludeChannels = lowFRchans;

%% Add Neural Features  

for iFeature = 1 : numel( params.neuralFeature )
    didExcludeChannels = false;
    
    if strfind( params.neuralFeature{iFeature}, 'spikes' )
        R = AddFeature( R, params.neuralFeature{iFeature} );

    elseif strfind( params.neuralFeature{iFeature}, 'lfp' ) 
        if isfield( R, params.neuralFeature{iFeature} )
            % this logic here because I have R structs with HLFP already in it
            fprintf('Field %s already exists (pre-generated?), will use that and just remove channels\n', params.neuralFeature{iFeature} )
            if ~isempty( params.excludeChannels ) && ~didExcludeChannels
                fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
                R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature{iFeature} );
            end
            continue
        end
        bandInfo = bandNameParse( params.neuralFeature{iFeature} );

        
        % if using very high frequency, need to use the 'raw' different source
        if bandInfo.hi >= 500 || params.CARlfp{iFeature}    
            if params.CARlfp{iFeature}
                keyboard % TODO: Should happen on a temporary raw so that I can have other features that DONT do this
                for iArray = 1 : numArrays
                    myfield = sprintf('raw%i', iArray );
                    if params.CARafterChannelRemoval
                        myExcludeChannels = params.excludeChannels([params.excludeChannels >= ((iArray-1)*96 +1)] & [params.excludeChannels < ((iArray)*96 +1)]);
                        myExcludeChannels = myExcludeChannels - 96*(iArray-1); % since operating within this one array
                        R = RemoveChannelsFromR( R, myExcludeChannels, 'sourceFeature', myfield ); % will be redundant if CARlfp and params.CARafterChannelRemoval happened
                        didExcludeChannels = true;
                        fprintf('Performing CAR array %i after removing channels %s\n', iArray, mat2str( myExcludeChannels ) )

                    else
                        fprintf('Performing CAR array %i ...\n', iArray)
                    end
                    
                    for iTrial = 1 : numel( R )
                        R(iTrial).(myfield).dat = R(iTrial).(myfield).dat - int16( repmat( mean( R(iTrial).(myfield).dat, 1 ), size( R(iTrial).(myfield).dat, 1 ), 1 ) );
                    end                    
                end
            end
            
            if ~isfield( R, 'raw')
                R  = AddCombinedFeature( R, {'raw1', 'raw2'}, 'raw', 'deleteSources', true );
            end
            R = AddFeature( R, params.neuralFeature{iFeature}, 'sourceSignal', 'raw' );                             
        else            
            if ~isfield( R, 'lfp')
                R  = AddCombinedFeature( R, {'lfp1', 'lfp2'}, 'lfp', 'deleteSources', true );
            end
            R = AddFeature( R, params.neuralFeature{iFeature}, 'sourceSignal', 'lfp' );
        end
    end
    
    if ~isempty( params.excludeChannels ) && ~didExcludeChannels
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature{iFeature} );
    end
    

end

% Create combo feature if so specified.
if numel( params.neuralFeature ) > 1
     R  = AddCombinedFeature( R, params.neuralFeature, 'comboFeature', 'deleteSources', false );
     params.componentNeuralFeatures = params.neuralFeature;
     fprintf('Created combination feature from {%s}\n', CellsWithStringsToOneString( params.componentNeuralFeatures  ) );
     params.neuralFeature = 'comboFeature'; % rename so downstream code still operates on this
else
    % unpack it so feature name isn't in a cell array
    params.neuralFeature =  params.neuralFeature{1};
end


%% Do the leave-one-out SVM classification

% for now just use middle as test one fold
testInds = [R.set] == 2;

tic
fprintf('Starting classification...\n')
params.distanceType = 'euclidean';
% params.distanceType = 'cosine';
classifyResult = classifySpeech_KNN( R, testInds, params, 'Distance', params.distanceType, ...
    'verbose', true );
toc

% Report results

% LEAVE-ONE-OUT ANALYSIS
fprintf('Classification Accuracy %s = %.4f%%\n', datasetName, 100*classifyResult.classificationSuccessRate );
fprintf('Chance is %.4f%%\n', 100*(1 / numel( classifyResult.uniqueLabelsStr )) )
% if params.numShuffles > 0
%     betterThanShuffles = nnz( classifyResult.classificationSuccessRate > classifyResult.classificationSuccessRate_shuffled );
%     classifyResult.minShuffle = 100 * min( classifyResult.classificationSuccessRate_shuffled );
%     classifyResult.maxShuffle = 100 * max( classifyResult.classificationSuccessRate_shuffled );
%     classifyResult.meanShuffle = 100 * mean( classifyResult.classificationSuccessRate_shuffled );
%     fprintf('This is better than %i/%i shuffles (min=%.1f, mean=%.1f, max=%.1f%%)\n', ...
%         betterThanShuffles, numel( classifyResult.classificationSuccessRate_shuffled ), classifyResult.minShuffle, ...
%         classifyResult.meanShuffle, classifyResult.maxShuffle );
%     for iLabel = 1 : numel( classifyResult.confuseMatLabels )
%         fprintf('  %s: p=%g\n', ...
%             classifyResult.confuseMatLabels{iLabel}, classifyResult.conufeMat_pValueVersusShuffle(iLabel,iLabel) )
%     end
% end


%% Plot Confusion Matrix

% for now just for leave-one-out mode
% re-order based on specified at top order
uniqueLabels = classifyResult.uniqueLabelsStr;
newOrder = cellfun( @(x) find( strcmp( classifyResult.confuseMatLabels, x) ), uniqueLabels );
for row = 1 : numel( uniqueLabels )
    for col = 1 : numel( uniqueLabels )
        orderedConfuseMat(row,col) = classifyResult.confuseMat(newOrder(row), newOrder(col));
    end
end
% Normalize to 100% is number of true labels
orderedConfuseMat = 100*(orderedConfuseMat./ repmat( sum( orderedConfuseMat, 2 ), 1, numel( uniqueLabels ) ));

figh = figure;
figh.Color = 'w';
titlestr = sprintf( '%s confusion matrix', datasetName );
figh.Name = titlestr;
axh = axes;
imagesc( orderedConfuseMat, [0 100] );

axh.TickLength = [0 0];
axh.XTickLabel = classifyResult.confuseMatLabels(newOrder);
axh.YTickLabel = classifyResult.confuseMatLabels(newOrder);
xlabel('Predicted Word');
ylabel('True Word');
title( sprintf('%s to %s', params.startEvent, params.endEvent ) )
cbarh = colorbar;
cbarh.TickDirection = 'out';
ylabel(cbarh, '% of true labels');
colormap('gray')
axis square

%% Save the results
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end
save( resultsFilename, 'classifyResult', 'params' )
fprintf('Saved results to %s\n%s\n', ...
    pathToLastFilesep( resultsFilename ), pathToLastFilesep( resultsFilename, 1 ) );

if isfield( params, 'componentNeuralFeatures' )
        fprintf('%s\n', CellsWithStringsToOneString( params.componentNeuralFeatures ) )
else
    fprintf('%s\n', params.neuralFeature)
end