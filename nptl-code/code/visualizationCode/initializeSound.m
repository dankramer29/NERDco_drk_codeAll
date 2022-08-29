function initializeSound()

    global soundParams;

    soundParams.oneSec=10000;%oneSec = 4095;
    beepTime = round(soundParams.oneSec/4);
    freq_factor = 5;
    soundParams.beep=sin(1/freq_factor*(1:0.5:beepTime));
    soundParams.lowbeep1=sin(1/freq_factor*(0.75*(1:0.5:beepTime)));
    soundParams.lowbeep2=sin(1/freq_factor*(0.5*(1:0.5:beepTime)));
    soundParams.extralowbeep=sin(1/freq_factor*(0.35*(1:0.5:beepTime)));
    soundParams.hitbeep=[soundParams.lowbeep1 soundParams.beep];
    soundParams.missbeep=[soundParams.lowbeep2 soundParams.extralowbeep];
    
    PsychPortAudio('Close');
    soundParams.audioHandle = PsychPortAudio('Open',[],[],0,44100,1);
    

