gridTask;
gridNeuralClickTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_7X7));

addCuedRandomGridSequence(50, 49);

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
