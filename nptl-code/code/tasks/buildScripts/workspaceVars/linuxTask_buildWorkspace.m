%% model tunable parameters
function taskParamsStruct = linuxTask_buildWorkspace()
taskParamsStruct = createTunableStructure('linuxTask','taskParameters', 'taskParamsBus',...
    'taskType',uint32(linuxConstants.TASK_FREE_RUN),...
    'maxTaskTime',uint16(0),...
    'gain',double(ones(1,double(xkConstants.NUM_TARGET_DIMENSIONS)) ),... % SDS August 2016 added third and fourth dimensions
    'inputType', uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'gloveBias', double(zeros([1 5])),...
    'mouseOffset', uint16([3400 2950]), ...
    'workspaceX', double([-500 500]), ...
    'workspaceY', double([-500 500]), ...
    'workspaceZ',double([-500 500]),...  Needed for generalized updateXk SDS August 2016
    'workspaceR',double([-3.142 3.142]),...  Needed for generalized updateXk SDS August 2016
    'useGloveLPF', false,...
    'screenUpdateRate', 0, ...
    'xpcVelocityOutputPeriodMS', uint16(0), ...
    'outputVelocityScaling', double([1 1]), ...
    'targetDevice', uint16(linuxConstants.DEVICE_LINUX),...
    'gloveLPNumerator', double(zeros(1, 11)), ...
    'gloveLPDenominator', double(zeros(1, 11)), ...
    'useMouseLPF', false,...
    'mouseLPNumerator', double(zeros(1, 11)), ...
    'mouseLPDenominator', double(zeros(1, 11)), ...
    'initialInput', uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'clickRefractoryPeriod', uint16(0),...
    'stopOnClick', true, ...
    'xk2HorizontalPos', uint8(1), ... % SDS August 2016   which state element the game should treat as horizontal position
    'xk2HorizontalVel', uint8(2), ... % SDS August 2016  which state element the game should treat as horizontal velocity
    'xk2VerticalPos', uint8(3), ... % SDS August 2016 which state element the game should treat as vertical position
    'xk2VerticalVel', uint8(4), ... % SDS August 2016  which state element the game should treat as vertical velocity
    'xk2DepthPos', uint8(5), ... % Not used for this task but updatexk expects it
    'xk2DepthVel', uint8(6), ... % Not used for this task but updatexk expects it
    'xk2RotatePos', uint8(7), ... % Not used for this task but updatexk expects it
    'xk2RotateVel', uint8(8)... % Not used for this task but updatexk expects it
);

% %% linuxParameters Bus
% linuxParams = Simulink.Bus;
% linuxParams.Elements(end+1) = createBusElement('taskType', 1, 'uint32', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('gain', [1 2], 'double', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('inputType', 1, 'uint16', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('gloveBias', [1 5], 'uint16', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('mouseOffset', [1 2], 'uint16', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('workspaceX', [2 1], 'double', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('workspaceY', [2 1], 'double', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('pxOffset', 1, 'double', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('pyOffset', 1, 'double', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('initialInput', 1, 'uint16', 'fixed');
% linuxParams.Elements(end+1) = createBusElement('stopOnClick', 1, 'boolean', 'fixed');
% 
% 
% % linuxTaskOutput NEW MODEL
% linuxTaskOutput = Simulink.Bus;
% linuxTaskOutput.Elements(end+1) = createBusElement('flushFiles', 1, 'boolean', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('sendFormat', 1, 'boolean', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('taskDetails', 1, 'Bus: fileLoggerFormat', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('discrete', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('continuous', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('screen', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('sound', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('xk', double(2*linuxConstants.NUM_DIMENSIONS+1), 'double', 'fixed');
% linuxTaskOutput.Elements(end+1) = createBusElement('inputType', 1, 'uint16', 'fixed');

% behaviorPacketBus_buildWorkspace;
% clickParameters_buildWorkspace;
% postProcessing_buildWorkspace;
% taskOutput_buildWorkspace;
% linuxTaskOutput = taskOutput;

% task = rig_taskEnumeration.linuxTask;