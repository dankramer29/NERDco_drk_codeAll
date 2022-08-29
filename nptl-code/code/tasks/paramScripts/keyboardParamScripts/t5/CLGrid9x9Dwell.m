gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', true);

% choose 9x9 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_9X9));
addCuedRandomGridSequence(300, 81); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;

resetDisplay2;

% set to 0.7
updateHMMThreshold(0.7, 0);

enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);