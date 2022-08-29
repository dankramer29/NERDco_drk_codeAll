gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 500);  %SELF: find out if Paul wants this to be like 20x20 (500) or like 10x10 (700)
setModelParam('holdTime', 500);

% choose 14x14 grid
numTargets = 14^2;
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_14X14));
addCuedRandomGridSequence(300, numTargets); % set number of "trials" and keyboard size

% neural decode
loadFilterParams;

resetDisplay2;


enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);