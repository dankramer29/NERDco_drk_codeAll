setModelParam('pause', true);
setModelParam('targetDiameter', 150);
setModelParam('holdTime', 350);
setModelParam('cursorDiameter', 45);
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 160);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('expRandMu', 0); %% this is the trial delay length parameter
setModelParam('expRandMin', 500);
setModelParam('expRandMax', 1500);
setModelParam('expRandBinSize', 100);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(cursorConstants.TASK_CENTER_OUT));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_THUMB_INDEX_POS_TO_POS));
setModelParam('showScores', false);

% original values at start of session
gain_x = 3.35; % touchpadX
gain_y = 2.4; % touchpadY
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);
setModelParam('gloveBias', [4840 3440 1700 2000 2000]);
setModelParam('gloveXCorrection', 2.5);
setModelParam('gloveYCorrection', 1.3);

numTargetsInt = uint16(4);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
%targetIndsMat(:,1:numTargetsInt)  = [0 484 0 -484; 409 0 -409 0];
targetIndsMat(:,1:numTargetsInt)  = [0 409  0 -409; 409 0 -409 0];

setModelParam('workspaceY', double([-539 539]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));

%% glove Low-pass Filter params
[gloveLPFb, gloveLPFa] =  cheby2(5, 30, 0.02);
setModelParam('gloveLPNumerator', [gloveLPFb, zeros(1, 5)]);
setModelParam('gloveLPDenominator', [gloveLPFa, zeros(1, 5)]);
setModelParam('useGloveLPF', true);
