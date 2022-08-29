% Loads an example block of the t5-extendedWords dataset. Plots rasters, audio, and task
% event times for an example trial.
%
% Note: I'm using this script to generate an example panel for Shaul+Krishna+Jaimie's SNI
% Seed Grant application.
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 12 March 2019
%



% Where to find the example block 
blockFile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2019.01.23_B1.mat'; % one of twelve blocks


params.thresholdRMS = -4.5; % spikes happen below this RMS

exampleTrial = 114; % plot this trial

%% Load the block and get rasters
in = load( blockFile );
R = in.R;
fprintf('Loaded %s which contains %i trials\n', ...
    blockFile, numel( R ) );

% Threshold the voltage excursions of these data to get spike rasters. 
% This uses NPTL git repo code.
% (already done in files sent to Shaul)
% RMS = channelRMS( R ); % compute rms of the block
% R = RastersFromMinAcausSpikeBand( R, params.thresholdRMS .*RMS );

%% Plot this trial
figh = figure;
figh.Color = 'w';
[~, bname] =  fileparts( blockFile );
titlestr = sprintf('%s trial %i ''%s''', ...
  bname, exampleTrial, R(exampleTrial).speechLabel );
figh.Name = titlestr;

% PLOT AUDIO
axh_audio = subplot( 2, 1, 1 );
% the audio was saved at 30ksps. Give it ms time labels
myAudio = R(exampleTrial).audio;
myAudioT = [1 : numel(myAudio)] ./ (R(exampleTrial).audioFs/1000);
plot( myAudioT, myAudio, 'Color', 'k');
ylabel('Audio (AU)');
axh_audio.TickDir = 'out';
box off;

% Put important ticks down
xTicks = [0 1000]; % useful for drawing scale bar
xTicks(3) = R(exampleTrial).goCue;
xTicks(4) = R(exampleTrial).timeSpeech;
xTickLabels = {'', '1s', 'Go', 'AO'};
axh_audio.XTick = xTicks;
axh_audio.XTickLabel = xTickLabels;
% also: 
% R(exampleTrial).trialStart is when the cue was thrown on screen 

% PLOT RASTERS
myRasters = R(exampleTrial).spikeRaster;
axh_raster = subplot( 2, 1, 2 );
linkaxes([axh_audio, axh_raster], 'x' )
% easy way with imagesc (I don't use it for figures because it hides spikes when shrunk down)
imagesc( myRasters )
colormap( flipud( gray ) )

% hard way: vectorized rasters
% rasterCells = {};
% for i = 1 : size( myRasters, 1 )
%     rasterCells{i} = find( myRasters(i,:) ); % once cell per channel
% end
% axh_raster.TickDir = 'out';
% xlimits = [ 0 size( myRasters, 2 ) ];
% axh_raster = drawRasters( axh_raster, rasterCells, xlimits, 'tickColor', 'k', 'tickWidth', 2 );
% box off;
% xlim(xlimits)
