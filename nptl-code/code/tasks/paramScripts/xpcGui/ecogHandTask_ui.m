
typeDataBinary = struct('trueText', 'ON', 'falseText', 'OFF');
typeDataParam1D = struct('dim', [1 1]);

idx = 1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'pauseTask', ...
    'type', 'binary', ...
    'label', 'Pause', ...
    'typeData', typeDataBinary);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'saveTag', ...
    'type', 'parameter', ...
    'label', 'Save Tag', ...
    'typeData', typeDataParam1D);


idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'brainControl', ...
    'type', 'binary', ...
    'label', 'Brain Control', ...
    'typeData', typeDataBinary);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'freePace', ...
    'type', 'binary', ...
    'label', 'Free Pace', ...
    'typeData', typeDataBinary);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'restTime', ...
    'type', 'parameter', ...
    'label', 'Rest Time', ...
    'typeData', typeDataParam1D);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'moveTime', ...
    'type', 'parameter', ...
    'label', 'Move Time', ...
    'typeData', typeDataParam1D);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'interTrialTime', ...
    'type', 'parameter', ...
    'label', 'Inter Trial Time', ...
    'typeData', typeDataParam1D);


idx = idx+1;
typeData = struct('trueText', 'Left', 'falseText', 'Right');
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'leftNotRight', ...
    'type', 'binary', ...
    'label', 'Handedness', ...
    'typeData', typeData);

idx = idx+1;
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'repsPerSet', ...
    'type', 'parameter', ...
    'label', 'Reps Per Set', ...
    'typeData', typeDataParam1D);

idx = idx+1;
typeData = struct('fieldNames', [])
typeData.fieldNames = {...
    'Thumb',                'Index',            'Middle',          'Ring',             'Pinkie',        'Fist',         'Pinch',         'Point', ...
    'Splay',                'Wrist Flext',      'Wrist Extend',    'Wrist Pronate',    'Wrist Radial',  'Wrist Ulnar',  'Elbow Flex',    'Humeral Rotate In',...
    'Humeral Rotate Out',   'Shoulder Forward', 'Shoulder Abduct', 'Vulcan Greeting',  'Unused',        'Unused',       'Unused',        'Unused', ...
    'Unused',               'Unused',           'Unused',           'Unused',          'Unused',        'Unused',       'Unused',        'REST'};
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'moveMask', ...
    'type', 'binaryField', ...
    'label', 'Move Mask', ...
    'typeData', typeData);

idx = idx+1;
typeDataBinary = struct('trueText', 'ON!!!!!!', 'falseText', 'OFF');
ecogHandTaskDescriptor(idx) = struct( ...
    'parameterName', 'fakeNeuralData', ...
    'type', 'binary', ...
    'label', 'Fake Neural Data', ...
    'typeData', typeDataBinary);


fh = figure;
autoLayoutParamUIs(fh, ecogHandTaskDescriptor, xpc, 'ecogHandTask');

%addDecoderDownload(fh, @loadDecoderXPC);