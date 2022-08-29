% Targets appear at a random location within the workspace boundary. Their
% sizes are randomly chosen from the target
% closed loop for T5
%
% March 14 2017, Sergey Stavisky


% Determine target sizes. These go by factor of 2 in the volume space
[diameters,volumes] = targetDiameterListByHypervolume(0.033, 4, 5); % 4 steps, doubling volume each time, from smallest size
diametersList = single(zeros(1, cursorConstants.MAX_DIAMETERS));
diametersList(1:numel(diameters)) = diameters;
fprintf('Possible Target Diameters are %s', mat2str( diameters, 4 ) ); 
setModelParam('randomTaskTargetDiameters', diametersList) 
setModelParam('randomTaskTargetRotDiameters', diametersList) 
% Workspace boundaries
setModelParam('randomTaskBoundaries', single([-0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10]) );
setModelParam('numDisplayDims', uint8(5) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', true )
setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 0.029)
setModelParam('trialTimeout', 15000); % 15s
setModelParam('maxTaskTime',floor(1000*60*15)); % 15 minute max
setModelParam('numTrials', 96);
setModelParam('randomSeed', 1);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_RANDOM));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

numTargetsInt = uint16(26*5);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));


setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));
setModelParam('workspaceR2', double([-0.13 0.13]));
setModelParam('targetInds', single(targetIndsMat));


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;


% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain_r2 = gain_x;
setModelParam('gain', [gain_x gain_y gain_z gain_r gain_r2]);

% Exponetial gain?
% setModelParam('exponentialGainBase', [1.3 1.3 1.3 1.3 1.3])
setModelParam('exponentialGainBase', [1 1 1 1 1])
setModelParam('exponentialGainUnityCrossing', ...
    [3.50e-05 3.50e-5 3.50e-5 3.50e-5 3.50e-5])

doResetBK = false;
unpauseOnAny(doResetBK);