% findBreaths.m
%
% Takes in a structure with breath transducer data (loaded by processBreathingDataset.m)
% and returns a vector of sample indicies corresponding to the inhalation maximums. Does
% some signal conditioning first to smooth out data and remove bad data points, prior to
% looking for peaks.
%
% USAGE: [ breathSamples, smoothBreath ] = findBreaths( sBreath, params, varargin )
%
% EXAMPLE:   [bTimesThisBlock, smoothBreath] = findBreaths( inB, params );
%
% INPUTS:
%     sBreath                   Structure with key field .audioDat which is a Tx1 vector
%                               of breath transducer voltage
%     params                    
%
% OUTPUTS:
%     breathSamples             indices into when the sBreath.audioDat corresponding to
%                               breath peaks
%     smoothBreath              vector of the breath sensor data (sBreath.audioDat) once
%                               it's been filtered and smoothed.
%
% Created by Sergey Stavisky on 03 Dec 2018 using MATLAB version 9.3.0.713579 (R2017b)

function [ breathSamples, smoothBreath ] = findBreaths( sBreath, params, varargin )
def.blockName = [];
def.showPlots = false;
assignargs ( def, varargin );

if showPlots
    figh = figure;
    plot( sBreath.audioTimeStamps_secs, sBreath.audioDat )
    figName = sprintf( 'Raw and filtered %s', blockName );
    title( figName );
    figh.Name = figName;
    hold on;
end

%% 1. Remove outlier values where the diff is huge
dB = diff( sBreath.audioDat );
dBM = abs( dB );
outlierInds = find( dBM > params.removeDiffGreaterThan ) + 1;
% it goes up and down, so ignore second of each pair
outlierInds = outlierInds(1:2:end);
fprintf('  [%s] Removing %i outlier samples\n', mfilename, numel( outlierInds ) );

bDat = sBreath.audioDat;
bDat(outlierInds) = nan;

%% 2. Low pass filter
d = designfilt('lowpassiir','FilterOrder',6, ...
         'PassbandFrequency', params.filterPb,'PassbandRipple', params.filterAp , ...
         'SampleRate', sBreath.FsRaw);
lpDat = filtfilt( d, double( bDat ) );
if showPlots
    plot( sBreath.audioTimeStamps_secs, lpDat, 'k', 'LineWidth', 2 )
end

%% 3. Find 'big peaks' (with large time between them) which I use to calibrate what a large prominence is
bigPeakMinDistance = 5; % seconds
% figh = figure;
% plot( sBreath.audioTimeStamps_secs, lpDat, 'k', 'LineWidth', 2 )
% hold on;
[pks, locs, widths, proms] = findpeaks( lpDat, 'MinPeakDistance', bigPeakMinDistance*sBreath.FsRaw );
% sh = scatter( locs/sBreath.FsRaw, pks, 'filled', 'MarkerFaceColor', [1 0 0] );
medianBigProminence = median( proms );
fprintf('  Median prominence of %i big peaks is %.2f\n', numel( proms ), medianBigProminence )
fprintf('  Will look for breaths with prominence of %.2f with minimum distance of %.1fs\n', ...
    params.minPeakProminenceFractionOfBigPeak*medianBigProminence, params.minPeakDistance )

%% 4. Find peaks using scpeified min distance using the specified fraction of big prominence
[pks, locs, widths, proms] = findpeaks( lpDat, 'MinPeakDistance', params.minPeakDistance*sBreath.FsRaw,  ...
    'MinPeakProminence', params.minPeakProminenceFractionOfBigPeak*medianBigProminence   );
if showPlots
    figh = figure;
    figName = sprintf( 'Breaths %s', blockName );
    title( figName );
    figh.Name = figName;
    plot( sBreath.audioTimeStamps_secs, lpDat, 'k', 'LineWidth', 2 )
    hold on;
    sh = scatter( locs/sBreath.FsRaw, pks, 'filled', 'MarkerFaceColor', [1 0 1], 'SizeData', 100 );
end
%% return breath samples and the smoothed breath sensor measurement
breathSamples = locs;
smoothBreath = lpDat;
end