% Makes scree plots (cumluative variance explianed by component) for the various
% dataset-epochs anlayzed for studying speech-related neural population dynamics.
%
% The variance explained values should have been generated for each dataset with
% WORKUP_speechCIS_regularized.m
%
% Sergey Stavisky, August 18 2019

clear



%% List the variance files

% T5, go cue epoch
% varFiles = {...
%     '/Users/sstavisk/Results/speech/dPCA/regularized/cumvars-t5.2017.10.25-words.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/cumvars-t5.2017.10.23-phonemes.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/cumvars-t5.2018.12.12-words_noRaw.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/cumvars-t5.2018.12.17-words_noRaw.mat';
%     };

% T8, go cue epoch (100 to 700 ms)
varFiles = {...
    '/Users/sstavisk/Results/speech/dPCA/regularized/later/cumvars-t8.2017.10.18-words.mat';
    '/Users/sstavisk/Results/speech/dPCA/regularized/later/cumvars-t8.2017.10.17-phonemes.mat';
    };


% T5, speech on epoch
% varFiles = {...
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t5.2017.10.25-words.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t5.2017.10.23-phonemes.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t5.2018.12.12-words_noRaw.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t5.2018.12.17-words_noRaw.mat';
%     };

% T8, speech on epoch
% varFiles = {...
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t8.2017.10.18-words.mat';
%     '/Users/sstavisk/Results/speech/dPCA/regularized/jPCAepoch/cumvars-t8.2017.10.17-phonemes.mat';
%     };




%%
figh = figure;
figh.Color = 'w';
figh.Name = 'Cumulative Var Explained';
axh = axes;
hold on;
ylim( [0 100] );

Ndatasets = numel( varFiles );

allColors = lines( Ndatasets );

dsetnames = {};
for iDataset = 1 : Ndatasets
    dsetnames{iDataset} = pathToLastFilesep( varFiles{iDataset}, 1 );
    dsetnames{iDataset} = regexprep( dsetnames{iDataset}, 'cumvars-', '');
    dsetnames{iDataset} = regexprep( dsetnames{iDataset}, '.mat', '');
    in = load( varFiles{iDataset} );
    
    % PCA (solid line)
    myPCA = in.explVar.cumulativePCA;
    lh = plot( 1 : numel( myPCA ), myPCA, '-o', 'Color', allColors(iDataset,:) );
    lh.MarkerEdgeColor = 'none';
    lh.MarkerFaceColor = allColors(iDataset,:);
    
    % dCPA (solid line)
    myDPCA = in.explVar.cumulativeDPCA;
    lh = plot( 1 : numel( myDPCA ), myDPCA, ':s', 'Color', allColors(iDataset,:) );
    lh.MarkerEdgeColor = 'none';
    lh.MarkerFaceColor = allColors(iDataset,:);
end

MakeDumbLegend( dsetnames, 'Color', allColors );
xlabel('# Components')
ylabel('Variance explained (%)')

legend( dsetnames );
axh.TickDir = 'out';
axh.XTick(1) = 1;

% % if dPCA with 8 dPCs, add
line([8 8], [0 100])

% if jPCA with 6 jPCs, add
% line([6 6], [0 100])