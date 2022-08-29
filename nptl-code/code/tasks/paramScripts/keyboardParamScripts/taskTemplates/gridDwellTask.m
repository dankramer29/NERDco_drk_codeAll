setModelParam('holdTime', 200);

%setModelParam('gainK', [1 1 1.4 1.4 1]);
%setModelParam('scaleXk', [1 1 0.8 0.8 1]);


setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_DWELL));
setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
