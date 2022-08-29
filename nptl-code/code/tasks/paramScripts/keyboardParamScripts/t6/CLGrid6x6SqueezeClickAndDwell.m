gridTask;
gridNeuralClickAndDwellTask;

%% threshold value from glove mean readings - CHANGE TO MEAN VALUE FROM GLOVETEST
setModelParam('gloveThreshold', 2300);
gInds = false(5,1);
gInds(1:5) = true; %% MEAN - all five fingers
setModelParam('gloveIndices', gInds);
setModelParam('clickHoldTime', uint16(200));
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_GLOVE));
setModelParam('stopOnClick', true);
setModelParam('hmmClickSpeedMax', 50);
setModelParam('clickRefractoryPeriod', 500);

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));

addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
setModelParam('resetDisplay', false);