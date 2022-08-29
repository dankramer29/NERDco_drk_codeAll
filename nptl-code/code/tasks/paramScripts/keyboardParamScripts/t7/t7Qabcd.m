typingTaskDwellOnly();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    uint8(keyboardConstants.ACQUIRE_DWELL));



setModelParam('keyboardDims', uint16([240 150 1440 850]));

setModelParam('dwellRefractoryPeriod', 1000);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('holdTime', 1400);
setModelParam('cumulativeDwell', true);
setModelParam('recenterFullscreen',true);
setModelParam('recenterOnSuccess',true);
setModelParam('recenterOnFail',true);
setModelParam('recenterDelay',500);
setModelParam('recenterOffset',[0 100]);


% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QABCD));
setModelParam('showStartStop', false);
setModelParam('maxTaskTime',1000*60*2);

addCuedText

%% neural decode
loadFilterParams;
% neural click


setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(1);
setModelParam('resetDisplay', false);
setModelParam('initialState', uint16(KeyboardStates.STATE_MOVE));
enableBiasKiller();
setBiasFromPrevBlock();
startContinuousMeansTracking(true,true);
thirtySecondPause();
% now disable mean updating
setModelParam('meansTrackingPeriodMS',0);
resetBiasKiller();

unpauseExpt



