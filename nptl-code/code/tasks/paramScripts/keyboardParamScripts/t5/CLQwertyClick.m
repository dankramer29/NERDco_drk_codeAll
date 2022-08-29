typingTaskNeural();

% allow click and dwell acquire
setModelParam('acquireMethods', ...
    bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));

monitor_scale_factor = 11.75 / 13.25; % 24" monitor height / 27" monitor height
screen_mid_point = [960 575];
keyboard_width = 1440 * monitor_scale_factor;
keyboard_height = 850 * monitor_scale_factor;
setModelParam('keyboardDims', uint16([screen_mid_point - [keyboard_width keyboard_height]/2 keyboard_width keyboard_height]));

% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

addCuedText;

resetDisplay2;

updateHMMThreshold(0.93, 1);

enableBiasKiller();
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);