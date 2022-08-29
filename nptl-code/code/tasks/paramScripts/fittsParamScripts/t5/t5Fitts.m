% Our standard 2D monthly Fitts task


setModelParam('pause', true)
setModelParam('holdTime', 500)
setModelParam('cursorDiameter', 19)
setModelParam('trialTimeout', 15000);
setModelParam('numTrials', 600);
setModelParam('maxTaskTime',1000*60*5.1);
setModelParam('randomSeed', 1);
setModelParam('useRandomDelay', 0);
setModelParam('failurePenalty', 0);
setModelParam('taskType', uint32(fittsConstants.TASK_FITTS));
setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));
setModelParam('initialInput', uint32(cursorConstants.INPUT_TYPE_NONE));
try
    setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics
catch
    % it hasn't been recompiled, no worries.
end
setModelParam('recenterOnFail', true);
setModelParam('recenterOnSuccess', true);
setModelParam('recenterDelay',0);

td = zeros([1 cursorConstants.MAX_DIAMETERS],'uint16');
td(1:3) = [56 121 196];
setModelParam('targetDiameters', td);
setModelParam('numTargetDiameters', uint16(3));
setModelParam('minTargetDistance', double(10));


%% trackpad position to position gain parameters
% Uncomment blow to use high gain, which is appropriate when using a
% SCL-built decoder for this task. 
% gain_x = 7000;  %to make a 3D decoder's gain roughly correct for this 2D Fitts task (hand-tuned) - SDS & BJ (
% gain_y = gain_x;  %to make a 3D decoder's gain roughly correct for this 2D Fitts task (hand-tuned) 

gain_x = 4000;
gain_y = 4000;

gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = gain_x;
gainCorrectDim(2) = gain_y;
setModelParam('gain', gainCorrectDim);
setModelParam('mouseOffset', [0 0]);

wspX = double([-720 720]);
wspY = double([-540 539]);
setModelParam('workspaceY', wspY);
setModelParam('workspaceX', wspX);
setModelParam('workspaceZ', [0 0]);
setModelParam('workspaceR', [0 0]);


margin = max(double(td))/2;
tgspY = [wspY(1)+margin wspY(2)-margin];
tgspX = [wspX(1)+margin wspX(2)-margin];
setModelParam('targetSpaceY', tgspY);
setModelParam('targetSpaceX', tgspX);

setModelParam('powerGain', 2  )

%% neural decode
loadFilterParams;

% Option to use biasKiller is below
enableBiasKiller([],[],true,model.beta);
setBiasFromPrevBlock;

doResetBK = true;
unpauseOnAny(doResetBK);