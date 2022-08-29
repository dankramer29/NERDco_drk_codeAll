function unpauseOnAny(doResetBiasKiller)

if ~exist('doReset','var')
    doResetBiasKiller = false;
end

disp('Press any key to unpause expt');
pause;


if doResetBiasKiller
    resetBiasKiller;
end
disp('Starting in 3 seconds!')
pause(3)

unpauseExpt();