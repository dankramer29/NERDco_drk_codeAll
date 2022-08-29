setModelParam('pause', true);
setModelParam('targetDiameter', 100);
setModelParam('holdTime', 750);
setModelParam('cursorDiameter', 45);
setModelParam('trialTimeout', 10000);
setModelParam('numTrials', 150);
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

%% trackpad position to position gain parameters
gain_x = 1.3;
gain_y = 2.8;
setModelParam('gain', [gain_x gain_y]);
setModelParam('mouseOffset', [0 0]);
setModelParam('gloveBias', [4900 2980 1700 2000 2000]);

numTargetsInt = uint16(8);
setModelParam('numTargets', numTargetsInt);
targetIndsMat = int16(zeros([2, double(cursorConstants.MAX_TARGETS)]));
%targetIndsMat(:,1:numTargetsInt)  = [0 316 484 316 0 -316 -484 -316; 409 316 0 -316 -409 -316 0 316];
targetIndsMat(:,1:numTargetsInt)  = [  0 289 409  289    0 -289 -409 -289; ...
                                     409 289   0 -289 -409 -289    0  289];

setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));


setModelParam('targetInds', int16(targetIndsMat));

%% glove Low-pass Filter params
[gloveLPFb, gloveLPFa] =  cheby2(5, 30, 0.02);
setModelParam('gloveLPNumerator', [gloveLPFb, zeros(1, 5)]);
setModelParam('gloveLPDenominator', [gloveLPFa, zeros(1, 5)]);
setModelParam('useGloveLPF', true);