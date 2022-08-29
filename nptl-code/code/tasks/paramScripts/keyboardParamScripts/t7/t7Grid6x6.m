gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 1000);
setModelParam('holdTime', 1400);
setModelParam('cumulativeDwell', true);
setModelParam('recenterFullscreen',true);
setModelParam('recenterOnSuccess',true);
setModelParam('recenterOnFail',true);
setModelParam('recenterDelay',500);

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));

addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(2);
setModelParam('resetDisplay', false);

enableBiasKiller();
setBiasFromPrevBlock();
startContinuousMeansTracking(true,true);
thirtySecondPause();
% now disable mean updating
setModelParam('meansTrackingPeriodMS',0);
resetBiasKiller();

unpauseExpt
