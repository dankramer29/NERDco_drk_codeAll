typingTaskDwellOnly();

monitor_scale_factor = 11.75 / 13.25; % 24" monitor height / 27" monitor height
screen_mid_point = [960 575];
keyboard_width = 1440 * monitor_scale_factor;
keyboard_height = 850 * monitor_scale_factor;
setModelParam('keyboardDims', uint16([screen_mid_point - [keyboard_width keyboard_height]/2 keyboard_width keyboard_height]));

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', true);

% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));
setModelParam('showStartStop', false);
setModelParam('maxTaskTime',1000*60*2);

addCuedText

% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(1);
setModelParam('resetDisplay', false);
setModelParam('initialState', uint16(KeyboardStates.STATE_MOVE));

enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;
unpauseOnAny(doResetBK);




