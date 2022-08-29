% Generates PSTHs of specified example electrodes, as well as plotting a difference from
% baseline over time, 
%
% Doesn't do anova for tuning, that's now broken out in a different function for clarity.
%
% Sergey Stavisky, December 14 2017
%
% There was an earlier version of this called WORKUP_cueAndSpeechPSTHs.m that operated on
% pilot data. This is a more cleaned up version.
clear


saveFiguresDir = [FiguresRootNPTL '/speech/psths/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end


neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = false; % false by default, needs to be enabled below
%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted. The RESPONSE label ('ga' in above example) is used as the label for this trial.



% t5.2017.10.23 Phonemes
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = true;
% rasterExampleChan = [];
% % rasterExampleChan = 'chan_1.20'; % if not empty, will plot spike rasters for this channel with same timings are PSTHs
% % rasterExampleChan = 'unit4(4)_array1_elec13(13)';
% % rasterExampleChan = 'unit15(3)_array2_elec4(100)';
% % plotChannels = {'unit4(4)_array1_elec13(13)', 'unit15(3)_array2_elec4(100)'};
% % plotChannels = {'chan_2.4', 'chan_1.66', 'chan_2.7', 'chan_2.91', 'chan_2.89', 'chan_2.19', 'chan_1.7', ...
% %     'chan_1.13', 'chan_1.22', 'chan_2.32', 'chan_1.37'};
% plotChannels = {'chan_2.4', 'chan_1.13', 'chan_2.91', 'chan_1.37'}; % same TCs as the neurons and also others

% t5.2017.10.23 Movements
% % participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = false;
% % rasterExampleChan = 'chan_1.20'; % if not empty, will plot spike rasters for this channel with same timings are PSTHs
% % rasterExampleChan = 'unit4(4)_array1_elec13(13)';
% % rasterExampleChan = 'unit15(3)_array2_elec4(100)';
% % plotChannels = {'unit4(4)_array1_elec13(13)', 'unit15(3)_array2_elec4(100)'}; % same as for phonemes
% plotChannels = {'unit20(8)_array2_elec36(132)', 'unit11(11)_array1_elec40(40)', 'unit28(16)_array2_elec76(172)', 'unit30(18)_array2_elec81(177)', ...
%     'unit22(10)_array2_elec39(135)', 'unit32(20)_array2_elec87(183)', 'unit31(19)_array2_elec85(181)', 'unit16(4)_array2_elec11(107)', ...
%     'unit2(2)_array1_elec4(4)', 'unit13(1)_array2_elec2(98)', 'unit24(12)_array2_elec67(163)', 'unit3(3)_array1_elec12(12)', 'unit10(10)_array1_elec37(37)' }; % other highly tuned ones

% t5.2017.10.25 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% plotChannels = {'chan_2.2', 'chan_2.95', 'chan_1.53', 'chan_2.91', 'chan_2.4', 'chan_2.66', 'chan_2.71', ...
%     'chan_2.93', 'chan_1.11', 'chan_2.37', 'chan_1.17', 'chan_2.7', 'chan_1.10', 'chan_1.19', 'chan_2.88', 'chan_1.66', 'chan_2.30', 'chan_1.37'};
% plotChannels = {'unit12(1)_array2_elec2(98)', 'unit13(2)_array2_elec4(100)', ...
%     'unit24(13)_array2_elec85(181)', 'unit5(5)_array1_elec20(20)'};
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
params.acceptWrongResponse = false;
rasterExampleChan = [];
% plotChannels = {'unit24(13)_array2_elec85(181)', 'unit5(5)_array1_elec20(20)'}; % Words supp fig
plotChannels = {'chan_2.2', 'chan_2.95'}; % Words supp fig

% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;
% % plotChannels = { 'unit35(29)_array2_elec68(164)', 'unit21(15)_array2_elec41(137)', 'unit4(4)_array1_elec45(45)', 'unit3(3)_array1_elec36(36)', ...
% %     'unit13(7)_array2_elec19(115)', 'unit36(30)_array2_elec71(167)', 'unit32(26)_array2_elec63(159)', 'unit48(42)_array2_elec93(189)', 'unit44(38)_array2_elec84(180)'};
% % plotChannels = {'chan_1.45', 'chan_1.33', 'chan_1.7', 'chan_1.1', 'chan_1.11', 'chan_2.68', 'chan_2.41', 'chan_2.71', ...
% %     'chan_1.36', 'chan_1.34', 'chan_2.67', 'chan_1.35', 'chan_2.63', 'chan_2.76', 'chan_2.64', 'chan_1.77', 'chan_1.83', 'chan_2.74', 'chan_1.71','chan_1.9'};
% rasterExampleChan = [];
% plotChannels = {'chan_2.68', 'chan_1.35'}; % same TCs as the neuron and also other



% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = false;
% % plotChannels = {'unit44(38)_array2_elec84(180)', 'unit35(29)_array2_elec68(164)'}; % same as for phonemes
% plotChannels = { 'unit11(5)_array2_elec10(106)', 'unit36(30)_array2_elec71(167)', 'unit32(26)_array2_elec63(159)', 'unit21(15)_array2_elec41(137)', 'unit22(16)_array2_elec43(139)', ...
%     'unit41(35)_array2_elec79(175)', 'unit40(34)_array2_elec78(174)', 'unit48(42)_array2_elec93(189)', 'unit3(3)_array1_elec36(36)', 'unit24(18)_array2_elec47(143)', 'unit20(14)_array2_elec39(135)', ...
%     'unit5(5)_array1_elec65(65)', 'unit6(6)_array1_elec80(80)', 'unit4(4)_array1_elec45(45)', 'unit34(28)_array2_elec66(162)' };


% % t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-18_-4.5RMSexclude' );
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );
% % plotChannels = {'unit5(5)_array1_elec45(45)', 'unit13(3)_array2_elec9(105)', 'unit40(30)_array2_elec72(168)', ...
% %     'unit6(6)_array1_elec65(65)', 'unit12(2)_array2_elec8(104)', 'unit37(27)_array2_elec66(162)', 'unit47(37)_array2_elec84(180)'};
% rasterExampleChan = [];
% 
% % plotChannels = {'chan_1.65', 'chan_1.79', 'chan_2.70', 'chan_2.35', 'chan_1.54', 'chan_1.6', 'chan_1.9', 'chan_2.72', 'chan_2.39', 'chan_1.45'};
% % plotChannels = {'chan_2.39'}; % Words supp fig
% plotChannels = {'unit47(37)_array2_elec84(180)'}; % Words supp fig


% t5.2018.12.12 Standalone
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.12-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.12-words_noRaw.mat'; 
% params.acceptWrongResponse = false;
% plotChannels = {'chan_2.2', 'chan_2.91', 'chan_2.4', 'chan_2.66', 'chan_2.71', ...
%     'chan_2.93', 'chan_1.11', 'chan_1.17', 'chan_2.7', 'chan_1.10', 'chan_1.19', 'chan_2.88', 'chan_1.66','chan_1.37'};
% rasterExampleChan = [];


% t5.2018.12.17 Standalone
% participant = 't5';
% params.excludeChannels = datasetChannelExcludeList( 't5.2018.12.17-words_-4.5RMSexclude' );
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2018.12.17-words_noRaw.mat';
% params.acceptWrongResponse = false;
% plotChannels = {'chan_2.2', 'chan_2.91', 'chan_2.4', 'chan_2.66', ...
%     'chan_2.93', 'chan_1.11', 'chan_1.17', 'chan_2.7', 'chan_1.10', 'chan_1.19', 'chan_2.88'};
% rasterExampleChan = [];


%%
includeLabels = labelLists( Rfile ); % lookup;
numArrays = 2; % don't anticipate this changing

datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly


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

% speach go and voice onset (Figure 1)

% Align to prompt
% params.alignEvent{1} = 'handCueEvent';
% params.startEvent{1} = 'handCueEvent - 0.500';
% params.endEvent{1} = 'handCueEvent + 1.0';
% 
% % Align to speak go cue.
% params.alignEvent{2} = 'handPreResponseBeep';
% params.startEvent{2} = 'handPreResponseBeep - 0.2';
% params.endEvent{2} = 'handPreResponseBeep + 0.5';
% % 
% % % When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{3} = 'handResponseEvent';
% params.startEvent{3} = 'handResponseEvent - 0.6';
% params.endEvent{3} = 'handResponseEvent + 1';


% -----------------------------------------------------
% This parameter set is for the supplementary figure  - longer epochs
% Align to speak go cue.
params.alignEvent{1} = 'handCueEvent';
params.startEvent{1} = 'handCueEvent - 0.500';
params.endEvent{1} = 'handCueEvent + 1.0';

params.alignEvent{2} = 'handPreResponseBeep';
params.startEvent{2} = 'handPreResponseBeep - 0.3';
params.endEvent{2} = 'handPreResponseBeep + 0.7';

% When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{2} = 'handPreResponseBeep';
% params.startEvent{2} = 'handPreResponseBeep - 0.500';
% params.endEvent{2} = 'handPreResponseBeep + 2'; 
params.alignEvent{3} = 'handResponseEvent';
params.startEvent{3} = 'handResponseEvent - 0.6';
params.endEvent{3} = 'handResponseEvent + 1';


% -----------------------------------------------------

% -----------------------------------------------------
% This parameter set is for the supplementary figure showing firing rates
% during face movements
% Align to speak go cue.
% params.alignEvent{1} = 'handCueEvent';
% params.startEvent{1} = 'handCueEvent - 0.500';
% params.endEvent{1} = 'handCueEvent + 1.0';
% % 
% % % When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{2} = 'handResponseEvent';
% params.startEvent{2} = 'handResponseEvent - 0.350';
% params.endEvent{2} = 'handResponseEvent + 1.500'; 
% -----------------------------------------------------


params.errorMode = 'sem'; % none, std, or sem
params.plotPCs = 5; % Can plot top N principal components


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
if params.neuralVoiceOffset
    offsetFile = sprintf('%soffsets-%s.mat', neuralVoiceOffsetRoot, datasetName );
    load( offsetFile, 'sOffsets' );
else
    sOffsets = [];
end

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
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode, 'sOffsets', sOffsets )];
end
R = Rnew; 
clear( 'Rnew' );

% specifically for t5-5words-A, there is one NaN handCueEvent; if that's the align event,
% delete this trial
atimes = TimesOf( R, params.alignEvent{1} );
nanInd = find( isnan( atimes ) );
if ~isempty( nanInd )
    fprintf( 2, 'Removing %i trials for  having a nan %s\n', numel( nanInd ), params.alignEvent{1} )
    R(nanInd) = [];
    allLabels = {R.label};
end
    

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




%% PSTH for specified channels
% ------------------------

% SORTED PSTHS
if isempty( plotChannels )
    plotChannels = result.channelNames; % just plot all of them
end

% EMBS 2018:
% T5 Example channels (high ANOVA scores):
% plotChannels = {'chan_1.3', 'chan_1.4', 'chan_1.61', 'chan_1.64', 'chan_2.35', 'chan_2.36', 'chan_2.89', ...
%     'chan_2.90', 'chan_2.92'}; % xtalk > 0.50 ones
% plotChannels = {'chan_2.3', 'chan_2.7', 'chan_2.82', 'chan_2.84', 'chan_2.63', 'chan_2.94', 'chan_2.11', ...
%     'chan_2.12', }; % xtalk > 0.01 but less than 0.5


% plotChannels = {'chan_1.6', 'chan_1.9', 'chan_1.20', 'chan_1.37', 'chan_2.1', 'chan_2.2', 'chan_2.3', ...
%     'chan_2.4', 'chan_2.7', 'chan_2.34', 'chan_2.41', 'chan_2.85', 'chan_2.91'};
% T8 Example channels (high ANOVA scores)
% plotChannels = {'chan_1.7', 'chan_1.33', 'chan_1.1', 'chan_2.68', 'chan_2.41', 'chan_1.71', 'chan_1.34', ...
%     'chan_2.75', 'chan_2.71', 'chan_2.73', 'chan_2.69', 'chan_2.63', 'chan_2.61'};

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


%% Raster Plot

if ~isempty( rasterExampleChan )   
    if R(1).spikes.numChans == 192
        % Remove exclude channels from spikes as well, otherwise result channelNames isn't correct for this
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', 'spikes' );
    end
    chanInd = find( strcmp( result.channelNames, rasterExampleChan) );

    
    figh = figure;
    figh.Color = 'w';
    titlestr = sprintf('rasters %s %s', datasetName, rasterExampleChan);
    figh.Name = titlestr;
   

%     jenga = AlignedMultitrialDataMatrix( R, 'featureField', 'spikes', ...
%         'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );

    
    for iEvent = 1 : numel( params.alignEvent )
        % Loop through temporal events
        axh = subplot(1, numel( params.alignEvent ), iEvent); hold on;     
        % make width proprotional to this epoch's duration
        myPos =  axh.Position;
        axh.Position= [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)];
        axh.YDir = 'reverse';
        axh.YLim = [0.5 numel(R)+.5]; % number of trials
        
        xlabel(['Time ' params.alignEvent{iEvent} ' (s)']);    
        trialPtr = 1; % will increment up trial by trial across labels.
        for iLabel = 1 : numel( uniqueLabels )
            myLabel = uniqueLabels{iLabel};
            % get all of its trials, and look at this channel
            myTrialInds = strcmp( allLabels, myLabel );
            jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', 'spikes', ...
                'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );
            t = jenga.t;
            myRaster = squeeze( jenga.dat(:,:,chanInd) ); % trials x time
            % plot rasters line by line (i.e. trial by trial).
            for iTrial = 1 : size( myRaster, 1 )
                mySpikes = t(find( myRaster(iTrial,:) )); % convert to times
                myY = repmat( [trialPtr+0.5;trialPtr-0.5], 1, numel( mySpikes ) );
                lh = line( [mySpikes;mySpikes], myY, 'Color', colors(iLabel,:) );
                trialPtr = trialPtr+1;
            end
        end
        axh.XLim = [t(1) t(end)];
        % prettyify
        axh.TickDir = 'out';        
    end
    % no y ticks for last event
    axh.YTick = [];
    axh.YAxis.Visible = 'off';
end
figh.Renderer = 'painters';
% note about saving: The .mat file ends up absurdly big, but the eps is fine. So just save
% only eps.


keyboard




%% Mean firing rate and 'modulation depth'
saveComparisonRoot = [ResultsRootNPTL '/speech/breathing/'];
resultsFilename = [saveComparisonRoot datasetName '_comparison.mat'];

fprintf('Press any key to continue and generate modulation depth for comparison to breathing...\n')
keyboard

comparisonAlignEvent = 'handResponseEvent';
comparisonStartEvent = 'handResponseEvent - 2.5';
comparisonEndEvent = 'handResponseEvent + 1.0';
% Added 16 January 2019 to compare to breathing.
myTrialInds = ~strcmp( allLabels, 'silence' );
jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
    'startEvent', comparisonStartEvent, 'alignEvent', comparisonAlignEvent, 'endEvent', comparisonEndEvent);
% not 1.5 after AO because for some reason silence trials sometimes don't have data that
% far (just the way trial cutoff went, I guess). So doing same time range of breathing,
% but shifted back more.
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
    'startEvent', comparisonStartEvent, 'alignEvent', comparisonAlignEvent, 'endEvent', comparisonEndEvent );
popMeanFRSilence = squeeze( mean( mean( jenga.dat,1 ), 3 ) );
t = jenga.t;
plot( t, popMeanFRSilence, 'Color', 'k');

%% MODULATION DEPTH
speakLabels = setdiff( uniqueLabels, 'silence' );
% populate a matrix of modulation depths for each channel, for each sound label
modDepths = [];
for iLabel = 1 : numel( speakLabels )
      myLabel = speakLabels{iLabel};
      myTrialInds = strcmp( allLabels, myLabel );
      jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
          'startEvent', comparisonStartEvent, 'alignEvent', comparisonAlignEvent, 'endEvent', comparisonEndEvent );
      myPSTH = squeeze( mean( jenga.dat, 1 ) );
      for iChan = 1 : size( myPSTH, 2 )
          modDepths(iChan,iLabel) = max( myPSTH(:,iChan) ) - min( myPSTH(:,iChan) );
      end
end
% meanAcrossLabelsModDepths = mean( modDepths, 2 );
% figure; histogram( meanAcrossLabelsModDepths );

save( resultsFilename, 'popMeanFR', 't', 'modDepths');
fprintf('Saved %s\n', resultsFilename )