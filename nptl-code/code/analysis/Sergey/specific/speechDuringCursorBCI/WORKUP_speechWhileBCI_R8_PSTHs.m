% Generates PSTHs of specified example electrodes, and get modulation depths,
% for the speaking DURING BCI datasets' Radial 8 task.
%
% As currently implemented, it incldues all R8 trials that contain no CUE event or
% SPEAKING event, i.e. the more 'pristine' Radial 8 trials. If I wanted to be even more
% conservative I could restrict to the silence blocks too.
% 
% Based on WORKUP_speechPSTHs.m
% Sergey D. Stavisky, March 4, 2019, Stanford Neural Prosthetics Translational Laboratory
%
clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/psths/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
% saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated



%% Dataset specification

%% t5.2018.12.17 During BCI (interlaved during BCIr)
datasetName = 't5.2018.12.17_R8_BCI';
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

% while speaking:
% plotChannels = {'chan_2.2', 'chan_2.77', 'chan_2.7', 'chan_2.66', 'chan_2.1', 'chan_2.87', 'chan_1.10', ...
%     'chan_1.17', 'chan_1.16', 'chan_1.6'};

% These are most modulating for beet for standalone speaking
plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
    'chan_1.33', 'chan_2.3', 'chan_2.90'};


%% t5.2018.12.12 During BCI (interlaved during BCI cursor control)
% datasetName = 't5.2018.12.12_R8_BCI';
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


%% t5.2018.12.12 During BCI (interlaved during BCI cursor control)
% datasetName = 't5.2018.12.12_R8_BCI';
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
% 
% %%% R structs during bci are one per block. Just lookup based on first
% includeLabels = labelLists( Rfile{1} ); % lookup;
% numArrays = 2; % don't anticipate this changing




%% Analysis Parameters

% TRIAL INCLUSION
params.maxTrialLength = 10000; %throw out trials > 10 seconds

% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% Time epochs to plot. There can be be multiple, in a cell array, and it'll plot these as
% subplots side by side.
params.alignEvent{1} = 'timeTargetOn';
params.startEvent{1} = 'timeTargetOn - 0.100';
params.endEvent{1} = 'timeTargetOn + 0.900';



% Baseline firing rate epoch: used to plot average absolute deviation from baseline
params.baselineAlignEvent = 'timeTargetOn';
params.baselineStartEvent = 'timeTargetOn - 0.100';
params.baselineEndEvent = 'timeTargetOn';


params.errorMode = 'sem'; % none, std, or sem


result.params = params;
result.params.Rfile = Rfile;

% Some aesthetics
FaceAlpha = 0.3; % 


%% Load the data
% Will load one block at a time
Rall = [];
for iR = 1 : numel( Rfile )
    in = load( Rfile{iR} );
    fprintf('Loaded %s (%i trials)\n', Rfile{iR}, numel( in.R ) )
    
    % I'm going to plot cursor position from time target on to time success, which is the end
    % time. I'll create a new field for that that I then update with prepend/append, so that I
    % can tell the overhead plot to look at that.
    for iTrial = 1 : numel( in. R )
        in.R(iTrial).timeTrialEnd = numel( in.R(iTrial).clock );
    end
    % Do a data prepend/postpend so I can plot PSTHs aligned to speech events
    % even if they happen right at start of trial or end of trial (buffer data)
    [prependFields, updateFields] = PrependAndUpdateFields;
    % add some specific ones for these data
    updateFields = [updateFields; ...
        'timeTargetOn';
        'timeTrialEnd'
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

% first, get rid of all exist silence speaking event, since it's nonsense (just arbitrary)
% Note: trials won't have more than one soeaking label *for these datasets*, so just set
% to nan and '' regardless of how many there were. IF I ever have a mixed words block this
% will need to change (but then I'll plan ahead and not get into this mess to begin with)
for iTrial = 1: numel( Rall )
    if ~isnan( Rall(iTrial).timeSpeech )
        if any( strcmp( Rall(iTrial).labelSpeech, 'silence' ) )
            Rall(iTrial).timeSpeech = NaN;
            Rall(iTrial).labelSpeech = {};
            Rall(iTrial).eventNumberSpeech = NaN;
        end
    end
end
        

% Now find every silence cue, and insert into either it or the next trial the silence response 
for iTrial = 1 : numel( Rall )
    if ~isnan( Rall(iTrial).timeCue )
        for iSpeak = 1 : min( numel( Rall(iTrial).timeCue ), 2 ) % ignore the 3 event trials, they're going to go anyway
            if strcmp( Rall(iTrial).labelCue{iSpeak}, 'silence' )
                timeSilenceResponse = Rall(iTrial).timeCue(iSpeak) + medianSpokenRT;
                % take into account prepend of this trial when computing if it should roll over               
                if ~isempty( Rall(iTrial).prependMS )
                    timeSilenceResponseForRollover = timeSilenceResponse - Rall(iTrial).prependMS;
                else
                    timeSilenceResponseForRollover = timeSilenceResponse;
                end
                
                
                if timeSilenceResponseForRollover <= Rall(iTrial).trialLength
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
                    myRolloverTime = timeSilenceResponseForRollover - Rall(iTrial).trialLength;
                    % take into account prepend of NEXT trial
                    if ~isempty( Rall(iTrial+1).prependMS )
                        myRolloverTime = myRolloverTime + Rall(iTrial+1).prependMS;
                    end
                    if isnan( Rall(iTrial+1).timeSpeech ) 
                        % insert into this trial
                        Rall(iTrial+1).timeSpeech = myRolloverTime;
                        Rall(iTrial+1).labelSpeech{1} = 'silence';
                        Rall(iTrial+1).eventNumberSpeech = Rall(iTrial).eventNumberCue(iSpeak);
                    else
                        % put it at the end (order doesn't really matter in the way I'm deciding to handle it)
                        Rall(iTrial+1).timeSpeech = [Rall(iTrial+1).timeSpeech, myRolloverTime];
                        Rall(iTrial+1).labelSpeech{end+1} = 'silence';
                        Rall(iTrial+1).eventNumberSpeech = [Rall(iTrial+1).eventNumberSpeech, Rall(iTrial).eventNumberCue(iSpeak)];
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


%% go through and keep only trials that have no cue or speaking events.
% then keep outward going R8

pristineTrials = false( size( Rall ) );
for iR = 1 : numel( Rall )
    Rall(iR).blockNumber = Rall(iR).startTrialParams.blockNumber;
    if isempty( Rall(iR).labelSpeech ) && isempty( Rall(iR).labelCue )
      pristineTrials(iR) = true;
    end
end
fprintf('%i/%i trials have no speaking or cue events\n', nnz( pristineTrials ), numel( pristineTrials ));
R = Rall(pristineTrials);

% Restrict to successful trials
R = R([R.isSuccessful]);
fprintf(' %i successful trials\n', numel( R ) );

% Divide by condition.
inInds = CenteringTrialInds( R );
R(inInds) = [];
fprintf(' %i outward trials\n', numel( R ) );

[targetIdx, uniqueTargets] = SortTrialsByTarget( R );
cmapR8 = hsv( size( uniqueTargets, 1 ) );
eachTrialColors = nan( numel( targetIdx ), 3 );
for iTrial = 1 : numel( R )
    R(iTrial).targetIdx = targetIdx(iTrial);
    % generate single-trial colors
    STcolor(iTrial,1:3) = cmapR8(targetIdx(iTrial),:);
end

allLabels = [R.targetIdx];
uniqueLabels = unique( allLabels );
blocksPresent = unique( [R.blockNumber] );


%% Plot Overheads
figh_cursorTrajectories = OverheadTrajectories_NPTL( R, ...
    'colors', STcolor, 'startEvent', 'timeTargetOn', 'endEvent', 'timeTrialEnd', ...
    'drawMode', 'line', 'cursorSize', 0.5  );
figh_cursorTrajectories = ConvertToWhiteBackground( figh_cursorTrajectories );
titlestr = sprintf('R8 Overheads %s', dataset );
figh_cursorTrajectories.Name = titlestr;


fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), mat2str( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' target %i: %i trials\n', uniqueLabels(iLabel), nnz( [R.targetIdx] == uniqueLabels(iLabel) ) )
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
        myLabel = uniqueLabels(iLabel);
        myLabelStr = sprintf('target%i', myLabel); % or else it can't be a field
        myTrialInds = allLabels == myLabel;        
        jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );
        result.(myLabelStr).t{iEvent} = jenga.t;
        result.(myLabelStr).psthMean{iEvent} = squeeze( nanmean( jenga.dat, 1 ) );
        result.(myLabelStr).psthStd{iEvent} = squeeze( nanstd( jenga.dat, [], 1 ) );
        for t = 1 : size( jenga.dat,2 )
            result.(myLabelStr).psthSem{iEvent}(t,:) = nansem( squeeze( jenga.dat(:,t,:) ) );
        end
        result.(myLabelStr).numTrials = jenga.numTrials;
        % channel names had best be the same across events/groups, so put them in one place
        result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
        
        % record each channel's modulation depth
        result.(myLabelStr).modDepth{iEvent} = max( result.(myLabelStr).psthMean{iEvent} ) - min( result.(myLabelStr).psthMean{iEvent} );
    end
end
% just spit out max mod depth for last event as some gauge of interesting chans to look at
[vals, inds] = sort( result.(myLabelStr).modDepth{iEvent}, 'descend' );
fprintf('Most modulating chan inds for %s event %i are: %s\n', myLabelStr, iEvent, mat2str( inds(1:10 ) ))


%% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = cmapR8( iLabel,: ); 
   myLabelStr = sprintf('target%i', iLabel);
   legendLabels{iLabel} = sprintf('%s (n=%i)', myLabelStr, result.(myLabelStr).numTrials );
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
jengaBaseline = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
    'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
% average across all trials
baselineRate = squeeze( nanmean( jengaBaseline.dat, 1 ) );
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
    myLabelStr = sprintf('target%i', 1);
    epochDurations(iEvent) = range( result.(myLabelStr).t{iEvent} );
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
        myLabel = uniqueLabels(iLabel);
        myLabelStr = sprintf('target%i', myLabel);
        myTrialInds = allLabels == myLabel;
        result.(myLabelStr).psthDiffFromBaseline{iEvent} = result.(myLabelStr).psthMean{iEvent} - repmat( baselineAvgRate, size( result.(myLabelStr).psthMean{iEvent}, 1 ), 1);
        result.(myLabelStr).meanAbsDiffFromBaseline{iEvent} = mean( abs( result.(myLabelStr).psthDiffFromBaseline{iEvent} ), 2 ); % average across channels.
        
        % PLOT IT
       myX = result.(myLabelStr).t{iEvent};
       myY = result.(myLabelStr).meanAbsDiffFromBaseline{iEvent};
       plot( myX, myY, 'Color', colors(iLabel,:), ...
           'LineWidth', 1 );
       
       if ~any( strcmp( myLabelStr, {'silence', 'stayStill'}) )
           maxDeviations(iLabel, iEvent) =  max( result.(myLabelStr).meanAbsDiffFromBaseline{iEvent} );
       else
           maxDeviationsSilence(iEvent) = max( max( result.(myLabelStr).meanAbsDiffFromBaseline{iEvent} ) );
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
    epochDurations(iEvent) = range( result.(myLabelStr).t{iEvent} ); % index into any label
end
% I want to fill 0.8 of the figure with both axes, and have a 0.05 gap between subplots,
epochWidthsFraction = (1 - 2*startAt  - gapBetween*(numel( epochDurations ) - 1)) * (epochDurations ./ sum( epochDurations ));
epochStartPosFraction(1) = startAt;
for iEvent = 2 : numel( epochDurations )
    epochStartPosFraction(iEvent) = epochStartPosFraction(iEvent-1) + epochWidthsFraction(iEvent-1) + gapBetween;
end
    
% -------------------------
for iCh = 1 : numel( plotChannels )
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
            myLabel = uniqueLabels(iLabel);
            myLabelStr = sprintf('target%i', myLabel );
            myX = result.(myLabelStr).t{iEvent};
            myY = result.(myLabelStr).psthMean{iEvent}(:,chanInd);
            myMax = max([myMax, max( myY )]);
            plot( myX, myY, 'Color', colors(iLabel,:), ...
                'LineWidth', 1 );
            switch params.errorMode
                case 'std'
                    myStd = result.(myLabelStr).psthStd{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
                    myMax = max([myMax, max( myY+myStd )]);

                case 'sem'
                    mySem = result.(myLabelStr).psthSem{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
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

comparisonAlignEvent = 'timeTargetOn';
comparisonStartEvent = 'timeTargetOn - 0.100';
comparisonEndEvent = 'timeTargetOn + 0.900';


jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.neuralFeature, ...
    'startEvent', comparisonStartEvent, 'alignEvent', comparisonAlignEvent, 'endEvent', comparisonEndEvent);
t = jenga.t;

popMeanFR = squeeze( mean( mean( jenga.dat,1 ), 3 ) );
figh = figure;
titlestr = sprintf('Pop mean FR %s', datasetName );
figh.Name = titlestr;
plot( t, popMeanFR);
xlabel( 'Time relative to AO (s)' );
ylabel( sprintf('Pop mean %s', params.neuralFeature  ) );
hold on;


% populate a matrix of modulation depths for each channel, for each sound label
modDepths = [];
for iLabel = 1 : numel( uniqueLabels )
      myLabel = uniqueLabels(iLabel);
      myLabelStr = sprintf('target%i', myLabel );
      myTrialInds =  allLabels == myLabel;
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', comparisonStartEvent, 'alignEvent', comparisonAlignEvent, 'endEvent', comparisonEndEvent );
      myPSTH = squeeze( mean( jenga.dat, 1 ) );
      for iChan = 1 : size( myPSTH, 2 )
          modDepths(iChan,iLabel) = max( myPSTH(:,iChan) ) - min( myPSTH(:,iChan) );
      end
end
% meanAcrossLabelsModDepths = mean( modDepths, 2 );
% figure; histogram( meanAcrossLabelsModDepths );

save( resultsFilename, 'popMeanFR', 't', 'modDepths', 'params');
fprintf('Saved %s\n', resultsFilename )




