% Loads analysis result files that have modulation depths (max - min firing rate in the
% analysis epoch of interest) for each electrode. Makes comparison histograms.
% The files it uses were genereated by WORKUP_speechWhileBCI_PSTHs,
% WORKUP_speechStandalone_PSTHs.m
% 
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 4 March 2019
% Updatd May 2019 based on Frank's feedback

% NOTE: I plot *MEAN*, not median, in the histograms, since speaking standalone is more
% distinguished by its long tail

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

colors = [...
    .3 .3 .3 ;
    0 0.8 0 ;
    ];

params.minFR = 1; % exclude channels that don't have at least this firing rate during SPEAKING in EITHER speaking alone or speaking during BCI
params.baselineSubtract = true; % if true, will subtract baseline FR from each channel (from that same condition)


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

%% Prepare figure
figh = figure;
figh.Name = 'Modulation depths comparisons';
hold on


% Load each file first to get meanFR; I want this across both conditions, so I do it in a
% separate loop first

for iCondition = 1 : numel( files )
    meanAcrossLabelsFR{iCondition} = [];    
    for iDataset = 1 : numel( files{iCondition} )
        in = load( files{iCondition}{iDataset} );
        meanAcrossLabelsFR{iCondition} = [meanAcrossLabelsFR{iCondition}, mean( in.speechMod.wordFR, 1 )];
    end
end
% remove dataset-channels that don't have a mean FR of 1 hz
validDatasetChannels = meanAcrossLabelsFR{1} >= params.minFR & meanAcrossLabelsFR{2} >= params.minFR;
fprintf('%i dataset-channels have FR >= %.1fHz in BOTH %s and %s. Using these for remaining analyses...\n', ...
    nnz( validDatasetChannels ), params.minFR, conditionNames{1}, conditionNames{2} )

binEdges = 0 : binWidth : XLIM(end) + binWidth;
% Load each file
for iCondition = 1 : numel( files )
    
    % Old way: modulation range (max - min within-condition) from in.modDepthjs
%     meanAcrossLabelsModDepths = [];
%     for iDataset = 1 : numel( files{iCondition} )
%         in = load( files{iCondition}{iDataset} ); 
%         myMeanAcrossLabelsModDepths = mean( in.modDepths, 2 );
%         meanAcrossLabelsModDepths = [meanAcrossLabelsModDepths; myMeanAcrossLabelsModDepths];
%     end
%     meanAcrossLabelsModDepths = meanAcrossLabelsModDepths(validDatasetChannels);
%     meanModEachCondition{iCondition} = meanAcrossLabelsModDepths;

    % Interim new way: |Speech modulation| for each (>1Hz) channel, where FR is averaged across the time window
    % set in in.params.comparisonStartEvent etc. Subtracts silence firing rates. Then takes the abs value for each 
    % speech label. Finally, averages across the five labels. 
   meanAcrossLabelsModDepths = [];
   for iDataset = 1 : numel( files{iCondition} )
        in = load( files{iCondition}{iDataset} ); 
        
        if params.baselineSubtract
            wordFR = in.speechMod.wordFR - in.speechMod.baselineFR;
            silenceFR = in.speechMod.silenceFR - in.speechMod.silenceBaselineFR;
        else
            wordFR = in.speechMod.wordFR;
            silenceFR = in.speechMod.silenceFR;
        end
        
        % subtract silence from each       
        silenceSubtractedMeanFR = wordFR - repmat( silenceFR, size( wordFR, 1 ), 1 );
        % take mean across labels of absoluve value change
        
        myMeanAcrossLabelsModDepths = mean( abs( silenceSubtractedMeanFR ) )';
        meanAcrossLabelsModDepths = [meanAcrossLabelsModDepths; myMeanAcrossLabelsModDepths];
    end
    meanAcrossLabelsModDepths(~validDatasetChannels) = nan;
    meanModEachCondition{iCondition} = meanAcrossLabelsModDepths;

    fprintf('Mean %s modulation depth = %.3f Hz, median = %.3fHz\n', ...
       upper( conditionNames{iCondition} ), nanmean( meanAcrossLabelsModDepths ), nanmedian( meanAcrossLabelsModDepths ) );
  
   
   % outlier bin
   numOutliers = nnz( meanAcrossLabelsModDepths > XLIM(end) );
   fprintf('  Setting %i outlier values to %.1f\n', numOutliers,  binEdges(end) )
   meanAcrossLabelsModDepths(meanAcrossLabelsModDepths > XLIM(end)) = binEdges(end);
   h(iCondition) = histogram( meanAcrossLabelsModDepths(validDatasetChannels), 'BinWidth', binWidth, 'BinEdges', binEdges );
  

   h(iCondition).EdgeColor = 'none';
   h(iCondition).FaceColor = colors(iCondition,:);
   
   line( [nanmean( meanAcrossLabelsModDepths ) nanmean( meanAcrossLabelsModDepths )], [0 max(h(iCondition).Values)+1], ...
       'Color', colors(iCondition,:) );

end
fprintf('%i dataset-electrodes across %i datasets\n', numel( meanAcrossLabelsModDepths(validDatasetChannels) ), numel( files ) )
legh = legend( h, conditionNames );

axh = gca;
axh.TickDir = 'out';

%% Statistics. 
if numel( meanModEachCondition ) > 1 
    [p,h] = signrank( meanModEachCondition{1}, meanModEachCondition{2} );
    fprintf('sign-rank test p=%g\n', p )
    [p,h] = ranksum( meanModEachCondition{1}, meanModEachCondition{2} );
    fprintf('ranksum test p=%g\n', p );
end
% Can do paired comparison since we have an electrode in each condition
