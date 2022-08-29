% Loads and visualizes a snippet of the continuous speaking data in order to give a sense
% of what these data are and what the various key variables are.
% Also plays the audio snippet to give a sense of what the PennTree Task sounded like.
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboraotry
% October 2018



% Example data files:
% audioFile = '/Users/sstavisk/Results/speech/contSpeech/block_3_audio.mat';
% rastersFile = '/Users/sstavisk/Results/speech/contSpeech/block_3_spikeRasters.mat';

% MOCHA-TIMIT
audioFile = '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_2_audio.mat';
rastersFile = '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_2_spikeRasters.mat';



startAt = 5.05*60; % where in the file to plot (e.g. from 5 minutes to 5:45 in)
endAt = 5.75*60;

% zoomed in rasters, in seconds
rasterStartAt = 308;
rastersEndAt = 308.7;




[~, name] = fileparts( audioFile );
blockName = regexprep( name, '_audio', '');

% Load the the continous speaking data
inAudio = load( audioFile );

audInds = floor( startAt*inAudio.FsRaw):ceil(endAt*inAudio.FsRaw);
mySampleAudio = inAudio.audioDat(audInds);
mySampleAudio_t = inAudio.audioTimeStamps_secs(audInds);



% Load the spike rasters
inRasters = load( rastersFile );
startSpikesInd = find( inRasters.spikeBand_timeStamps_secs >= startAt, 1, 'first' );
endSpikesInd = find(  inRasters.spikeBand_timeStamps_secs > endAt, 1, 'first' );
myRasters = inRasters.spikeRasters(startSpikesInd:endSpikesInd,:);
myRasters_t = inRasters.spikeBand_timeStamps_secs(startSpikesInd:endSpikesInd);


% also prepare Gaussian-smoothed firing rate across the arrays
FR = sum( myRasters,2 )./size(myRasters,2).*1000; % normalize by # electrodes and multiply by 1000 to be in Hz
[FRsmooth, kernel] = smoothdata(FR,'gaussian',3*200); %whole Gaussian fits in a 600 ms, so roughly 200 ms S.D.

%% Plot the data
figh = figure; figh.Color = 'w';
figh.Name = sprintf('Example data from %s\n', blockName );
% plot the audio
axh_audio = subplot( 4,1,1 );
plot( mySampleAudio_t, mySampleAudio, 'k', 'LineWidth', 2 );
ylabel('Audio');
% plot the zoom in line
yzoom = axh_audio.YLim(1)+ 0.1*range( axh_audio.YLim);
lzoom = line( axh_audio, [rasterStartAt, rastersEndAt], [yzoom yzoom], 'LineWidth', 2, 'Color', 'b' )

% plot the spike rasters
axh_rasters = subplot( 4,1, [2,3] );
axh_rasters.TickDir = 'out';
axh_rasters.Box = 'off';
imagesc( myRasters_t, 1:size(myRasters,2), myRasters' );
colormap([1 1 1; 0 0 0]);
ylabel('Spike rasters (electrode #)');
% plot average spike rate.
axh_FR = subplot( 4, 1, 4 );
plot( myRasters_t, FRsmooth, 'Color', 'b', 'LineWidth', 2 );
ylabel( 'Smoothed population rate (Hz)');
xlabel( 'Time in block (seconds)' )
axh_FR.TickDir = 'out';
linkaxes( [axh_audio, axh_rasters, axh_FR], 'x')
xlim( [myRasters_t(1), myRasters_t(end)] )
set( findall( figh ,'-property','FontSize') ,'FontSize', 16)

%% Separate figure for zoom in rasters
% vectorized plot
startSpikesInd = find( inRasters.spikeBand_timeStamps_secs >= rasterStartAt, 1, 'first' );
endSpikesInd = find(  inRasters.spikeBand_timeStamps_secs > rastersEndAt, 1, 'first' );
myRastersZoom = inRasters.spikeRasters(startSpikesInd:endSpikesInd,:);
myRastersZoom_t = inRasters.spikeBand_timeStamps_secs(startSpikesInd:endSpikesInd);
rasterCells = {};
for i = 1 : size( myRastersZoom, 2 )
    rasterCells{i} = find( myRastersZoom(:,i) );
end
figh_zoom = figure; figh_zoom.Color = 'w';
axh_zoom = axes;
axh_zoom.TickDir = 'out';
xlimits = [ 0 size( myRastersZoom, 1 ) ];

axh_zoom = drawRasters( axh_zoom, rasterCells, xlimits, 'tickColor', 'k', 'tickWidth', 2 );


%% Play the example audio. Comment out if you don't want it to play.
playbackObj = audioplayer( mySampleAudio, inAudio.FsRaw  );
playbackObj.play;

