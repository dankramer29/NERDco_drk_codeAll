%% postProcessing parameters/bus

% Creates a bus that is used in decoder/postProcessingParams
% SDS documention July 2016

%% model tunable parameters
biasCorrectionVelocityThreshold = createTunableParameter(0, 'double'); 
biasCorrectionTau =     createTunableParameter(1000*120, 'double');
biasCorrectionEnable =     createTunableParameter(false, 'boolean');
biasCorrectionInitial =     createTunableParameter(zeros(double(xkConstants.NUM_STATE_DIMENSIONS),1), 'double');
biasCorrectionResetToInitial =     createTunableParameter(false, 'boolean');
biasCorrectionType =     createTunableParameter(uint16(0), 'uint16');
biasCorrectionStateInds = createTunableParameter( false( xkConstants.NUM_STATE_DIMENSIONS, 1 ), 'boolean' ); % SDS July 2016
biasCorrectionPower = createTunableParameter( 1.5, 'double'); % SDS June 2017: controls bias killer nonlinearity in BIAS_CORRECTION_SERGEY


%% decoderParameters Bus
postProcessingParams = Simulink.Bus;
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionVelocityThreshold', 1, 'double', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionTau', 1, 'double', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionEnable', 1, 'boolean', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionInitial', [double( xkConstants.NUM_STATE_DIMENSIONS ) 1], 'double', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionResetToInitial', 1, 'boolean', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionType', 1, 'uint16', 'fixed');
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionStateInds', [double( xkConstants.NUM_STATE_DIMENSIONS ) 1], 'boolean', 'fixed');  % SDS July 2016
postProcessingParams.Elements(end+1) = createBusElement('biasCorrectionPower', 1, 'double', 'fixed');

