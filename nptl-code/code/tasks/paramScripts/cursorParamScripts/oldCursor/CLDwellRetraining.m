setModelParam('pause', true)
setModelParam('targetDiameter', 150)
setModelParam('holdTime', 500)
setModelParam('maxTaskTime',floor(1000*60*4));
setModelParam('cursorDiameter', 50)
setModelParam('trialTimeout', 6000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('showScores', false);

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
%setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
setModelParam('failOnLiftoff', false);

setModelParam('recenterOnFail', true);
setModelParam('soundOnFail', false);
setModelParam('recenterOnSuccess', false);
setModelParam('recenterDelay',0);


% enable error assist
setModelParam('errorAssistR', 0.2);
setModelParam('errorAssistTheta', 0.05);


numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = double(zeros([2, double(cursorConstants.MAX_TARGETS)]));
targetIndsMat(:,1:numTargetsInt)  = double(4.09)*double([0    71   100  71   0     -71  -100 -71;
                                                        100  71   0    -71  -100  -71  0    71]);

setModelParam('workspaceY', double([-520 520]));
setModelParam('workspaceX', double([-939 939]));

setModelParam('targetInds', int16(targetIndsMat));

%% neural decode
loadFilterParams;
startContinuousMeansTracking(false, false);

disp('unpauseExpt will happen automatically in 3 seconds');
pause(1)
disp('2 seconds left.');
pause(1)
disp('1 second left.');
pause(1)
disp('unpausing experiment.');
unpauseExpt