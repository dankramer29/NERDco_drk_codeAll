gridTask;
gridDwellTask;

setModelParam('maxTaskTime',1000*60*2);

setModelParam('dwellRefractoryPeriod', 700);
setModelParam('holdTime', 900);
setModelParam('cumulativeDwell', true);

% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_6X6));

%addCuedRandomGridSequence(300, 36); % set number of "trials" and keyboard size
addCuedRandom6x6GridSequenceEdge(300);


%% neural decode
loadFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(2);
setModelParam('resetDisplay', false);

enableBiasKiller();
%setModelParam('biasCorrectionVelocityThreshold',0.1);
setModelParam('biasCorrectionTau',20000);

setBiasFromPrevBlock();

disp('Press any key to unpauseExpt');
pause;

unpauseExpt
