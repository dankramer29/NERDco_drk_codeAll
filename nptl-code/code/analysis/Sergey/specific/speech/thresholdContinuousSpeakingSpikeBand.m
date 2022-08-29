% Runs after processContinuousSpeakingDataset.m and applies a RMS
% thresholding to the spike minAcausalSpikeBand in order to get spike
% rasters. I break these operations up so that it's quick and easy to
% rethreshold as desired.
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory, 8
% October 2018


clear

%% List the spike band files to be thresholded
params.thresholdRMS = -3.5; 

% PennTree
% fileList = {...
%     '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2018.06.13/block_1_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2018.06.13/block_2_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2018.06.13/block_3_spikeBand.mat';
%     '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2018.06.13/block_4_spikeBand.mat';
%     };

% PennTree
fileList = {...
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_2_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_3_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_4_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_5_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_7_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_8_spikeBand.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/contSpeak/t5.2019.05.29/block_9_spikeBand.mat';
    };

for iFile = 1 : numel( fileList )
    fprintf('Processing %s...\n', fileList{iFile} );
    in = load( fileList{iFile} );
    FsSpikeBand = in.FsSpikeBand; % copy
    spikeBand_RMS = in.spikeBand_RMS;
    spikeBand_timeStamps_secs = in.spikeBand_timeStamps_secs;
    spikeRasters = false( size( in.spikeBand_dat ) ) ;
    for iChan = 1 : size( in.spikeBand_dat, 2 )
        myThresh = spikeBand_RMS(iChan) * params.thresholdRMS;
        spikeRasters(:,iChan) = in.spikeBand_dat(:,iChan) < myThresh;
    end
    
    % Save this file
    newName = regexprep( fileList{iFile}, 'spikeBand', 'spikeRasters' );
    fprintf('Saving %s... ', newName );
    save( newName, 'spikeRasters', 'FsSpikeBand', 'spikeBand_timeStamps_secs', 'spikeBand_RMS' )
    fprintf('OK\n')
end