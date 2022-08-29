gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', true);


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));
addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(2);
setModelParam('resetDisplay', false);

% enableBiasKiller();
% setBiasFromPrevBlock();

gain_x = 4000;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y 0 0 0]);

% in case you want to change task duration
% setModelParam('maxTaskTime',1000*60*6);


doResetBK = true;

unpauseOnAny(doResetBK);
