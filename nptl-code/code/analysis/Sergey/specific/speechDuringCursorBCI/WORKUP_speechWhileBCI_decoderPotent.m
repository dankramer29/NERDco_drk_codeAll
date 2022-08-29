% Generates PSTHs for Radial 8 outward reaches AND speaking during BCI, and then
% calculates these PSTHs decoder-potent neural push. 
%
% R8 Neural Push:
% As currently implemented, it incldues all R8 trials that contain no CUE event or
% SPEAKING event, i.e. the more 'pristine' Radial 8 trials. If I wanted to be even more
% conservative I could restrict to the silence blocks too.
% 
%
% Sergey D. Stavisky, March 4, 2019, Stanford Neural Prosthetics Translational Laboratory
% UPDATED May 2019 with unbiased neural push using Frank's method, and also a longer
% baseline for speech during R8
clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/decoderPotent/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
saveResultsRoot = [ResultsRootNPTL '/speechDuringBCI/newRescaled/']; % 
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end


%% Dataset specification

%% t5.2018.12.17 During BCI (interlaved during BCIr)
datasetName = 't5.2018.12.17_R8andSpeaking';
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
decoderPath = [CachedDatasetsRootNPTL filesep 'NPTL' filesep 't5.2018.12.17' filesep 'Data' filesep 'Filters' filesep];
% params.excludeChannels = [1:96];
% params.excludeChannels = [97:192];
params.excludeChannels = [];


%% t5.2018.12.12 During BCI (interlaved during BCI cursor control)
% datasetName = 't5.2018.12.12_R8andSpeaking';
% participant = 't5';
% Rfile = {...
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B7.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B9.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B10.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B12.mat';
% };
% decoderPath = [CachedDatasetsRootNPTL filesep 'NPTL' filesep 't5.2018.12.12' filesep 'Data' filesep 'Filters' filesep];
% 
% params.excludeChannels = [];



%% R structs during bci are one per block. Just lookup based on first
includeLabels = labelLists( Rfile{1} ); % lookup;
numArrays = 2; % don't anticipate this changing
    

%% Analysis Parameters

% TRIAL INCLUSION
params.maxTrialLength = 10000; %throw out trials > 10 seconds

% note: RMS is calculated from the decoder.
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 

% R8 PARAMETERS
% Time epochs to plot. There can be be multiple, in a cell array, and it'll plot these as
% subplots side by side.
params.alignEvent{1} = 'timeTargetOn';
params.startEvent{1} = 'timeTargetOn - 0.100';
params.endEvent{1} = 'timeTargetOn + 0.900';

% Baseline epoch: used to compute change in neural push
params.subtractBaselinePush = true;

params.baselineAlignEvent = 'timeTargetOn';
params.baselineStartEvent = 'timeTargetOn - 0.100';
params.baselineEndEvent = 'timeTargetOn';

% SPEECH PARAMETERS
params.alignEventSpeech{1} = 'timeSpeech';
params.startEventSpeech{1} = 'timeSpeech - 2.000';
params.endEventSpeech{1} = 'timeSpeech + 2.000';

params.baselineAlignEventSpeech = 'timeCue';
params.baselineStartEventSpeech = 'timeCue - 0.500';
params.baselineEndEventSpeech = 'timeCue';



result.params = params;
result.params.Rfile = Rfile;

% for pixels/second converion
params.externalGain = 5000; % taken from param scripts and log.

% Some aesthetics
FaceAlpha = 0.3; % 
params.errorMode = 'sem'; % for plotting neural push

%% Load the data
% Will load one block at a time

allDecoders = {};

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
    
   
    
    % Do a data prepend/postpend so I can plot PSTHs aligned to speech events
    % even if they happen right at start of trial or end of trial (buffer data)
    [prependFields, updateFields] = PrependAndUpdateFields;
    % add some specific ones for these data
    updateFields = [updateFields; ...
        'timeTargetOn';
        'timeTrialEnd';
        'timeCue';
        'timeSpeech';
        ];
    fprintf('Prepending and appending trials to allow for alignment to speech event even at start/end of trial\n')
    in.R = PrependPrevTrialRastersAndKin( in.R, ...
        'prependFields', prependFields, 'updateFields', updateFields, 'appendTrials', true );

    % Load the decoder for this block
    myDecoderName = deblank( in.R(3).decoderD.filterName ); % remove trailing white space. Sometimes trial 1 or 2 doesn't have decoder, so just go with 3
    myDecoderFile = [decoderPath myDecoderName];
    fprintf('Loading decoder %s\n', myDecoderFile )
    inDecoder = load( myDecoderFile );
    inDecoder = rmfield(inDecoder, 'modelsFull'); % don't need all that extra crap eating memory
    allDecoders{iR} = inDecoder;
    % note in each trial which decoder they use.
    for iTrial = 1 : numel( in.R )
        in.R(iTrial).decoderLookupInd = iR;
    end
    
    % Threshold each block individually (somewhat adapts to changing RMS across blocks)
    fprintf('Thresholding according to decoder\n' );
    RMS{iR} = inDecoder.model.thresholds;
    in.R = RastersFromMinAcausSpikeBand( in.R, RMS{iR} );
    
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




%% Generate neural feature
Rall = AddFeature( Rall, params.neuralFeature  );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    Rall = RemoveChannelsFromR( Rall, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end

%% Generate neural push for each trial
fprintf('Adding neural push to all trials...\n')
for iTrial = 1 : numel( Rall )
    % What is my decoder?
    myDecoder = allDecoders{Rall(iTrial).decoderLookupInd};
    binMS = myDecoder.model.dtMS;
    activeChans = 1:numel(RMS{Rall(iTrial).decoderLookupInd}); % decoder wasn't using HFLP
    
    % K is M2
    velProjector = double( myDecoder.model.K([2,4],: ) );
    velProjector = velProjector(:,activeChans)'; % spikes only, chans x 2    
    
    
    % NEW
    % Convert firing rates to binned spike counts (as the decoder expects) 
    myNeural = Rall(iTrial).(params.neuralFeature).dat;
    myNeural = myNeural .* (binMS/1000);
    % Do the softnorm thing our decoders did for some mystery reason
    myNeural = myNeural .*  myDecoder.model.invSoftNormVals(1:192);
    % / NEW
    
    
    % these decoders have a firing rate baseline offset. Without that, the pushes have a DC
    % shift.
    decoderOffset = double( myDecoder.model.C(:,21) );
    decoderOffset = decoderOffset(activeChans); % spikes only, chans x 1

%     decoderOffset = decoderOffset*(1000/binMS); % no longer necessary since neural is in binned spikes
%     decoderOffset = zeros( size( decoderOffset ) ); % uncomment to not to baseline subtraction (BAD IDEA)

    myOffsetNeural = myNeural - repmat( decoderOffset, 1, Rall(iTrial).(params.neuralFeature).numSamples );
    myNeuralPush = myOffsetNeural' * velProjector; % time x 2
    
    % Convert to pixels/second
    alpha = myDecoder.model.alpha;
    myNeuralPush = myNeuralPush .* 1000 .* params.externalGain .* (1/(1-alpha));
    
    % I want to keep it as a contDatObject, since its timestamps don't quite line up with the
    % MS trial stuff because of the clipping in smoothed neural data. So I'll just make a
    % copy of the neural feature and put neural push into that
    Rall(iTrial).neuralPush = Rall(iTrial).(params.neuralFeature);
    Rall(iTrial).neuralPush.dat = myNeuralPush';
    Rall(iTrial).neuralPush.channelName = {'vx', 'vy'};
end


% ************************************************************************************
%                   Radial 8-aligned Neural Push 
% ************************************************************************************

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
R8 = Rall(pristineTrials);

% Restrict to successful trials
R8 = R8([R8.isSuccessful]);
fprintf(' %i successful trials\n', numel( R8 ) );

% Divide by condition.
inInds = CenteringTrialInds( R8 );
R8(inInds) = [];
fprintf(' %i outward trials\n', numel( R8 ) );

[targetIdx, uniqueTargets] = SortTrialsByTarget( R8 );
cmapR8 = hsv( size( uniqueTargets, 1 ) );
eachTrialColors = nan( numel( targetIdx ), 3 );
for iTrial = 1 : numel( R8 )
    R8(iTrial).targetIdx = targetIdx(iTrial);
    % generate single-trial colors
    STcolor(iTrial,1:3) = cmapR8(targetIdx(iTrial),:);
end

allLabels = [R8.targetIdx];
uniqueLabels = unique( allLabels );
blocksPresent = unique( [R8.blockNumber] );

% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' target %i: %i trials\n', uniqueLabels(iLabel), nnz( [R8.targetIdx] == uniqueLabels(iLabel) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;


% If I want to look at cursor speed
% (sanity check that the units of eurap push are OK )
% R8 = AddSpeed( R8 );
% jengaSpeed = AlignedMultitrialDataMatrix( R8, 'featureField', 'speed', ...
%     'startEvent', params.startEvent{1}, 'alignEvent', params.alignEvent{1}, 'endEvent', params.endEvent{1} );
% figure;
% myMeanSpeed = 1000.*nanmean( jengaSpeed.dat, 1 ); %convert to pixels/sec
% plot( jengaSpeed.t, myMeanSpeed );
% xlabel( sprintf('T (%s)', params.alignEvent{1} ) );
% ylabel('Speed')

%% Now calculate mean neural push for each label
for iEvent = 1 : numel( params.alignEvent )
    for iLabel = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels(iLabel);
        myLabelStr = sprintf('target%i', myLabel); % or else it can't be a field
        myTrialInds = allLabels == myLabel;        
      
        jenga = AlignedMultitrialDataMatrix( R8(myTrialInds), 'featureField', 'neuralPush', ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );

        result.(myLabelStr).t{iEvent} = jenga.t;
        result.(myLabelStr).pushMean{iEvent} = squeeze( nanmean( jenga.dat, 1 ) );
        result.(myLabelStr).pushStd{iEvent} = squeeze( nanstd( jenga.dat, [], 1 ) );
        for t = 1 : size( jenga.dat,2 )
            result.(myLabelStr).pushSem{iEvent}(t,:) = nansem( squeeze( jenga.dat(:,t,:) ) );
        end
        result.(myLabelStr).numTrials = jenga.numTrials;
        % channel names had best be the same across events/groups, so put them in one place
        result.channelNames = R8(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
        
        if params.subtractBaselinePush
            % get baseline push.
            jengaBaseline = AlignedMultitrialDataMatrix( R8(myTrialInds), 'featureField', 'neuralPush', ...
                'startEvent', params.baselineStartEvent, 'alignEvent', params.baselineAlignEvent, 'endEvent', params.baselineEndEvent );
            % time average and trial average to get the baseline
            result.(myLabelStr).baselinePush{iEvent} = squeeze( nanmean( nanmean( jengaBaseline.dat, 1 ) ) );
            % subtract this from saved push.
            result.(myLabelStr).pushMean{iEvent}(:,1:2) = result.(myLabelStr).pushMean{iEvent}(:,1:2) - ...
                repmat( result.(myLabelStr).baselinePush{iEvent}', size( result.(myLabelStr).pushMean{iEvent}, 1 ), 1 );
             % Note I'm careful about the norm having been calculated on
            % trial averaged data.              
        end
                
        % Tricky stuff: I'm going to calculate the vector norm of *single trial* neural pushes.
        % But I do it here so that I can subtract the *trial-averaged baseline push* from these
        % individual trials' neural pushes (this avoids having variance seem really large when the
        % push is fluctuating around a biased amount).
        myTrials = find( myTrialInds );
        for iTrial = 1 : nnz( myTrials )
           myTrialInd =  myTrials(iTrial);
           % calculate its vector norm push:
           % 1. start with the 2d neural push
           myNorm = R8(myTrialInd).neuralPush;
           % 2. if baseline subtraction is enabled, subtract that away
           if params.subtractBaselinePush
               myNorm.dat = myNorm.dat - repmat( result.(myLabelStr).baselinePush{iEvent}, 1, size( myNorm.dat, 2 ) );
           end
           % 3. now take its norm at each time point
           myNorm.dat = norms( myNorm.dat );
           myNorm.channelName = {'norm'};
           % Write it back into this trial
           R8(myTrialInd).neuralPushNorm = myNorm;
        end
        
        % Now compute the vector norm push. This is done from baseline-subtracted mean x,y
        result.(myLabelStr).pushMean{iEvent}(:,3) = norms( result.(myLabelStr).pushMean{iEvent}' );
        
        % Now calculate neural push SEM from the single trial norms. I write this into dim 3 of
        % pushSem.
        jengaNorm = AlignedMultitrialDataMatrix( R8(myTrialInds), 'featureField', 'neuralPushNorm', ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );
        for t = 1 : size( jengaNorm.dat,2 ) 
            result.(myLabelStr).pushSem{iEvent}(t,3) = nansem( squeeze( jengaNorm.dat(:,t,:) ) );
        end
        
        
        % record peak neural push (vector norm across both x and y push)
        myNormPush = norms( result.(myLabelStr).pushMean{iEvent}' );
        result.(myLabelStr).peakPush{iEvent} = max( result.(myLabelStr).pushMean{iEvent}(:,3) );
              
         % Unbiased estimate of the neural push norm (using Frank's method)
        mySingleTrialPushes = jenga.dat; % trials x time x dim
        if params.subtractBaselinePush
            mySingleTrialPushes = mySingleTrialPushes - ...
                repmat( reshape( result.(myLabelStr).baselinePush{iEvent}, 1, 1, []), size( mySingleTrialPushes, 1 ), size( mySingleTrialPushes, 2 ), 1 );
        end
        myUnbiasedPush = [];
        myBiasedPush = []; % for curiosity
        for iT = 1 : size( mySingleTrialPushes, 2 )
            mySamples = squeeze( mySingleTrialPushes(:,iT,:) ); % trials x 2
            mySamples(isnan( mySamples(:,1) ),:) = []; % remove nans

            matchedZeros = zeros( size( mySamples ) ); % corresponding zeros
            myUnbiasedPush(iT) = lessBiasedDistance( mySamples, matchedZeros );
            myBiasedPush(iT) = norm( [mean(mySamples(:,1)), mean(mySamples(:,2))] ); % DEV
        end
%         figure; plot( myUnbiasedPush, 'r' ); hold on; plot( myBiasedPush, 'k'); legend( {'unbiased', 'biased'}); % DEV
         % save this
        result.(myLabelStr).unbiasedPush{iEvent} = myUnbiasedPush;
        result.(myLabelStr).peakUnbiasedPush{iEvent} = max( myUnbiasedPush );        
    end
end



%% Prep for plotting
% Define the specific colormap
colorsR8 = [];
legendLabelsR8 = {};
for iLabel = 1 : numel( uniqueLabels )
   colorsR8(iLabel,1:3) = cmapR8( iLabel,: ); 
   myLabelStr = sprintf('target%i', iLabel);
   legendLabelsR8{iLabel} = sprintf('%s (n=%i)', myLabelStr, result.(myLabelStr).numTrials );
end


%% Plot R8 Neural Push
% ------------------------

% compute how long each event-aligned time window is, so that the subplots can be made of
% the right size such that time is uniformly scaled along the horizontal axis
startAt = 0.1;
gapBetween = 0.05;
epochDurations = nan( numel( params.alignEvent ), 1 );
epochStartPosFraction = epochDurations; % where within the figure each subplot starts. 
for iEvent = 1 : numel( params.alignEvent )
    epochDurations(iEvent) = range( result.(myLabelStr).t{iEvent} );
end
% I want to fill 0.8 of the figure with both axes, and have a 0.05 gap between subplots,
epochWidthsFraction = (1 - 2*startAt  - gapBetween*(numel( epochDurations ) - 1)) * (epochDurations ./ sum( epochDurations ));
epochStartPosFraction(1) = startAt;
for iEvent = 2 : numel( epochDurations )
    epochStartPosFraction(iEvent) = epochStartPosFraction(iEvent-1) + epochWidthsFraction(iEvent-1) + gapBetween;
end
    
% -------------------------
for iDim = 1 : 3
    % identify this electrode channel in the potentially channel-reduced dat
    switch iDim
        case 1
            chanStr = 'x';
        case 2
            chanStr = 'y';
        case 3 
            chanStr = 'xy';
    end   
    chanInd = iDim;
    
    
    figh = figure;
    figh.Color = 'w';
    titlestr = sprintf('neural push R8 %s %s', datasetName, chanStr);
    figh.Name = titlestr;
    axh = [];
    myMax = 0; % will be used to track max oush across all conditions.
    for iEvent = 1 : numel( params.alignEvent )
        % Loop through temporal events
        axh(iEvent) = subplot(1, numel( params.alignEvent ), iEvent); hold on;     
        % make width proprotional to this epoch's duration
        myPos =  get( axh(iEvent), 'Position');
        set( axh(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )
        xlabel(['Time ' params.alignEvent{iEvent} ' (s)']);    
        
        for iLabel = 1 : numel( uniqueLabels )
            myLabel = uniqueLabels(iLabel);
            myLabelStr = sprintf('target%i', iLabel);

            myX = result.(myLabelStr).t{iEvent};
            myY = result.(myLabelStr).pushMean{iEvent}(:,chanInd);
            
            myMax = max([myMax, max( abs(myY) )]);

            plot( myX, myY, 'Color', colorsR8(iLabel,:), ...
                'LineWidth', 1 );
            switch params.errorMode
                case 'std'
                    myStd = result.(myLabelStr).pushStd{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
                    h = patch( px, py, colorsR8(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
%                     plot( myX, myY+myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
%                     plot( myX, myY-myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
                    myMax = max([myMax, max( abs(myY)+myStd )]);

                case 'sem'
                    mySem = result.(myLabelStr).pushSem{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
                    h = patch( px, py, colorsR8(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
                    myMax = max([myMax, max( abs(myY)+mySem )]);
                case 'none'
                    % do nothing
            end
        end
        
        % PRETTIFY
        % make horizontal axis nice
        xlim([myX(1), myX(end)])
        % make vertical axis nice
        if iEvent == 1
            ylabel( sprintf('Neural Push %s', chanStr ), 'Interpreter', 'none' );
        else
            % hide it
            yaxh = get( axh(iEvent), 'YAxis');
            yaxh.Visible = 'off';
        end
        set( axh(iEvent), 'TickDir', 'out' )
    end
    
    linkaxes(axh, 'y');
    if iDim < 3
        ylim([-ceil( myMax ) - 1 ,ceil( myMax ) + 1]);
    else
        ylim([0 ,ceil( myMax ) + 1]);
    end
    % add legend
    axes( axh(1) );
    MakeDumbLegend( legendLabelsR8, 'Color', colorsR8 );
end

% PLOT THE FRANK-METHOD:
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels(iLabel);
    myLabelStr = sprintf('target%i', iLabel);
    
    myX = result.(myLabelStr).t{iEvent};
    myY = result.(myLabelStr).unbiasedPush{iEvent};
    
    plot( myX, myY, 'Color', colorsR8(iLabel,:), ...
        'LineWidth', 2, 'LineStyle', '--' );
end


% ************************************************************************************
%%                   Speech-aligned Neural Push 
% ************************************************************************************
% go through and keep only trials that have speaking. If they have two speaking events, create two trials out of it, with one speaking. I ignore cue events, which will be a pain since they could happen on a previous trial, actually.
Rspeech = []; % will build this
for iR = 1 : numel( Rall )
    Rall(iR).blockNumber = Rall(iR).startTrialParams.blockNumber;
    if ~isempty( Rall(iR).labelSpeech )
        for iR2 = 1 : numel( Rall(iR).labelSpeech )
            myR = Rall(iR);           
            myR.timeSpeech = myR.timeSpeech(iR2);
            myR.labelSpeech = myR.labelSpeech{iR2};
            myR.eventNumberSpeech = myR.eventNumberSpeech(iR2);
            Rspeech = [Rspeech, myR];
        end
    end
end
allLabels = arrayfun(@(x) x.labelSpeech, Rspeech, 'UniformOutput', false );


% Also go through and keep only trials that have speech cue events. If they have two cue events, create two trial
% out of it, each with one cue event. 
Rcue = []; % will build this
for iR = 1 : numel( Rall )
    Rall(iR).blockNumber = Rall(iR).startTrialParams.blockNumber;
    if ~isempty( Rall(iR).labelCue )
        for iR2 = 1 : numel( Rall(iR).labelCue )
            myR = Rall(iR);           
            myR.timeCue = myR.timeCue(iR2);
            myR.labelCue = myR.labelCue{iR2};
            if ~isempty( myR.eventNumberCue ) && numel( myR.eventNumberCue ) >= iR2
                myR.eventNumberCue = myR.eventNumberCue(iR2);
            end
            Rcue = [Rcue, myR];
        end
    end
end
allLabelsCue = arrayfun(@(x) x.labelCue, Rcue, 'UniformOutput', false );


% survey the data
uniqueLabels = includeLabels( ismember( includeLabels, unique( allLabels ) ) ); % throws out any includeLabels not actually present but keeps order

% Restrict to trials of the labels we care about
Rspeech = Rspeech(ismember(  allLabels, uniqueLabels ));
allLabels = arrayfun(@(x) x.labelSpeech, Rspeech, 'UniformOutput', false );

fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( Rspeech), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.labelSpeech, uniqueLabels{iLabel} ), Rspeech ) ) )
end
result.uniqueSpeechLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;


%% Now calculate mean neural push for each speech condition
for iEvent = 1 : numel( params.alignEventSpeech )
    for iLabel = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );        
      
        jenga = AlignedMultitrialDataMatrix( Rspeech(myTrialInds), 'featureField', 'neuralPush', ...
            'startEvent', params.startEventSpeech{iEvent}, 'alignEvent', params.alignEventSpeech{iEvent}, 'endEvent', params.endEventSpeech{iEvent} );

        % DEV: Examine if there are a lot of missing snippet sor not with this alignment
        % figure; imagesc( jenga.t, [], isnan( squeeze( jenga.dat(:,:,1))) ); %

        
        result.(myLabel).t{iEvent} = jenga.t;
        result.(myLabel).pushMean{iEvent} = squeeze( nanmean( jenga.dat, 1 ) );
        result.(myLabel).pushStd{iEvent} = squeeze( nanstd( jenga.dat, [], 1 ) );
        for t = 1 : size( jenga.dat,2 )
            result.(myLabel).pushSem{iEvent}(t,:) = nansem( squeeze( jenga.dat(:,t,:) ) );
        end
        result.(myLabel).numTrials = jenga.numTrials;
        % channel names had best be the same across events/groups, so put them in one place
        result.channelNames = Rspeech(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
        
        if params.subtractBaselinePush
            % get baseline push.
            % depending on alignment used for baseline, either Rspeech or Rcue is the right R struct.
            % Ugh, I know, awful.
            if ~isempty( strfind( params.baselineAlignEventSpeech, 'timeSpeech' ) )
                myTrialIndsBaseline = strcmp( allLabels, myLabel );
                jengaBaseline = AlignedMultitrialDataMatrix( Rspeech(myTrialInds), 'featureField', 'neuralPush', ...
                    'startEvent', params.baselineStartEventSpeech, 'alignEvent', params.baselineAlignEventSpeech, 'endEvent', params.baselineEndEventSpeech );
            elseif ~isempty( strfind( params.baselineAlignEventSpeech, 'timeCue' ) )
                myTrialIndsBaseline = strcmp( allLabelsCue, myLabel );
                jengaBaseline = AlignedMultitrialDataMatrix( Rcue(myTrialInds), 'featureField', 'neuralPush', ...
                    'startEvent', params.baselineStartEventSpeech, 'alignEvent', params.baselineAlignEventSpeech, 'endEvent', params.baselineEndEventSpeech );
            else
                error(' baselineAlignEvent %s not recognzied', params.baselineAlignEventSpeech )
            end
          
            % time average and trial average to get the baseline
            result.(myLabel).baselinePush{iEvent} = squeeze( nanmean( nanmean( jengaBaseline.dat, 1 ) ) );
            % subtract this from saved push.
            result.(myLabel).pushMean{iEvent}(:,1:2) = result.(myLabel).pushMean{iEvent}(:,1:2) - ...
                repmat( result.(myLabel).baselinePush{iEvent}', size( result.(myLabel).pushMean{iEvent}, 1 ), 1 );
             % Note I'm careful about the norm having been calculated on
            % trial averaged data.              
        end
                
        % Tricky stuff: I'm going to calculate the vector norm of *single trial* neural pushes.
        % But I do it here so that I can subtract the *trial-averaged baseline push* from these
        % individual trials' neural pushes (this avoids having variance seem really large when the
        % push is fluctuating around a biased amount).
        myTrials = find( myTrialInds );
        for iTrial = 1 : nnz( myTrials )
           myTrialInd =  myTrials(iTrial);
           % calculate its vector norm push:
           % 1. start with the 2d neural push
           myNorm = Rspeech(myTrialInd).neuralPush;
           % 2. if baseline subtraction is enabled, subtract that away
           if params.subtractBaselinePush
               myNorm.dat = myNorm.dat - repmat( result.(myLabel).baselinePush{iEvent}, 1, size( myNorm.dat, 2 ) );
           end
           % 3. now take its norm at each time point
           myNorm.dat = norms( myNorm.dat );
           myNorm.channelName = {'norm'};
           % Write it back into this trial
           Rspeech(myTrialInd).neuralPushNorm = myNorm;
        end
        
        % Now compute the vector norm push. This is done from baseline-subtracted mean x,y
        result.(myLabel).pushMean{iEvent}(:,3) = norms( result.(myLabel).pushMean{iEvent}' );
        
        % Now calculate neural push SEM from the single trial norms. I write this into dim 3 of
        % pushSem.
        jengaNorm = AlignedMultitrialDataMatrix( Rspeech(myTrialInds), 'featureField', 'neuralPushNorm', ...
            'startEvent', params.startEventSpeech{iEvent}, 'alignEvent', params.alignEventSpeech{iEvent}, 'endEvent', params.endEventSpeech{iEvent} );
        for t = 1 : size( jengaNorm.dat,2 ) 
            result.(myLabel).pushSem{iEvent}(t,3) = nansem( squeeze( jengaNorm.dat(:,t,:) ) );
        end
        
        
        % record peak neural push (vector norm across both x and y push)
        myNormPush = norms( result.(myLabel).pushMean{iEvent}' );
        result.(myLabel).peakPush{iEvent} = max( result.(myLabel).pushMean{iEvent}(:,3) );
        
          % Unbiased estimate of the neural push norm (using Frank's method)
        mySingleTrialPushes = jenga.dat; % trials x time x dim
        if params.subtractBaselinePush
            mySingleTrialPushes = mySingleTrialPushes - ...
                repmat( reshape( result.(myLabel).baselinePush{iEvent}, 1, 1, []), size( mySingleTrialPushes, 1 ), size( mySingleTrialPushes, 2 ), 1 );
        end
        myUnbiasedPush = [];
        myBiasedPush = []; % for curiosity
        for iT = 1 : size( mySingleTrialPushes, 2 )
            mySamples = squeeze( mySingleTrialPushes(:,iT,:) ); % trials x 2            
            mySamples(isnan( mySamples(:,1) ),:) = []; % remove nans
            matchedZeros = zeros( size( mySamples ) ); % corresponding zeros
            myUnbiasedPush(iT) = lessBiasedDistance( mySamples, matchedZeros );
            myBiasedPush(iT) = norm( [mean(mySamples(:,1)), mean(mySamples(:,2))] ); % DEV
        end
%         figure; plot( myUnbiasedPush, 'r' ); hold on; plot( myBiasedPush, 'k'); legend( {'unbiased', 'biased'}); % DEV
        % save this
        result.(myLabel).unbiasedPush{iEvent} = myUnbiasedPush;
        result.(myLabel).peakUnbiasedPush{iEvent} = max( myUnbiasedPush );        
    end
end

%% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = speechColors( uniqueLabels{iLabel} ); 
   legendLabels{iLabel} = sprintf('%s (n=%i)', uniqueLabels{iLabel}, result.(uniqueLabels{iLabel}).numTrials );
end

%% Plot Speech Neural Push
% ------------------------

% compute how long each event-aligned time window is, so that the subplots can be made of
% the right size such that time is uniformly scaled along the horizontal axis
startAt = 0.1;
gapBetween = 0.05;
epochDurations = nan( numel( params.alignEventSpeech ), 1 );
epochStartPosFraction = epochDurations; % where within the figure each subplot starts. 
for iEvent = 1 : numel( params.alignEventSpeech )
    epochDurations(iEvent) = range( result.(myLabel).t{iEvent} );
end
% I want to fill 0.8 of the figure with both axes, and have a 0.05 gap between subplots,
epochWidthsFraction = (1 - 2*startAt  - gapBetween*(numel( epochDurations ) - 1)) * (epochDurations ./ sum( epochDurations ));
epochStartPosFraction(1) = startAt;
for iEvent = 2 : numel( epochDurations )
    epochStartPosFraction(iEvent) = epochStartPosFraction(iEvent-1) + epochWidthsFraction(iEvent-1) + gapBetween;
end
    
% -------------------------
for iDim = 1 : 3
    % identify this electrode channel in the potentially channel-reduced dat
    switch iDim
        case 1
            chanStr = 'x';
        case 2
            chanStr = 'y';
        case 3 
            chanStr = 'xy';
    end   
    chanInd = iDim;
    
    
    figh = figure;
    figh.Color = 'w';
    titlestr = sprintf('neural push speech %s %s', datasetName, chanStr);
    figh.Name = titlestr;
    axh = [];
    myMax = 0; % will be used to track max oush across all conditions.
    for iEvent = 1 : numel( params.alignEventSpeech )
        % Loop through temporal events
        axh(iEvent) = subplot(1, numel( params.alignEventSpeech ), iEvent); hold on;     
        % make width proprotional to this epoch's duration
        myPos =  get( axh(iEvent), 'Position');
        set( axh(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )
        xlabel(['Time ' params.alignEventSpeech{iEvent} ' (s)']);    
        
        for iLabel = 1 : numel( uniqueLabels )
            myLabel = uniqueLabels{iLabel};

            myX = result.(myLabel).t{iEvent};
            myY = result.(myLabel).pushMean{iEvent}(:,chanInd);
            
            myMax = max([myMax, max( abs(myY) )]);

            plot( myX, myY, 'Color', colors(iLabel,:), ...
                'LineWidth', 1 );
            switch params.errorMode
                case 'std'
                    myStd = result.(myLabel).pushStd{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
%                     plot( myX, myY+myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
%                     plot( myX, myY-myStd, 'Color', colors(iLabel,:), ...
%                         'LineWidth', 0.3 );
                    myMax = max([myMax, max( abs(myY)+myStd )]);

                case 'sem'
                    mySem = result.(myLabel).pushSem{iEvent}(:,chanInd);
                    [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
                    h = patch( px, py, colors(iLabel,:), 'FaceAlpha', FaceAlpha, ...
                        'EdgeColor', 'none');
                    myMax = max([myMax, max( abs(myY)+mySem )]);
                case 'none'
                    % do nothing
            end
        end
        
        % PRETTIFY
        % make horizontal axis nice
        xlim([myX(1), myX(end)])
        % make vertical axis nice
        if iEvent == 1
            ylabel( sprintf('Neural Push %s', chanStr ), 'Interpreter', 'none' );
        else
            % hide it
            yaxh = get( axh(iEvent), 'YAxis');
            yaxh.Visible = 'off';
        end
        set( axh(iEvent), 'TickDir', 'out' )
    end
    
    linkaxes(axh, 'y');
    if iDim < 3
        ylim([-ceil( myMax ) - 1 ,ceil( myMax ) + 1]);
    else
        ylim([0 ,ceil( myMax ) + 1]);
    end
    % add legend
    axes( axh(1) );
    MakeDumbLegend( legendLabels, 'Color', colors );
end

% PLOT THE FRANK-METHOD:
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    
    myX = result.(myLabel).t{iEvent};
    myY = result.(myLabel).unbiasedPush{iEvent};
    
    plot( myX, myY, 'Color', colors(iLabel,:), ...
        'LineWidth', 2, 'LineStyle', '--' );
end

%% Save the results
resultsFilename = [saveResultsRoot datasetName '_decoderPotent.mat'];
save( resultsFilename, 'result');
fprintf('Saved %s\n', resultsFilename )

