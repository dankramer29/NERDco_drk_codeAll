% lower hold time for open loop
setModelParam('holdTime', 950);
setModelParam('trialTimeout', 5000);
setModelParam('autoplayMovementDuration', 50);

setModelParam('numTrials', 128); % real
% setModelParam('numTrials', 64); % DEV


% set to auto aquire targets
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_WIA_HEAD));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_WIA_HEAD));

% open loop specific?
setModelParam('soundOnOverTarget', false);

% T5 asked for slower than it was at 1
gain_x = 0.7;
gain_y = gain_x;
setModelParam('gain', [gain_x gain_y 0 0 0]); % BJ May 2017: now 5D

% Targets
numTargetsInt = uint16(32);
setModelParam('numTargets', numTargetsInt);

targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));  
%targetIndsMat(1:2,1:numTargetsInt)  = [200	-720	40	360	720	720	1480	1800	-720	-720	-880	-560	720	720	558	880	-415	415	-359	359	-283	283	-78	78	-392	392	-311	311	-298 298	-116	116; ...
%                                       -380	-60	-220	-220	130	450	280	-220	-130	-450	-280	-280	-434	-111	-273	-273	285	285	216	216	236	236	273	273	-408	-408	-367	-367	-182	-182	-175	-175];

targetIndsMat(1:2,1:16) = [-720	-720	-880	-560	720	720	560	880	-720	-720	-880	-560	720	720	558	880;
                                        120	440	280	280	130	450	280	280	-130	-450	-280	-280	-434	-111	-273	-273];
targetIndsMat(1:2,17:32)= [-415    415    -359 359 -160 160 -78 78 -392 392 350 -350 248 -248    -116 116;
                           285    285    216    216    310    310    273    273    -408 -408 -270 -270 -285 -285 -175 -175];
%targetIndsMat(1:2,17:32)= [-415	415	-359	359	-283	283	-78	78	-392	392	-311	311	-298	298	-116	116;
%                            285	285	216	216	236	236	273	273	-408	-408	-367	-367	-182	-182	-175	-175];
targetIndsMat(2,1:numTargetsInt) = -targetIndsMat(2,1:numTargetsInt);

% targetIndsMat(1:2,1:numTargetsInt)  = [0 316 447  316    0 -316 -447 -316; ...
%                                      447 316   0 -316 -447 -316     0 316];
setModelParam('targetInds', single(targetIndsMat));

% task
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT_NO_BACK));
setModelParam('numDisplayDims', uint8(2) );
% max task duration
setModelParam('maxTaskTime',1000*60*5);
% Target and cursor sizes
setModelParam('targetDiameter', 70);
setModelParam('cursorDiameter', 20);
% other params
setModelParam('wiaMode',uint16(cursorConstants.WIA_IMAGINE_ONLY_NO_HC));
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 2500); %% this is the trial delay length parameter
setModelParam('expRandMin', 2500);
setModelParam('expRandMax', 2500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('showScores', false);
setModelParam('trialsPerScore', uint16(48));
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);
setModelParam('preTrialLength',20 );
setModelParam('failOnLiftoff', false);
setModelParam('clickPercentage', 0); % all dwell by default
setModelParam('stopOnClick', false);
setModelParam('stopOffTarget', false);
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));
setModelParam('headSpeedCap',single(100.0));
setModelParam('showWiaText',uint16(0));
setModelParam('displayObject',uint8(cursorConstants.BACKGROUND_QUAD_CARDINAL_JOINTS));
setModelParam('discreteOLMode',uint8(0)); %1=with replacement random targets
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

% Brief unpause  so game sends over target coordinates before pausing again
% This avoids having flashing of PTB on and off at game start
setModelParam('pause', false);
pause(0.100); 
setModelParam('pause', true);

unpauseOnAny;

