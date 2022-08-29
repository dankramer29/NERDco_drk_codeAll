% Part of the continuous speaking pipeline. This script takes a block-long audio file (as
% a .wav), and uses the accompanying .textGrid (manual annotation done in PRAAT) to pull
% out individual passages' audio. These are saved as .wav. It also uses the annotation to
% pull out the corresponding prompted text, and saves that as a .txt with the same name.
%
% TODO: Also split apart the corresponding spikes and HLFP files
%
% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory
% 18 July 2019


%% PTB Dataset
% Inputs live here
% promptsFile = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/treebankTaskLog_13-Jun-2018_15-33-24.mat'];
% annotationDir = [ResultsRootNPTL '/speech/contSpeech/annotate'];

% Leopard
annotationDir = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/'];
promptsFile =  [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/treebankTaskLog_13-Jun-2018_15-33-24.mat'];

% each block described here
% Block 1
% longWav = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_1_audio.wav'];
% longHLFP = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_1_HLFP.mat'];
% longRasters = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_1_spikeRasters.mat'];

% Block 2
% longWav = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_2_audio.wav'];
% longHLFP = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_2_HLFP.mat'];
% longRasters = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_2_spikeRasters.mat'];

% Block 3
% longWav = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_3_audio.wav'];
% longHLFP = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_3_HLFP.mat'];
% longRasters = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_3_spikeRasters.mat'];

% Block 4
longWav = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_4_audio.wav'];
longHLFP = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_4_HLFP.mat'];
longRasters = [ResultsRootNPTL '/speech/contSpeak/t5.2018.06.13/block_4_spikeRasters.mat'];

% longWav = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/block_1_audio.wav'];
% longWav = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/block_2_audio.wav'];
% longWav = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/block_3_audio.wav'];
% longWav = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/block_4_audio.wav'];


% Outputs will go here
saveToDir = [CachedDatasetsRootNPTL '/NPTL/t5.2018.06.13 penntree/splitPassages/'];
if ~isdir( saveToDir )
    mkdir( saveToDir )
end

%% MOCHA-TIMIT Dataset:
% TODO: fill this in

% promptsFile = [CodeRootNPTL '/code/analysis/Sergey/specific/speech/MochaTimitText.mat'];



%% Load the big wav and prompts
[inW, Fs] = audioread( longWav );
inPrompts = load( promptsFile );
fprintf('Loaded %.2f seconds of audio from %s\n', ...
    numel( inW )/Fs, longWav )


%% Load the textGrid
[~, wavFilename] = fileparts( longWav );
tgFilename = sprintf('%s/%s.TextGrid', annotationDir,  wavFilename );
tg = tgRead( tgFilename );
fprintf('Loaded %i passage start/stop annotatins from %s\n', ...
    numel( tg.tier{1}.Label ), tgFilename )

%% Load the HLFP
inHLFP = load( longHLFP );
fprintf('Loaded %.2f seconds (%i channels) of HLFP data from %s\n', ...
    size( inHLFP.HLFP_dat, 1 ) /inHLFP.FsHLFP,  size( inHLFP.HLFP_dat, 2 ), longHLFP );
%Note: this will reveal that the HLFP starts 1 second after the audio and
%spike rasters; this is due to filter edges in the filtering code I used. 
% See AddBandPower.m, where default CLIPENDSECS is 1. (1 second is overkill, yes, I think that's a hard-coded value in the LFP
%filtering stack). Will need to account for this offset when grabbing data
%snippets below. 


%% Load the rasters
inRasters = load( longRasters );
fprintf('Loaded %.2f seconds (%i channels) of spike rasters from %s\n', ...
    size( inRasters.spikeRasters, 1 ) /inRasters.FsSpikeBand,  size( inRasters.spikeRasters, 2 ), longRasters );

%% Go through each event in the textgrid annotation

for i = 1 : numel( tg.tier{1}.Label )
    % Read in the label for this segment
    myLabel = tg.tier{1}.Label{i};
    
    % Make sure it's valid
    if isempty( myLabel )
        continue
    end
    % non-empty label. Get its corresponding text.
    myPassageNum = str2num( myLabel );    
    if isempty( myPassageNum )
        error('label #%i is ''%s'', wheras a counting number is expected. Check annotation.', i, myLabel )
    end
    fprintf('Passage named ''%s''\n', myLabel )
    
    % Get the text for it
    [promptText, promptNum] = TrimScreenText( inPrompts.formattedForScreenText{myPassageNum} );
    % warn if promptNum doesn't match what the manual segmentation label had
    if promptNum ~= myPassageNum
        fprintf( '[%s] Warning: the passage number in the prompt log file is %i, whearas the manual annotation has it as %i.\n', ...
            mfilename, promptNum, myPassageNum );
    end
    
    %% Save the prompted text
    thisTextFile = sprintf('%spassage_%03i.txt', ...
        saveToDir, myPassageNum );
    fid = fopen( thisTextFile, 'w');
    fprintf( fid, '%s', promptText );
    fclose( fid );
    fprintf(' Wrote %s\n', thisTextFile )
    
    %% Grab the corresponding audio snippet
    startSec = tg.tier{1}.T1(i);
    endSec = tg.tier{1}.T2(i);
    
    startSample = round( startSec * Fs );
    endSample = round( endSec * Fs );
    myDurS = (endSample - startSample)/Fs;
    thisWavFile = sprintf('%spassage_%03i.wav', ...
        saveToDir, myPassageNum );
    audiowrite( thisWavFile, inW(startSample:endSample), Fs );

    fprintf(' Wrote %.1f s audio to %s\n', myDurS, thisWavFile)
    
    %% Grab the corresponding spike raster snippet
    [tMatch, startSample] = FindClosest( inRasters.spikeBand_timeStamps_secs, startSec );
    if abs( tMatch - startSec ) > 0.005
        error('no time match')
    end
    [tMatch, endSample] = FindClosest( inRasters.spikeBand_timeStamps_secs, endSec );
    if abs( tMatch - endSec ) > 0.005
        error('no time match')
    end
    spikeRasters = inRasters; % copy big file, then trim it
    spikeRasters.fromLargerFile = longRasters;
    spikeRasters.spikeBand_timeStamps_secs = spikeRasters.spikeBand_timeStamps_secs(startSample:endSample);
    spikeRasters.spikeRasters = spikeRasters.spikeRasters(startSample:endSample,:);
    thisRastersFile = sprintf('%spassage_%03i_spikeRasters.mat', ...
        saveToDir, myPassageNum );
    save( thisRastersFile, 'spikeRasters' );
    fprintf(' Wrote %.1f s spike rasters to %s\n', size( spikeRasters.spikeRasters, 1 )/spikeRasters.FsSpikeBand, thisRastersFile)

     %% Grab the corresponding HLFP snippet
    [tMatch, startSample] = FindClosest( inHLFP.HLFP_timeStamps_secs, startSec );
    if abs( tMatch - startSec ) > 0.005
        error('no time match')
    end
    [tMatch, endSample] = FindClosest( inHLFP.HLFP_timeStamps_secs, endSec );
    if abs( tMatch - endSec ) > 0.005
        error('no time match')
    end
    HLFP = inHLFP; % copy big file, then trim it
    HLFP.fromLargerFile = longHLFP;
    HLFP.HLFP_timeStamps_secs = HLFP.HLFP_timeStamps_secs(startSample:endSample);
    HLFP.HLFP = HLFP.HLFP_dat(startSample:endSample,:);
    HLFP = rmfield( HLFP, 'HLFP_dat' ); % more consisent naming
    thisHLFPFile = sprintf('%spassage_%03i_HLFP.mat', ...
        saveToDir, myPassageNum );
    save( thisHLFPFile, 'HLFP' );
    fprintf(' Wrote %.1f s HLFP  to %s\n', size( HLFP.HLFP, 1 )/HLFP.FsHLFP, thisHLFPFile)

    
end