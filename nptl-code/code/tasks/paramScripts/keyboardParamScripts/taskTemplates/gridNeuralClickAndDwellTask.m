%setModelParam('gainK', [1 1 1.4 1.4 1]);
%setModelParam('scaleXk', [1 1 0.8 0.8 1]);

% dwell hold time
setModelParam('holdTime', 1000);
% click hold time
setModelParam('clickHoldTime', uint16(30));
% trying 45 ms - 2016-10-10
%setModelParam('clickHoldTime', uint16(45));

% click params
setModelParam('hmmClickSpeedMax', 0.6);
% the hmmResetOnFast is causing bad behavior. just cut it.
setModelParam('hmmResetOnFast',false);
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
disp('warning: gridNeuralClickAndDwellTask is not updating HMM threshold - make sure you are doing that somewhere else');
%updateHMMThreshold(0.96, 0); % set HMM threshold, no prompt for new likelihoods (use last built from buildHMM)
setHMMThreshold()

% allow click and dwell acquire
 setModelParam('acquireMethods', ...
     bitor(uint8(keyboardConstants.ACQUIRE_CLICK), uint8(keyboardConstants.ACQUIRE_DWELL)));

setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
setModelParam('inputType', uint16(cursorConstants.INPUT_TYPE_DECODE_V));
