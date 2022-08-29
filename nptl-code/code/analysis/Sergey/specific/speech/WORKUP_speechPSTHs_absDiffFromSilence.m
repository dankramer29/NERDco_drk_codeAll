% Generates PSTHs of specified example electrodes, as well as plotting a difference from
% baseline over time, 
%
% Doesn't do anova for tuning, that's now broken out in a different function for clarity.
%
% Sergey Stavisky, December 14 2017
%
% There was an earlier version of this called WORKUP_cueAndSpeechPSTHs.m that operated on
% pilot data. This is a more cleaned up version.
%
% This one is to test doing firing rate differences compared to SILENCE, rather than
% baseline
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
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
% params.acceptWrongResponse = false;


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;




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
participant = 't8';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-18_-4.5RMSexclude' );
params.acceptWrongResponse = false;
[params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );

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
% Align to speak go cue.
% params.alignEvent{1} = 'handPreResponseBeep';
% params.startEvent{1} = 'handPreResponseBeep - 0.2';
% params.endEvent{1} = 'handPreResponseBeep + 0.5';
% 
% % When audible speaking started (based on hand-annotated audio data)
% params.alignEvent{2} = 'handResponseEvent';
% params.startEvent{2} = 'handResponseEvent - 0.6';
% params.endEvent{2} = 'handResponseEvent + 1';


% -----------------------------------------------------
% This parameter set is for the supplementary figure showing that firing rates change much
% more around speaking than around cue.
% Align to speak go cue.
params.alignEvent{1} = 'handCueEvent';
params.startEvent{1} = 'handCueEvent - 0.500';
params.endEvent{1} = 'handCueEvent + 1.0';

% When audible speaking started (based on hand-annotated audio data)
params.alignEvent{2} = 'handPreResponseBeep';
params.startEvent{2} = 'handPreResponseBeep - 0.500';
params.endEvent{2} = 'handPreResponseBeep + 2'; 

% window in which to compare firing rate deviation (from baseline) 
% across the two epochs.
params.compareWindow{1} = [0 1]; % in seconds, relative to params.alignEvent{1}
params.compareWindow{2} = [0 1.75]; % in seconds, relative to params.alignEvent{2}


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

% Baseline firing rate epoch: used to plot average absolute deviation from baseline
params.baselineAlignEvent = 'handPreCueBeep';
params.baselineStartEvent = 'handPreCueBeep - 1.250';
params.baselineEndEvent = 'handPreCueBeep - 0.750';




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



%% All channels response.


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
maxDeviationsFromSilence = nan( numel( uniqueLabels ), numel( params.alignEvent ) ); % label, event
meanDeviationsFromSilence = nan( numel( uniqueLabels ), numel( params.alignEvent ) ); % label, event

for iEvent = 1 : numel( params.alignEvent )
    axh_baseline(iEvent) = subplot(1, numel( params.alignEvent ), iEvent); hold on;           
    myPos =  get( axh_baseline(iEvent), 'Position');
    set( axh_baseline(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )

    xlabel([params.alignEvent{iEvent} ' (s)']);
    for iLabel = 2 : numel( uniqueLabels ) % start at 2 so as to not do silence
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );
        % subtract silence
        result.(myLabel).psthDiffFromSilence{iEvent} = result.(myLabel).psthMean{iEvent} - result.silence.psthMean{iEvent};
        result.(myLabel).meanAbsDiffFromSilence{iEvent} = mean( abs( result.(myLabel).psthDiffFromSilence{iEvent} ), 2 ); % average across channels.

        
        % PLOT IT
        myX = result.(myLabel).t{iEvent};
        myY = result.(myLabel).meanAbsDiffFromSilence{iEvent};
        plot( myX, myY, 'Color', colors(iLabel,:), ...
            'LineWidth', 1 );
       
       
       % Compute maximum deviation (from silence) within the analysis epoch
       [~, myStartInd{iEvent}] = FindClosest( result.(myLabel).t{iEvent}, params.compareWindow{iEvent}(1) );
       [~, myEndInd{iEvent}] = FindClosest( result.(myLabel).t{iEvent}, params.compareWindow{iEvent}(2) );       

       %speaking/moving conditions
       maxDeviationsFromSilence(iLabel, iEvent) =  max( result.(myLabel).meanAbsDiffFromSilence{iEvent}(myStartInd{iEvent}:myEndInd{iEvent}) );
       meanDeviationsFromSilence(iLabel, iEvent) =  mean( result.(myLabel).meanAbsDiffFromSilence{iEvent}(myStartInd{iEvent}:myEndInd{iEvent}) );
      
       % plot its mean deviation from baseline
       lh = line( [params.compareWindow{iEvent}(1), params.compareWindow{iEvent}(2)], [mean( result.(myLabel).meanAbsDiffFromSilence{iEvent}(myStartInd{iEvent}:myEndInd{iEvent}) ) mean( result.(myLabel).meanAbsDiffFromSilence{iEvent}(myStartInd{iEvent}:myEndInd{iEvent}) )], ...
           'LineWidth', 0.5, 'Color', speechColors( myLabel ) );
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

% Plot analysis epochs
myY = get( axh_baseline(1), 'YLim' );
myY = myY(2)-0.05*range( myY );
line( params.compareWindow{1}, [myY myY], 'LineWidth', 1.5, 'Color', 'k' )
axes(  axh_baseline(2) );
line( params.compareWindow{2}, [myY myY], 'LineWidth', 1.5, 'Color', 'k' )




% Report maximum deviation ratio between the epochs
[p, h] = signrank( meanDeviationsFromSilence(:,1), meanDeviationsFromSilence(:,2) );
meanDeviationEachEpoch = nanmean( meanDeviationsFromSilence );
fprintf('Mean deviations from silence are:\n%s\n', mat2str( meanDeviationEachEpoch ) );
fprintf('p = %g (sign-rank, using each labels epoch1 and epoch2)\n', p );
fprintf( 'Ratio of epoch 2 mean to epoch 1 mean is: %.2f\n', ...
    meanDeviationEachEpoch(2) / meanDeviationEachEpoch(1) );





