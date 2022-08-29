radial8Task

% different task - no back
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT_NO_BACK));

% bigger
setModelParam('targetDiameter', 150)
setModelParam('cursorDiameter', 50)

% longer
setModelParam('trialTimeout', 100000);

% recenter
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true);
setModelParam('recenterDelay',300);
setModelParam('soundOnFail', false);

% closer 8
numTargetsInt = uint16(8); % 8 targets
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
                                     409 289   0 -289 -409 -289    0 289];
setModelParam('targetInds', int16(targetIndsMat));
setModelParam('workspaceY', double([-520 520]));
setModelParam('workspaceX', double([-940 940]));


% neural decode
loadFilterParams;

enableBiasKiller();
setModelParam('biasCorrectionTau',20000);

setBiasFromPrevBlock();

unpauseOnAny;

resetBiasKiller();