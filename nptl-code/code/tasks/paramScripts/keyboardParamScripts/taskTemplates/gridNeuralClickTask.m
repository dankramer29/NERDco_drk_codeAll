setModelParam('holdTime', 200);

%setModelParam('gainK', [1 1 1.4 1.4 1]);
%setModelParam('scaleXk', [1 1 0.8 0.8 1]);

setModelParam('clickHoldTime', uint16(30));
setModelParam('hmmClickSpeedMax', 0.4);
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
% setHMMThreshold(modelConstants.sessionParams.hmmClickLikelihoodThreshold);
setHMMThreshold()


setModelParam('acquireMethods', uint8(keyboardConstants.ACQUIRE_CLICK));
setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
