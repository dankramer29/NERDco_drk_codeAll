% Targets appear at a random location within the workspace boundary. Their
% sizes are randomly chosen from the target
% closed loop for T5
%
% March 6 2017, Sergey Stavisky


% Determine target sizes. These go by factor of 2 in the volume space
[diameters,volumes] = targetDiameterListByHypervolume(0.029, 4, 4); % 5 steps, doubling volume each time, from smallest size
diametersList = single(zeros(1, cursorConstants.MAX_DIAMETERS));
diametersList(1:numel(diameters)) = diameters;
fprintf('Possible Target Diameters are %s\n', mat2str( diameters, 4 ) ); 
setModelParam('randomTaskTargetDiameters', diametersList) 
% setModelParam('randomTaskTargetRotDiameters', diametersList) 
% Workspace boundaries
setModelParam('randomTaskBoundaries', single([-0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10; 0 0]) );
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 0.029)
setModelParam('trialTimeout', 20000);
setModelParam('maxTaskTime',floor(1000*60*10)); % 10 minute max
setModelParam('numTrials', 96);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_RANDOM));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('mouseOffset', [0 0]);
setModelParam('preTrialLength',20 );
%% 
setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
enableBiasKiller;
setBiasFromPrevBlock;
% setModelParam('biasCorrectionEnable',false); % rigH DEV

% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

% Linear gain?
gain_x = 1;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

% Exponetial gain?
setModelParam('powerGain', 1)
setModelParam('powerGainUnityCrossing', 1e-04)

doResetBK = false;
unpauseOnAny(doResetBK);