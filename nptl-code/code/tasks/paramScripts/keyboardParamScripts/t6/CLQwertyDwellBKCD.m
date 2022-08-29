typingTaskDwellOnly();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    uint8(keyboardConstants.ACQUIRE_DWELL));



setModelParam('keyboardDims', uint16([240 150 1440 850]));

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('clickRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', true);


% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));
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



