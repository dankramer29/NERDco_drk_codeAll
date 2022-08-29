gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 500);
setModelParam('holdTime', 500);

% choose 12x12 grid
numTargets = 12^2;
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_12X12));
addCuedRandomGridSequence(300, numTargets); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;

resetDisplay2;

enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);