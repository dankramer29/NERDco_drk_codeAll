% Plots classification accuracies as bar plots (and one dot for each individual syllable
% or word). Also shows chance range.
%
% Sergey Stavisky, Neural Prosthetics Translational Laboratory, August 21 2019
%
%
%
%
clear



% Results files, including shuffle tests, were generated by WORKUP_classifySpeech.m
resultsFiles = {...
    [ResultsRootNPTL '/speech/classification/t5.2017.10.23-phonemes_54372a56624ed46ef4a330e5d60a75ce.mat']; % T5-phonemes
    [ResultsRootNPTL '/speech/classification/prompt/t5.2017.10.23-phonemes_0d791a10ed5c0dfcbb9ae4b506c2d365.mat']; % T5-phonemes PROMPT
    [ResultsRootNPTL '/speech/classification/t5.2017.10.25-words_3e44dc66b956d1f7ce0dfb072e402867.mat']; % T5-Words
    [ResultsRootNPTL '/speech/classification/prompt/t5.2017.10.25-words_c7f12ac5f7a4d05644e0cbaa4769df4b.mat']; % T5-phonemes PROMPT
    [ResultsRootNPTL '/speech/classification/t8.2017.10.17-phonemes_938d80c0b9ac485e6ea6ad3cdc397b85.mat']; % T8-phonemes
    [ResultsRootNPTL '/speech/classification/prompt/t8.2017.10.17-phonemes_69a7e6f4bb1539fb9aedc602df8a910c.mat']; % T8-phonemes PROMPT
    [ResultsRootNPTL '/speech/classification/t8.2017.10.18-words_566566985dff6e14bad31dd07e8ec75d.mat']; % T8-Words
    [ResultsRootNPTL '/speech/classification/prompt/t8.2017.10.18-words_d3f3144470c21cb9ddfa88297a70b5ab.mat']; % T8-Words PROMPT
};





%% Aesthetic
maxVal = 100;
XLIM = [0 30];

%% Get key data from all files
overallPerf = [];
eachClassPerfs = {};
% chance performance for each file
chanceMax = [];
chanceMean = [];
chanceMin = [];

for iFile = 1 : numel( resultsFiles )
    in = load( resultsFiles{iFile} );
    
    % sanity check: are there 101 shuffles
    assert( in.params.numShuffles == 101 )
    
    % overall and individual class performances
    overallPerf(iFile) = 100.* in.classifyResult.classificationSuccessRate; % percentage
    numSuccess = diag( in.classifyResult.confuseMat );
    numTotal = sum( in.classifyResult.confuseMat, 2 );   
    eachClassPerfs{iFile} = 100 .* numSuccess./numTotal;
    
    % Chance (shuffle)
    chanceMean(iFile) = in.classifyResult.meanShuffle;
    chanceMax(iFile) = in.classifyResult.maxShuffle;
    chanceMin(iFile) = in.classifyResult.minShuffle;
end



%% Prepare figure
figh = figure;
figh.Name = 'Classification  comparisons';
hold on
figh.Color = 'w';


lineWidth = 10;
axh = gca; 

xlim( [0 numel( resultsFiles )+1] );
ylim( [0 100] );
axh.TickDir = 'out';
axh.XTick = [];


% plot chance

for iFile = 1 : numel( resultsFiles )
   
    % For each dataset, plot its mean classification accuracy bar    
    barMean = line( axh, [iFile iFile], [0 overallPerf(iFile)], 'LineWidth', lineWidth, ...
        'Color', 0.7.* [1 0 0]);
    
    % chance performacne
    lh = line( [iFile-0.4 iFile+0.4], [chanceMin(iFile) chanceMin(iFile)], 'Color', [.5 .5 .5]); 
    lh = line( [iFile-0.4 iFile+0.4], [chanceMean(iFile) chanceMean(iFile)], 'Color', [.3 .3 .3]);
    lh = line( [iFile-0.4 iFile+0.4], [chanceMax(iFile) chanceMax(iFile)], 'Color', [.5 .5 .5]);
    
    % plot individual label points
    hSpeechAlone = scatter( axh, iFile.*ones( numel( eachClassPerfs{iFile} ), 1 ), eachClassPerfs{iFile}, ...
        'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'r', 'Parent', axh );
    
    
end