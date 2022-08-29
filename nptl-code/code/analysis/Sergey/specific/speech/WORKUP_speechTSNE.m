% Prepares neural features similar to WORKUP_classifySpeech.m and then plots these data in
% 2D using t-SNE. The purpose is to be able to visualize the single-trial high-dimensional
% data and get some intuition about how decodable it may be, and how similar different
% phonmes may be.
%
% Sergey Stavisky, September 23 2017
% Stanford Neural Prosthetics Translational Laboratory
% Updated December 6 2017
%
% Also plots example features used in the tSNE (and decoding).
%
% NOTE: ONLY WORKS IN MATLAB R_2017a or later (tsne.m was added then)!

clear

saveFiguresDir = [FiguresRootNPTL '/speech/tsne/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end

neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = true; % Whether to use PC1 neural alignment to adjust voice onset

%% Select Dataset


%% T5.2017.10.23 Phonemes
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
participant = 't5';
params.acceptWrongResponse = 'true';
params.excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');
params.divideIntoNtimeBins = 10;


% -500 to 500 ms around start of response speech
params.alignEvent = 'handResponseEvent';
params.startEvent = 'handResponseEvent - 0.500';
params.endEvent = 'handResponseEvent + 0.500';

% params.alignEvent = 'votResponseEvent';
% params.startEvent = 'votResponseEvent - 0.500';
% params.endEvent = 'votResponseEvent + 0.500';


%% T5.2017.10.25 Words
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; 
% participant = 't5';
% params.acceptWrongResponse = 'true';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.divideIntoNtimeBins = 10;
% 
% % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% 
% % params.alignEvent = 'votResponseEvent';
% % params.startEvent = 'votResponseEvent - 0.500';
% % params.endEvent = 'votResponseEvent + 0.500';

%% T8.2017.10.18 Words
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; 
% participant = 't8';
% params.acceptWrongResponse = false;
% params.excludeChannels = participantChannelExcludeList( participant );
% params.divideIntoNtimeBins = 10;
% 
% % % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% 
% % params.alignEvent = 'votResponseEvent';
% % params.startEvent = 'votResponseEvent - 0.500';
% % params.endEvent = 'votResponseEvent + 0.500';


%% T8.2017.10.17 Phonemes
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% participant = 't8';
%  % if so, then labels like 'da-ga' (he was cued 'da' but said 'ga') are accepted
% % The RESPONSE label ('ga' in above example) is used as the label for this trial.
% params.acceptWrongResponse = true;
% params.excludeChannels = [];
% 
% params.divideIntoNtimeBins = 10;
% % 
% % % -500 to 500 ms around start of response speech
% params.alignEvent = 'handResponseEvent';
% params.startEvent = 'handResponseEvent - 0.500';
% params.endEvent = 'handResponseEvent + 0.500';
% 
% % params.alignEvent = 'votResponseEvent';
% % params.startEvent = 'votResponseEvent - 0.500';
% % params.endEvent = 'votResponseEvent + 0.500';




%% Feature parameters
% these should be set the same to what I'm decoding with
numArrays = 2;
params.thresholdRMS = -3.5; % spikes happen below this RMS
params.neuralFeature = {'spikesBinned_1ms', 'lfpPow_125to5000_50ms'};
% params.neuralFeature = {'spikesBinned_1ms'};
% params.neuralFeature = {'lfpPow_125to5000_50ms'};



%% tSNE parameters
% params.tsneNumPCAComponents = 500;
params.tsneNumPCAComponents = 0;

% params.tsneStandardize = false; % normalizes (z-score) input data; probably good given different feature types
params.tsneStandardize = true; % normalizes (z-score) input data; probably good given different feature types

% params.tsnePerplexity = 10;
params.tsnePerplexity = 15;
% params.tsnePerplexity = 30; %wdefault


%% Prepare the data features
includeLabels = labelLists( Rfile ); % lookup;
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly





%% Load the data
in = load( Rfile );
R = in.R;
clear('in'); % save memory
%% Annotate the data

% Scan for whether event labels files exist for these blocks. 
% Accept trials with wrong response to cue, if it was one of the included responses
if params.acceptWrongResponse
    numCorrected = 0;
    for iTrial = 1 : numel( R )
        myLabel = R(iTrial).label;
        if strfind( myLabel, '-' ) 
            myResponse = myLabel(strfind( myLabel , '-' )+1:end);
            if ismember( myResponse, includeLabels )
                R(iTrial).label = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end

allLabels = {R.label};
uniqueLabels = includeLabels( ismember( includeLabels, unique( allLabels ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember( allLabels, uniqueLabels ));
fprintf('Analyzing %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end


% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if params.neuralVoiceOffset
    offsetFile = sprintf('%soffsets-%s.mat', neuralVoiceOffsetRoot, datasetName );
    load( offsetFile, 'sOffsets' );
else
    sOffsets = [];
end

if strfind( params.alignEvent, 'vot' )
    fprintf('VOT alignment required, will add those now...\n')
    alignMode = 'VOTdetection';
else
    alignMode = 'handLabels';
end
uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode, 'sOffsets', sOffsets )];
end
R = Rnew; 
clear( 'Rnew' );


%% Add Neural Features  
% (weak version -- it won't generate High Frequency LFP features, as I don't have those
% large files on my laptop. If I want those, create the necessary R structs with createSpeechRwithHLFP.m
for iFeature = 1 : numel( params.neuralFeature )
    if strfind(  params.neuralFeature{iFeature}, 'spikes' )
        % THRESHOLD CROSSING FEATURE
        % apply RMS thresholding if needed
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
               
                R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
            end
        end
        % Will generate crossings-derived featurte
        R = AddFeature( R, params.neuralFeature{iFeature} );
    elseif strfind( params.neuralFeature{iFeature}, 'lfp' )
        % LFP Feature
        bandInfo = bandNameParse( params.neuralFeature{iFeature} );

        % if using very high frequency, need to use the 'raw' different source
        if bandInfo.hi > 500 || params.CARlfp{iFeature}    
            if isfield( R,  params.neuralFeature{iFeature} )
                % all good, this feature already exists
            else
                error( 'this raw-derived feature doesn''t exist in R struct but should. Specify an Rfile that already has it')
            end
        else            
            if ~isfield( R, 'lfp')
                R  = AddCombinedFeature( R, {'lfp1', 'lfp2'}, 'lfp', 'deleteSources', true );
            end
            R = AddFeature( R, params.neuralFeature{iFeature}, 'sourceSignal', 'lfp' );
        end
    else

    end
    
    % Channel exclusion
    if ~isempty( params.excludeChannels )
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


% Reduce memory usage
R = rmfield( R, 'lfp1' );
R = rmfield( R, 'lfp2' );

%% Bin the features to create the high-D feature vector that would have been used for classification
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
    'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
jenga = TrimToSolidJenga( jenga );
divisionInds = indexEvenSpaced( jenga.numSamples, params.divideIntoNtimeBins+1 );
if numel( divisionInds ) == 2
    divisionInds(end) = divisionInds(end)+1; % no samples left behind if just 1 bin (edge splitting issues)
end
datMat = [];
datMatWithTime = []; % used for plotting
for iBin = 1 : params.divideIntoNtimeBins
    thisBin = jenga.dat(:,divisionInds(iBin):divisionInds(iBin+1)-1,:);
    % sum across time. Multiple time bins just become additional features for each trial, same
    % as added channels or neural features
    thisBin = squeeze( mean( thisBin, 2 ) ); % in classify it's sum, but here this keeps Gamma power from getting crazy
    datMat = cat(2, datMat, thisBin);
    datMatWithTime = cat( 3, datMatWithTime, thisBin ); % trials x feature x time 
end



%% t-SNE 
rng(1)
labels = {R.label}';
options.MaxIter = 10000;
options.OutputFcn = [];
options.TolFun = 1e-10;
[Y, loss] = tsne( datMat, ...
    'NumPCAComponents', params.tsneNumPCAComponents, 'Standardize', params.tsneStandardize, ...
    'verbose', 1, 'Options', options, 'Algorithm', 'exact', 'Distance', 'euclidean', ...
    'Perplexity', params.tsnePerplexity );
fprintf('KL Loss = %f\n', loss);

%% Plot tSNE 
figh = figure;
axh = axes;
colors = cell2mat( cellfun( @speechColors, labels, 'UniformOut', false ) );
hscat = gscatter( Y(:,1), Y(:,2), labels, colors );

titlestr = pathToLastFilesep( Rfile, 1 );
titlestr = regexprep( titlestr, '.mat', '' );
figh.Name = titlestr;
title( titlestr, 'Interpreter', 'none' );
axis equal;
axis off;
saveas( figh, [saveFiguresDir titlestr '.fig'])
saveas( figh, [saveFiguresDir titlestr '.eps'], 'epsc' )
fprintf( 'Saved %s\n', [saveFiguresDir titlestr '.fig'] )

%% 3D tSNE (not dramatically more useful)
% [Y, loss] = tsne( datMat, ...
%     'NumPCAComponents', params.tsneNumPCAComponents, 'Standardize', params.tsneStandardize, ...
%     'verbose', 1, 'Options', options, 'Algorithm', 'exact', 'Distance', 'euclidean', ...
%     'Perplexity', params.tsnePerplexity, 'NumDimensions',3 );
% v = double(categorical(labels));
% uniqueLabels = unique( labels );
% colorsUnique = parula( numel( unique( v ) ) );
% scatterColors = cell2mat( arrayfun( @(x) colorsUnique(x,:), v, 'UniformOutput', false ) );
% 
% figh_3d = figure;
% hscat = scatter3( Y(:,1), Y(:,2), Y(:,3), 100, scatterColors, 'filled' );
% axh = hscat.Parent;
% MakeDumbLegend( uniqueLabels, 'Color', colorsUnique )


%% Prep individual trial features for plotting
% z score each feature to across all trials 
numFeatures = size( datMatWithTime, 2 );
featureMean = nan( numFeatures, 1 );
featureSTD = nan( numFeatures, 1 );
for iFeature = 1 : size( datMatWithTime, 2 )
   % feature mean across all trials, times
    featureMean(iFeature) = mean( reshape( datMatWithTime(:,iFeature,: ), [], 1 ) );
    featureSTD(iFeature) = std( reshape( datMatWithTime(:,iFeature,: ), [], 1 ) );
end

%% Reorder so same electrode appears together
% electrodeOrdered = reshape( [1 : numFeatures], [], numel( params.componentNeuralFeatures ) );
% electrodeOrdered = reshape( electrodeOrdered', 1, [] );
% datMatWithTime = datMatWithTime(:,electrodeOrdered,:);
% featureMean = featureMean(electrodeOrdered);
% featureSTD = featureSTD(electrodeOrdered);

%%



%% Prepare to plot
% trial 1, 16, 29 is 'sh'
% trial 6, 28, 104 is 'k'



% plotTrials = [1 16 29 6 28 104];
plotTrials = [28 29];
% normalize these trials' features
for iTrial = 1 : numel( plotTrials )
    myTrialInd = plotTrials(iTrial);
    myFeatures{iTrial} = squeeze( datMatWithTime(myTrialInd, :, : ) );
    % Z score 
    for iFeature = 1 : numFeatures
        myFeatures{iTrial}(iFeature,:) = (myFeatures{iTrial}(iFeature,:) - featureMean(iFeature))./ featureSTD(iFeature);
    end
end

% rank by differnece between first two example trials
% I average across the 10 time bins, so different temporal profiles may not show as well
featureTrialDiff = nan( numFeatures, 1 ); 
for iFeature = 1 : numFeatures 
    d = myFeatures{2}(iFeature,:) - myFeatures{1}(iFeature,:);
    [~, maxInd] = max( abs( d ) );
%     featureTrialDiff(iFeature) = d(maxInd); % biggest difference across any bvin
    featureTrialDiff(iFeature) = mean( d ); % mean across time
end
[~, plotOrder] = sort( featureTrialDiff, 'descend' );

%% Do the actual plotting
figh_examples = figure;
for iTrial = 1 : numel( plotTrials )
    myTrialInd = plotTrials(iTrial);
    
    axhEx(iTrial) = subplot( numel( plotTrials ), 1, iTrial );
    imh = imagesc( myFeatures{iTrial}(plotOrder,:), [-3 3] );
    axhEx(iTrial).TickLength = [0 0];
    colorbar;
    ylabel( sprintf('Trial %i %s', myTrialInd, labels{myTrialInd} ) );
    
    % label it on the tSNE plot
    th = text( axh, Y(myTrialInd,1), Y(myTrialInd,2), sprintf('%i', myTrialInd) );
end