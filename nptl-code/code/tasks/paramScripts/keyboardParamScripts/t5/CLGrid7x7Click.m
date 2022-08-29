gridTask;
gridNeuralClickAndDwellTask;

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_7X7));
addCuedRandomGridSequence(300, 49); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

resetDisplay2;

updateHMMThreshold(0.9, 0);

enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);