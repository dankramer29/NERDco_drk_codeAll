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
% Sep 2019: This version incorporates Frank's unbiased population distance metric. It runs
% very slowly (multiple hours).
clear



saveResultsRoot = [ResultsRootNPTL '/speech/popFiringRateDistance/compareToSilence/'];   % 
% saveResultsRoot = [ResultsRootNPTL '/speech/popFiringRateDistance/compareToSilence/oneArray/'];   % 
if ~isdir( saveResultsRoot )
    mkdir( saveResultsRoot )
end



neuralVoiceOffsetRoot = [ResultsRootNPTL '/speech/neuralVoiceOffsets/']; % directory with acoustic onset offset lags previously calcualted by WORKUP_findNeuralOnsetOffsets.m
params.neuralVoiceOffset = false; % false by default, needs to be enabled below
%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted. The RESPONSE label ('ga' in above example) is used as the label for this trial.




% t5.2017.10.23 Phonemes
% % participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.23-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-23_-4.5RMSexclude' );
% params.acceptWrongResponse = true;
% % main analysis: compare post-prompt "hearing" epoch to post-go "speaking" epoch
% params.compareWindow{1} = [0 1]; % in seconds, relative to params.alignEvent{1}
% params.compareWindow{2} = [0 1.75]; % in seconds, relative to params.alignEvent{2}
% % Secondary: compare pre-cue to post-cue
% params.baselineCompareWindow = [-0.999 0]; % in seconds, relative to params.alignEvent{1}



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
% params.compareWindow{1} = [0 1]; % in seconds, relative to params.alignEvent{1}
% params.compareWindow{2} = [0 1.75]; % in seconds, relative to params.alignEvent{2}
% % Secondary: compare pre-cue to post-cue
% params.baselineCompareWindow = [-0.999 0]; % in seconds, relative to params.alignEvent{1}


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-phonemes_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = true;
% % window in which to compare firing rate deviation 
% % across the two epochs.
% params.compareWindow{1} = [0 1]; % in seconds, relative to params.alignEvent{1}
% params.compareWindow{2} = [0.5 1.75]; % in seconds, relative to params.alignEvent{2}
% % Secondary: compare pre-cue to post-cue
% params.baselineCompareWindow = [-0.999 0]; % in seconds, relative to params.alignEvent{1}




% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.17-movements_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );
% params.acceptWrongResponse = false;
% % plotChannels = {'unit44(38)_array2_elec84(180)', 'unit35(29)_array2_elec68(164)'}; % same as for phonemes
% plotChannels = { 'unit11(5)_array2_elec10(106)', 'unit36(30)_array2_elec71(167)', 'unit32(26)_array2_elec63(159)', 'unit21(15)_array2_elec41(137)', 'unit22(16)_array2_elec43(139)', ...
%     'unit41(35)_array2_elec79(175)', 'unit40(34)_array2_elec78(174)', 'unit48(42)_array2_elec93(189)', 'unit3(3)_array1_elec36(36)', 'unit24(18)_array2_elec47(143)', 'unit20(14)_array2_elec39(135)', ...
%     'unit5(5)_array1_elec65(65)', 'unit6(6)_array1_elec80(80)', 'unit4(4)_array1_elec45(45)', 'unit34(28)_array2_elec66(162)' };


% t8.2017.10.18 Words
participant = 't8';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't8.2017.10-18_-4.5RMSexclude' );
params.acceptWrongResponse = false;
[params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );
params.compareWindow{1} = [0 1]; % in seconds, relative to params.alignEvent{1}
params.compareWindow{2} = [0.5 1.75]; % in seconds, relative to params.alignEvent{2}
% Secondary: compare pre-cue to post-cue
params.baselineCompareWindow = [-0.999 0]; % in seconds, relative to params.alignEvent{1}



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

% params.excludeChannels = union( params.excludeChannels, [1:96] ); % array 2 only
% params.excludeChannels = union( params.excludeChannels, [97:192] ); % array 1 only

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


% speach prompt and go onset (Figure 1)
% Align to audio prompt
params.alignEvent{1} = 'handCueEvent';
params.startEvent{1} = 'handCueEvent - 1.000';
params.endEvent{1} = 'handCueEvent + 1.0';

% When go cue happened (based on hand-annotated audio data)
params.alignEvent{2} = 'handPreResponseBeep';
params.startEvent{2} = 'handPreResponseBeep - 0.500';
params.endEvent{2} = 'handPreResponseBeep + 2.5'; 




% params.timeAvgSilence = true; % if true, it will compare to single trials' time-average across the plotted epoch, which might smooth things a bit?
params.timeAvgSilence = false; % if true, it will compare to single trials' time-average across the plotted epoch, which might smooth things a bit?

params.sqrtRootNorm = false; % if true, divide by sqrt( # electodes) to make for a more intuitive unit.


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



%store the maximum deviation from baseline for each condition in each epoch

for iEvent = 1 : numel( params.alignEvent )
    
    myTrialInds_silence = strcmp( allLabels, 'silence' );
    jengaSilence = AlignedMultitrialDataMatrix( R(myTrialInds_silence), 'featureField', params.neuralFeature, ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );       
    if params.timeAvgSilence
        silenceTimeAvgFR = squeeze( mean( jengaSilence.dat, 2 ) ); % trials x channels
    end
    
    
    xlabel(['Time ' params.alignEvent{iEvent} ' (s)']);
    for iLabel = 2 : numel( uniqueLabels ) % compare to silence
        myLabel = uniqueLabels{iLabel};
        myTrialInds = strcmp( allLabels, myLabel );
        %  need to compute jenga so I have each trial's rate at each time
        jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
            'startEvent', params.startEvent{iEvent}, 'alignEvent', params.alignEvent{iEvent}, 'endEvent', params.endEvent{iEvent} );       


        result.(myLabel).popDistanceFromBaseline{iEvent} = nan( jenga.numSamples, 1 );
        fprintf('   Unbiased population distances %s (this takes a while)... ', myLabel )
        % loop over time calculating pop unbiased 
        fprintf('Sample      1');
        for t = 1 : 1 : min( jenga.numSamples, jengaSilence.numSamples )
            if ~mod( t, 10)
                fprintf('\b\b\b\b%4i', t)
            end
            myRates = squeeze( jenga.dat(:,t,:) ); % trials x channels
            if params.timeAvgSilence
                mySilence = silenceTimeAvgFR;
            else                
                mySilence = squeeze( jengaSilence.dat(:,t,:) );
            end
%             myDistance = lessBiasedDistance( myRates, baselineRateAvgOverTime );
            myDistance = lessBiasedDistance( myRates, mySilence ); % compare to silence
            result.(myLabel).popDistanceFromBaseline{iEvent}(t) = myDistance;
        end
        fprintf('\n')
        if params.sqrtRootNorm
            result.(myLabel).popDistanceFromBaseline{iEvent} = result.(myLabel).popDistanceFromBaseline{iEvent} ./ sqrt( size( baselineRateAvgOverTime, 2 ) );
        end
    end

end

resultsFilename = [saveResultsRoot datasetName structToFilename( params ) '.mat'];
save( resultsFilename, 'result', 'params' )
fprintf('Saved results to %s\n%s\n', ...
    pathToLastFilesep( resultsFilename ), pathToLastFilesep( resultsFilename, 1 ) );


% ------------------------------------------
%% Get max and mean distance in each epoch and plot
% ------------------------------------------
% PLOT POP FR DISTANCE FOR EACH LABEL
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


maxDeviations = nan( numel( uniqueLabels ), numel( params.alignEvent ) ); % label, event
meanDeviations = nan( numel( uniqueLabels ), numel( params.alignEvent ) ); % label, event
meanDeviationsBaseline = nan( numel( uniqueLabels ), 1 ); % label x 1 (there's also a baseline epoch for event 1 alignment)
for iEvent = 1 : 2
    axh(iEvent) = subplot(1, numel( params.alignEvent ), iEvent); hold on;           
    myPos =  get( axh(iEvent), 'Position');
    set( axh(iEvent), 'Position', [epochStartPosFraction(iEvent) myPos(2) epochWidthsFraction(iEvent) myPos(4)] )
    xlabel( [params.alignEvent{iEvent} ' (s)']);
    axh(iEvent).TickDir = 'out';
    
    for iLabel = 2 : numel( uniqueLabels ) % don't include silence
        myLabel = uniqueLabels{iLabel};

        % PLOT THIS POP FR DISTANCE
       myX = result.(myLabel).t{iEvent};
       myY = result.(myLabel).popDistanceFromBaseline{iEvent};
       plot( myX, myY, 'Color', speechColors( myLabel ), ...
           'LineWidth', 1 );
        
        % this analysis epoch start and stop
        [~, myStartInd] = FindClosest( result.(myLabel).t{iEvent}, params.compareWindow{iEvent}(1) );
        [~, myEndInd] = FindClosest( result.(myLabel).t{iEvent}, params.compareWindow{iEvent}(2) );

        % MAX DEVIATION
        [val, ind] = max( result.(myLabel).popDistanceFromBaseline{iEvent}(myStartInd:myEndInd) );
        maxDeviations(iLabel,iEvent) = val;
        myT =  result.(myLabel).t{iEvent}(myStartInd + ind-1); % note ind was from within a subset of the t range
        % mark max
        sh = scatter( myT, val, ...
            'Marker', 'o', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', speechColors( myLabel ), 'SizeData', 64 );
        
        % MEAN DEVIATION
        meanDeviations(iLabel,iEvent) = mean( result.(myLabel).popDistanceFromBaseline{iEvent}(myStartInd:myEndInd) );
        % show it
        lh = line( params.compareWindow{iEvent}, [meanDeviations(iLabel,iEvent) meanDeviations(iLabel,iEvent)], ...
            'LineWidth', 0.5, 'Color', speechColors( myLabel ) );
        
        if iEvent == 1
            % baseline
            % this analysis epoch start and stop
            [~, myStartInd] = FindClosest( result.(myLabel).t{1}, params.baselineCompareWindow(1) );
            [~, myEndInd] = FindClosest( result.(myLabel).t{1}, params.baselineCompareWindow(2) );
            meanDeviationsBaseline(iLabel) = mean( result.(myLabel).popDistanceFromBaseline{1}(myStartInd:myEndInd) );
        end
        
    end

end

% plot analysis epochs
linkaxes( axh, 'y' )
myY = get( axh(2), 'YLim' ); % for plotting analysis epoch
myY = myY(2)-0.05*range( myY );
axes( axh(1) )
line( params.compareWindow{1}, [myY myY], 'LineWidth', 1.5, 'Color', 'k' )
line( params.baselineCompareWindow, 0.95.*[myY myY], 'LineWidth', 1.5, 'Color', 'b' ) % baseline epoch
ylabel('Unbiased pop FR distance')
axes( axh(2) )
line( params.compareWindow{2}, [myY myY], 'LineWidth', 1.5, 'Color', 'k' )
axh(2).YAxis.Visible = 'off';
axh(2).YAxis.Visible = 'off';

% Report max and mean of each epoch
meanOfMax1 = nanmean( maxDeviations(:,1) );
meanOfMax2 = nanmean( maxDeviations(:,2) );
fprintf('MAX DEVIATION: Mean across conditions 1 = %.3f, mean across conditions 2 = %.3f. ratio = %g\n', ...
    meanOfMax1, meanOfMax2, meanOfMax2/meanOfMax1 )

meanOfMean1 = nanmean( meanDeviations(:,1) );
meanOfMean2 = nanmean( meanDeviations(:,2) );
[p,h] = signrank( meanDeviations(:,1), meanDeviations(:,2) );
% [p,h] = ranksum( meanDeviations(:,1), meanDeviations(:,2) )

fprintf('MEAN DEVIATION: Mean across conditions 1 = %.3f, mean across conditions 2 = %.3f. ratio = %g, p = %g (sign-rank)\n', ...
    meanOfMean1, meanOfMean2, meanOfMean2/meanOfMean1, p )

% baseline to epoch 1 comparison
meanOfBaseline = nanmean( meanDeviationsBaseline (:,1) );
[p,h] = signrank(  meanDeviations(:,1), meanDeviationsBaseline );
fprintf('MEAN DEVIATION: Mean baseline epoch = %.3f, mean across conditions 1 = %.3f. p = %g (sign-rank)\n', ...
    meanOfBaseline, meanOfMean1 , p )
