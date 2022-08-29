gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 1000);
setModelParam('holdTime', 1200);

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_5X5));

addCuedRandomGridSequence(300, 25); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
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