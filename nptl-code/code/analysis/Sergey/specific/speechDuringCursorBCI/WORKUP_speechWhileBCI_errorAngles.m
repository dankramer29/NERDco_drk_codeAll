% Generates speak go cue aligned neural push error angles
% for the speaking DURING BCI datasets' Radial 8 task.
% ALSO does cursor speed.
% Can operate on a list of R structs from multiple sessions.
%
% 
% Sergey D. Stavisky, March 10, 2019, Stanford Neural Prosthetics Translational Laboratory
%
clear
rng(1)

saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/errorAngle/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
saveResultsRoot = [ResultsRootNPTL '/speechDuringBCI/errorAngle/']; % I don't think there will be results file generated



%% Dataset specification


%% t5.2018.12.12 and t5.2018.12.17 During BCI 
datasetName = 't5.2018.12.17_and_t5.2018.12.12_R8_BCI';
participant = 't5';
Rfile = {...
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B7.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B9.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B10.mat';
    '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12_B12.mat';
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

%% t5.2018.12.17 During BCI (interlaved during BCIr)
% datasetName = 't5.2018.12.17_R8_BCI';
% participant = 't5';
% Rfile = {...
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B8.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B9.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B10.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B11.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B12.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B13.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B16.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B17.mat';    
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B18.mat';
%     '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17_B19.mat';
% };
% 
% % params.excludeChannels = [1:96];
% % params.excludeChannels = [97:192];
% params.excludeChannels = [];



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
% 


%% R structs during bci are one per block. Just lookup based on first
includeLabels = labelLists( Rfile{1} ); % lookup;
numArrays = 2; % don't anticipate this changing




%% Analysis Parameters

% TRIAL INCLUSION
params.maxTrialLength = 10000; %throw out trials > 10 seconds

params.ignoreMSafterTargetOn = 200; % don't compute error angles this many ms after target on to account for visual latency + get-going time

% THRESHOLD CROSSINGS
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% Time epochs to plot. There can be be multiple, in a cell array, and it'll plot these as
% subplots side by side.
params.alignEvent = 'timeCue';
params.startEvent = 'timeCue - 1.000';
params.endEvent = 'timeCue + 2.000';


% params.errorMode = 'std'; % none, std, or sem
params.errorMode = 'sem'; % none, std, or sem


result.params = params;
result.params.Rfile = Rfile;

% for pixels/second converion
params.externalGain = 5000; % taken from param scripts and log. Doesn't matter at all for this since angle is what counts

% Some aesthetics
FaceAlpha = 0.3; % 


%% Load the data
% Will load one block at a time. Will also get the decoders used in each.
Rall = [];
allDecoders = {};

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
    prependFields = [prependFields; 'currentTarget'];
    % add some specific ones for these data
    updateFields = [updateFields; ...
        'timeTargetOn';
        'timeTrialEnd'
        'timeCue';
        'timeSpeech';
        ];
    fprintf('Prepending and appending trials to allow for alignment to speech event even at start/end of trial\n')
    in.R = PrependPrevTrialRastersAndKin( in.R, ...
        'prependFields', prependFields, 'updateFields', updateFields, 'appendTrials', true );

    
    % Load the decoder for this block
    myDecoderName = deblank( in.R(3).decoderD.filterName ); % remove trailing white space. Sometimes trial 1 or 2 doesn't have decoder, so just go with 3
    
    % decoder path is derived from experiment name 
    participantDate = Rfile{iR}(strfind( Rfile{iR}, 'R_' )+2:strfind( Rfile{iR}, '_B' )-1);
    decoderPath = [CachedDatasetsRootNPTL filesep 'NPTL' filesep participantDate filesep 'Data' filesep 'Filters' filesep];
    myDecoderFile = [decoderPath myDecoderName];
    fprintf('Loading decoder %s\n', myDecoderFile )
    inDecoder = load( myDecoderFile );
    inDecoder = rmfield(inDecoder, 'modelsFull'); % don't need all that extra crap eating memory
    allDecoders{iR} = inDecoder;
    % note in each trial which decoder they use.
    for iTrial = 1 : numel( in.R )
        in.R(iTrial).decoderLookupInd = iR;
    end
    
     % annotate it with block number and condition
    for iTrial = 1 : numel( in.R )
        in.R(iTrial).blockNum = in.R(iTrial).startTrialParams.blockNumber;
        % did previous trial have a speech cue?
        in.R(iTrial).prevTrialHasCue = false;
        if (iTrial > 1) && (in.R(iTrial).trialNum == in.R(iTrial-1).trialNum+1)
            % yes, we have a previous trial available
            if any( ~isnan( in.R(iTrial-1).timeCue ) )
                in.R(iTrial).prevTrialHasCue = true;
            end
        end
    end
    
    % Threshold each block individually (somewhat adapts to changing RMS across blocks)
    fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
    RMS{iR} = channelRMS( in.R );
    in.R = RastersFromMinAcausSpikeBand( in.R, params.thresholdRMS .*RMS{iR} );
   
    Rall = [Rall, in.R];
end
clear('in')



%% Exclude trials based on trial length. I do this early to avoid gross 3+ audio events
% trials
tooLong = [Rall.trialLength] > params.maxTrialLength;
fprintf('Removing %i/%i (%.2f%%) trials for having length > %ims\n', ...
    nnz( tooLong ), numel( tooLong ), 100*nnz( tooLong )/numel( tooLong ), params.maxTrialLength )
Rall(tooLong) = [];



%% go through and keep only trials that have go cue. These become R
% If they have two cue events, create two trials out of it, so each only has one cue
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

% Restrict to successful trials
R = R([R.isSuccessful]);
fprintf(' %i successful trials\n', numel( R ) );

allLabels = arrayfun(@(x) x.labelCue, R, 'UniformOutput', false ); % uses CUE for label
uniqueLabels = unique( allLabels );
blocksPresent = unique( [R.blockNumber] );

fprintf('Neural push error angle from %i trials across %i blocks with % i labels:\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf('cued %s %i trials\n', uniqueLabels{iLabel}, nnz( strcmp( allLabels, uniqueLabels{iLabel} ) ) );
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;

%% Create faux cue times in pristine trials by randomly sampling from the actual cue times.
% Step 1: get list of timeCue from the cued trials
% Recall that R at this stage is just trials with go cue
allCueTimes = [R.timeCue];
allPrependMS = zeros( size( allCueTimes ) ); % trial with no prepend ([]) gets 0
for i = 1 : numel( R )
    if isempty( R(i).prependMS )
        allPrependMS(i) = 0;
    else
        allPrependMS(i) = R(i).prependMS;
    end
end        
% subtract prepend time
allCueTimesNoPrepend = allCueTimes - allPrependMS;

% Step 2: Get pristine trials
% I'm also including the trial that follows a speech cue, which allows for both 
% speaking that rolls into the next trial, and some lingering attentional interference.

hasCueTrials = arrayfun( @(x) any(~isnan( x.timeCue ) ), Rall );
followsCueTrials = [Rall.prevTrialHasCue];

% non-speaking pristine
pristineTrials = ~(hasCueTrials | followsCueTrials);
fprintf('\n%i ''pristine'' trials with no cue and not following a cue trial. Faux cues added\n',...
    nnz( pristineTrials ) )

% Step 3: write a faux cue time to each of these pristine trials
pristineTrialInds = find( pristineTrials );
for i = 1 : numel( pristineTrialInds)
   myInd =  pristineTrialInds(i);
   % Method 1: Pick from the distribution of actual cue times
%    hasTime = false;
%    while hasTime == false
%           diceroll = allCueTimesNoPrepend(randperm( numel( allCueTimesNoPrepend ), 1 ));
%           myPrepend =  Rall(myInd).prependMS;
%           if isempty( myPrepend )
%               myPrepend = 0;
%           end
%           myFauxCueTime = diceroll + myPrepend; % account for prependMS
%           
%           if myFauxCueTime > myPrepend && myFauxCueTime < numel( Rall(myInd).clock )
%               % great, this faux cue falls within the tiral.
%                  Rall(myInd).timeCue = myFauxCueTime; 
%                  hasTime = true;
%           end
%    end
%     keyboard
    % Method 2: Pick uniform from within this trial (the actual trial, not including
    % prepend/append)
    myPrepend =  Rall(myInd).prependMS;
    if isempty( myPrepend )
        myPrepend = 0;
    end
    myEndThisTrial = numel( Rall(myInd).clock );
    Rall(myInd).timeCue = round( rand*(myEndThisTrial-myPrepend) + myPrepend );

end

% CHECK:
% Number of CUE trials with timeCue that happens after the end of the trial
trialLength_cued = arrayfun( @(x) numel( x.clock ), R );
cueTime_cued = [R.timeCue];
fprintf('%i CUED trials have cue after end of trial\n', nnz( trialLength_cued - cueTime_cued < 1) )
% Number of PRISTINE trials with timeCue that happens after the end of the trial
trialLength_pristine = arrayfun( @(x) numel( x.clock ), Rall(pristineTrials) );
cueTime_pristine = [Rall(pristineTrials).timeCue];
fprintf('%i PRISTINE trials have cue after end of trial\n', nnz( trialLength_pristine - cueTime_pristine < 1) )



% Step 4: append these to the cued trials. Keep indices of which are which.
cuedTrialIdx = [ones( numel( R), 1 ); zeros( nnz( pristineTrials ), 1 )];
pristineTrialIdx = [zeros( numel( R), 1 ); ones( nnz( pristineTrials ), 1 )];
R = [R, Rall(pristineTrials)];
allLabels = arrayfun(@(x) x.labelCue, R, 'UniformOutput', false ); % uses CUE for label. Empty for pristine trials
% now R is cued trials and pristine trials

%% Generate neural feature
R = AddFeature( R, params.neuralFeature  );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
end



%% Generate neural push for each trial
taskDims = 1:2; % this is a xy task
fprintf('Adding neural push and error angle and cursor speed to all trials...\n')
for iTrial = 1 : numel( R )
    % What is my decoder?
    myDecoder = allDecoders{R(iTrial).decoderLookupInd};
    binMS = myDecoder.model.dtMS;
    activeChans = 1:numel(RMS{R(iTrial).decoderLookupInd}); % decoder wasn't using HFLP
    
    % K is M2
    velProjector = double( myDecoder.model.K([2,4],: ) );
    velProjector = velProjector(:,activeChans)'; % spikes only, chans x 2    
    
    
    % NEW
    % Convert firing rates to binned spike counts (as the decoder expects) 
    myNeural = R(iTrial).(params.neuralFeature).dat;
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

    myOffsetNeural = myNeural - repmat( decoderOffset, 1, R(iTrial).(params.neuralFeature).numSamples );
    myNeuralPush = myOffsetNeural' * velProjector; % time x 2
    
    % Convert to pixels/second
    alpha = myDecoder.model.alpha;
    myNeuralPush = myNeuralPush .* 1000 .* params.externalGain .* (1/(1-alpha));
    
    % I want to keep it as a contDatObject, since its timestamps don't quite line up with the
    % MS trial stuff because of the clipping in smoothed neural data. So I'll just make a
    % copy of the neural feature and put neural push into that
    R(iTrial).neuralPush = R(iTrial).(params.neuralFeature);
    R(iTrial).neuralPush.dat = myNeuralPush';
    R(iTrial).neuralPush.channelName = {'vx', 'vy'};
    
          
    % create an error angle contDatObject by copying neural push
    R(iTrial).errorAngle = R(iTrial).neuralPush;
    R(iTrial).errorAngle.dat = nan(1, size( R(iTrial).errorAngle.dat, 2 ) );
    R(iTrial).errorAngle.channelName = {'abs error angle'};
    
    % Next compute error angle
    for iT = 1 : R(iTrial).neuralPush.numSamples
        % based on this time (in seconds), what MS sample into the R struct is it?
        myMS = round( 1000.*R(iTrial).neuralPush.t(iT) );      
        
        % Rule 1: if the cursor is over the target don't count it
        STATE_ACQUIRE = 4;
        if R(iTrial).state(myMS) == STATE_ACQUIRE
            myAngle = nan;    
       
        % Rule 2: if it is less than 100 ms after target on, don't count it.
        % but from previous trial is OK, hence myMS > >= R(iTrial).timeTargetOn
        elseif myMS >= R(iTrial).timeTargetOn && myMS <= R(iTrial).timeTargetOn + params.ignoreMSafterTargetOn
            myAngle = nan;
            
        else 
            %OK now compute error angle.
            % where's my current target and position?
            myTarget = R(iTrial).currentTarget(taskDims,myMS);
            myPos = R(iTrial).cursorPosition(taskDims,myMS);
            % what is its angle from my current position?
            toTargetVector = myTarget - myPos;
            % convert to an angle
            toTargetAngleDeg = rad2deg( cart2pol( toTargetVector(1), toTargetVector(2) ) );
            
            % neural push angle:
            myInstPush = R(iTrial).neuralPush.dat(:,iT);
            myInstPushAngleDeg =  rad2deg( cart2pol( myInstPush(1), myInstPush(2) ) );
            
            myAngle = toTargetAngleDeg - myInstPushAngleDeg;
            myAngle = abs( toTargetAngleDeg - myInstPushAngleDeg );
            % circular wrap
            if myAngle > 180
                myAngle = 360 - myAngle ;
            end            
        end
        R(iTrial).errorAngle.dat(iT) = myAngle;            
    end 
    
    % ADD CURSOR SPEED (ms basis)
    posDiff =  diff( R(iTrial).cursorPosition(taskDims,:)' );    
    mySpeed = abs( posDiff );
    % convert to speed across all dimensions
    mySpeed = 1000*sqrt( nansum( mySpeed.^2,2 ) ); % pixels / second       
    R(iTrial).speed = [nan mySpeed']; % prepend one nan because diff loses 1 ms
end



%% Make trial-averaged neural angle error and speed
% I do it for the silence trials and for all the other
for iCond = 1 : 3
    switch iCond
        case 1 
            myCondStr = 'pristine';
            myTrialIdx = logical( pristineTrialIdx );
        case 2
            myCondStr = 'cuedSilent';
            myTrialIdx = logical( strcmp( allLabels, 'silence')' & cuedTrialIdx );
        case 3
            myCondStr = 'cuedVerbal';
            myTrialIdx = logical( ~strcmp( allLabels, 'silence')' & cuedTrialIdx );
    end

    % ERROR ANGLE   
    jenga = AlignedMultitrialDataMatrix( R(myTrialIdx), 'featureField', 'errorAngle', ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myCondStr).t = jenga.t;
    result.(myCondStr).angleMean = squeeze( nanmean( jenga.dat, 1 ) );
    result.(myCondStr).angleStd = nanstd( jenga.dat, [], 1 );
    result.(myCondStr).angleSem = nansem( jenga.dat, [], 1 );  
    result.(myCondStr).numTrials = jenga.numTrials;
    result.(myCondStr).angleJenga = jenga;
    
  
    % CURSOR SPEED
    jenga = AlignedMultitrialDataMatrix( R(myTrialIdx), 'featureField', 'speed', ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myCondStr).t = jenga.t;
    result.(myCondStr).speedMean = squeeze( nanmean( jenga.dat, 1 ) );
    result.(myCondStr).speedStd = nanstd( jenga.dat, [], 1 );
    result.(myCondStr).speedSem = nansem( jenga.dat, [], 1 );  
    result.(myCondStr).speedJenga = jenga;
    
    legendLabels{iCond} = sprintf('%s n=%i', myCondStr, jenga.numTrials );
end

% Stat test sample by sample

% compare cuedVerbal to cuedSilent: ANGLE
pVals = nan( result.cuedVerbal.angleJenga.numSamples, 1 );
for t = 1 : result.cuedVerbal.angleJenga.numSamples
    verbalDat = result.cuedVerbal.angleJenga.dat(:,t);
    silentDat = result.cuedSilent.angleJenga.dat(:,t);
    pVals(t) = ranksum( verbalDat, silentDat );
end
result.pVals_angle_verbalVsSilent= pVals;


% compare cuedVerbal to cuedSilent: SPEED
pVals = nan( result.cuedVerbal.speedJenga.numSamples, 1 );
for t = 1 : result.cuedVerbal.speedJenga.numSamples
    verbalDat = result.cuedVerbal.speedJenga.dat(:,t);
    silentDat = result.cuedSilent.speedJenga.dat(:,t);
    pVals(t) = ranksum( verbalDat, silentDat );
end
result.pVals_speed_verbalVsSilent= pVals;

%% Plot this dataset: ANGLE
colors = [...
    .3 .3 .3; % gray for pristine
    .42 0.01 .49; %purple for cued silent
    .99 0.5 .62]; % pink for cued verbal
    
% ------------------------


figh = figure;
figh.Color = 'w';
titlestr = sprintf( 'error angle %s', datasetName );
figh.Name = titlestr;
axh = axes;
xlabel(['Time ' params.alignEvent ' (s)']);
hold on;
    
for iCond = 1 : 3
    switch iCond
        case 1
            myCondStr = 'pristine';
        case 2
            myCondStr = 'cuedSilent';
        case 3
            myCondStr = 'cuedVerbal';
    end        
    myX = result.(myCondStr).t;
    myY = result.(myCondStr).angleMean;
    plot( myX, myY, 'Color', colors(iCond,:), ...
        'LineWidth', 1 );
    switch params.errorMode
        case 'std'
            myStd = result.(myCondStr).angleStd;
            [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
            h = patch( px, py, colors(iCond,:), 'FaceAlpha', FaceAlpha, ...
                'EdgeColor', 'none');
            
        case 'sem'
            mySem = result.(myCondStr).angleSem;
            [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
            h = patch( px, py, colors(iCond,:), 'FaceAlpha', FaceAlpha, ...
                'EdgeColor', 'none');
        case 'none'
            % do nothing
    end
end
    
% PRETTIFY
% make horizontal axis nice
xlim([myX(1), myX(end)])
% make vertical axis nice
ylabel('|error angle|' );
set( axh, 'TickDir', 'out' )
MakeDumbLegend( legendLabels, 'Color', colors );

% SIGNIFICANCE
yValSig = axh.YLim(end)-1;
for t = 2 : result.cuedVerbal.angleJenga.numSamples
    myP = result.pVals_angle_verbalVsSilent(t);
    
    if myP < 0.01
        myX = [result.cuedVerbal.angleJenga.t(t-1) result.cuedVerbal.angleJenga.t(t)];

        
        
        
        if myP < 0.001
            lWidth = 5;
            extraString = '***';
        elseif myP < 0.01
            lWidth = 2;
            extraString = '';
        end
        fprintf('At t=%g, p=%g %s\n', myX(2), myP, extraString )

        slh(t) = line( myX, [yValSig yValSig], 'Color', 'k', 'LineWidth', lWidth );
    end
end

%% %Plot this dataset: SPEED

figh = figure;
figh.Color = 'w';
titlestr = sprintf( 'speed %s', datasetName );
figh.Name = titlestr;
axh = axes;
xlabel(['Time ' params.alignEvent ' (s)']);
hold on;
    
for iCond = 1 : 3
    switch iCond
        case 1
            myCondStr = 'pristine';
        case 2
            myCondStr = 'cuedSilent';
        case 3
            myCondStr = 'cuedVerbal';
    end        
    myX = result.(myCondStr).t;
    myY = result.(myCondStr).speedMean;
    plot( myX, myY, 'Color', colors(iCond,:), ...
        'LineWidth', 1 );
    switch params.errorMode
        case 'std'
            myStd = result.(myCondStr).speedStd;
            [px, py] = meanAndFlankingToPatchXY( myX, myY, myStd );
            h = patch( px, py, colors(iCond,:), 'FaceAlpha', FaceAlpha, ...
                'EdgeColor', 'none');
            
        case 'sem'
            mySem = result.(myCondStr).speedSem;
            [px, py] = meanAndFlankingToPatchXY( myX, myY, mySem );
            h = patch( px, py, colors(iCond,:), 'FaceAlpha', FaceAlpha, ...
                'EdgeColor', 'none');
        case 'none'
            % do nothing
    end
end
    
% PRETTIFY
% make horizontal axis nice
xlim([myX(1), myX(end)])
% make vertical axis nice
ylabel('cursor speed (px/s)' );
set( axh, 'TickDir', 'out' )
MakeDumbLegend( legendLabels, 'Color', colors );

% SIGNIFICANCE
yValSig = axh.YLim(end)-1;
for t = 2 : result.cuedVerbal.speedJenga.numSamples
    myP = result.pVals_speed_verbalVsSilent(t);
    
    if myP < 0.01
        myX = [result.cuedVerbal.speedJenga.t(t-1) result.cuedVerbal.speedJenga.t(t)];
        fprintf('At t=%g, p=%g\n', myX(2), myP )

        if myP < 0.001
            lWidth = 3;
        elseif myP < 0.01
            lWidth = 2;
        end
        slh(t) = line( myX, [yValSig yValSig], 'Color', 'k', 'LineWidth', lWidth );
    end
end

%% Save results
resultsFilename = [saveResultsRoot datasetName '_angleAndSpeed.mat'];
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end

save( resultsFilename, 'result');
fprintf('Saved %s\n', resultsFilename )




