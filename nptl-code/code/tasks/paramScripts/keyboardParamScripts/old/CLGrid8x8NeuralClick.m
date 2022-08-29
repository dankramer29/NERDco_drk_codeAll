gridTask;
gridNeuralClickTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_8X8));

addCuedRandomGridSequence(50, 64);

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

%addCuedRandomGridSequence(100);
