radial8Task;

%error_assist_low;

cursor_click_enable;

% neural decode cursor
loadFilterParams;
% neural click
loadDiscreteFilterParams;

% update HMM threshold
updateHMMThreshold(0.85, 0); % open loop training params, prompt for block for recalc of likelihoods

enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;

unpauseOnAny(doResetBK);



