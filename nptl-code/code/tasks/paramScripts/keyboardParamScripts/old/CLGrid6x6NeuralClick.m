gridTask;
gridNeuralClickTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));

addCuedRandomGridSequence(70, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;
