gridTask;
gridNeuralClickAndDwellTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));
setModelParam('maxTaskTime', 30*1000);
setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_DECODE_V));

addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
