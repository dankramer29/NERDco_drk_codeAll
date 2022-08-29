% Takes audiofiles, converts them into MATLAB-friendly .mat files.
% Part of code for running minimal viable experiment to survey for neural tuning in motor
% cortex when a participant hears or produces language-related sounds.
%
% Sergey D. Stavisky, 2017, Stanford Neural Prosthetics Translational Laboratory.

filePath = [CodeRoot '/NPTL/code/tasks/heardAndSpoken/soundFiles/'];

% Movement Cues
% fileList = {...
%     'tongueRight.m4a';
%     'tongueDown.m4a';
%     'tongueLeft.m4a';
%     'tongueUp.m4a';
%     'mouthOpen.m4a';
%     'lipsForward.m4a';
%     'lipsBack.m4a';
%     'stayStill.m4a';
%     'return.m4a';
%     };

% Phonemes
fileList = {...
    'i.m4a';
    'ae.m4a';
    'a.m4a';
    'u.m4a';
    'ba.m4a';
    'da.m4a';
    'ga.m4a';
    'sh.m4a';
    'k.m4a';    
    't.m4a';
    'p.m4a';    
    'silence.m4a';
    };

% Words
fileList = {...
    'beet.m4a';
    'bat.m4a';
    'bot.m4a';
    'boot.m4a';
    'dot.m4a';
    'got.m4a';
    'shot.m4a';
    'keep.m4a';
    'seal.m4a';    
    'more.m4a';
};

fileList = {...
    'beep.mp3';
    'metronomeShort.wav';
    }
    

% fileList = {...
%     'arm.wav';
%     'beach.wav';
%     'metronomeup.wav';
%     'pull.wav';
%     'push.wav';
%     'tree.wav';
%     'beep.mp3'; 
%     'ba.aiff';
%     'da.aiff';
%     'ga.aiff';
%     'oo.aiff';
%     'sh.aiff';
%     };


for i = 1 : numel( fileList )
    soundName = fileList{i};
    [y,Fs] = audioread( [filePath fileList{i}] );
    if size( y, 2 ) == 2 % if it's stero, make mono
        y = sum(y,2);
        fprintf('Making %s mono from stereo\n', soundName );
    end

    soundName = regexprep(soundName, {'.wav', '.mp3', '.aiff', '.m4a'}, '');
    save( [filePath soundName], 'y', 'Fs' )
    
    % some hard-coded shortenings of sound files, determined by hand 
    if strcmp( soundName, 'metronomeup')
        y = y(1:9000);
    end
    fprintf('Created %s, duration %.1f ms\n', ...
        soundName, 1000*numel(y)/Fs )
    
    % now play it.
    sobj = audioplayer( y, Fs );
    sobj.playblocking;
end