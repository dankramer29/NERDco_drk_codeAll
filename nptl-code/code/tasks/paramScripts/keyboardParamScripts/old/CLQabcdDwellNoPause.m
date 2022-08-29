typingTaskNeural();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    uint8(keyboardConstants.ACQUIRE_DWELL));


setModelParam('keyboardDims', uint16([240 150 1440 850]));

setModelParam('dwellRefractoryPeriod', 1000);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('holdTime', 1200);


% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QABCD));
setModelParam('showStartStop', false);
setModelParam('maxTaskTime',1000*60*3);

addCuedText

%% neural decode
loadFilterParams;
% neural click


setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(1);
setModelParam('resetDisplay', false);
setModelParam('initialState', uint16(KeyboardStates.STATE_MOVE));

startContinuousMeansTracking(false,false);

disp('unpauseExpt will happen automatically in 3 seconds');
pause(1)
disp('2 seconds left.');
pause(1)
disp('1 second left.');
pause(1)
disp('unpausing experiment.');
unpauseExpt



