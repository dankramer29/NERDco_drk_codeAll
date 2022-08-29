% Generates PSTHs of specified example electrodes, and get modulation depths,
% for the dataset that Frank and Darrel collected in which T5 did the Radial 8 task either
% head still or head free.
%
% 
% Based on WORKUP_speechWhileBCI_R8_PSTHs.m
% Sergey D. Stavisky, March 29, 2019, Stanford Neural Prosthetics Translational Laboratory
%
clear


saveFiguresDir = [FiguresRootNPTL '/speechDuringBCI/psths/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
% saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated



%% Dataset specification

%% t5.2019.03.27 BCI with and without head movements
datasetName = 't5.2019.03.27_R8_headFree';
participant = 't5';
blockPaths = {...
    '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.03.27/Data/FileLogger/27/'; 
   '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.03.27/Data/FileLogger/29/';
};

% datasetName = 't5.2019.03.27_R8_headFixed';
% participant = 't5';
% blockPaths = {...
%     '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.03.27/Data/FileLogger/28/';
%    '/Users/sstavisk/CachedDatasets/NPTL/t5.2019.03.27/Data/FileLogger/30/';
% };



params.excludeChannels = [];
% plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
%     'chan_2.7', 'chan_1.17', 'chan_2.66'};

% while speaking:
% plotChannels = {'chan_2.2', 'chan_2.77', 'chan_2.7', 'chan_2.66', 'chan_2.1', 'chan_2.87', 'chan_1.10', ...
%     'chan_1.17', 'chan_1.16', 'chan_1.6'};

% These are most modulating for beet for standalone speaking
plotChannels = {'chan_1.9', 'chan_2.96', 'chan_2.81', 'chan_2.1', 'chan_1.34', 'chan_2.15', 'chan_1.6', ...
    'chan_1.33', 'chan_2.3', 'chan_2.90'};







%% Analysis Parameters
numArrays = 2; % don't anticipate this changing

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
result.params.datasetName = datasetName;

% Some aesthetics
FaceAlpha = 0.3; % 


%% Load the data
% Will load one block at a time
Rall = [];
for iR = 1 : numel( blockPaths )
    in.R = onlineR( parseDataDirectoryBlock( blockPaths{iR} ) );
    fprintf('Loaded %s (%i trials)\n', blockPaths{iR}, numel( in.R ) )
    
    % I'm going to plot cursor position from time target on to time success, which is the end
    % time. I'll create a new field for that that I then update with prepend/append, so that I
    % can tell the overhead plot to look at that.
    for iTrial = 1 : numel( in.R )
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

%%
% Exclude trials based on trial length. I do this early to avoid gross 3+ audio events
% trials
tooLong = [Rall.trialLength] > params.maxTrialLength;
fprintf('Removing %i/%i (%.2f%%) trials for having length > %ims\n', ...
    nnz( tooLong ), numel( tooLong ), 100*nnz( tooLong )/numel( tooLong ), params.maxTrialLength )
Rall(tooLong) = [];



%% go through and keep only trials that have no cue or speaking events.
% (not needed here, they all are 'pristine'
R = Rall;

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


%% Plot Overheads
figh_cursorTrajectories = OverheadTrajectories_NPTL( R, ...
    'colors', STcolor, 'startEvent', 'timeTargetOn', 'endEvent', 'timeTrialEnd', ...
    'drawMode', 'line', 'cursorSize', 0.5  );
figh_cursorTrajectories = ConvertToWhiteBackground( figh_cursorTrajectories );
titlestr = sprintf('R8 Overheads %s', dataset );
figh_cursorTrajectories.Name = titlestr;


fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blockPaths ), ...
    numel( uniqueLabels ), mat2str( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' target %i: %i trials\n', uniqueLabels(iLabel), nnz( [R.targetIdx] == uniqueLabels(iLabel) ) )
end
result.uniqueLabels = uniqueLabels;
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




