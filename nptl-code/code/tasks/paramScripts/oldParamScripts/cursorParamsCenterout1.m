setModelParam('pause', true)
setModelParam('targetDiameter', 60)
setModelParam('cursorDiameter', 20)
setModelParam('trialTimeout', 30000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 1); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 1);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));


%% IMU position to position
% setModelParam('gain', [1000 1000]);
% setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_IMU_POS_TO_POS));

%% IMU and dataglove, position to position
%% gain parameters
gain_x = -5;
gain_y = 750;
%% neutral positions
thumbNeutral = 1550;
indexNeutral = 1550;
setModelParam('gloveBias', uint16([thumbNeutral indexNeutral 500 500 500]));
setModelParam('gain', [gain_x gain_y]);
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_INDEX_IMU_POS_TO_POS));


%% IMU position to velocity
% setModelParam('gain', [1 1]);
% setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_IMU_POS_TO_VEL));

%thumbNeutral = 1550;
%indexNeutral = 1550;
%setModelParam('gloveBias', uint16([thumbNeutral indexNeutral 500 500 500]));
%% gain parameters
%gain_x = 1.5;
%gain_y = 0.005;
%setModelParam('gain', [gain_x gain_y]);
%setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_INDEX_IMU_POS_TO_VEL));


%% gain parameters
%gain_x = -0.003;
%gain_y = 0.003;
%setModelParam('gain', [gain_x gain_y]);
%setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_VEL));


numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(1.5)*double([0    71   100  71   0     -71  -100 -71;
                                                        100  71   0    -71  -100  -71  0    71]);
setModelParam('targetInds', int16(targetIndsMat));
