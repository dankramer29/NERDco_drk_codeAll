% Targets appear at a random location within the workspace boundary. Their
% sizes are randomly chosen from the target
% closed loop for T5
%
% March 6 2017, Sergey Stavisky


% Click Fails
setModelParam('falseClickFails', false)
setModelParam('selectionRefractoryMS', uint16( 500 ) ); % grace period. Used for both click and dwell

% % Click Fails
% setModelParam('falseClickFails', true)
% setModelParam('selectionRefractoryMS', uint16( 0 ) ); % grace period. Used for both click and dwell

setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( inf ) ); % no max speed
% setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % 



% Determine target sizes. These go by factor of 2 in the volume space
[diameters,volumes] = targetDiameterListByHypervolume(0.029, 4, 4); % 5 steps, doubling volume each time, from smallest size
diametersList = single(zeros(1, cursorConstants.MAX_DIAMETERS));
diametersList(1:numel(diameters)) = diameters;
fprintf('Possible Target Diameters are %s\n', mat2str( diameters, 4 ) ); 
setModelParam('randomTaskTargetDiameters', diametersList) 
% setModelParam('randomTaskTargetRotDiameters', diametersList) 
% Workspace boundaries
setModelParam('randomTaskBoundaries', single([-0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10; -0.10 0.10]) );
setModelParam('numDisplayDims', uint8(4) );
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR))  % this is important
setModelParam('showXYZaura', false )
setModelParam('pause', true)
setModelParam('holdTime', inf)
setModelParam('cursorDiameter', 0.029)
setModelParam('trialTimeout', 10000);
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

setModelParam('recenterOnFail', false); % will do nothing unless recenterDelay >= 1 s
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay', 0);
setModelParam('preTrialLength',20 );


setModelParam('mouseOffset', [0 0]);


% Get the coordinates for all the radial targets


setModelParam('workspaceY', double([-0.13 0.13]));
setModelParam('workspaceX', double([-0.13 0.13]));
setModelParam('workspaceZ', double([-0.13 0.13]));
setModelParam('workspaceR', double([-0.13 0.13]));

%% Click parameters
cursor_click_enable;


%% neural decode
loadFilterParams;

% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);
% enableBiasKiller;
% setBiasFromPrevBlock;



% neural click
loadDiscreteFilterParams;
updateHMMThreshold(0.90, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% a bit brittle, will fail if hmm wasn't trained this time
setModelParam('clickHoldTime', uint16(60)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 



% startContinuousMeansTracking(true, true);  %SELF/TODO: add iterative rebuilds during block instead of means-tracking, so modulation due to intended movement or click is accounted for 
% now disable mean updating
% setModelParam('meansTrackingPeriodMS',0);

%% Linear gain?
gain_x = 0.9;
gain_y = gain_x;
gain_z = gain_x;
gain_r = gain_x;
gain = getModelParam('gain');
gain(1:4) = [gain_x gain_y gain_z gain_r];
setModelParam('gain', gain);

%%
% Exponetial gain?
setModelParam('powerGain', 1)
setModelParam('powerGainUnityCrossing', 4.5e-05)

doResetBK = false;
unpauseOnAny(doResetBK);