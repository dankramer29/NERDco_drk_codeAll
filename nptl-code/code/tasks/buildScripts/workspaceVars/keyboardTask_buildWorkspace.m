function taskParamsStruct = keyboardTask_buildWorkspace(DO_UPDATE_KEYS)
taskParamsStruct = createTunableStructure('keyboardTask','taskParameters', 'taskParamsBus',...
    'keyboardDims',uint16([240 90 1440 900]),...
    'maxTaskTime',uint32(0),...
    'holdTime',uint16(500),...
    'acquireMethods',uint8(keyboardConstants.ACQUIRE_DWELL),...
    'cumulativeDwell',false,...
    'keyboard',uint16(keyboardConstants.KEYBOARD_QWERTY1),...
    'cuedText',zeros([1 keyboardConstants.MAX_CUED_TEXT],'uint8'),...
    'cuedTextLength',uint16(0),...
    'taskType',uint16(keyboardConstants.TASK_FREE_TYPE),...
    'trialTimeout',uint16(15000),...
    'gain',double(ones(1,double(xkConstants.NUM_TARGET_DIMENSIONS)) ),... % SDS August 2016 added third and fourth dimensions
    'cursorDiameter',uint16(10),...
    'inputType',uint16(cursorConstants.INPUT_TYPE_MOUSE_ABSOLUTE),...
    'gloveBias',uint16(zeros([1 5])),...
    'mouseOffset',uint16([0 0]),... % empirical values from dell laptop trackpad
    'workspaceX',double([-540 540]),... %% THESE VARIABLES ARE BACKWARDS!!!
    'workspaceY',double([-540 540]),...
    'workspaceZ',double([-540 540]),...  Needed for generalized updateXk SDS August 2016
    'workspaceR',double([-3.142 3.142]),...  Needed for generalized updateXk SDS August 2016
    'centerOffset',double([960; 540; 0; 0]),...   %SDS Dec 2016 was xyOffset before but now just centerOffset 
    'showScores',false,...
    'scoreTime',uint16(3000),...
    'recenterOnFail',false,...
    'recenterOnSuccess',false,...
    'recenterFullscreen',false,...
    'recenterDelay',uint16(0),...
    'recenterOffset',int16(zeros(double(xkConstants.NUM_TARGET_DIMENSIONS),1)), ...  %SDS Dec 2016 now Nd
    'initialInput',uint16(cursorConstants.INPUT_TYPE_NONE),...
    'initialLockout',uint16(1000),...
    'resetDisplay',false,...
    'clickPercentage',double(0),...
    'clickRefractoryPeriod',uint16(200),...
    'dwellRefractoryPeriod',uint16(200),...
    'keyPressedTime',uint16(100),...
    'showBackspace',false,...
    'showStartStop',false,...
    'initialState',uint16(KeyboardStates.STATE_MOVE),...
    'cursorNeuralColor',[255; 255; 255],...
    'cursorNonneuralColor',[255; 133; 0],...
    'cursorDownColor',[255; 0; 0 ],...
    'showCueOnTarget', false,...
    'showCueOffTarget', true,...
    'showTargetText', true,...
    'soundOnError', false,...
    'showTypedText', true,...
    'useGloveLPF', false,...
    'gloveLPNumerator', double(zeros(1, 11)), ...
    'gloveLPDenominator', double(zeros(1, 11)), ...
    'useMouseLPF', false,...
    'mouseLPNumerator', double(zeros(1, 11)), ...
    'mouseLPDenominator', double(zeros(1, 11)), ...
    'stopOnClick',true, ...
    'xk2HorizontalPos', uint8(1), ... % SDS August 2016   which state element the game should treat as horizontal position
    'xk2HorizontalVel', uint8(2), ... % SDS August 2016  which state element the game should treat as horizontal velocity
    'xk2VerticalPos', uint8(3), ... % SDS August 2016 which state element the game should treat as vertical position
    'xk2VerticalVel', uint8(4), ... % SDS August 2016  which state element the game should treat as vertical velocity
    'xk2DepthPos', uint8(5), ... % SDS December 2016 which state element the game should treat as depth position
    'xk2DepthVel', uint8(6), ... % SDS December 2016  which state element the game should treat as depth velocity
    'xk2RotatePos', uint8(7), ... % Not used for this task but updatexk expects it
    'xk2RotateVel', uint8(8),... % Not used for this task but updatexk expects it
    'outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR),...  % SDS Dec 2016: toggles visualization engine, default is PTB
    'autoplayReactionTime', uint16(250), ... % in ms SDS Jan 2016 to be compatible with updateXk
    'autoplayMovementDuration', uint16(1000), ... %in ms  SDS Jan 2016 to be compatible with updateXk
    'exponentialGainBase', single( 1 ), ... % expontial gain base. 1 is special and means unity out/in mapping  SDS Feb 2016
    'exponentialGainUnityCrossing', single(5e-5)... % exponential gain base. At speeds above this (in each dimension), output is > input SDS Feb 2016
);

%% add the keyboard variables to the workspace


% behaviorPacketBus_buildWorkspace;
% clickParameters_buildWorkspace;
% postProcessing_buildWorkspace;
% taskOutput_buildWorkspace;

% task = rig_taskEnumeration.keyboardTask;

% load all the keyboards into the workspace
% keyboards = Simulink.Parameter;
% keyboards.Value = allKeyboards();
% keyboards.CoderInfo.StorageClass = 'ExportedGlobal';
% open_system('allTasks');
% open_system('allTasks/keyboardTask');
% keyboards = createTunableStructure(...
%     'allTasks/keyboardTask','keyboards', 'keyboardsBus',...
%     allKeyboards());

k = allKeyboards();

keys1 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard1', 'keysParamsBus',...
    '_1',k(keyboardConstants.KEYBOARD_QWERTY1).keys);
keys2 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard2', 'keysParamsBus',...
    '_2',k(keyboardConstants.KEYBOARD_QWERTY2).keys);
keys3 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard3', 'keysParamsBus',...
    '_3',k(keyboardConstants.KEYBOARD_GRID_6X6).keys);
keys4 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard4', 'keysParamsBus',...
    '_4',k(keyboardConstants.KEYBOARD_GRID_7X7).keys);
keys5 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard5', 'keysParamsBus',...
    '_5',k(keyboardConstants.KEYBOARD_GRID_8X8).keys);
keys6 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard6', 'keysParamsBus',...
    '_6',k(keyboardConstants.KEYBOARD_GRID_9X9).keys);
keys7 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard7', 'keysParamsBus',...
    '_7',k(keyboardConstants.KEYBOARD_GRID_10X10).keys);
keys8 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard8', 'keysParamsBus',...
    '_8',k(keyboardConstants.KEYBOARD_QABCD).keys);
keys9 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard9', 'keysParamsBus',...
    '_9',k(keyboardConstants.KEYBOARD_OPTIII).keys);
keys10 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard10', 'keysParamsBus',...
    '_10',k(keyboardConstants.KEYBOARD_GRID_5X5).keys);
keys11 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard11', 'keysParamsBus',...
    '_11',k(keyboardConstants.KEYBOARD_OPTIFREE).keys);
keys12 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard12', 'keysParamsBus',...
    '_12',k(keyboardConstants.KEYBOARD_GRID_12X12).keys);
keys13 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard13', 'keysParamsBus',...
    '_13',k(keyboardConstants.KEYBOARD_GRID_14X14).keys);
keys14 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard14', 'keysParamsBus',...
    '_14',k(keyboardConstants.KEYBOARD_GRID_15X15).keys);
keys15 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard15', 'keysParamsBus',...
    '_15',k(keyboardConstants.KEYBOARD_GRID_16X16).keys);
keys16 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard16', 'keysParamsBus',...
    '_16',k(keyboardConstants.KEYBOARD_GRID_18X18).keys);
keys17 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard17', 'keysParamsBus',...
    '_17',k(keyboardConstants.KEYBOARD_GRID_20X20).keys);
keys18 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard18', 'keysParamsBus',...
    '_18',k(keyboardConstants.KEYBOARD_GRID_22X22).keys);
keys19 = createTunableStructurePost(...
    'keyboardTask','taskInterface/keyboard19', 'keysParamsBus',...
    '_19',k(keyboardConstants.KEYBOARD_GRID_24X24).keys);

% THIS NEEDS TO BE MANUALLY CALLED BY SETTING DO_UPDATE_KEYS = true,
% otherwise it won't update them.
if ~exist('DO_UPDATE_KEYS','var')
    DO_UPDATE_KEYS = false;
end

if DO_UPDATE_KEYS
    keyboardTask_updateParameters();
end
