gridTask;
gridNeuralClickAndDwellTask;

% choose 16x16 grid
numTargets = 16^2;
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_16X16));
addCuedRandomGridSequence(300, numTargets); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

resetDisplay2;

updateHMMThreshold(0.93, 1);

enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);