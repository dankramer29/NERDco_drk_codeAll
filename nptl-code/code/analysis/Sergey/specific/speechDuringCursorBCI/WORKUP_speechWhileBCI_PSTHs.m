% Generates PSTHs of specified example electrodes, as well as plotting a difference from
% baseline over time, for the speaking DURING BCI datasets.
%
% 
% Based on WORKUP_speechPSTHs.m
% Sergey D. Stavisky, March 2, 2019, Stanford Neural Prosthetics Translational Laboratory
%
% UPDATED: May 2019 with better speech modulation metric


clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/psths/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end



%% Dataset specification

%% t5.2018.12.17 During BCI (interlaved during BCIr)
datasetName = 't5.2018.12.17_duringBCI';
participant = 't5';
Rfile = {...
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B8.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B9.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B10.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B11.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B12.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B13.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B16.mat';    
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B17.mat';    
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B18.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B19.mat';
};

% params.excludeChannels = [1:96];
% params.excludeChannels = [97:192];
params.excludeChannels = [];
% plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
%     'chan_2.7', 'chan_1.17', 'chan_2.66'};

% These are most modulating for beet for standalone speaking
plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
    'chan_1.33', 'chan_2.3', 'chan_2.90'};

% % while speaking:
% plotChannels = {'chan_2.2', 'chan_2.77', 'chan_2.7', 'chan_2.66', 'chan_2.1', 'chan_2.87', 'chan_1.10', ...
%     'chan_1.17', 'chan_1.16', 'chan_1.6'};

%% t5.2018.12.12 During BCI (interlaved during BCI cursor control)
% datasetName = 't5.2018.12.12_duringBCI';
% participant = 't5';
% Rfile = {...
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B7.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B9.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B10.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B12.mat';
% };
% 
% params.excludeChannels = [];
% % while speaking:
% plotChannels = {'chan_2.2', 'chan_2.77', 'chan_2.7', 'chan_2.66', 'chan_2.1', 'chan_2.87', 'chan_1.10', ...
%     'chan_1.17', 'chan_1.16', 'chan_1.6'};




%% R structs during bci are one per block. Just lookup based on first
includeLabels = labelLists( Rfile{1} ); % lookup;
numArrays = 2; % don't anticipate this changing




%% Analysis Parameters

% TRIAL INCLUSION
params.maxTrialLength = 10000; %throw out trials > 10 seconds

% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% Time epochs to plot. There can be be multiple, in a cell array, and it'll plot these as
% subplots side by side.
params.alignEvent{1} = 'timeSpeech';
params.startEvent{1} = 'timeSpeech - 1.0';
params.endEvent{1} = 'timeSpeech + 1.0';



% Baseline firing rate epoch: used to plot average absolute deviation from baseline
params.baselineAlignEvent = 'timeCue';
params.baselineStartEvent = 'timeCue - 0.500';
params.baselineEndEvent = 'timeCue';


% USE THESE FOR TIME CUE ALIGNMENT
% params.alignEvent{1} = 'timeCue';
% params.startEvent{1} = 'timeCue - 1.0';
% params.endEvent{1} = 'timeCue + 1.5';
% plotChannels = {'chan_2.66', 'chan_1.10', 'chan_2.7', 'chan_1.23', 'chan_2.2', 'chan_1.17', 'chan_2.85', 'chan_1.13'};
% 
% 
% % % Baseline firing rate epoch: used to plot average absolute deviation from baseline


% Speech Modulation 
% May 2019: I'm calculating mean FR in a window, and also using the silence condition as
% baseline. This lets me compute speech modulation as a (mean FR speaking) - (mean FR
% silent).
params.comparisonAlignEvent = 'timeSpeech';
params.comparisonStartEvent = 'timeSpeech - 1.0';
params.comparisonEndEvent = 'timeSpeech + 1.0';


params.errorMode = 'sem'; % none, std, or sem


result.params = params;
result.params.Rfile = Rfile;

% Some aesthetics
FaceAlpha = 0.3; % 


%%



%% Load the data
% Will load one block at a time
Rall = [];
for iR = 1 : numel( Rfile )
    in = load( Rfile{iR} );
    fprintf('Loaded %s (%i trials)\n', Rfile{iR}, numel( in.R ) )
    
    % wipe out timeSpeech if it's a silence trial, since these are fictitious anyway
    for iTrial = 1 : numel( in.R )
        if ~isempty( in.R(iTrial).labelSpeech) && strcmp( in.R(iTrial).labelSpeech{end}, 'silence' )
            in.R(iTrial).timeSpeech = NaN;
            in.R(iTrial).labelSpeech = {};
            in.R(iTrial).eventNumberSpeech = NaN;
        end
    end
    
    % Make every speech trial have a .timeCue for each .timeSpeech (even if initially negative because it's in the
    % prior trial).
    for iTrial = 1 : numel( in.R ) % trial 1 won't have a prev trial so watch out
        numSpeechs = numel( in.R(iTrial).timeSpeech ); 
        numCues = numel( in.R(iTrial).timeCue );
        cuePtr = numCues + 1; % where to initially look for a cue: at end of cues in THIS trial (there is a -1 in this for loop )
        for iSp = numel( in.R(iTrial).timeSpeech) : -1 : 1 % work backwards in time, since one cue to 2 speech means the cue is for the 1 speech
                        
            if ~isnan( in.R(iTrial).timeSpeech(iSp) ) % this is a timeSpeech we care about, i.e. there's a speech event
                thisSpeechSettled = false;
                while ~thisSpeechSettled
                    
                    % take a look at my possible corresponding cue
                    cuePtr = cuePtr - 1;
                    
                    if cuePtr >= 1
                        % Look in this trial
                        possibleCue = in.R(iTrial).timeCue(cuePtr);
                        
                        % if it's not a nan, great
                        if ~isnan( possibleCue )
                            % make sure it's in the corresponding element
                            thisSpeechSettled = true;
                            in.R(iTrial).timeCue(iSp) = possibleCue;
                            in.R(iTrial).labelCue{iSp} = in.R(iTrial).labelSpeech{iSp};
                        end
                    else
                        % look at previous trial
                        % it's a nan pointer, so let's look at previous trial if we can
                        if iTrial > 1  && ( in.R(iTrial).trialNum == 1 + in.R(iTrial-1).trialNum )
                            cuesPrevTrial = numel( in.R(iTrial-1).timeCue );
                            possibleCue = in.R(iTrial-1).timeCue(cuesPrevTrial+cuePtr) - length(in.R(iTrial-1).clock);
                            if ~isnan( possibleCue )
                                % great, found it in previous trial
                                thisSpeechSettled = true;
                                in.R(iTrial).timeCue(iSp) = possibleCue;
                                in.R(iTrial).labelCue{iSp} = in.R(iTrial).labelSpeech{iSp};
                            end
                        else
                            keyboard
                        end
                        
                    end
                end
            end            
        end
    end

    
    % Do a data prepend/postpend so I can plot PSTHs aligned to speech events
    % even if they happen right at start of trial or end of trial (buffer data)
    [prependFields, updateFields] = PrependAndUpdateFields;
    % add some specific ones for these data
    updateFields = [updateFields; ...
        'timeCue';
        'timeSpeech';
        ];
    fprintf('Prepending and appending trials to allow for alignment to speech event even at start/end of trial\n')
    in.R = PrependPrevTrialRastersAndKin( in.R, ...
        'prependFields', prependFields, 'updateFields', updateFields, 'appendTrials', true );

    
    % Threshold each block individually (somewhat adapts to changing RMS across blocks)
    fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
    RMS{iR} = channelRMS( in.R );
    in.R = RastersFromMinAcausSpikeBand( in.R, params.thresholdRMS .*RMS{iR} );
   
    Rall = [Rall, in.R];
end
clear('in')


%% Make statistically-matched AO times for silence trials
% Go through and find all non-silence speaking events, and compute their delay from cue to
% speaking. I'll use the MEDIAN of this to put in a reasonable .timeSpeech for all silence trials. To
% make this simpler, I just pull the audio annotations files.
annotationFiles = {};
for iTrial = 1 : numel( Rall )
    if ~isempty( Rall(iTrial).audioEventFromFile )
        annotationFiles{end+1} = Rall(iTrial).audioEventFromFile;
    end
end
annotationFiles = unique( annotationFiles );

RTs = [];
FsAudio = 30000; % used to go from the audio sample units there to ms here
% load each audio annotation file, and from each pull out the reaction times.
for iFile = 1 : numel( annotationFiles )
    in = load( annotationFiles{iFile} );
    for iSpeak = 1 : numel( in.sAnnotation.trialNumber )
        if ~strcmp( in.sAnnotation.label{iSpeak}, 'silence' )
            % occasionally there is a speaking event without a start time or speak time (they'r
            % eempty) ignore those
            if isempty( in.sAnnotation.cueStartTime{iSpeak} ) || isempty( in.sAnnotation.speechStartTime{iSpeak} )
                continue
            else
                RTs(end+1) = round( (in.sAnnotation.speechStartTime{iSpeak} -  in.sAnnotation.cueStartTime{iSpeak})  / (FsAudio/1000) );
            end
        end
    end
end

medianSpokenRT = nanmedian( RTs );
fprintf('%i non-silence speech events (across %i blocks). Will use their median RT = %.1fms for ''AO'' of silence trials\n', ...
    numel( RTs ), numel( annotationFiles ), medianSpokenRT )



% Find every silence cue, and insert into either it or the next trial the silence response 
for iTrial =  numel( Rall ) : -1 : 1 % go backwards so when we insert into next trial, it doesnt' get double counted
    if ~isnan( Rall(iTrial).timeCue )
        for iSpeak = 1 : min( numel( Rall(iTrial).timeCue ), 2 ) % ignore the 3 event trials, they're going to go anyway
            if length( Rall(iTrial).labelCue ) >= iSpeak && strcmp( Rall(iTrial).labelCue{iSpeak}, 'silence' )
                timeSilenceResponse = Rall(iTrial).timeCue(iSpeak) + medianSpokenRT;
                % take into account prepend of this trial when computing if it should roll over               
                if ~isempty( Rall(iTrial).prependMS )
                    timeSilenceResponseForRollover = timeSilenceResponse - Rall(iTrial).prependMS;
                else
                    timeSilenceResponseForRollover = timeSilenceResponse;
                end
                
                if timeSilenceResponseForRollover < 1
                    % this response was in the previous trial; do nothing
                    fprintf('DEV this is from prev trial\n')
                    continue
                end
                
                if timeSilenceResponseForRollover <= size( Rall(iTrial).firstCerebusTime, 2 )
                    if isnan( Rall(iTrial).timeSpeech )
                        % insert into this trial
                        Rall(iTrial).timeSpeech = timeSilenceResponse;
                        Rall(iTrial).labelSpeech{1} = 'silence';
                        Rall(iTrial).eventNumberSpeech = Rall(iTrial).eventNumberCue(iSpeak);
                    else
                        % put it at the end (order doesn't really matter in the way I'm deciding to handle it)
                        Rall(iTrial).timeSpeech(end+1) = timeSilenceResponse;
                        Rall(iTrial).labelSpeech{end+1} = 'silence';
                        Rall(iTrial).eventNumberSpeech(end+1) = Rall(iTrial).eventNumberCue(iSpeak);
                    end
                else
                    % Need to add it to this next R struct trial
                    if ~( Rall(iTrial+1).trialNum == Rall(iTrial).trialNum + 1 ) % if trials aren't in order, we have a problem...
                        fprintf(2, 'Trial Rall(%i) does not have a directly next trial (based on trialNum), so cannot insert silence into the next trial. Ignoring this one\n', ...
                            iTrial)
                        continue
                    end
                    myRolloverTime = timeSilenceResponseForRollover - size( Rall(iTrial).firstCerebusTime, 2 );
                    % take into account prepend of NEXT trial
                    if ~isempty( Rall(iTrial+1).prependMS )
                        myRolloverTime = myRolloverTime + Rall(iTrial+1).prependMS;
                    end
                    if isnan( Rall(iTrial+1).timeSpeech ) 
                        % insert into this trial
                        Rall(iTrial+1).timeSpeech = myRolloverTime;
                        Rall(iTrial+1).labelSpeech{1} = 'silence';
                        Rall(iTrial+1).eventNumberSpeech = Rall(iTrial).eventNumberCue(iSpeak);
                        % put a .timeCue into this next trial too so can get baseline. Don't give it a label, so
                        % if I filter by 'silence' labelCue, it doesn't get double counted
                        Rall(iTrial+1).timeCue = myRolloverTime - medianSpokenRT;
                    else
                        % put it at the end (order doesn't really matter in the way I'm deciding to handle it)
                        Rall(iTrial+1).timeSpeech = [Rall(iTrial+1).timeSpeech, myRolloverTime];
                        Rall(iTrial+1).labelSpeech{end+1} = 'silence';
                        Rall(iTrial+1).eventNumberSpeech = [Rall(iTrial+1).eventNumberSpeech, Rall(iTrial).eventNumberCue(iSpeak)];
                        % put a .timeCue into this next trial too so can get baseline. Don't give it a label, so
                        % if I filter by 'silence' labelCue, it doesn't get touble counted
                        Rall(iTrial+1).timeCue = [Rall(iTrial+1).timeCue, myRolloverTime - medianSpokenRT]; 
                    end
                end
            end
        end
    end
end



% Exclude trials based on trial length. I do this early to avoid gross 3+ audio events
% trials
tooLong = [Rall.trialLength] > params.maxTrialLength;
fprintf('Removing %i/%i (%.2f%%) trials for having length > %ims\n', ...
    nnz( tooLong ), numel( tooLong ), 100*nnz( tooLong )/numel( tooLong ), params.maxTrialLength )
Rall(tooLong) = [];



switch params.alignEvent{1}
    case 'timeSpeech'
        % go through and keep only trials that have speaking. If they have two speaking events, create two trials out of it, with one speaking. 
        R = []; % will build this
        for iR = 1 : numel( Rall )
            Rall(iR).blockNumber = Rall(iR).startTrialParams.blockNumber;
            if ~isempty( Rall(iR).labelSpeech )
                for iR2 = 1 : numel( Rall(iR).labelSpeech )
                    myR = Rall(iR);
                    myR.timeSpeech = myR.timeSpeech(iR2);
                    myR.labelSpeech = myR.labelSpeech{iR2};
                    myR.eventNumberSpeech = myR.eventNumberSpeech(iR2);
                    myR.timeCue = myR.timeCue(iR2);
                    R = [R, myR];
                end
            end
        end
        fprintf('%i speaking trials\n', numel( R ) );
        allLabels = arrayfun(@(x) x.labelSpeech, R, 'UniformOutput', false );
    case 'timeCue'
%         uncomment below if doing cue align
keyboard % not sure I trust it; make sure number of trials lines up between this and alignign to speech
% my concern is that since we added a cue to all speech trials, then there are duplicate
% trials
        R = []; % will build this
        for iR = 1 : numel( Rall )
            Rall(iR).blockNumber = Rall(iR).startTrialParams.blockNumber;
            if ~isempty( Rall(iR).labelCue )
                for iR2 = 1 : numel( Rall(iR).labelCue )
                    myR = Rall(iR);
                    myR.timeCue = myR.timeCue(iR2);
                    myR.labelCue = myR.labelCue{iR2};
                    myR.eventNumberCue = myR.eventNumberCue(iR2);
                    R = [R, myR];
                end
            end
        end
        fprintf('%i cued trials\n', numel( R ) );
        allLabels = arrayfun(@(x) x.labelCue, R, 'UniformOutput', false );
    otherwise
        error( 'unrecognized alignment type')
end

%% Survey the data

uniqueLabels = includeLabels( ismember( includeLabels, unique( allLabels ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );

% Restrict to trials of the labels we care about
R = R(ismember(  allLabels, uniqueLabels ));
allLabels = arrayfun(@(x) x.labelSpeech, R, 'UniformOutput', false );

fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.labelSpeech, uniqueLabels{iLabel} ), R ) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;


%% Generate neural feature
R = AddFeature( R, params.neuralFeature  );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
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



%% SPEECH-MODULATION
% updated version of 'modulation depth and pop fr above', but should be less sensitive to
% noise in low FR or low modulation channels.

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
      myPSTH = squeeze( mean( jenga.dat, 1 ) ); % average across tirals
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
popMod.silenceTrialsByChans = squeeze( nanmean( jenga.dat, 2 ) ); % average across time

% record silence's baseline FR
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
popMod.silenceTrialsByChans_baseline = squeeze( nanmean( jenga.dat, 2 ) ); % average across time



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


