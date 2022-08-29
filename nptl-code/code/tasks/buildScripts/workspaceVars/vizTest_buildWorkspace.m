%% model tunable parameters
taskParams = createTunableStructure('vizTest','taskParameters', 'taskParamsBus',...
    'targetDiameter',uint16(60),...
    'holdTime',uint16(500),...
    'trialTimeout',uint16(15000),...
    'numTrials',uint16(100),...
    'randomSeed',double(1),...
    'expRandMu',double(700),...
    'expRandMin',double(500),...
    'expRandMax',double(1000),...
    'expRandBinSize',double(200),...
    'taskType',uint32(cursorConstants.TASK_CENTER_OUT),...
    'targetInds',int16(zeros([2, cursorConstants.MAX_TARGETS])),...
    'numTargets',uint16(0),...
    'gain',double([1 1]),...
    'failurePenalty',uint16(1000),...
    'cursorDiameter',uint16(30),...
    'inputType',uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'gloveBias',uint16(zeros([1 5])),...
    'useRandomDelay',uint16(0),...
    'mouseOffset',uint16([3400 2950]),... % empirical values from dell laptop trackpad
    'workspaceX',double([-500 500]),...
    'workspaceY',double([-500 500]),...
    'showNeuralCursor',false,...
    'showScores',false,...
    'trialsPerScore',uint16(16),...
    'recenterOnFail',false,...
    'recenterOnSuccess',false,...
    'recenterDelay',uint16(0),...
    'initialInput',uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'clickPercentage',double(0),...
    'stopOnClick',true);

for nn = 1:length(taskParams)
    eval([taskParams(nn).signal.name ' = createTunableParameter(taskParams(nn).signal.value, ''' ...
        taskParams(nn).signal.class ''');' ]);
end


%cursorParameters = Simulink.Bus.createObject(taskParams);

% targetDiameter = createTunableParameter(60, 'uint16');
% holdTime =       createTunableParameter(500, 'uint16');
% trialTimeout =   createTunableParameter(15000, 'uint16');
% numTrials =      createTunableParameter(100, 'uint16');
% randomSeed =     createTunableParameter(1, 'double');
% expRandMu =      createTunableParameter(700, 'double');
% expRandMin =     createTunableParameter(500, 'double');
% expRandMax =     createTunableParameter(1000, 'double');
% expRandBinSize = createTunableParameter(200, 'double');
% taskType       = createTunableParameter(uint32(cursorConstants.TASK_CENTER_OUT), 'uint32');
% targetInds     = createTunableParameter(int16(zeros([2, cursorConstants.MAX_TARGETS])), 'int16');
% numTargets     = createTunableParameter(uint16(0), 'uint16');
% gain           = createTunableParameter(double([1 1]), 'double');
% failurePenalty = createTunableParameter(1000, 'uint16');
% cursorDiameter = createTunableParameter(30, 'uint16');
% inputType      = createTunableParameter(uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE), 'uint16');
% gloveBias      = createTunableParameter(double(zeros([1 5])), 'uint16');
% useRandomDelay = createTunableParameter(uint16(0), 'uint16');
% mouseOffset    = createTunableParameter(uint16([3400 2950]), 'uint16'); % empirical values from dell laptop trackpad
% workspaceX     = createTunableParameter(double([-500 500]), 'double');
% workspaceY     = createTunableParameter(double([-500 500]), 'double');
% showNeuralCursor = createTunableParameter(false, 'boolean');
% showScores     = createTunableParameter(false, 'boolean');
% trialsPerScore = createTunableParameter(16, 'uint16');
% recenterOnFail = createTunableParameter(false, 'boolean');
% recenterOnSuccess = createTunableParameter(false, 'boolean');
% recenterDelay  = createTunableParameter(0, 'uint16');
% initialInput      = createTunableParameter(uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE), 'uint16');
% clickPercentage = createTunableParameter(double(0), 'double');
% stopOnClick = createTunableParameter(true, 'boolean');
%
%
% %% cursorParameters Bus
% cursorParams = Simulink.Bus;
% cursorParams.Elements(end+1) = createBusElement('targetDiameter', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('holdTime', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('trialTimeout', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('numTrials', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('randomSeed', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('expRandMu', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('expRandMin', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('expRandMax', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('expRandBinSize', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('taskType', 1, 'uint32', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('targetInds', [2 double(cursorConstants.MAX_TARGETS)], 'int16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('numTargets', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('gain', [1 2], 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('failurePenalty', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('cursorDiameter', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('inputType', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('gloveBias', [1 5], 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('useRandomDelay', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('mouseOffset', [1 2], 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('workspaceX', [2 1], 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('workspaceY', [2 1], 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('showNeuralCursor', 1, 'boolean', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('showScores', 1, 'boolean', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('trialsPerScore', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('recenterOnFail', 1, 'boolean', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('recenterOnSuccess', 1, 'boolean', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('recenterDelay', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('initialInput', 1, 'uint16', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('clickPercentage', 1, 'double', 'fixed');
% cursorParams.Elements(end+1) = createBusElement('stopOnClick', 1, 'boolean', 'fixed');
%


behaviorPacketBus_buildWorkspace;
clickParameters_buildWorkspace;
postProcessing_buildWorkspace;
taskOutput_buildWorkspace;
cursorTaskOutput = taskOutput;
cursorTaskOutput.Elements(end+1) = createBusElement('xk', double(2*cursorConstants.NUM_DIMENSIONS+1), 'double', 'fixed');
cursorTaskOutput.Elements(end+1) = createBusElement('inputType', 1, 'uint16', 'fixed');

load playback75Percent
task = rig_taskEnumeration.cursorTask;