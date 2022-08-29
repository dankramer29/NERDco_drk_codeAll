gridTask;
gridNeuralClickTask;


% choose grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_9X9));

addCuedRandomGridSequence(50, 81);

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
