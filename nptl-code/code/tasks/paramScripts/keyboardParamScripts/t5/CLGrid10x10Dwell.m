gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 500);

% choose 10x10 grid
numTargets = 10^2;
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_10X10));
addCuedRandomGridSequence(300, numTargets); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;

resetDisplay2;


enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);