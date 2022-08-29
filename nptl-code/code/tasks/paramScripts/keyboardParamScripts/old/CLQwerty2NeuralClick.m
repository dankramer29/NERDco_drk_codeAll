typingTaskNeural();

setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));

setModelParam('keyboardDims', uint16([240 150 1440 850]));

% choose qwerty2
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_QWERTY2));

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
