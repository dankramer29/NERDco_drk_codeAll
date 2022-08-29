% Generates PSTHs of specified example electrodes, as well as plotting a difference from
% baseline over time, 
%
% Doesn't do anova for tuning, that's now broken out in a different function for clarity.
% 
% Based on WORKUP_speechPSTHs.m
% Updated: February 14, 2019
% UPDATED: May 2019 with better speech modulation metric
% Sergey Stavisky, December 14 2017
%
clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/psths/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
% saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated



%% Dataset specification


%% t5.2018.12.17 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';

% Sanity check the speaking DURING BCI that was constructed like a stand-alone speech R
% struct
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-wordsDuringBCI.mat'; 

% params.excludeChannels = [1:96];
% params.excludeChannels = [97:192];

params.excludeChannels = [];

% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
params.acceptWrongResponse = false;

% These are most modulating for beet for standalone speaking
plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
    'chan_1.33', 'chan_2.3', 'chan_2.90'};
% plotChannels = {'chan_1.9'}; % plot just 1 to speed things up



%% t5.2018.12.12 Words
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% % params.excludeChannels = [1:96];
% % params.excludeChannels = [97:192];
% 
% params.excludeChannels = [];
% 
% % params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = false;
% 
% % plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
% %     'chan_2.7', 'chan_1.17', 'chan_2.66'};
% plotChannels = {'chan_1.9'}; % plot just 1 to speed things up

%%
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_noRaw', ''); %otherwise names get ugly


%% Analysis Parameters
% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;
% sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (


% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% Time epochs to plot. There can be be multiple, in a cell array, and it'll plot these as
% subplots side by side.


%---------------------------------------------------
% speak go and VOT (Figure 1)
% Align to speak go cue.
params.alignEvent{1} = 'handPreResponseBeep';
params.startEvent{1} = 'handPreResponseBeep - 0.2';
params.endEvent{1} = 'handPreResponseBeep + 0.5';

% When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{2} = 'handResponseEvent';
% params.startEvent{2} = 'handResponseEvent - 1.0';
% params.endEvent{2} = 'handResponseEvent + 1.0';
params.alignEvent{2} = 'handResponseEvent';
params.startEvent{2} = 'handResponseEvent - 1.75';
params.endEvent{2} = 'handResponseEvent + 1.25';


% Baseline firing rate epoch: used to plot average absolute deviation from baseline
params.baselineAlignEvent = 'handPreCueBeep';
params.baselineStartEvent = 'handPreCueBeep - 0.500';
params.baselineEndEvent = 'handPreCueBeep';


params.errorMode = 'sem'; % none, std, or sem

% Speech Modulation 
% May 2019: I'm calculating mean FR in a window, and also using the silence condition as
% baseline. This lets me compute speech modulation as a (mean FR speaking) - (mean FR
% silent).
params.comparisonAlignEvent = 'handResponseEvent';
params.comparisonStartEvent = 'handResponseEvent - 1.0';
params.comparisonEndEvent = 'handResponseEvent + 1.0';

result.params = params;
result.params.Rfile = Rfile;

% Some aesthetics
FaceAlpha = 0.3; % 


%% Load the data
in = load( Rfile );
R = in.R;
clear('in')

% exclude some trials?
if isfield( params, 'excludeTrials' ) && ~isempty( params.excludeTrials )
    excludeInds =  find( ismember( [R.trialNumber], params.excludeTrials ) .* ismember( [R.blockNumber], params.excludeTrialsBlocknum ) );
    fprintf('Excluding trials %s from blocks %s (%i trials)\n', ...
        mat2str( params.excludeTrials ), mat2str( params.excludeTrialsBlocknum ), numel( excludeInds ) );
    R(excludeInds) = [];
end

    

%% Annotate the data
% Scan for whether event labels files exist for these blocks. 
% Accept trials with wrong response to cue, if it was one of the included responses
if params.acceptWrongResponse
    numCorrected = 0;
    for iTrial = 1 : numel( R )
        myLabel = R(iTrial).label;
        if contains( myLabel, '-' ) 
            myResponse = myLabel(strfind( myLabel , '-' )+1:end);
            if ismember( myResponse, includeLabels )
                R(iTrial).label = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end

uniqueLabels = includeLabels( ismember( includeLabels, unique( {R.label} ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember(  {R.label}, uniqueLabels ));
fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;
allLabels = {R.label};


% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if any( cell2mat( strfind( params.alignEvent, 'vot' ) ) )
    fprintf('VOT alignment required, will add those now...\n')
    alignMode = 'VOTdetection';
else
    alignMode = 'handLabels';
end
uniqueBlocks = unique( [R.blockNumber] );


Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode )];        
end
R = Rnew; 
clear( 'Rnew' );
% Quick and dirty for getting the speaking-while doign BCI when constructed as an R struct
% from .ns5 and audio annotation (not from cursor task). To use these, comment the above
% bit of code too.
% get mean RT for nonsilence
% nonsilentIdx = ~arrayfun( @(x) strcmp( x.label, 'silence' ), R );
% RT = [R(nonsilentIdx).timeSpeechStart] - [R(nonsilentIdx).timeCueStart];
% 
% for iTrial = 1 : numel( R )
%     R(iTrial).handPreResponseBeep = R(iTrial).timeCueStart; % go cue
%     if strcmp( R(iTrial).label, 'silence' )
%         R(iTrial).handResponseEvent = R(iTrial).timeCueStart + median( RT ); % median RT
%     else
%         R(iTrial).handResponseEvent = R(iTrial).timeSpeechStart; % AO was hand marked
%     end
%     R(iTrial).label
% end
% params.baselineAlignEvent = 'handResponseEvent';
% params.baselineStartEvent = 'handResponseEvent - 1.500';
% params.baselineEndEvent = 'handResponseEvent - 1.000';
% 
% % When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{2} = 'handResponseEvent';
% params.startEvent{2} = 'handResponseEvent - 1';
% params.endEvent{2} = 'handResponseEvent + 1';
% End quick and dirty cross-check of ns5-derived speaking



%% Generate neural feature
if strfind( params.neuralFeature, 'sorted' )
    % Quick and easy way to do it: replace rasters with the spike sorted one
    fprintf('Using spike sorted rasters \n');
    [ R, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
        'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
        'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
    params.neuralFeature = regexprep( params.neuralFeature, 'sorted', '');
    R = AddFeature( R, params.neuralFeature, 'channelName', sorted.unitString );
    
elseif ~isempty( params.thresholdRMS )
    % Apply RMS thresholding
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
            R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( myACB, 2 ) ) );
        end
    end
    R = AddFeature( R, params.neuralFeature  );
    
    if ~isempty( params.excludeChannels )
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
    end
else
    error('Feature not yet implemented')
end



%% Make PSTH
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
for iEvent = 1 : numel( params.alignEvent )
    for iLabel = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );        
        jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );
        result.(myLabel).t{iEvent} = jenga.t;
        result.(myLabel).psthMean{iEvent} = squeeze( mean( jenga.dat, 1 ) );
        result.(myLabel).psthStd{iEvent} = squeeze( std( jenga.dat, [], 1 ) );
        for t = 1 : size( jenga.dat,2 )
            result.(myLabel).psthSem{iEvent}(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
        end
        result.(myLabel).numTrials = jenga.numTrials;
        % channel names had best be the same across events/groups, so put them in one place
        result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
        
        % record each channel's modulation depth
        result.(myLabel).modDepth{iEvent} = max( result.(myLabel).psthMean{iEvent} ) - min( result.(myLabel).psthMean{iEvent} );
    end
end
% just spit out max mod depth for last event as some gauge of interesting chans to look at
[vals, inds] = sort( result.(myLabel).modDepth{iEvent}, 'descend' );
fprintf('Most modulating chan inds for %s event %i are: %s\n', myLabel, iEvent, mat2str( inds(1:10 ) ))


%% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = speechColors( uniqueLabels{iLabel} ); 
   legendLabels{iLabel} = sprintf('%s (n=%i)', uniqueLabels{iLabel}, result.(uniqueLabels{iLabel}).numTrials );
end



%% All channels response.

% below code snippet is to sanity check that there isn't an audio cue during this epoch
% jengaAudio = AlignedMultitrialDataMatrix( R, 'featureField', 'audio', ...
%             'startEvent', 'handPreCueBeep-1.5', 'alignEvent', 'handPreCueBeep', 'endEvent', 'handPreCueBeep + 1.5' );
% % take it asbolute value
% absAudio = mean( abs( jengaAudio.dat ), 1 );
% figh = figure;
% plot( jengaAudio.t, absAudio );
% xlabel('handPreCueBeep')
% ylabel('|audio|');

% GET BASELINE
jengaBaseline = TrimToSolidJenga( AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
    'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent ) );
% average across all trials
baselineRate = squeeze( mean( jengaBaseline.dat, 1 ) );
baselineAvgRate = mean( baselineRate, 1 ); % average over this window.

% PLOT BASELINE-SUBTRACTED |FR DIFF| FOR EACH LABEL
figh = figure;
figh.Color = 'w';
titlestr = sprintf('diff from baseline %s', datasetName);
figh.Name = titlestr;
axh_baseline = [];

% consistent horizontal axis between panels 
startAt = 0.1;
gapBetween = 0.05;
epochDurations = nan( numel( params.alignEvent ), 1 );
epochStartPosFraction = epochDurations; % where within the figure each subplot starts. 
for iEvent = 1 : numel( params.alignEvent )
    epochDurations(iEvent) = range( result.(uniqueLabels{1}).t{iEvent} );
end
% I want to fill 0.8 of the figure with both axes, and have a 0.05 gap between subplots,
epochWidthsFraction = (1 - 2*startAt  - gapBetween*(numel( epochDurations ) - 1)) * (epochDurations ./ sum( epochDurations ));
epochStartPosFraction(1) = startAt;
for iEvent = 2 : numel( epochDurations )
    epochStartPosFraction(iEvent) = epochStartPosFraction(iEvent-1) + epochWidthsFraction(iEvent-1) + gapBetween;
end

%store the maximum deviation from baseline for each condition in each epoch
maxDeviations = nan( numel( uniqueLabels ), numel( params.alignEvent ) ); % label, event
maxDeviationsSilence = nan( 1,  numel( params.alignEvent ) ); % for silence condition, specifically
for iEvent = 1 : numel( params.alignEvent )
    axh_baseline(iEvent) = subplot(1, numel( params.alignEvent ), iEvent); hold on;           
    myPos =  get( axh_baseline(iEvent), 'Position');
    set( axh_baseline(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )

    xlabel(['Time ' params.alignEvent{iEvent} ' (s)']);
    for iLabel = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );
%         jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
%             'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );       
        result.(myLabel).psthDiffFromBaseline{iEvent} = result.(myLabel).psthMean{iEvent} - repmat( baselineAvgRate, size( result.(myLabel).psthMean{iEvent}, 1 ), 1);
        result.(myLabel).meanAbsDiffFromBaseline{iEvent} = mean( abs( result.(myLabel).psthDiffFromBaseline{iEvent} ), 2 ); % average across channels.
        
        % PLOT IT
       myX = result.(myLabel).t{iEvent};
       myY = result.(myLabel).meanAbsDiffFromBaseline{iEvent};
       plot( myX, myY, 'Color', colors(iLabel,:), ...
           'LineWidth', 1 );
       
       if ~any( strcmp( myLabel, {'silence', 'stayStill'}) )
           maxDeviations(iLabel, iEvent) =  max( result.(myLabel).meanAbsDiffFromBaseline{iEvent} );
       else
           maxDeviationsSilence(iEvent) = max( max( result.(myLabel).meanAbsDiffFromBaseline{iEvent} ) );
       end
    end
     % PRETTIFY
     % make horizontal axis nice
     xlim([myX(1), myX(end)])
     % make vertical axis nice
     if iEvent == 1
         ylabel( sprintf('|%s-baseline|', params.neuralFeature), 'Interpreter', 'none' );
     else
         % hide it
         yaxh = get( axh_baseline(iEvent), 'YAxis');
         yaxh.Visible = 'off';
     end
     set( axh_baseline(iEvent), 'TickDir', 'out' )
end
linkaxes(axh_baseline, 'y');
% add legend
axes( axh_baseline(1) );
MakeDumbLegend( legendLabels, 'Color', colors );

% Subtract silence max deviation from speaking/moving maximum deviation
maxDeviationsSubtracted = maxDeviations - maxDeviationsSilence;

% Report maximum deviation ratio between the epochs
meanDeviationEachEpoch = nanmean( maxDeviationsSubtracted );
fprintf('Mean deviations (across labels, not including silence/stayStill) for each condition are:\n%s\n', mat2str( meanDeviationEachEpoch ) )
if numel( maxDeviationsSubtracted ) > 1
    fprintf( 'Ratio of epoch 2 to epoch 1 is: %.2f\n', ...
        meanDeviationEachEpoch(2) / meanDeviationEachEpoch(1) );
end



%% waterfall
% whichEpoch = 2; % hand-set, right now this would do for move
% figh = figure;
% titlestr = sprintf('Waterfall %s', datasetName);
% figh.Name = titlestr;
% FRrange = [0 50];
% for iLabel = 1 : numel( uniqueLabels )
%     axh(iLabel) = subplot(numel( uniqueLabels ), 1, iLabel );
%     myLabel = uniqueLabels{iLabel};
%     myFR = result.(myLabel).psthMean{whichEpoch};
%     numChans = size( myFR, 2 );
%     imh = imagesc( myFR' );
% 
%     imh = imagesc(  result.(myLabel).t{whichEpoch}, 1:numChans, myFR' );
%     ylabel( sprintf('Chans %s', myLabel ) )
%     axh(iLabel).CLim = FRrange;
% end
% linkaxes( axh );



%% PSTH for specified channels
% ------------------------

% SORTED PSTHS
if isempty( plotChannels )
    plotChannels = result.channelNames; % just plot all of them
end

% compute how long each event-aligned time window is, so that the subplots can be made of
% the right size such that time is uniformly scaled along the horizontal axis
startAt = 0.1;
gapBetween = 0.05;
epochDurations = nan( numel( params.alignEvent ), 1 );
epochStartPosFraction = epochDurations; % where within the figure each subplot starts. 
for iEvent = 1 : numel( params.alignEvent )
    epochDurations(iEvent) = range( result.(uniqueLabels{1}).t{iEvent} );
end
% I want to fill 0.8 of the figure with both axes, and have a 0.05 gap between subplots,
epochWidthsFraction = (1 - 2*startAt  - gapBetween*(numel( epochDurations ) - 1)) * (epochDurations ./ sum( epochDurations ));
epochStartPosFraction(1) = startAt;
for iEvent = 2 : numel( epochDurations )
    epochStartPosFraction(iEvent) = epochStartPosFraction(iEvent-1) + epochWidthsFraction(iEvent-1) + gapBetween;
end
    
% -------------------------
for iCh = 1 : numel( plotChannels )
% plotChannels = num2cell(1:192, 1) % uncomment this and below to plot all PSTHs
% for iCh = 1 : 192
    % identify this electrode channel in the potentially channel-reduced dat
    if ischar( plotChannels{iCh} )
        chanStr = plotChannels{iCh} ;
    else
        % It's a number
        chanStr = ['chan_' chanNumToName( plotChannels{iCh} )];
    end
    chanInd = find( strcmp( result.channelNames, chanStr) );
    if isempty( chanInd )
        error('Channel %s not in data. Was it excluded earlier?', chanStr )
    end
    
    
    figh = figure;
    figh.Color = 'w';
    titlestr = sprintf('psth %s %s', datasetName, chanStr);
    figh.Name = titlestr;
    axh = [];
    myMax = 0; % will be used to track max FR across all conditions.

    for iEvent = 1 : numel( params.alignEvent )
        % Loop through temporal events
        axh(iEvent) = subplot(1, numel( params.alignEvent ), iEvent); hold on;     
        % make width proprotional to this epoch's duration
        myPos =  get( axh(iEvent), 'Position');
        set( axh(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )
        xlabel(['Time ' params.alignEvent{iEvent} ' (s)']);    
        
        for iLabel = 1 : numel( uniqueLabels )
            myLabel = uniqueLabels{iLabel};
            myX = result.(myLabel).t{iEvent};
            myY = result.(myLabel).psthMean{iEvent}(:,chanInd);
            myMax = max([myMax, max( myY )]);
            plot( myX, myY, 'Color', colors(iLabel,:), ...
                'LineWidth', 1 );
            switch params.errorMode
                case 'std'
                    myStd = result.(myLabel).psthStd{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
%                     plot( myX, myY+myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
%                     plot( myX, myY-myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
                    myMax = max([myMax, max( myY+myStd )]);

                case 'sem'
                    mySem = result.(myLabel).psthSem{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');

%                     plot( myX, myY+mySem, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
%                     plot(  myX, myY-mySem, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
                    myMax = max([myMax, max( myY+mySem )]);
                case 'none'
                    % do nothing
            end
        end
        
        % PRETTIFY
        % make horizontal axis nice
        xlim([myX(1), myX(end)])
        % make vertical axis nice
        if iEvent == 1
            ylabel( params.neuralFeature, 'Interpreter', 'none' );
        else
            % hide it
            yaxh = get( axh(iEvent), 'YAxis');
            yaxh.Visible = 'off';
        end
        set( axh(iEvent), 'TickDir', 'out' )
    end
    
    linkaxes(axh, 'y');
    ylim([0 ,ceil( myMax ) + 1]);
    % add legend
    axes( axh(1) );
    MakeDumbLegend( legendLabels, 'Color', colors );
end



%% MODULATION DEPTH and pop FR
% This is the old way that we don't think is a good idea.
% get modulation depth across speaking labels and save it.
saveComparisonRoot = [ResultsRootNPTL '/speechDuringBCI/'];
resultsFilename = [saveComparisonRoot datasetName '_comparison.mat'];


myTrialInds = ~strcmp( allLabels, 'silence' );
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent);
t = jenga.t;

popMeanFR = squeeze( mean( mean( jenga.dat,1 ), 3 ) );
figh = figure;
titlestr = sprintf('Pop mean FR %s', datasetName );
figh.Name = titlestr;
plot( t, popMeanFR);
xlabel( 'Time relative to AO (s)' );
ylabel( sprintf('Pop mean %s', params.neuralFeature  ) );
hold on;
% also plot silent
myTrialInds = strcmp( allLabels, 'silence' );
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
popMeanFRSilence = squeeze( mean( mean( jenga.dat,1 ), 3 ) );
t = jenga.t;
plot( t, popMeanFRSilence, 'Color', 'k');


speakLabels = setdiff( uniqueLabels, 'silence' );

% populate a matrix of modulation depths for each channel, for each sound label
modDepths = [];
for iLabel = 1 : numel( speakLabels )
      myLabel = speakLabels{iLabel};
      myTrialInds = strcmp( allLabels, myLabel );
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
      myPSTH = squeeze( mean( jenga.dat, 1 ) );
      for iChan = 1 : size( myPSTH, 2 )
          modDepths(iChan,iLabel) = max( myPSTH(:,iChan) ) - min( myPSTH(:,iChan) );
      end
end
% meanAcrossLabelsModDepths = mean( modDepths, 2 );
% figure; histogram( meanAcrossLabelsModDepths );



%% SPEECH-MODULATION, SPEAK - SILENCE, BASELINE SUBTRACTED, 
% updated version of 'modulation depth and pop fr above', but should be less sensitive to
% noise in low FR or low modulation channels. Still likely not the best way to do this.

% will save it all into structure 'speechMod'
speechMod = struct();

% SILENCE
% get mean FR in the silent condition
myLabel = 'silence';
myTrialInds = strcmp( allLabels, myLabel );
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
myPSTH = squeeze( mean( jenga.dat, 1 ) );
for iChan = 1 : size( myPSTH, 2 )
    speechMod.silenceFR(iChan) = nanmean( myPSTH(:,iChan) );
end

% Baseline FR
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
myPSTH = squeeze( mean( jenga.dat, 1 ) ); % average across trials
for iChan = 1 : size( myPSTH, 2 )
    speechMod.silenceBaselineFR(iChan) = nanmean( myPSTH(:,iChan) );
end


% Get mean FR in the spoken conditions
% Also get mean FR in the baseline, *for this same condition*.
for iLabel = 1 : numel( speakLabels )
      myLabel = speakLabels{iLabel};
      myTrialInds = strcmp( allLabels, myLabel );
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
      myPSTH = squeeze( mean( jenga.dat, 1 ) ); % average across trials
      for iChan = 1 : size( myPSTH, 2 )
          speechMod.wordFR(iLabel,iChan) = nanmean( myPSTH(:,iChan) );
      end
      
      % Baseline FR
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
      myPSTH = squeeze( mean( jenga.dat, 1 ) ); % average across trials
      for iChan = 1 : size( myPSTH, 2 )
          speechMod.baselineFR(iLabel,iChan) = nanmean( myPSTH(:,iChan) );
      end
end

%% POPULATION SPEECH-MODULATION, SPEAK - SILENCE, BASELINE SUBTRACTED, 
% updated version of 'modulation depth and pop fr above', but should be less sensitive to
% noise in low FR or low modulation channels. Still likely not the best way to do this.

% will save the data I'll need into structure 'popMod'. The actual population difference
% calculation will happen in WORKUP_compareModDepths_popUnbiased.m. That way, I can rule
% out channels that are < 1 Hz across EITHER stand-alone or speech during BCI
popMod = struct();

% SILENCE
% get mean FR in the silent condition
myLabel = 'silence';
myTrialInds = strcmp( allLabels, myLabel );
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
popMod.silenceTrialsByChans = squeeze( mean( jenga.dat, 2 ) ); % average across time

% record silence's baseline FR
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
popMod.silenceTrialsByChans_baseline = squeeze( mean( jenga.dat, 2 ) ); % average across time



% SPEAKING
for iLabel = 1 : numel( speakLabels )
      myLabel = speakLabels{iLabel};
      myTrialInds = strcmp( allLabels, myLabel );
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', params.comparisonStartEvent, 'alignEvent', params.comparisonAlignEvent, 'endEvent', params.comparisonEndEvent );
      popMod.speakingTrialsByChans{iLabel} = squeeze( nanmean( jenga.dat, 2 ) ); % average across time

      % Baseline FR
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
      popMod.speakingTrialsByChans_baseline{iLabel} = squeeze( nanmean( jenga.dat, 2 ) ); % average across time 
end

save( resultsFilename, 'popMod', 'speechMod', 'popMeanFR', 't', 'modDepths', 'params');
fprintf('Saved %s\n', resultsFilename )
