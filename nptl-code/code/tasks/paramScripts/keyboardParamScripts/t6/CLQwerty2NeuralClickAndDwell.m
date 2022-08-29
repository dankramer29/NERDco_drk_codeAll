typingTaskNeural();

% allow click and dwell acquire
setModelParam('acquireMethods', ...
    bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));

setModelParam('keyboardDims', uint16([240 150 1440 850]));

% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
setModelParam('resetDisplay', false);