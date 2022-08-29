% Makes the dendrograms and articulator grouping wtihin vs between-groups figures.
% NOTE: For some reason MATLAB has trouble reading all the phoneme characters which are
% UTF-16, so I work around this by loading them from a separate .txt file. Otherwise, when
% the .m function is closed, some characters turn into '?'.
% 
%
% 10 September 2019,
% Sergey D. Stavisky and Guy Wilson, Stanford Neural Prosthetics Translational Laboratory
clear

% data file provided by Guy:
% datFile =  '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/manyWords/updated/moses_fig_data_-70_to_50.mat';
% datFile =  '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/manyWords/moses_fig_data.mat';
% datFile =  '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/manyWords/100 ms/moses_fig_data.mat';
datFile =  '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/manyWords/150 ms/moses_fig_data.mat'; % elife revisions
SCALE_DISTS = 1000; % convert to hz


% datFile =  '/Users/sstavisk/Google Drive/Speech Paper/Figures/source/manyWords/150 ms 2 bins/moses_fig_data.mat';
% SCALE_DISTS = 1000/sqrt(2); % convert to hz, divide by sqrt(2) because 2 features per channel

% bunch of awkward reading from text file to get around the fact that MATLAB doesn't
% really handle UTF-16 well, so it needs to read the txt and then get those chars from
% that
fid = fopen( 'place_of_articulation_phones.txt', 'r', 'n', 'UTF-16' );
[~,~,~,encoding] = fopen( fid );
mosesLabels = textscan(fid, '%s', 'Delimiter', ',' );
mosesLabels = mosesLabels{1}';
% Place of articulation grouping
groups{1} = [1 5]; % Labial
groups{2} = [6 18]; % Coronal (note: last 4 are Palato-alveolar as a secondary feature, but can be reasonably grouped as coronal)
groups{3} = [19 19]; % palatal
groups{4} = [20 23];  % velar
groups{5} = [24 24]; % glottal
groups{6} = [25 27]; % high front vowel
groups{7} = [28 28]; % low front vowel
groups{8} = [29 30]; % central vowel
groups{9} = [31 32]; % high back vowel
groups{10} = [33 36]; % low back vowel
groups{11} = [37 41]; % dipthongs

for iGroup = 1 : numel( groups )
    groups{iGroup} = mosesLabels(groups{iGroup}(1):groups{iGroup}(2));
end
% read these from mosesLabels

% groups{3}
groupColor{1} = [10 90 35]./255;
groupColor{2} = [249 145 17]./255;
groupColor{3} = [0 0 0]; % need my own color
groupColor{4} = [36 173 206]./255;
groupColor{5} = [174 219 65]./255;
groupColor{6} = [246 14 71]./255;
groupColor{7} = [24 15 109]./255;
groupColor{8} = [0 0 0]; % need my own color
groupColor{9} = [166 53 151]./255;
groupColor{10} = [23 146 50]./255;
groupColor{11} = [28 149 194]./255;



% SCALE_DISTS = 50; % convert to hz


%% 
in = load( datFile );


% Moses distance matrix
mosesDists = in.moses_ordered;
% convert to hz
mosesDists = mosesDists.*SCALE_DISTS; %(because rates are in 20 ms bins)
figh_dists = figure;
axh_dists = axes;
imh = imagesc( mosesDists );
colorbar
axis square
axh_dists.TickDir = 'out';
box off
colormap('cool');

axh_dists.XTick = 1 : size( mosesDists,1);
axh_dists.XTickLabel = mosesLabels;
axh_dists.YTick = 1 : size( mosesDists,1);
axh_dists.YTickLabel = mosesLabels;

% now add grouping boxes
for iGroup = 1 : numel( groups )
    myStart = find( strcmp( mosesLabels, groups{iGroup}{1} ) );
    myEnd = find( strcmp( mosesLabels, groups{iGroup}{end} ) );
    myPos = [myStart-0.5, myStart-0.5, myEnd-myStart+1, myEnd-myStart+1];
    hrect(iGroup) = rectangle( 'Position', myPos, 'EdgeColor', groupColor{iGroup} );
    hrect(iGroup).LineWidth = 3;
end


%% Violin plots
figh_violin = figure; 
axh_violin = subplot(1,2,1);
datMat = nan( size( in.empirical_between, 2 ), 2 );
datMat(1:numel(in.empirical_within),1) = in.empirical_within;
datMat(:,2) = in.empirical_between;
dat.within = SCALE_DISTS*in.empirical_within;
dat.between = SCALE_DISTS*in.empirical_between;

vh = violinplot( dat );
vh(1).ShowMean = true;
vh(2).ShowMean = true;
ylabel('Population firing rate distance')
true_dist =  mean( dat.between ) - mean( dat.within );
fprintf('Mean BETWEEN - WITHIN distance is %g\n', true_dist);

% Compare to shuffles
axh_shuffles =  subplot(1,2,2);
nullDat = SCALE_DISTS*in.null_diffs; 
histh = histogram( nullDat );
histh.FaceColor = [.5 .5 .5];
histh.EdgeColor = 'none';
axh_shuffles.TickDir = 'out';
xlabel('Between - Within Distance')
line([true_dist true_dist], axh_shuffles.YLim, 'Color', 'k', 'LineWidth', 2 );

fprintf('True distance is greater than %i/%i shuffles\n', ...
    nnz( true_dist > nullDat ), numel( nullDat ) )

fprintf('Mean of diagonals is %f\n', SCALE_DISTS*mean( diag( in.distances ) ) );