% Generates PSTHs. Also does a check for which channels pass a simple ANOVA of firing rate
% across a large epoch (specified in params below) across any of the cues, including
% silence.
% Important: 
%
% Sergey Stavisky, September 18 2017
clear


% R struct has already been prepared by WORKUP_prepareSpeechBlocks.m, which built off of
% WORKUP_labelSpeechExptData.m. Hand-annotation of the audo (using soundLabelTool.m) 
% was already run.
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-words.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/new/R_T5_2017_09_20-phonemes.mat';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/t5.2017.09.20/R_T5_2017_09_20-thoughtSpeak.mat';
% excludeLabels = {'mm'}; % too few of these
% These channels are excised. Numbers > 96 are on array2
% burstChans = [67, 68, 69, 73, 77, 78, 82];
% smallBurstChans = [2, 46, 66, 76, 83, 85, 86, 94, 95, 96]; % just to be super caref
% params.excludeChannels = sort( [burstChans, smallBurstChans ] );

% t8 2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/t8.2017.10.17/R_T8_2017_10_17-phonemes.mat';

% t8 2017.10.17 Instructed Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/t8.2017.10.17/R_T8_2017_10_17-movements.mat';


%% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/t5.2017.10.17/R_T5_2017_10_23-phonemes_1.mat';


 % if so, then labels like 'da-ga' (he was cued 'da' but said 'ga') are accepted
% The RESPONSE label ('ga' in above example) is used as the label for this trial.
params.acceptWrongResponse = true;
params.excludeChannels = participantChannelExcludeList( participant );


% Hard coded labels in a specific order that groups things more logically, which is good
% for presentation.
if strfind( Rfile, 'phonemes')
    if strfind( Rfile, 't5.2017.09.20')
        % pilot day
        includeLabels = {'silence', 'ba', 'ga', 'da', 'sh', 'oo'};
    else
        % main days
        includeLabels = {'silence', 'i', 'ae', 'a', 'u', 'ba', 'ga', 'da', 'k', 'p', 'sh'};
    end
elseif strfind( Rfile, 'words' )
     if strfind( Rfile, 't5.2017.09.20')
        % pilot day
        includeLabels = {'silence', 'arm', 'push', 'pull', 'beach', 'tree'};
     else
         % main days
        includeLabels = {'silence', 'beet', 'bat', 'bot', 'boot', 'dot', 'got', 'shot', 'keep', 'seal', 'more'};
     end
elseif strfind( Rfile, 'movements' )
    includeLabels = {'stayStill', 'tongueLeft', 'tongueRight', 'tongueDown', 'tongueUp', 'lipsForward', 'lipsBack', 'mouthOpen'};
end

%% Analysis Parameters
% params;



params.thresholdRMS = -4.5; % spikes happen below this RMS
% params.spikeFeature = 'spikesBinnedRate_50ms'; % firing rates, binned every 50ms (ending at the timestamp)
params.spikeFeature = 'spikesBinnedRateGaussian_25ms'; % spike counts binned smoothed with 25 ms SD Gaussian 


% When the audible cue started
params.plot.cueAlignEvent = 'cueEvent';
params.plot.cueStartEvent = 'cueEvent - 0.3';
params.plot.cueEndEvent = 'cueEvent + 1';

% When the second beep happened
% params.plot.cueAlignEvent = 'timeSecondBeep';
% params.plot.cueStartEvent = 'timeSecondBeep';
% params.plot.cueEndEvent = 'timeSecondBeep + 2.5';


% When audible speaking started (based on audio data)
params.plot.speechAlignEvent = 'speechEvent';
params.plot.speechStartEvent = 'speechEvent - 0.6';
params.plot.speechEndEvent = 'speechEvent + 1';

% When 'go cue' (second tick) happened. Use this for instructed movements
% params.plot.speechAlignEvent = 'timeGoCue';
% params.plot.speechStartEvent = 'timeGoCue';
% params.plot.speechEndEvent = 'timeGoCue + 2.5';

params.plot.errorMode = 'none';
%

% Will try anova when taking mean rate across this whole epoch.
% note that start event should be pushed forward to account for the binning window
% 0 to 500 ms after cue speech
params.simpleAnova.cueAlignEvent = 'cueEvent';
params.simpleAnova.cueStartEvent = 'cueEvent + 0.050';
params.simpleAnova.cueEndEvent = 'cueEvent + 0.500';

% 0 to 1500 ms after secondBeep
% params.simpleAnova.cueAlignEvent = 'timeSecondBeep';
% params.simpleAnova.cueStartEvent = 'timeSecondBeep + 0.050';
% params.simpleAnova.cueEndEvent = 'timeSecondBeep + 2.500';

% -500 to 500 ms around start of response speech
params.simpleAnova.speechAlignEvent = 'speechEvent';
params.simpleAnova.speechStartEvent = 'speechEvent - 0.450';
params.simpleAnova.speechEndEvent = 'speechEvent + 0.500';

% -500 to 500 ms around start of go cue speech
% params.simpleAnova.speechAlignEvent = 'timeGoCue';
% params.simpleAnova.speechStartEvent = 'timeGoCue';
% params.simpleAnova.speechEndEvent = 'timeGoCue + 2.000';

params.simpleAnova.reportChannelsBelowPvalue = 0.001;




params.plotPCs = 5;





%% Load the data
in = load( Rfile );
R = in.R;

% no support for > 2 arrays since that won't happen
if isfield( R, 'minAcausSpikeBand2' )     
    numArrays = 2;
else
    numArrays = 1;
end

% Scan for whether event labels files exist for these blocks. 
allLabels = arrayfun( @(x) x.label, R, 'UniformOutput', false );
% Accept trials with wrong response to cue, if it was one of the included responses
if params.acceptWrongResponse
    numCorrected = 0;
    for iTrial = 1 : numel( allLabels )
        if strfind( allLabels{iTrial}, '-' ) 
            myResponse = allLabels{iTrial}(strfind(allLabels{iTrial} , '-')+1:end);
            if ismember( myResponse, includeLabels )
                allLabels{iTrial} = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end




uniqueLabels = includeLabels( ismember( includeLabels, unique( allLabels ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );

fprintf('Loaded %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;


%% Apply RMS thresholding
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
        
        % Hack until I fix this in the data loading
        if size( myACB, 2 ) > size( R(iTrial).(rasterField),2 )
            myACB(:,end) = [];
        elseif size( myACB, 2 ) < size( R(iTrial).(rasterField),2 )
            myACB(:,end+1)=inf;
        end
        
        R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
    end
end

%% Organize data

% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), 'alignMode', 'handLabels' )];
end
R = Rnew; 
clear( 'Rnew' );




% Add firing rates
R = AddFeature( R, params.spikeFeature );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.spikeFeature );
end

% Group by cues
for iGroup = 1 : numel( uniqueLabels )
    Rgroup{iGroup} = R(strcmp( allLabels, uniqueLabels{iGroup} ));    
end

%% Make PSTH

% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.

for iGroup = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iGroup};
    
    % CUE
    jenga = AlignedMultitrialDataMatrix( Rgroup{iGroup}, 'featureField', params.spikeFeature, ...
        'startEvent', params.plot.cueStartEvent, 'alignEvent', params.plot.cueAlignEvent, 'endEvent', params.plot.cueEndEvent );
    result.(myLabel).cue.t = jenga.t;
    result.(myLabel).cue.psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).cue.psthStd = squeeze( std( jenga.dat, 1 ) );
    for t = 1 : size( jenga.dat,2 )
        result.(myLabel).cue.psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).cue.numTrials = jenga.numTrials;
    
    % for simple-anova
    jenga = AlignedMultitrialDataMatrix( Rgroup{iGroup}, 'featureField', params.spikeFeature, ...
        'startEvent', params.simpleAnova.cueStartEvent, 'alignEvent', params.simpleAnova.cueAlignEvent, 'endEvent', params.simpleAnova.cueEndEvent );
    result.(myLabel).cue.meanRateEachTrial = squeeze( nanmean( jenga.dat, 2 ) );
    
    
    % SPEECH
    jenga = AlignedMultitrialDataMatrix( Rgroup{iGroup}, 'featureField', params.spikeFeature, ...
        'startEvent', params.plot.speechStartEvent, 'alignEvent', params.plot.speechAlignEvent, 'endEvent', params.plot.speechEndEvent );
    result.(myLabel).speech.t = jenga.t;
    result.(myLabel).speech.psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).speech.psthStd = squeeze( std( jenga.dat, 1 ) );
    for t = 1 : size( jenga.dat,2 )
        result.(myLabel).speech.psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).speech.numTrials = jenga.numTrials;    
    
      
    % for simple-anova
    jenga = AlignedMultitrialDataMatrix( Rgroup{iGroup}, 'featureField', params.spikeFeature, ...
        'startEvent', params.simpleAnova.speechStartEvent, 'alignEvent', params.simpleAnova.speechAlignEvent, 'endEvent', params.simpleAnova.speechEndEvent );
    result.(myLabel).speech.meanRateEachTrial = squeeze( nanmean( jenga.dat, 2 ) );
end


%% Trying to get to the bottom of this crazy artefact
% if any( strcmp( uniqueLabels, 'push' ) )
% %     myLabel = 'push';     % crazy burst
% %     myLabel = 'pull'; % crazy birst
%     myLabel = 'beach'; % later crazy burst
% elseif any( strcmp( uniqueLabels, 'sh' ) )
%     myLabel = 'sh';
% end
% 
% 
% myGroup = Rgroup{strcmp( uniqueLabels, myLabel )};
% myChan = 67;
% jenga = AlignedMultitrialDataMatrix( myGroup, 'featureField', params.spikeFeature, ...
%         'startEvent', params.plot.cueStartEvent, 'alignEvent', params.plot.cueAlignEvent, 'endEvent', params.plot.cueEndEvent );
% figure; h = imagesc( squeeze( jenga.dat(:,:,myChan) )' );
% axh = get( h, 'Parent');
% title( sprintf('%s Cue, Chan%i', myLabel, myChan ) );
% xlabel('Trial')
% axh.YTickLabel = round( 1000*jenga.t(axh.YTick) );
% 
% ylabel(sprintf('Time %s (ms)', params.plot.cueAlignEvent ) );
% colorbar; 
% 
% % Raster
% figure; imagesc( myGroup(1).spikeRaster );
% myGroup(1).timeCueStart;
% line([myGroup(1).timeCueStart, myGroup(1).timeCueStart], [0 96], 'Color', 'w');
% title(sprintf('%s Trial 1', myLabel ) );
% 
% % Average across trials to get a sense for which channels show this thing.
% trialAvg = squeeze( mean( jenga.dat, 1 ) );
% figh = figure; figh.Color = 'w';
% figh.Name = sprintf('Trial avg rates ''%s''', myLabel );
% axh = axes; 
% axh.TickDir = 'out';
% imh = imagesc( jenga.t, 1 : jenga.numChans, trialAvg' );
% ylabel('Electrode');
% cbarh = colorbar; 
% ylabel( cbarh, 'FR (Hz)')
% axh.XTickLabel = round( axh.XTick .*1000 );
% title( figh.Name );
% xlabel( sprintf('time relative to %s (ms)', params.plot.cueAlignEvent ) );
% 
% % average across trials
% figh = figure;
% figh.Name = sprintf('Trial/Channel avg rates ''%s''', myLabel );
% plot( jenga.t, mean( trialAvg,2 ) );
% title( figh.Name );
% xlabel( sprintf('time relative to %s (ms)', params.plot.cueAlignEvent ) );
% ylabel('Mean FR (Hz');

%% A simple ANOVA to look for tuning, one electrode at a time.
chanNames = R(1).(params.spikeFeature).channelName; % used to report actual string names instead of indices,
% so removal of channel numbers doesn't mess things up.

% INCLUDING SILENCE
numChans = size( result.(uniqueLabels{1}).cue.meanRateEachTrial, 2 );
for iChan = 1 : numChans
    myRates_cue = [];
    myRates_speech = [];
    myLabels = {};
    for iGroup = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iGroup};
        myLabels = [myLabels; repmat( {myLabel}, numel( result.(myLabel).cue.meanRateEachTrial(:,iChan) ), 1 )];
        myRates_cue = [myRates_cue; result.(myLabel).cue.meanRateEachTrial(:,iChan)];
        myRates_speech = [myRates_speech; result.(myLabel).speech.meanRateEachTrial(:,iChan)];
    end
    % Compare for Cues
    [p,tbl] = anova1( myRates_cue, myLabels, 'off' );
    result.simpleAnova.pCue(iChan,1) = p;
    result.simpleAnova.FCue(iChan,1) = tbl{2,5};
    
    % Compare for Speech
    [p,tbl] = anova1( myRates_speech, myLabels, 'off' );
    result.simpleAnova.pSpeech(iChan,1) = p;
    result.simpleAnova.FSpeech(iChan,1) = tbl{2,5};
end

% Report how many electrodes appear to be tuned 
REPORT_TOP_N = 20;
% CUE
significantDuringCue = find( result.simpleAnova.pCue < params.simpleAnova.reportChannelsBelowPvalue );
reportTop = min( REPORT_TOP_N, numel( significantDuringCue ) );
cueFvals = result.simpleAnova.FCue(significantDuringCue);
[~,rankF] = sort( cueFvals, 'descend');
mostSignifChannels = significantDuringCue(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) chanNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('CUE: %i/%i (%.1f%%) electrodes tuned (p<%f, anova1), highest F vals are: %s\n', ...
    numel(significantDuringCue), numChans, 100*numel(significantDuringCue)/numChans,...
    params.simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );

% Speech
significantDuringSpeech = find( result.simpleAnova.pSpeech < params.simpleAnova.reportChannelsBelowPvalue );
reportTop = min( REPORT_TOP_N, numel( significantDuringSpeech ) );
cueFvals = result.simpleAnova.FSpeech(significantDuringSpeech);
[~,rankF] = sort( cueFvals, 'descend');
mostSignifChannels = significantDuringSpeech(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) chanNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('SPEECH: %i/%i (%.1f%%) electrodes tuned (p<%f, anova1), highest F vals are channels %s\n', ...
    numel(significantDuringSpeech), numChans, 100*numel(significantDuringSpeech)/numChans,...
    params.simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );


% ECLUDING SILENCE (so tuned between different sounds)
for iChan = 1 : numChans
    myRates_cue = [];
    myRates_speech = [];
    myLabels = {};
    for iGroup = 1 : numel( uniqueLabels )        
        myLabel = uniqueLabels{iGroup};
        if strcmp( myLabel, 'silence' ) || strcmp( myLabel, 'stayStill' )
            continue
        end
        myLabels = [myLabels; repmat( {myLabel}, numel( result.(myLabel).cue.meanRateEachTrial(:,iChan) ), 1 )];
        myRates_cue = [myRates_cue; result.(myLabel).cue.meanRateEachTrial(:,iChan)];
        myRates_speech = [myRates_speech; result.(myLabel).speech.meanRateEachTrial(:,iChan)];
    end
    % Compare for Cues
    [p,tbl] = anova1( myRates_cue, myLabels, 'off' );
    result.simpleAnova_noSilence.pCue(iChan,1) = p;
    result.simpleAnova_noSilence.FCue(iChan,1) = tbl{2,5};
    
    % Compare for Speech
    [p,tbl] = anova1( myRates_speech, myLabels, 'off' );
    result.simpleAnova_noSilence.pSpeech(iChan,1) = p;
    result.simpleAnova_noSilence.FSpeech(iChan,1) = tbl{2,5};
end


% Report how many electrodes appear to be tuned 
% CUE
significantDuringCue = find( result.simpleAnova_noSilence.pCue < params.simpleAnova.reportChannelsBelowPvalue );
reportTop = min( REPORT_TOP_N, numel( significantDuringCue ) );
cueFvals = result.simpleAnova.FCue(significantDuringCue);
[~,rankF] = sort( cueFvals, 'descend');
mostSignifChannels = significantDuringCue(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) chanNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('CUE, exclude silence: %i/%i (%.1f%%) electrodes tuned (p<%f, anova1), highest F vals are channels %s\n', ...
    numel(significantDuringCue), numChans, 100*numel(significantDuringCue)/numChans,...
    params.simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );

% Speech
significantDuringSpeech = find( result.simpleAnova_noSilence.pSpeech < params.simpleAnova.reportChannelsBelowPvalue );
reportTop = min( REPORT_TOP_N, numel( significantDuringSpeech ) );
cueFvals = result.simpleAnova.FSpeech(significantDuringSpeech);
[~,rankF] = sort( cueFvals, 'descend');
mostSignifChannels = significantDuringSpeech(rankF(1:reportTop));
mostSignifChannels_names = arrayfun( @(x) chanNames{x},  mostSignifChannels, 'UniformOutput', false ); % Convert these to strings
fprintf('SPEECH, exclude silence: %i/%i (%.1f%%) electrodes tuned (p<%f, anova1), highest F vals are channels %s\n', ...
    numel(significantDuringSpeech), numChans, 100*numel(significantDuringSpeech)/numChans,...
    params.simpleAnova.reportChannelsBelowPvalue, CellsWithStringsToOneString( mostSignifChannels_names ) );


%% PSTH for an example trial.
% Define a colormap
colors = jet( numel( uniqueLabels ) );
silenceInd = strcmp( uniqueLabels, 'silence' ) | strcmp(uniqueLabels, 'stayStill');
colors(silenceInd,:) = 0; 


% -------------------------
exampleChan = 'chan_2.69';
% -------------------------

% identify this electrode channel in the potentially channel-reduced dat
if ischar( exampleChan )
    exChanStr = exampleChan;
else
    % It's a number
    exChanStr = ['chan_' chanNumToName( exampleChan )];
end
exChanInd = find( strcmp( R(1).(params.spikeFeature).channelName, exChanStr) );



figh = figure;
figh.Color = 'w';
axhCue = subplot(1,2,1); hold on;
xlabel(['Time ' params.plot.cueAlignEvent ' (s)']);

pCueAll = result.simpleAnova.pCue(exChanInd);
pCueExcludeSilence = result.simpleAnova_noSilence.pCue(exChanInd);

title(sprintf( 'Cue %s p=%g,%g', exChanStr, pCueAll, pCueExcludeSilence ), ...
    'FontSize', 8, 'Interpreter', 'none' )
axhSpeech = subplot(1,2,2); hold on;
xlabel(['Time ' params.plot.speechAlignEvent ' (s)']);

% get relevant ANOVA p values
pSpeechAll = result.simpleAnova.pSpeech(exChanInd);
pSpeechExcludeSilence = result.simpleAnova_noSilence.pSpeech(exChanInd);
title( sprintf( 'Response p=%g,%g', pSpeechAll, pSpeechExcludeSilence ), 'FontSize', 8 )

titlestr = sprintf('%s %s', ...
    regexprep( pathToLastFilesep( Rfile, 1 ), '.mat', ''), exChanStr );
figh.Name = titlestr;
legendLabels = {};
myMax = 0;
for iGroup = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iGroup};
    legendLabels{iGroup} = sprintf('%s (n=%i)', myLabel, result.(myLabel).cue.numTrials );
    for iEvent = 1 : 2
        switch iEvent
            case 1
                myEvent = 'cue';
                axes( axhCue )
            case  2
                myEvent = 'speech';
                axes( axhSpeech )
        end
        
        
        myX = result.(myLabel).(myEvent).t;
        myY = result.(myLabel).(myEvent).psthMean(:,exChanInd);
        myMax = max([myMax, max( myY )]);
        plot( myX, myY, 'Color', colors(iGroup,:), ...
            'LineWidth', 1 );
        switch params.plot.errorMode
            case 'std'
                myStd = result.(myLabel).(myEvent).psthStd(:,exChanInd);
                plot( myX, myY+myStd, 'Color', colors(iGroup,:), ...
                    'LineWidth', 0.5 );
                plot( myX, myY-myStd, 'Color', colors(iGroup,:), ...
                    'LineWidth', 0.5 );
            case 'sem'
                mySem = result.(myLabel).(myEvent).psthSem(:,exChanInd);
                plot( myX, myY+mySem, 'Color', colors(iGroup,:), ...
                    'LineWidth', 0.5 );
                plot(  myX, myY-mySem, 'Color', colors(iGroup,:), ...
                    'LineWidth', 0.5 );
            case 'none';
                
        end
    end
end
linkaxes([axhCue, axhSpeech]);
axis auto
ylim([0 ,ceil( myMax ) + 1]);
xlim([myX(1), myX(end)])
axes( axhCue )
MakeDumbLegend( legendLabels, 'Color', colors );




%% PCA
bigDat = [];
for iGroup = 1 : numel( uniqueLabels )
%     bigDat = [bigDat; result.(uniqueLabels{iGroup}).speech.psthMean; result.(uniqueLabels{iGroup}).speech.psthMean];
    % only based on response
    bigDat = [bigDat; result.(uniqueLabels{iGroup}).speech.psthMean];

end
[coeff, score, latent] = pca( bigDat );
varExplained = latent ./ sum( latent );
fprintf('First %i PCs explain %s of the variance (together, %.4f)\n', ...
    params.plotPCs, mat2str( varExplained(1:params.plotPCs), 4 ), sum( varExplained(1:params.plotPCs) ) );
centeringMeanEachChan = nanmean( bigDat, 1 );


% Plot top PCs
for iPC = 1 : params.plotPCs
    figh = figure;
    axhCue = subplot(1,2,1); hold on;
    xlabel(['Time ' params.plot.cueAlignEvent ' (s)']);
    title(sprintf( 'Cue. PC%i (%.1f%%)', iPC, 100*varExplained(iPC) ))
    axhSpeech = subplot(1,2,2); hold on;
    xlabel(['Time ' params.plot.speechAlignEvent ' (s)']);
    title('Response')
    
    titlestr = sprintf('%s PC%i', ...
        regexprep( pathToLastFilesep( Rfile, 1 ), '.mat', ''), iPC );
    figh.Name = titlestr;
    legendLabels = {};
    myMax = -inf;
    myMin = inf;
    for iGroup = 1 : numel( uniqueLabels )
        myLabel = uniqueLabels{iGroup};
        legendLabels{iGroup} = sprintf('%s (n=%i)', myLabel, result.(myLabel).cue.numTrials );
        for iEvent = 1 : 2
            switch iEvent
                case 1
                    myEvent = 'cue';
                    axes( axhCue )
                case  2
                    myEvent = 'speech';
                    axes( axhSpeech )
            end
            
            
            myX = result.(myLabel).(myEvent).t;
            myDat = result.(myLabel).(myEvent).psthMean;
            % subtract mean
            myDat = myDat - repmat( centeringMeanEachChan, size( myDat, 1 ), 1 );
            % do PCA
            myY = myDat * coeff(iPC,:)';
            
            
            myMin = min([myMin, min( myY )]);
            myMax = max([myMax, max( myY )]);
            plot( myX, myY, 'Color', colors(iGroup,:), ...
                'LineWidth', 1 );
            switch params.plot.errorMode
                case 'std'
                    myStd = result.(myLabel).(myEvent).psthStd(:,exampleChan);
                    plot( myX, myY+myStd, 'Color', colors(iGroup,:), ...
                        'LineWidth', 0.5 );
                    plot( myX, myY-myStd, 'Color', colors(iGroup,:), ...
                        'LineWidth', 0.5 );
                case 'sem'
                    mySem = result.(myLabel).(myEvent).psthSem(:,exampleChan);
                    plot( myX, myY+mySem, 'Color', colors(iGroup,:), ...
                        'LineWidth', 0.5 );
                    plot(  myX, myY-mySem, 'Color', colors(iGroup,:), ...
                        'LineWidth', 0.5 );
                case 'none';
                    
            end
        end
    end
    linkaxes([axhCue, axhSpeech]);
    axis auto
    ylim([floor( myMin )-1,ceil( myMax ) + 1]);
    xlim([myX(1), myX(end)])
    axes( axhCue )
    MakeDumbLegend( legendLabels, 'Color', colors );
end

