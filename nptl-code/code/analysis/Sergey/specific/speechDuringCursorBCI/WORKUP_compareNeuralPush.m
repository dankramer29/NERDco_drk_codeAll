% Loads analysis result files that have peak neural push for each behavior
% (meaning either R8 target or speaking word).
% Makes comparison histograms.
% The files it uses were genereated by WORKUP_speechWhileBCI_decoderPotent.m,
% WORKUP_speechStandalone_PSTHs.m
% 
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 8 March 2019

% NOTE: I plot *MEAN*, not median, in the histograms, since speaking standalone is more
% distinguished by its long tail

clear

%% Speaking 
conditionNames = {...
    'R8';
    'Speaking Alone'
    'Speech during BCI'    
    };



% Data for R8 and speaking during BCI. 
files = {...
    '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12_R8andSpeaking_decoderPotent.mat';
    '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.17_R8andSpeaking_decoderPotent.mat';
    };


% Added later, so loaded separately
filesSpeakAlone = {...
    '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.17_SpeakingAlone_decoderPotent.mat'
    '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12_SpeakingAlone_decoderPotent.mat'
    };

colorR8 = [255,127,80]./255;  % coral for R8 
colorSpeechAlone = [0 1 0]; % green for speaking alone
colorSpeech = [0 0 0.8]; % blue for speech during BCI;


%% Load data and get into two vectors of peak modulations

r8Pushes = [];
speechPushes = [];
speechAlonePushes = [];

for iFile = 1 : numel( files )
    fprintf('Loading %s\n', files{iFile} );
    in = load( files{iFile} );
    result = in.result;
    
    % unpack its R8 pushes
    for i = 1 : numel( result.uniqueLabels )
        myLabelStr = sprintf('target%i', result.uniqueLabels(i) );
        r8Pushes = [r8Pushes; cell2mat( result.(myLabelStr).peakPush )];
    end
    
    % unpack its speech pushes
    for i = 1 : numel( result.uniqueSpeechLabels )
        myLabelStr = result.uniqueSpeechLabels{i};
        % ignore silence
        if ~strcmp( myLabelStr, 'silence' )
            speechPushes = [speechPushes; cell2mat( result.(myLabelStr).peakPush )];
        end
    end    
    
    fprintf('Loading %s\n', filesSpeakAlone{iFile} );
    in = load( filesSpeakAlone{iFile} );
    result = in.result;
    % unpack its speech alone pushes
    for i = 1 : numel( result.uniqueSpeechLabels )
        myLabelStr = result.uniqueSpeechLabels{i};
        % ignore silence
        if ~strcmp( myLabelStr, 'silence' )
            speechAlonePushes = [speechAlonePushes; cell2mat( result.(myLabelStr).peakPush )];
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

% plot speechALONE points
hSpeechAlone = scatter( axh, 2.*ones( numel( speechAlonePushes ), 1 ), speechAlonePushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeechAlone, 'Parent', axh );


% plot speech during BCI bar
barSpeech = line( axh, [ 3 3], [0 mean( speechPushes )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorSpeech);

% plot speech during BCI points
hSpeech = scatter( axh, 3.*ones( numel( speechPushes ), 1 ), speechPushes, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeech, 'Parent', axh );

xlim([0.5 3.5]);
axh.XTick = [1, 2, 3];
axh.XTickLabel = conditionNames;

ylabel('\Delta neural push')