

setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics


% task
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('numDisplayDims', uint8(2) );

% control - decode velocity (override elsewhere if not desired)
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));

% number of trials
setModelParam('numTrials', 160);

% max task duration
setModelParam('maxTaskTime',1000*60*5);

% timing
setModelParam('holdTime', 500);
setModelParam('trialTimeout', 10000);

% task params
setModelParam('targetDiameter', 100);
setModelParam('cursorDiameter', 45);

% other params
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
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

% default gain
gain_x = 0; % so cursor is still during pre state
gain_y = gain_x;
gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('mouseOffset', [0 0]);

% set targets & workspace bounds
numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([double(xkConstants.NUM_TARGET_DIMENSIONS), double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(1:2,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
                                       409 289   0 -289 -409 -289    0 289];
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));
setModelParam('targetInds', single(targetIndsMat));
% other target choices (open loop was 289 & 409...why?
%targetIndsMat(1:2,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
%                                     409 289   0 -289 -409 -289    0 289];
%targetDistanceScale = 3;
%targetIndsMat(:,1:numTargetsInt)  = [ 0  71 100 71 0    -71 -100 -71; ...
%                                    100  71 0  -71 -100 -71 0     71] * targetDistanceScale;

% Set output type last so PTB doesn't flash a bunch of times each time a
% monitored parameter changes. SDS March 2017
setModelParam('pause', false);
pause(0.100); % just enough so game sends over target coordinates before pausing again
% so no flashing of PTB on and off.
setModelParam('pause', true);

