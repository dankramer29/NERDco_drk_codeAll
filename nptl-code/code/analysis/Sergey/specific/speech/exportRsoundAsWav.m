% The purpose of this script is to take R structs with audio data,
% and to export a wav file for each trial.
%

% Sergey D. Stavisky, Stanford Neural Prosthetics Translational Laboratory,
% 8 June 2019,

clear
saveWavTo = [ResultsRootNPTL filesep 'speech' filesep 'wav' filesep];
if ~isdir( saveWavTo )
    mkdir( saveWavTo )
end

%% t5.2019.01.23 Slutzky Extended Words List

Rlist = {...
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B1.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B2.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B3.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B4.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B5.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B6.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B7.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B8.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B9.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B10.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B11.mat';
    '/media/sstavisk/ExtraDrive1/Results/speech/Rstructs/R_t5.2019.01.23_B12.mat';
};

audioField = 'audio'; % name of field in R struct with audio dat
labelField = 'speechLabel'; % if not empty, will append this to filename (it's nice to have the word in the filename).

%% Loop through R structs
for iR = 1 : numel( Rlist )
    fprintf('Loading %i/%i %s\n', iR, numel( Rlist ), Rlist{iR} )
    in = load( Rlist{iR} );
    [~, Rname] = fileparts( Rlist{iR} );
    for iTrial = 1 : numel( in.R )
        myAudio = in.R(iTrial).(audioField);
        myFs = in.R(iTrial).audioFs;
        if ~isempty( labelField )
            myLabel = in.R(iTrial).(labelField);
            myFilename = sprintf('%s%s_trial%04i_%s.wav', ...
                saveWavTo, Rname, iTrial, myLabel );
        else
            myFilename = sprintf('%s%s_trial%04i.wav', ...
                saveWavTo, Rname, iTrial );
        end
    
        audiowrite(myFilename, myAudio, myFs);
        fprintf(' wrote %s\n', myFilename )
    end
    
end
fprintf('DONE\n')