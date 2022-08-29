% Generates PSTHs for Radial 8 outward reaches and speaking during BCI, and then
% calculates these PSTHs decoder-potent neural push.
%
% Based off of WORKUP_speechWhileBCI_decoderPotent.m
%
% Sergey D. Stavisky, March 20, 2019, Stanford Neural Prosthetics Translational Laboratory
%
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

%% t5.2018.12.17 Standalone 
datasetName = 't5.2018.12.17_SpeakingAlone';
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';

decoderPath = [CachedDatasetsRootNPTL filesep 'NPTL' filesep 't5.2018.12.17' filesep 'Data' filesep 'Filters' filesep];

% This is the decoder used for the first block-set of speak-during-BCI 
decoderName = '003-blocks004_006-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat';

params.excludeChannels = [];


%% t5.2018.12.12 Standalone
% datasetName = 't5.2018.12.12_SpeakingAlone';
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% decoderPath = [CachedDatasetsRootNPTL filesep 'NPTL' filesep 't5.2018.12.12' filesep 'Data' filesep 'Filters' filesep];
% 
% % This is the decoder used for the first block-set of speak-during-BCI 
% decoderName = '002-blocks004-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat';
% params.excludeChannels = [];



%% R structs during bci are one per block. Just lookup based on first
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing
    

%% Analysis Parameters

% TRIAL INCLUSION
params.maxTrialLength = 10000; %throw out trials > 10 seconds

% note: RMS is calculated from the decoder.
params.neuralFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% SPEECH PARAMETERS
params.alignEventSpeech{1} = 'handResponseEvent';
params.startEventSpeech{1} = 'handResponseEvent - 2.000';
params.endEventSpeech{1} = 'handResponseEvent + 2.000';


% Baseline epoch: used to compute change in neural push
params.subtractBaselinePush = true;
% params.subtractBaselinePush = false;


% new way:
params.baselineAlignEventSpeech = 'handCueEvent';
params.baselineStartEventSpeech = 'handCueEvent - 0.500';
params.baselineEndEventSpeech = 'handCueEvent';

% for pixels/second converion
params.externalGain = 5000; % taken from param scripts and log.

result.params = params;
result.params.Rfile = Rfile;

% Some aesthetics
FaceAlpha = 0.3; % 
params.errorMode = 'sem'; % for plotting neural push

%% Load the data

in = load( Rfile );
Rall = in.R;
fprintf('Loaded %s (%i trials)\n', Rfile, numel( Rall ) )

    
%% Add event times
uniqueLabels = includeLabels( ismember( includeLabels, unique( {Rall.label} ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [Rall.blockNumber] );
% Restrict to trials of the labels we care about
Rall = Rall(ismember(  {Rall.label}, uniqueLabels ));



% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
alignMode = 'handLabels';
uniqueBlocks = unique( [Rall.blockNumber] );
Rnew = speechEventAlignment( Rall, Rfile, 'alignMode', alignMode, 'silenceMode', 'medianRTofAudble' );
Rall = Rnew; 

% in t5.2018.12.12 there's one trial with a handCueEvent. Get rid of it.
hasNoCue = arrayfun(@(x) isnan(x.handCueEvent), Rall );
Rall(hasNoCue) = [];
if nnz( hasNoCue ) > 0
    fprintf('Deleted %i trials without a cue event\n', nnz( hasNoCue ) )
end

clear( 'Rnew' );

% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), Rall ) ) )
end
allLabels = {Rall.label};


%% Load the decoder 
myDecoderFile = [decoderPath decoderName];
fprintf('Loading decoder %s\n', myDecoderFile )
inDecoder = load( myDecoderFile );
inDecoder = rmfield(inDecoder, 'modelsFull'); % don't need all that extra crap eating memory

%% Generate Neural Feature 
% Threshold block according to the decoder's RMS multiplier
% (NOTE: I might also consider thresholding at exact values of decoder)
RMSmultiplier = inDecoder.options.rmsMultiplier;
fprintf('Thresholding according to decoder multiplier of %g\n',  RMSmultiplier);
for iTrial = 1 : numel( Rall )
    for iArray = 1 : numArrays
        switch iArray
            case 1
                rasterField = 'spikeRaster';
            otherwise
                rasterField = sprintf( 'spikeRaster%i', iArray );
        end
        ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
        myACB = Rall(iTrial).(ACBfield);
        RMSfield = sprintf( 'RMSarray%i', iArray );
        Rall(iTrial).(rasterField) = logical( myACB <  RMSmultiplier .*repmat( Rall(iTrial).(RMSfield), 1, size( myACB, 2 ) ) );
    end
end

% fprintf('Thresholding according to decoder specific voltage values\n');
% RMS = inDecoder.model.thresholds;
% Rall = RastersFromMinAcausSpikeBand( Rall, RMS );
    

clear('in')



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
    myDecoder = inDecoder;
    binMS = myDecoder.model.dtMS;
    activeChans = 1:numel( myDecoder.model.thresholds ); % decoder wasn't using HFLP
    
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
%%                   Speech-aligned Neural Push 
% ************************************************************************************

result.uniqueSpeechLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;
allLabelsCue = allLabels; % they're the same in the speech standalone datasets

%% Now calculate mean neural push for each speech condition
for iEvent = 1 : numel( params.alignEventSpeech )
    for iLabel = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );        
      
        jenga = AlignedMultitrialDataMatrix( Rall(myTrialInds), 'featureField', 'neuralPush', ...
            'startEvent', params.startEventSpeech{iEvent}, 'alignEvent', params.alignEventSpeech{iEvent}, 'endEvent', params.endEventSpeech{iEvent} );

        result.(myLabel).t{iEvent} = jenga.t;
        result.(myLabel).pushMean{iEvent} = squeeze( nanmean( jenga.dat, 1 ) );
        result.(myLabel).pushStd{iEvent} = squeeze( nanstd( jenga.dat, [], 1 ) );
        for t = 1 : size( jenga.dat,2 )
            result.(myLabel).pushSem{iEvent}(t,:) = nansem( squeeze( jenga.dat(:,t,:) ) );
        end
        result.(myLabel).numTrials = jenga.numTrials;
        % channel names had best be the same across events/groups, so put them in one place
        result.channelNames = Rall(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
        
        if params.subtractBaselinePush
            % get baseline push.
            myTrialIndsBaseline = strcmp( allLabels, myLabel );
            jengaBaseline = AlignedMultitrialDataMatrix( Rall(myTrialInds), 'featureField', 'neuralPush', ...
                'startEvent', params.baselineStartEventSpeech, 'alignEvent', params.baselineAlignEventSpeech, 'endEvent', params.baselineEndEventSpeech );
            
          
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
           myNorm = Rall(myTrialInd).neuralPush;
           % 2. if baseline subtraction is enabled, subtract that away
           if params.subtractBaselinePush
               myNorm.dat = myNorm.dat - repmat( result.(myLabel).baselinePush{iEvent}, 1, size( myNorm.dat, 2 ) );
           end
           % 3. now take its norm at each time point
           myNorm.dat = norms( myNorm.dat );
           myNorm.channelName = {'norm'};
           % Write it back into this trial
           Rall(myTrialInd).neuralPushNorm = myNorm;
        end
        
        % Now compute the vector norm push. This is done from baseline-subtracted mean x,y
        result.(myLabel).pushMean{iEvent}(:,3) = norms( result.(myLabel).pushMean{iEvent}' );
        
        % Now calculate neural push SEM from the single trial norms. I write this into dim 3 of
        % pushSem.
        jengaNorm = AlignedMultitrialDataMatrix( Rall(myTrialInds), 'featureField', 'neuralPushNorm', ...
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
result.params = params;
result.uniqueSpeechLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
resultsFilename = [saveResultsRoot datasetName '_decoderPotent.mat'];
save( resultsFilename, 'result');
fprintf('Saved %s\n', resultsFilename )

