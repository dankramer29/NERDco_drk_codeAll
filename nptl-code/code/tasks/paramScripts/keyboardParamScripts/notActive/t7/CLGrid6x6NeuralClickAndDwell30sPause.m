gridTask;
gridNeuralClickAndDwellTask;

setModelParam('dwellRefractoryPeriod', 800);
setModelParam('clickRefractoryPeriod', 800);
setModelParam('holdTime', 1800);
setModelParam('hmmClickSpeedMax', 0.35);

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;



setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(1);
setModelParam('resetDisplay', false);

startContinuousMeansTracking(true, true);
%startDiscreteMeansTracking();

thirtySecondPause();
unpauseExpt
