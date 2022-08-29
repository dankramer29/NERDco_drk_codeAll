typingTaskNeural();


% allow click and dwell acquire
setModelParam('acquireMethods', ...
    uint8(keyboardConstants.ACQUIRE_DWELL));

screenMidPoint = [960 540];
gridWidth = 1000; gridHeight = 1000;

setModelParam('keyboardDims', uint16([screenMidPoint - [gridWidth gridHeight]/2 gridWidth gridHeight]));

setModelParam('dwellRefractoryPeriod', 1000);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('holdTime', 1200);


% choose OPTI II
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_OPTIII));
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

startContinuousMeansTracking(false,false);

disp('unpauseExpt will happen automatically in 3 seconds');
pause(1)
disp('2 seconds left.');
pause(1)
disp('1 second left.');
pause(1)
disp('unpausing experiment.');
unpauseExpt

