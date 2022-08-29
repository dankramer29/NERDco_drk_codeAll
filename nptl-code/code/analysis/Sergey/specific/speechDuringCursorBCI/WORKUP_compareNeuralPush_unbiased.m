% Loads analysis result files that have peak neural push for each behavior
% (meaning either R8 target or speaking word).

% The files it uses were genereated by WORKUP_speechWhileBCI_decoderPotent.m,
% WORKUP_speechStandalone_decoderPotent.m
% 
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 8 March 2019
% Updated May 2019: uses the unbiased neural push estimate using Frank's method.
% Also can take mean push across a time epoch, instead of the peak push.


clear

%% Speaking 
conditionNames = {...
    'R8';
    'Speaking Alone'
    'Speech during BCI'    
    };



% Data for R8 and speaking during BCI. 
files = {...
    '/Users/sstavisk/Results/speechDuringBCI/newRescaled/t5.2018.12.12_R8andSpeaking_decoderPotent.mat';
    '/Users/sstavisk/Results/speechDuringBCI/newRescaled/t5.2018.12.17_R8andSpeaking_decoderPotent.mat';
    };


% Added later, so loaded separately
filesSpeakAlone = {...
    '/Users/sstavisk/Results/speechDuringBCI/newRescaled/t5.2018.12.12_SpeakingAlone_decoderPotent.mat'
    '/Users/sstavisk/Results/speechDuringBCI/newRescaled/t5.2018.12.17_SpeakingAlone_decoderPotent.mat'
    };

colorR8 = [255,127,80]./255;  % coral for R8 
colorSpeechAlone = [0 1 0]; % green for speaking alone
colorSpeech = [0 0 0.8]; % blue for speech during BCI;

% params.useUnbiased = false; 
params.useUnbiased = true; % if true, uses Frank's unbiased norm method

% What epoch to average neural push in.
params.comparisonEpochSpeech = [-1 1]; % in seconds, aligned to params.alignEventSpeech in the scripts that generated the data
% params.comparisonEpochSpeech = []; % leave empty to look for peak instead
params.comparisonEpochR8 = [0.2 0.7]; % in seconds
% params.comparisonEpochR8 = []; % leave empty to look for peak instead

%% Load data and get into two vectors of peak modulations

r8Pushes = [];
speechPushes = []; % during BCI
silencePushes = []; %during BCI
speechAlonePushes = []; %stand-alone
silenceAlonePushes = []; % stand-alone

for iFile = 1 : numel( files )
    fprintf('Loading %s\n', files{iFile} );
    in = load( files{iFile} );
    result = in.result;
    
    % unpack its R8 pushes
    for i = 1 : numel( result.uniqueLabels )
        myLabelStr = sprintf('target%i', result.uniqueLabels(i) );       
        if params.useUnbiased
            if isempty( params.comparisonEpochR8 )
                myPush = result.(myLabelStr).peakUnbiasedPush{1};
            else
                % analysis epoch
                [~, startInd] = FindClosest( result.(myLabelStr).t{1},   params.comparisonEpochR8(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1},   params.comparisonEpochR8(2) );
                myPush = nanmean( result.(myLabelStr).unbiasedPush{1}(startInd:endInd) );
            end
        else %  biased
            if isempty( params.comparisonEpochR8 )
                myPush = result.(myLabelStr).peakPush{1};
            else
                [~, startInd] = FindClosest( result.(myLabelStr).t{1},   params.comparisonEpochR8(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1},   params.comparisonEpochR8(2) );
                myPush = nanmean( result.(myLabelStr).pushMean{1}(startInd:endInd,3) );
            end            
        end
        r8Pushes = [r8Pushes; myPush ];
    end
    
    % unpack its Speech During BCI pushes
    for i = 1 : numel( result.uniqueSpeechLabels )
        myLabelStr = result.uniqueSpeechLabels{i};
        if params.useUnbiased
            if isempty( params.comparisonEpochSpeech )
                myPush = result.(myLabelStr).peakUnbiasedPush{1};
            else
                [~, startInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(2) );
                myPush = nanmean( result.(myLabelStr).unbiasedPush{1}(startInd:endInd) );
            end
        else
            % biased (old way)
            if isempty( params.comparisonEpochSpeech )
                myPush = result.(myLabelStr).peakPush{1};
            else
                [~, startInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(2) );
                myPush = nanmean( result.(myLabelStr).pushMean{1}(startInd:endInd,3) );
            end
        end

        if ~strcmp( myLabelStr, 'silence' )
            speechPushes = [speechPushes; myPush];
        else
            silencePushes = [silencePushes; myPush];
        end
    end    
    
    fprintf('Loading %s\n', filesSpeakAlone{iFile} );
    in = load( filesSpeakAlone{iFile} );
    result = in.result;
    % unpack its speech alone pushes
    for i = 1 : numel( result.uniqueSpeechLabels )
        myLabelStr = result.uniqueSpeechLabels{i};
        if params.useUnbiased 
             if isempty( params.comparisonEpochSpeech )
                myPush = result.(myLabelStr).peakUnbiasedPush{1};
             else
                [~, startInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(2) );
                myPush = nanmean( result.(myLabelStr).unbiasedPush{1}(startInd:endInd) );
            end
        else
            if isempty( params.comparisonEpochSpeech )
                myPush = result.(myLabelStr).peakPush{1};
            else
                [~, startInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(1) );
                [~, endInd] = FindClosest( result.(myLabelStr).t{1}, params.comparisonEpochSpeech(2) );
                myPush = nanmean( result.(myLabelStr).pushMean{1}(startInd:endInd,3) );
            end
        end
        % ignore silence
        if ~strcmp( myLabelStr, 'silence' )
            speechAlonePushes = [speechAlonePushes; myPush];
        else
            silenceAlonePushes = [silenceAlonePushes; myPush ];
        end
    end
end

%% Stats:
% Compare R8 to speech during BCI
[p,h] = ranksum( r8Pushes, speechPushes );
fprintf('Mean delta neural push during R8: %.2f +- %.2f (s.d.), mean delta neural push during ongoing speaking: %.2f +- %.2f (p=%g, rank-sum test)\n', ...
    mean( r8Pushes ), std( r8Pushes ), mean( speechPushes ), std( speechPushes ), p )

% Compare R8 to speech alone
[p,h] = ranksum( r8Pushes, speechAlonePushes );
fprintf('Mean delta neural push during R8: %.2f +- %.2f (s.d.), mean delta neural push during STANDALONE speaking: %.2f +- %.2f (p=%g, rank-sum test)\n', ...
    mean( r8Pushes ), std( r8Pushes ), mean( speechAlonePushes ), std( speechAlonePushes ), p )

% Compare Speech during BCI to speech alone
[p,h] = ranksum( speechPushes, speechAlonePushes );
fprintf('Mean delta neural push during speaking during BCI: %.2f +- %.2f (s.d.), mean delta neural push during STANDALONE speaking: %.2f +- %.2f (p=%g, rank-sum test)\n', ...
    mean( speechPushes ), std( speechPushes ), mean( speechAlonePushes ), std( speechAlonePushes ), p )

%% Prepare figure
figh = figure;
figh.Color = 'w';
titlestr = sprintf('Neural push comparisons' );
figh.Name = titlestr;
hold on

lineWidth = 20;
axh = gca; 
% plot r8 bar
barr8 = line( axh, [ 1 1], [0 mean( r8Pushes )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorR8);
hold on

% plot r8 points
hr8 = scatter( axh, ones( numel( r8Pushes ), 1 ), r8Pushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorR8, 'Parent', axh );




% plot speech ALONE bar
barSpeechAlone = line( axh, [ 2 2], [0 mean( speechAlonePushes )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorSpeechAlone);

% plot silence alone line
barSilenceAlone = line( axh, [1.6 2.4], [mean( silenceAlonePushes ), mean( silenceAlonePushes )], 'LineWidth', 3, ...
    'Color', [0 0 0] );
% silence alone points
hSilenceAlone = scatter( axh, 2.*ones( numel( silenceAlonePushes ), 1 ), silenceAlonePushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'k', 'Parent', axh );

% plot speechALONE points
hSpeechAlone = scatter( axh, 2.*ones( numel( speechAlonePushes ), 1 ), speechAlonePushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeechAlone, 'Parent', axh );




% plot speech during BCI bar
barSpeech = line( axh, [ 3 3], [0 mean( speechPushes )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorSpeech);

% plot silence during BCI  line
barSilence = line( axh, [2.6 3.4], [mean( silencePushes ), mean( silencePushes )], 'LineWidth', 3, ...
    'Color', [0 0 0] );
% silence alone points
hSilence = scatter( axh, 3.*ones( numel( silencePushes ), 1 ), silencePushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'k', 'Parent', axh );

% plot speech during BCI points
hSpeech = scatter( axh, 3.*ones( numel( speechPushes ), 1 ), speechPushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeech, 'Parent', axh );

xlim([0.5 3.5]);
axh.XTick = [1, 2, 3];
axh.XTickLabel = conditionNames;

ylabel('\Delta neural push')