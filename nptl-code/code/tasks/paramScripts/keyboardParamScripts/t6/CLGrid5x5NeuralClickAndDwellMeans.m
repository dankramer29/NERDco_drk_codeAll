gridTask;
gridNeuralClickAndDwellTask;


% choose 6x6 grid
setModelParam('keyboard', uint8(keyboardConstants.KEYBOARD_GRID_5X5));

addCuedRandomGridSequence(300, 25); % set number of "trials" and keyboard size

%% neural decode
loadFilterParams;
% neural click
loadDiscreteFilterParams;

setModelParam('resetDisplay', true);
clear pause % sometimes the 'pause' variable gets set by build scripts
pause(4);
setModelParam('resetDisplay', false);


try
    % presumably meansTrackingInitial was loaded above. now reset the
    % meansTracker to take in those values
    setModelParam('meansTrackingEnable',true);
    setModelParam('meansTrackingPeriodMS',30000);
    setModelParam('meansTrackingUseFastAdapt', true);
    setModelParam('meansTrackingResetToCurrent', true);
    setModelParam('meansTrackingResetToCurrent', false);
catch
    disp('CLWestCoast8FastAdaptive: warning: couldn''t set meansTrackingResetToInitial');
end

disp('Pausing for 30 seconds. Afterwards, unpauseExpt will happen automatically');
pause(10)
disp('20 seconds left.');
pause(10)
disp('10 seconds left.');
pause(5)
disp('5 seconds left.');
pause(2)
disp('3 seconds left.');
pause(1)
disp('2 seconds left.');
pause(1)
disp('1 second left.');
pause(1)
disp('unpausing experiment.');
unpauseExpt