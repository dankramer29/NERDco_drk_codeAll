% Runs after processBreathingDataset.m and applies a RMS
% thresholding to the spike minAcausalSpikeBand in order to get spike
% rasters. I break these operations up so that it's quick and easy to
% rethreshold as desired.
%
% Basically same as thresholdContinuousSpeakingSpikeBand.m
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 9 November 2018


clear

%% List the spike band files to be thresholded
params.thresholdRMS = -4.5; 

% Free breathing blocks
% fileList = {...
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_0_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_1_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_2_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_3_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_4_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_5_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_6_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_passive_spikeBand.mat';
%     };

% Cued breathing blocks
fileList = {...
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_9_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_10_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_11_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_12_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_13_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_14_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_15_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_16_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_17_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_18_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_19_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_20_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_21_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_22_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/breathing/t5.2018.10.24/block_23_spikeBand.mat';
    };

minAcausAll = []; % will store all blocks' minAcausBand. Useful for seeing if there's an abrupt shift.
rollovers = []; % when files changed (useful for making sense of minAcausAll)
thresholdsEachFile = {};
for iFile = 1 : numel( fileList )
    fprintf('Processing %s...\n', fileList{iFile} );
    in = load( fileList{iFile} );
    FsSpikeBand = in.FsSpikeBand; % copy
    rollovers(iFile) = size( minAcausAll, 1 );
    minAcausAll = [minAcausAll; in.spikeBand_dat];
    spikeBand_RMS = in.spikeBand_RMS;
    spikeBand_timeStamps_secs = in.spikeBand_timeStamps_secs;
    spikeRasters = false( size( in.spikeBand_dat ) ) ;
    for iChan = 1 : size( in.spikeBand_dat, 2 )
        myThresh = spikeBand_RMS(iChan) * params.thresholdRMS;
        spikeRasters(:,iChan) = in.spikeBand_dat(:,iChan) < myThresh;
        thresholdsEachFile{iFile}(iChan) = myThresh;
    end
    
    % Save this file
    newName = regexprep( fileList{iFile}, 'spikeBand', 'spikeRasters' );
    fprintf('Saving %s... ', newName );
    save( newName, 'spikeRasters', 'FsSpikeBand', 'spikeBand_timeStamps_secs', 'spikeBand_RMS' )
    fprintf('OK\n')
end
rollovers(end+1) = size( minAcausAll, 1 );

%% Plot minAcausBand for an example channel:
exampleChan = 99;
markTime = 1184*1000; 
figh = figure;
figh.Name = sprintf('minAcausAll for chan%i', exampleChan );
plot( minAcausAll(:,exampleChan ) );
hold on;
ylabel('minAcausAll (uV)')
xlabel('ms')
colors = spring( numel( fileList ) );
for iFile = 1 : numel( fileList )
    lh= plot( [rollovers(iFile) rollovers(iFile+1)], [thresholdsEachFile{iFile}(exampleChan) thresholdsEachFile{iFile}(exampleChan)], ...
        'Color', colors(iFile,:) );
end
axh = gca;
line( [markTime, markTime], axh.YLim, 'Color', 'k')