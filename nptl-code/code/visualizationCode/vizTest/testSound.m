PsychPortAudio('Close')
sp = [];
if ~exist('sp','var') || ~isfield(sp,'audioHandle')
    sp.audioHandle = PsychPortAudio('Open', [], [], 0, 44100, 1);
end

sp.oneSec=10000;%oneSec = 4095;
beepTime = round(sp.oneSec/4);
freq_factor = 5;
sp.beep=sin(1/freq_factor*(1:0.5:beepTime));
sp.lowbeep1=sin(1/freq_factor*(0.75*(1:0.5:beepTime)));
sp.lowbeep2=sin(1/freq_factor*(0.5*(1:0.5:beepTime)));
sp.extralowbeep=sin(1/freq_factor*(0.35*(1:0.5:beepTime)));
sp.hitbeep=[sp.lowbeep1 sp.beep];
sp.missbeep=[sp.lowbeep2 sp.extralowbeep];

% PsychPortAudio('FillBuffer', sp.audioHandle, sp.hitbeep);
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% pause(1);
% y = wavread('../sounds/rigaudio/EC_go.wav')';
% PsychPortAudio('FillBuffer', sp.audioHandle, y(1,:));
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% pause(0.5);
% y = wavread('../sounds/rigaudio/C#C_failure.wav')';
% PsychPortAudio('FillBuffer', sp.audioHandle, y(1,:));
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% pause(0.5)
% % y = wavread('../sounds/rigaudio/EC_go.wav')';
% % PsychPortAudio('FillBuffer', sp.audioHandle, y(1,1:floor(end/9)));
% % PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% 
% y = loadvar('../sounds/tap.mat','sound');
% PsychPortAudio('FillBuffer', sp.audioHandle, y);
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% 
% pause(0.5);
% y = wavread('../sounds/rigaudio/EC_go.wav')';
% killind = floor(length(y)/4)+1;
% PsychPortAudio('FillBuffer', sp.audioHandle, y(1,1:killind));
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% pause(0.5);
% y2 = y;
% dampen = zeros([1 length(y)-killind+1]);
% t=1:length(dampen);
% dampen = exp(-(t-1)*0.001);
% y2(1,killind:end)=y2(1,killind:end).*dampen;
% PsychPortAudio('FillBuffer', sp.audioHandle, y2);
% PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);
% 


[y,fs,nb] = wavread('../sounds/movementCue/index.wav');
y = resample(y,44100,fs);
y=y';
PsychPortAudio('FillBuffer', sp.audioHandle, y(1,1:end));
PsychPortAudio('Start', sp.audioHandle, 1, 0, 0);

