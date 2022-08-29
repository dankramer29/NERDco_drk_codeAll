% Reports overlaps between channels tuned to various things in the speech project. This is
% useful for reporting that of the speech-tuned channels, X% also responded during face
% movements.
%
%
% Uses results created by WORKUP_speechTuning.m
%
% Sergey Stavisky, January 4 2018
clear




% Specify the results files of interest:
% T5 PHONEMES and MOVEMENTS - THRESHOLD CROSSINGS
% phonemeResultFile = '/Users/sstavisk/Results/speech/tuning/t5.2017.10.23-phonemes_lfpPow_125to5000_50ms_b269e34efcf8b4c0e975e1b51a1d43f2.mat';
% faceResultFile = '/Users/sstavisk/Results/speech/tuning/t5.2017.10.23-movements_lfpPow_125to5000_50ms_e790d90b929f293d21adcd2b20017b74.mat';
% excludeChannels = datasetChannelExcludeList('t5.2017.10-23_-4.5RMSexclude');

% T5 PHONEMES and MOVEMENTS - SORTED UNITS OF QUALITY > 3 
phonemeResultFile = '/Users/sstavisk/Results/speech/tuning/t5.2017.10.23-phonemes_lfpPow_125to5000_50ms_7874d420fa08fc141dea6e9769a74c6b.mat';
faceResultFile = '/Users/sstavisk/Results/speech/tuning/t5.2017.10.23-movements_lfpPow_125to5000_50ms_5a2f806303e5f12e0a62f7764e472765.mat';
excludeChannels = [];

% T8 PHONEMES and MOVEMENTS - THRESHOLD CROSSINGS
% phonemeResultFile = '/Users/sstavisk/Results/speech/tuning/t8.2017.10.17-phonemes_lfpPow_125to5000_50ms_f8817a911e15701de24c8f337c3b7cc7.mat';
% faceResultFile = '/Users/sstavisk/Results/speech/tuning/t8.2017.10.17-movements_lfpPow_125to5000_50ms_3955398cbef69d122b6b477e9b835af2.mat';
% excludeChannels = datasetChannelExcludeList( 't8.2017.10-17_-4.5RMSexclude' );

% T8 PHONEMES and MOVEMENTS - SORTED UNITS OF QUALITY > 3 
% phonemeResultFile = '/Users/sstavisk/Results/speech/tuning/t8.2017.10.17-phonemes_lfpPow_125to5000_50ms_8d9a692fdb6644ed5c67b98dcf0738f5.mat';
% faceResultFile = '/Users/sstavisk/Results/speech/tuning/t8.2017.10.17-movements_lfpPow_125to5000_50ms_8e6fcd883080fe9755626eedfdc4cd3e.mat';
% excludeChannels = [];

% appearance
viz.totalWidth = 110; % should be above maximum number of union channels

%% analysis parameters


% Method 1: ANOVA
simpleAnova.reportChannelsBelowPvalue = 0.001; % definition of a responder
simpleAnova.reportChannelsBelowPvalue = 0.01; % definition of a responder

% Method 2: ranksum test against silence/stay still
testAgainstNull.reportChannelsBelowPvalue = 0.05; % note: it gets Bonferonni corrected later

% Pick which method to use
% whichTest = 'ANOVA';
whichTest = 'ranksum';

%% Load the results files
in = load( phonemeResultFile );
phonemeResult = in.result;

in = load( faceResultFile );
faceResult = in.result;

% are any of these channels in the exclude list?
if ~isempty( excludeChannels )
    excludedChanInds = find( ismember( ChannelNameToNumber( phonemeResult.channelNames ), excludeChannels ) );
    if ~isempty( excludedChanInds )
       fprintf( 2, 'Warning: chans %s are in phonemeResults but also in excludeChannels\n', mat2str( excludeChannels(excludedChanInds) ) );
    end
    allUnits = setdiff( 1 : 192, excludeChannels ); % all non-excluded channels
    allUnitsNames = chanNumToName( allUnits );
    for i =  1 : numel( allUnitsNames )
        allUnitsNames{i} = ['chan_' allUnitsNames{i}]; % same format as in results files
    end
else
    % for sorted analysis
    allUnitsNames = union( phonemeResult.channelNames, faceResult.channelNames );
    % out of curiosity, what are firing rates for these units averaged across all the epochs
    numConds = 0;
    FRvec = zeros( numel( allUnitsNames ), 1 );
    for i = 1 : numel( phonemeResult.uniqueLabels ) % loop across phoneme results
        myLabel = phonemeResult.uniqueLabels{i};
        % my mean FR?
        FRvec = FRvec + mean( phonemeResult.(myLabel).meanWindowActivity, 1 )';
        numConds = numConds + 1;
    end
    for i = 1 : numel( faceResult.uniqueLabels ) % loop across face results
        myLabel = faceResult.uniqueLabels{i};
        % my mean FR?
        FRvec = FRvec + mean( faceResult.(myLabel).meanWindowActivity, 1 )';
        numConds = numConds + 1;
    end
    FRvec = FRvec./numConds;
end

%% Rather than ANOVA, I can do this by looking at channels that respond to at least one phoneme
% (this is more consistent with the rest of that analysis)

% DO IT FOR PHONEMES
numChans = numel( phonemeResult.channelNames );
phonemeResult.pValueVsSilent = nan( numChans, numel( phonemeResult.uniqueLabels ) - 1 );
for iChan = 1 : numChans
    % silence/stayStill rates
    myLabel = phonemeResult.uniqueLabels{1};
    silenceDat = phonemeResult.(myLabel).meanWindowActivity(:,iChan);
    
    % loop through each of the other labels and compare them to the silent label
    for iLabel = 2 : numel( phonemeResult.uniqueLabels )
        myLabel = phonemeResult.uniqueLabels{iLabel};
        myDat = phonemeResult.(myLabel).meanWindowActivity(:,iChan);
        phonemeResult.pValueVsSilent(iChan,iLabel) = ranksum( myDat, silenceDat );
    end  
end
% p value cutoff 
testVal = (testAgainstNull.reportChannelsBelowPvalue ./ (numel( phonemeResult.uniqueLabels )-1) ); % Bonefonni correction
signifPvalueVsSilent = phonemeResult.pValueVsSilent < testVal;
numEachTunedTo = sum( signifPvalueVsSilent, 2 );
% restrict to responders, meaning having significant tuning to at least one channel 
signifRespondersPhonemes = phonemeResult.channelNames(numEachTunedTo >= 1 );


% DO IT FOR MOVEMENTS
numChans = numel( faceResult.channelNames );
faceResult.pValueVsSilent = nan( numChans, numel( faceResult.uniqueLabels ) - 1 );
for iChan = 1 : numChans
    % silence/stayStill rates
    myLabel = faceResult.uniqueLabels{1};
    silenceDat = faceResult.(myLabel).meanWindowActivity(:,iChan);
    
    % loop through each of the other labels and compare them to the silent label
    for iLabel = 2 : numel( faceResult.uniqueLabels )
        myLabel = faceResult.uniqueLabels{iLabel};
        myDat = faceResult.(myLabel).meanWindowActivity(:,iChan);
        faceResult.pValueVsSilent(iChan,iLabel) = ranksum( myDat, silenceDat );
    end  
end
% p value cutoff 
testVal = (testAgainstNull.reportChannelsBelowPvalue ./ (numel( faceResult.uniqueLabels )-1) ); % Bonefonni correction
signifPvalueVsSilent = faceResult.pValueVsSilent < testVal;
numEachTunedTo = sum( signifPvalueVsSilent, 2 );
% restrict to responders, meaning having significant tuning to at least one channel 
signifRespondersFace = faceResult.channelNames(numEachTunedTo >= 1 );





%% Compare fraction tuning
switch whichTest
    case 'ANOVA'
        phonemeResponders = find( phonemeResult.simpleAnovaWithSilence.p <= simpleAnova.reportChannelsBelowPvalue );
        phonemeRespondersNames = phonemeResult.channelNames(phonemeResponders);
        faceResponders = find( faceResult.simpleAnovaWithSilence.p <= simpleAnova.reportChannelsBelowPvalue );
        faceRespondersNames = faceResult.channelNames(faceResponders);
        testVal = simpleAnova.reportChannelsBelowPvalue;
    case 'ranksum'
        phonemeRespondersNames = signifRespondersPhonemes;
        faceRespondersNames = signifRespondersFace;
end
fprintf('ANALYSIS USING %s TEST, p = %f\n', whichTest, testVal );
allResponders = union( phonemeRespondersNames, faceRespondersNames );
phonemeOnlyResponders = setdiff( phonemeRespondersNames, faceRespondersNames );
faceOnlyResponders = setdiff( faceRespondersNames, phonemeRespondersNames );
bothResponders = intersect( phonemeRespondersNames, faceRespondersNames );
% how many respond to nothing?
noResponders =  setdiff( allUnitsNames, allResponders );

fprintf( '%i (%.1f%%) phoneme-exclusive, %i (%.1f%%) shared, %i (%.1f%%) face-exclusive\n', ...
    numel( phonemeOnlyResponders ), 100* numel( phonemeOnlyResponders ) / numel( allResponders ), ...
    numel( bothResponders ), 100* numel( bothResponders ) / numel( allResponders ), ...
    numel( faceOnlyResponders ), 100* numel( faceOnlyResponders ) / numel( allResponders ) );
fprintf('Of the %i phoneme-responders, %i (%.1f%%) also responded to face movements\n', ...
    numel( phonemeRespondersNames ), numel( bothResponders ), 100 * numel( bothResponders )/ numel( phonemeRespondersNames ) );
fprintf('%i (%.1f%% of all functioning channels) did not respond to phoneme or orofacial movements\n', ...
    numel( noResponders ), 100 * numel( noResponders ) / numel( allUnitsNames ) );
fprintf('\n non-responders'' grand mean FR = %s\n', mat2str( FRvec(ismember( allUnitsNames, noResponders )),4 ) );

%% Plot 
figh = figure;
axh = axes; hold on;
figh.Position = [10 10 400 60];
axh.XLim = [-1 viz.totalWidth+1];
myx = [0 numel( phonemeOnlyResponders )];
line( myx, [0.5 0.5], 'LineWidth', 5, 'Color', [1 0 0] );
text( mean( myx ), 1, sprintf('%i', numel( phonemeOnlyResponders ) ), ...
    'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom' )

myx = [numel( phonemeOnlyResponders ) numel( phonemeOnlyResponders )+numel(bothResponders)];
line( myx, [0.5 0.5], 'LineWidth', 5, 'Color', [.5 0 .5] );
text( mean( myx ), 1, sprintf('%i', numel( bothResponders ) ), ...
    'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom' )

myx = [numel( phonemeOnlyResponders )+numel(bothResponders), numel( phonemeOnlyResponders )+numel(bothResponders) + numel(faceOnlyResponders)];
line( myx, [0.5 0.5], 'LineWidth', 5, 'Color', [0 0 1] );
text( mean( myx ), 1, sprintf('%i', numel( faceOnlyResponders ) ), ...
    'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom' )

myx = [numel( phonemeOnlyResponders )+numel(bothResponders) + numel(faceOnlyResponders), numel( phonemeOnlyResponders )+numel(bothResponders) + numel(faceOnlyResponders) + numel(noResponders)];
line( myx, [0.5 0.5], 'LineWidth', 5, 'Color', [0.5 0.5 0.5] );
text( mean( myx ), 1, sprintf('%i', numel( noResponders ) ), ...
    'HorizontalAlignment', 'Center', 'VerticalAlignment', 'Bottom' )

axh.Visible = 'off';