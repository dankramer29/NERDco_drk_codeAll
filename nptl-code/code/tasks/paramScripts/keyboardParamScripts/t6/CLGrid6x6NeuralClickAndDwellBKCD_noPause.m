gridTask;
gridNeuralClickAndDwellTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));

addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
setModelParam('resetDisplay', false);


enableBiasKiller();
setBiasFromPrevBlock();

%% update HMM threshold
updateHMMThreshold(0.80, 0); % open loop training params, prompt for block for recalc of likelihoods

disp('press any key to unpauseExpt');
pause();
resetBiasKiller();
unpauseExpt