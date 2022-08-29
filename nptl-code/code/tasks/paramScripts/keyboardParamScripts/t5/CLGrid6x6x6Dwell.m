% Created 5 December 2016 by Sergey Stavisky
% I'm starting with developing this using PsychToolbox visualizations
% as a bridge until we have SCL visualizations working well. 

%
gridTask;
gridDwellTask;

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', false);

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

setModelParam('gain', [1 1 1 1]);
setModelParam('workspaceX', double([-540 540]));
setModelParam('workspaceY', double([-540 539])); 
setModelParam('workspaceZ', double([-540 540]));

doResetBK = true;

unpauseOnAny(doResetBK);
