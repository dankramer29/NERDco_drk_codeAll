% Loads analysis result files that have modulation depths (max - min firing rate in the
% analysis epoch of interest) for each electrode. Makes comparison histograms.
% The files it uses were genereated by WORKUP_speechWhileBCI_PSTHs,
% WORKUP_speechStandalone_PSTHs.m
% 
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 4 March 2019
% Updated May 2019 based on Frank's feedback



clear

%% Speaking 
conditionNames = {...
    'speaking alone';
    'speaking during BCI'
    };
% Load data. Each row is a condition, each column is a dataset.
files = {...
    {'/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12-words_comparison.mat', '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.17-words_comparison.mat'};
    {'/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12_duringBCI_comparison.mat', '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.17_duringBCI_comparison.mat'};
    };

% files = {...
%     {'/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12-words_comparison.mat'};
%     {'/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12_duringBCI_comparison.mat'};
%     };



params.minFR = 1; % exclude channels that don't have at least this firing rate during SPEAKING in EITHER speaking alone or speaking during BCI
params.baselineSubtract = true; % if true, will subtract baseline FR from each channel (from that same condition)
params.sqrtRootNorm = true; % if true, divide by sqrt( # electodes) to make for a more intuitive unit.

colorSpeechAlone = [0 1 0]; % green for speaking alone
colorSpeechBCI = [0 0 0.8]; % blue for speech during BCI;


%% R8
% conditionNames = {...
%     'BCI R8';
%     };
% files = {...
%     {'/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.12_R8_BCI_comparison.mat', '/Users/sstavisk/Results/speechDuringBCI/t5.2018.12.17_R8_BCI_comparison.mat'};
%     };
% colors = [...
%     1 0 .0 ;
%     ];

%% R8 head still vs head restrained

% conditionNames = {...
%     'BCI head still';
%     'BCI head free'
%     };
% % Load data. Each row is a condition, each column is a dataset.
% files = {...
%     {'/Users/sstavisk/Results/speechDuringBCI/t5.2019.03.27_R8_headFixed_comparison.mat'};
%     {'//Users/sstavisk/Results/speechDuringBCI/t5.2019.03.27_R8_headFree_comparison.mat'};
%     };
% 
% 
% colors = [...
%     1 0 .0 ;
%     0 0 1 ;
%     ];

%% Aesthetic
binWidth = 5;
maxVal = 100;
XLIM = [0 30];


numDatasets = numel( files{1} );
numConditions = numel( files );

% Load each file first to get meanFR; I want this across both conditions, so I do it in a
% separate loop first.
% All the processed data I want is in in.popMod. Other fields are for other approaches to
% this population modulation metric.
meanAcrossLabelsFR = cell(0); % will be cell array that is conditions x datasets
validChannels = cell(0); % will have one cell per *dataset*
for iDataset = 1 : numDatasets
    for iCondition = 1 : numConditions
        
        in = load( files{iCondition}{iDataset} );
        % how many words are there
        numWords = numel( in.popMod.speakingTrialsByChans );
        for iWord = 1 : numWords
            meanAcrossLabelsFR{iCondition, iDataset}(:,iWord) = nanmean( in.popMod.speakingTrialsByChans{iWord}, 1 ); % trial average
        end
    end
    % remove dataset-channels that don't have a mean FR of 1 hz
    % take mean across the words within each dataset
    validDatasetChannels{iDataset} = mean( meanAcrossLabelsFR{1,iDataset},2 ) >= params.minFR & ...
        mean( meanAcrossLabelsFR{2,iDataset}, 2 ) >= params.minFR;
    fprintf('Dataset %i, %i channels have FR >= %.1fHz in BOTH %s and %s. Using these for remaining analyses...\n', ...
        iDataset, nnz( validDatasetChannels{iDataset} ), params.minFR, conditionNames{1}, conditionNames{2} )
    
end



% Run for each label and each dataset.
for iCondition = 1 : numConditions
    fprintf('Condition %s\n', conditionNames{iCondition} )
    acrossLabelsAndDatasetsModulation{iCondition} = []; % one element for each word condition, from each dataset
    for iDataset = 1 : numDatasets
        in = load( files{iCondition}{iDataset} );
        numWords = numel( in.popMod.speakingTrialsByChans );
        fprintf( ' Averaging FR across %s to %s\n', in.params.comparisonStartEvent, in.params.comparisonEndEvent )

        
        
        % Get silence
        silenceFR = in.popMod.silenceTrialsByChans;
        if params.baselineSubtract
            BL = mean( in.popMod.silenceTrialsByChans_baseline, 1 );
            silenceFR = silenceFR - repmat( BL, size( silenceFR, 1 ), 1 ); % subtract trial-averaged baseline
        end
        % restrict only to valid channels
        silenceFR = silenceFR(:, validDatasetChannels{iDataset});
        
        
        for iWord = 1 : numWords
            wordFR = in.popMod.speakingTrialsByChans{iWord};
            title( sprintf('Word %i dataset %i condition %i', iWord, iDataset, iCondition) )
            
            if params.baselineSubtract
                BL = mean( in.popMod.speakingTrialsByChans_baseline{iWord}, 1 );
                wordFR = wordFR - repmat( BL, size( wordFR, 1 ), 1 ); % subtract trial-averaged baseline
            end
            % restrict only to valid channels
            wordFR = wordFR(:, validDatasetChannels{iDataset});
            
            % Euclidean distance (if I want to compare)
%             myDistance = norm( mean( wordFR, 1 ) - mean( silenceFR, 1 ) );
            
%             Frank's less biased distance. Updated to handle different distribution sizes.
            myDistance = lessBiasedDistance( wordFR, silenceFR );
            if params.sqrtRootNorm 
                myDistance = myDistance ./ sqrt( size( silenceFR, 2 ) );               
            end
            
            fprintf(' Dataset %i, word %i, distance is %f\n', iDataset, iWord, myDistance )
            acrossLabelsAndDatasetsModulation{iCondition}(end+1) = myDistance;
        end
    end
end
  



%% Prepare figure
figh = figure;
figh.Name = 'Population modulation comparisons';
hold on
figh.Color = 'w';


lineWidth = 20;
axh = gca; 

% plot speech ALONE bar
speechAloneMods = acrossLabelsAndDatasetsModulation{1};
fprintf('Speech alone: mean across %i dataset-words is %f +- %f (mean +- s.d.)\n', ...
    numel( speechAloneMods ), mean( speechAloneMods ), std( speechAloneMods ) )

barSpeechAlone = line( axh, [ 2 2], [0 mean( speechAloneMods )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorSpeechAlone);
% plot speech ALONE points
hSpeechAlone = scatter( axh, 2.*ones( numel( speechAloneMods ), 1 ), speechAloneMods, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeechAlone, 'Parent', axh );


% plot speech during BCI bar
speechBCIMods = acrossLabelsAndDatasetsModulation{2};
fprintf('Speech during BCI: mean across %i dataset-words is %f +- %f\n', ...
    numel( speechBCIMods ), mean( speechBCIMods ), std( speechBCIMods ) )

barSpeech = line( axh, [ 3 3], [0 mean( speechBCIMods )], 'LineWidth', lineWidth, ...
    'Color', 0.7.* colorSpeechBCI);

% plot speech during BCI points
hSpeech = scatter( axh, 3.*ones( numel( speechBCIMods ), 1 ), speechBCIMods, ...
    'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', colorSpeechBCI, 'Parent', axh );

xlim([0.5 3.5]);
axh.XTick = [2, 3];
axh.XTickLabel = conditionNames;

ylabel('\Delta population firing rate ')


%% Statistics. 
[p,h] = ranksum( speechAloneMods, speechBCIMods );
fprintf('ranksum test p=%g\n', p );
