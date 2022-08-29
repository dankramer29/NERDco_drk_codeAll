%% Script that generates various figures for the speech project.

% 4.6 inches is to accomodate's Science's awful 2 of 3 columns figure max 




%% SUPP. FIG X: Acoustic Spectrograms
pagesize = [9 ,7.5]; % height, width; 

T5_phonemes= '/Users/sstavisk/Figures/speech/acoustic/Spectrogram t5_2017_10_23-phonemes handResponseEvent.fig';
T5_words = '/Users/sstavisk/Figures/speech/acoustic/Spectrogram t5_2017_10_25-words handResponseEvent.fig';
T8_phonemes= '/Users/sstavisk/Figures/speech/acoustic/Spectrogram t8_2017_10_17-phonemes handResponseEvent.fig';
T8_words = '/Users/sstavisk/Figures/speech/acoustic/Spectrogram t8_2017_10_18-words handResponseEvent.fig';


figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



% PHONEMES
includeLabels = labelLists( 'phonemes' );
N = numel( includeLabels ) - 1; %total number of labels plotted
for i = 2 : numel( includeLabels ) % no silence
    colors(i-1,:) = speechColors( includeLabels{i} );
end
figin = open(T5_phonemes); 
inAxes = figin.Children;
% go through each panel and put it in its place based on color (the order is not set for
% some reason, hence this color hack)./
for iAx = 1 : numel( inAxes )
    % find matching color
    myColorInd = find( EqRow(colors, inAxes(iAx).YAxis.Color) );
    if ~isempty( myColorInd )
        axh = subplot(N,4, 4*(myColorInd-1)+1, inAxes(iAx), 'Parent', figh );
    end
    cmap = colormap( 'bone' );
    colormap(axh, flipud( cmap ) );
end

figin = open(T8_phonemes); 
inAxes = figin.Children;
% go through each panel and put it in its place based on color (the order is not set for
% some reason, hence this color hack)./
for iAx = 1 : numel( inAxes )
    % find matching color
    myColorInd = find( EqRow(colors, inAxes(iAx).YAxis.Color) );
    if ~isempty( myColorInd )
        axh = subplot(N,4, 4*(myColorInd-1)+2, inAxes(iAx), 'Parent', figh );
    end
    cmap = colormap( 'bone' );
    colormap(axh, flipud( cmap ) );
end

% WORDS

includeLabels = labelLists( 'words' );
N = numel( includeLabels ) - 1; %total number of labels plotted
for i = 2 : numel( includeLabels ) % no silence
    colors(i-1,:) = speechColors( includeLabels{i} );
end
figin = open(T5_words); 
inAxes = figin.Children;
% go through each panel and put it in its place based on color (the order is not set for
% some reason, hence this color hack)./
for iAx = 1 : numel( inAxes )
    % find matching color
    myColorInd = find( EqRow(colors, inAxes(iAx).YAxis.Color) );
    if ~isempty( myColorInd )
        axh = subplot(N,4, 4*(myColorInd-1)+3, inAxes(iAx), 'Parent', figh );
    end
    cmap = colormap( 'bone' );
    colormap(axh, flipud( cmap ) );
end

figin = open(T8_words); 
inAxes = figin.Children;
% go through each panel and put it in its place based on color (the order is not set for
% some reason, hence this color hack)./
for iAx = 1 : numel( inAxes )
    % find matching color
    myColorInd = find( EqRow(colors, inAxes(iAx).YAxis.Color) );
    if ~isempty( myColorInd )
        axh = subplot(N,4, 4*(myColorInd-1)+4, inAxes(iAx), 'Parent', figh );
    end
    cmap = colormap( 'bone' );
    colormap(axh, flipud( cmap ) );
end
%% SUPP. FIG X: CUE-ALIGNED RESPONSES
pagesize = [4.6 ,7.5]; % height, width; 4.6

T5_phonemes= '/Users/sstavisk/Figures/speech/psths/diff from baseline t5.2017.10.23-phonemes.fig';
T5_words = '/Users/sstavisk/Figures/speech/psths/diff from baseline t5.2017.10.25-words.fig';
T8_phonemes= '/Users/sstavisk/Figures/speech/psths/diff from baseline t8.2017.10.17-phonemes.fig';
T8_words = '/Users/sstavisk/Figures/speech/psths/diff from baseline t8.2017.10.18-words.fig';


figh = figure; figh.Units = 'inches';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )

figin = open(T5_phonemes); 
axh = subplot(2,4, 1, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 5]; pause(0.1); % pause or for some reason axis doesn't get updated
axh = subplot(2,4, 2, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 5]; close( figin ) % Children(1) since it vanishes after first one

figin = open(T5_words); 
axh = subplot(2,4, 5, figin.Children(1), 'Parent', figh );
axh.YLim = [0 5]; pause( 0.1 );
axh = subplot(2,4, 6, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 5]; pause( 0.1) ;close( figin ) 

figin = open(T8_phonemes); 
axh = subplot(2,4, 3, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 3]; pause( 0.1 );
axh = subplot(2,4, 4, figin.Children(1), 'Parent', figh );
axh.YLim = [0 3]; close( figin );

figin = open(T8_words); 
axh = subplot(2,4, 7, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 3];
axh = subplot(2,4, 8, figin.Children(1), 'Parent', figh ); 
axh.YLim = [0 3]; close( figin ) 

%% SUPP. FIG X: Classifier Feature Comparisons
% TODO: consider adding SUA as a feature once that's ready.
pagesize = [4.6 ,7.5]; % height, width; 4.6

T5_phonemes= '/net/derivative/user/sstavisk/Figures/speech/classification/t5_2017_10_23-phonemes feature comparison.fig';
T5_words = '/net/derivative/user/sstavisk/Figures/speech/classification/t5_2017_10_25-words feature comparison.fig';
T8_phonemes= '/net/derivative/user/sstavisk/Figures/speech/classification/t8_2017_10_17-phonemes feature comparison.fig';
T8_words = '/net/derivative/user/sstavisk/Figures/speech/classification/t8_2017_10_18-words feature comparison.fig';


figh = figure; figh.Units = 'inches';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )

figin = open(T5_phonemes); 
axh = subplot(2,2, 1, figin.Children(1), 'Parent', figh ); 

figin = open(T8_phonemes); 
axh = subplot(2,2, 2, figin.Children(1), 'Parent', figh ); 

figin = open(T5_words); 
axh = subplot(2,2, 3, figin.Children(1), 'Parent', figh ); 

figin = open(T8_words); 
axh = subplot(2,2, 4, figin.Children(1), 'Parent', figh ); 


%% dPC plots for all six datasets
% (eLife revisions
pagesize = [9 , 7]; % height, width; 

figFiles = {...
    '/Users/sstavisk/Figures/speech/CIS/regularized/CIS dPCA t5_2017_10_25-words.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/CIS dPCA t5_2017_10_23-phonemes.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/CIS dPCA t5_2018_12_12-words_noRaw.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/CIS dPCA t5_2018_12_17-words_noRaw.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/later/CIS dPCA t8_2017_10_18-words 8dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/later/CIS dPCA t8_2017_10_17-phonemes 8dims.fig';
    };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   figin = open( figFiles{i} ); 
   % dPC var explained bars
   axh = subplot(2, Ndatasets, i, figin.Children(2), 'Parent', figh );
   % scale to maximum
   allDat = [axh.Children(1).YData+ axh.Children(2).YData];
   axh.XLim = [0 max( allDat )];
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';

   % CIS1 projections
   axh = subplot(2, Ndatasets, i + Ndatasets, figin.Children(1), 'Parent', figh );
   axh.Box = 'off';
   allDat = [];
  
   allDat = [axh.Children.YData];
   axh.YLim = [min( allDat ), max( allDat )];
   axh.YAxis.Visible = 'off';

end

%% dPC angle between dPCs plots for all six datasets
% (eLife revisions)
pagesize = [3 , 7]; % height, width; 

figFiles = {...
    '/Users/sstavisk/Figures/speech/CIS/regularized/dPC correlations t5_2017_10_25-words.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/dPC correlations t5_2017_10_23-phonemes.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/dPC correlations t5_2018_12_12-words_noRaw.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/dPC correlations t5_2018_12_17-words_noRaw.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/later/dPC correlations t8_2017_10_18-words 8dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/later/dPC correlations t8_2017_10_17-phonemes 8dims.fig';
    };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   figin = open( figFiles{i} ); 
   cmapin = figin.Colormap;
   % dPC var explained bars
   axh = subplot(1, Ndatasets, i, figin.Children(1), 'Parent', figh );
   axes( axh );colormap( cmapin )
   
   % no x, y axes;just the colormap
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';
end

%% jPCA plots for all six datasets
% (eLife revisions)
pagesize = [3 , 7]; % height, width; 

%jPC1,2 plane plots
figFiles = {...
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t5.2017.10.25-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t5.2017.10.23-phonemes.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t5.2018.12.12-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t5.2018.12.17-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t8.2017.10.18-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/jPCA trajectories t8.2017.10.17-phonemes.fig';
    };

% comparison to surrogates plots
histFiles = {...
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t5.2017.10.25-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t5.2017.10.23-phonemes.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t5.2018.12.12-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t5.2018.12.17-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t8.2017.10.18-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/Surrogate distribution t8.2017.10.17-phonemes.fig';
    };

% these are the prompt-aligned ones
% histFiles = {...
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt/Surrogate distribution t5.2017.10.25-words.fig';
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt//Surrogate distribution t5.2017.10.23-phonemes.fig';
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt//Surrogate distribution t5.2018.12.12-words.fig';
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt//Surrogate distribution t5.2018.12.17-words.fig';
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt//Surrogate distribution t8.2017.10.18-words.fig';
%     '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/jPCA/prompt//Surrogate distribution t8.2017.10.17-phonemes.fig';
%     };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   % jPCA plot 
   figin = open( figFiles{i} );
   axh = subplot(2, Ndatasets, i, figin.Children(1), 'Parent', figh );
   axes( axh );colormap( cmapin )
   
   % Stats plot
   figin = open( histFiles{i} );
   axh = subplot(2, Ndatasets, i+Ndatasets, figin.Children(2), 'Parent', figh );
   hold on;
   axh.XLim = [0 1];
   % ylim is to 110% maximum height
   axh.YLim = [0 1.1*max( axh.Children(2).YData )];
   % no x, y axes;
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';
   

   
   % replace the black circle of original data with a vertical bar
   trueX = axh.Children(1).XData;
   delete( axh.Children(1) );
   axes( axh );
   lh = line( [trueX trueX], axh.YLim, 'Color', 'b');
   
      % no legend
   legend off
end


%% jPCA plots for multiple dimensionalities 
% (eLife revisions, Supp Fig )
pagesize = [3 , 7]; % height, width; 

%jPC1,2 plane plots
figFiles = {...
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 2.fig'; % T5
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 4.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 6.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 8.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 10.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/plane 12.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 2.fig'; % T8
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 4.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 6.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 8.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 10.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/plane 12.fig';
    };

% comparison to surrogates plots
histFiles = {...
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 2.fig'; % T5-Words
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 4.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 6.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 8.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 10.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t5-words/stats 12.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 2.fig'; % T8-Words
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 4.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 6.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 8.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 10.fig';
    '/Users/sstavisk/Figures/speech/jPCA/varyDims/t8-words/stats 12.fig';
    };


Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   % jPCA plot 
   figin = open( figFiles{i} );
   cmapin = figin.Colormap;
   axh = subplot(2, Ndatasets, i, figin.Children(1), 'Parent', figh );
   axes( axh );colormap( cmapin )
   
   % Stats plot
   figin = open( histFiles{i} );
   axh = subplot(2, Ndatasets, i+Ndatasets, figin.Children(2), 'Parent', figh );
   hold on;
   axh.XLim = [0 1];
   % ylim is to 110% maximum height
   axh.YLim = [0 1.1*max( axh.Children(2).YData )];
   % no x, y axes;
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';
   

   
   % replace the black circle of original data with a vertical bar
   trueX = axh.Children(1).XData;
   delete( axh.Children(1) );
   axes( axh );
   lh = line( [trueX trueX], axh.YLim, 'Color', 'b');
   
      % no legend
   legend off
end


%% dPC plots for all T5-words and T8-words across multiple dimensionalities datasets
% (eLife revisions
pagesize = [9 , 7]; % height, width; 

figFiles = {...
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 2dims.fig'; % T5
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 4dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 6dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 8dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 10dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/CIS dPCA t5_2017_10_25-words 12dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 2dims.fig'; % T8
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 4dims.fig'; 
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 6dims.fig'; 
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 8dims.fig'; 
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 10dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/CIS dPCA t8_2017_10_18-words 12dims.fig'; 
    };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )

maxDims = 12; % used to make bars same height across #dims


for i = 1 : Ndatasets
   figin = open( figFiles{i} ); 
   % dPC var explained bars
   axh = subplot(2, Ndatasets, i, figin.Children(2), 'Parent', figh );
   % scale to maximum
   allDat = [axh.Children(1).YData+ axh.Children(2).YData];
   axh.XLim = [0 max( allDat )];
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';
   
   % makes bars same height across #dims plots
   axh.YLim = [0 maxDims+1];

   % CIS1 projections
   axh = subplot(2, Ndatasets, i + Ndatasets, figin.Children(1), 'Parent', figh );
   axh.Box = 'off';
   allDat = [];
  
   allDat = [axh.Children.YData];
   axh.YLim = [min( allDat ), max( allDat )];
   axh.YAxis.Visible = 'off';

end

%% dPC angle between dPCs plots for multiple dimensionalities for T5-words and T8-words (supplementary fig)
% (eLife revisions)
pagesize = [3 , 7]; % height, width; 

figFiles = {...
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 2dims.fig'; % T5-Words
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 4dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 6dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 8dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 10dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/dPC correlations t5_2017_10_25-words 12dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 2dims.fig'; % T8-Words
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 4dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 6dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 8dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 10dims.fig';
    '/Users/sstavisk/Figures/speech/CIS/regularized/varyDims/later/dPC correlations t8_2017_10_18-words 12dims.fig'; 
    };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   figin = open( figFiles{i} ); 
   cmapin = figin.Colormap;
   % dPC var explained bars
   axh = subplot(1, Ndatasets, i, figin.Children(1), 'Parent', figh );
   axes( axh );colormap( cmapin )
   
   % no x, y axes;just the colormap
   axh.XAxis.Visible = 'off';
   axh.YAxis.Visible = 'off';
end

%% Reaction time histograms
pagesize = [3 , 7]; % height, width; 

figFiles = {...
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/RT histograms/RTs t5.2017.10.23-phonemes.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/RT histograms/RTs t8.2017.10.17-phonemes.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/RT histograms/RTs t5.2017.10.25-words.fig';
    '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/RT histograms/RTs t8.2017.10.18-words.fig';
    };

Ndatasets = numel( figFiles );

figh = figure; figh.Units = 'inches';
figh.Color = 'w';
pos = get( figh, 'Position');
pos(4) = pagesize(1);
pos(3) = pagesize(2);
set( figh, 'Position', pos )



for i = 1 : Ndatasets
   figin = open( figFiles{i} ); 
   
   axh = subplot(1, Ndatasets, i, figin.Children(1), 'Parent', figh );
   axes( axh );
   
   ch = get( axh, 'Children');
   ch(2).BinWidth = 100;
   ch(1).YData = [60 80]; %median
   
   xlim([500 2000]);
   ylim([0 80]);
   axh.TickDir = 'out';
   
   box off
   
   % no x, y axes;just the colormap
%    axh.XAxis.Visible = 'off';
%    axh.YAxis.Visible = 'off';
end
