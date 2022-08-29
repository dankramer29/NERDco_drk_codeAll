% Look at breath sensor data from breath transducer
%
%
clear



% dataFile = '/Users/sstavisk/CachedDatasets/NPTL/breathing/breathing008.ns5';
dataFile = '/Users/sstavisk/CachedDatasets/NPTL/breathing/1_cursorTask_Complete_t5_bld(001)002.ns5';
params.transducerChannel = 'c:99';




params.filterAp = 0.2; % passband ripple
params.filterPb = 3; % passband (Hz)
params.filterAst = 50; % stop band attenuation (dB)

%% Load
in = openNSx( 'read', dataFile, params.transducerChannel ); % audio
FsRaw = in.MetaTags.SamplingFreq;
t = [0 : numel( in.Data{end} )-1]./FsRaw; % in seconds



%% Smooth
d = designfilt('lowpassiir','FilterOrder',6, ...
         'PassbandFrequency', params.filterPb,'PassbandRipple', params.filterAp , ...
         'SampleRate', FsRaw);
lpDat = filtfilt( d, double( in.Data{end} ) );
rawDat = in.Data{end}(2*FsRaw:end-2*FsRaw);
lpT = t(2*FsRaw:end-2*FsRaw);


%% Plot

figh = figure;
figh.Color = 'w';
[~, fname ] = fileparts( dataFile );
title( fname, 'Interpreter', 'none' );
% plot( t, in.Data ); % blue is raw
xlabel( 'Seconds', 'FontSize', 16);
ylabel( 'Belt Length (au)', 'FontSize', 16 )
hold on; 


% cut off first and last 2 seconds because of filtering
lpDat = lpDat(2*FsRaw:end-2*FsRaw);
plot( lpT, lpDat, 'k' )
% plot( lpT, rawDat, 'Color', [.5 .5 .5] )