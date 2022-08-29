%% clickParametersBus Bus
gloveThreshold = createTunableParameter(60, 'uint16');
gloveIndices = createTunableParameter([1; 0; 0; 0; 0], 'boolean');
clickHoldTime = createTunableParameter(200, 'uint16');
clickSource    = createTunableParameter(uint8(clickConstants.CLICK_TYPE_NONE), 'uint8');
hmmResetOnClick =  createTunableParameter(false, 'boolean');
hmmResetOnFast =  createTunableParameter(true, 'boolean');
hmmClickLikelihoodThreshold =  createTunableParameter(single(0.95), 'single');
hmmClickSpeedMax =  createTunableParameter(single(9999), 'single');

clickParametersBus = Simulink.Bus;
clickParametersBus.Elements(end+1) = createBusElement('gloveThreshold', 1, 'uint16', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('gloveIndices', [5 1], 'boolean', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('clickHoldTime', 1, 'uint16', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('clickSource', 1, 'uint8', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('hmmResetOnClick', 1, 'boolean', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('hmmResetOnFast', 1, 'boolean', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('hmmClickLikelihoodThreshold', 1, 'single', 'fixed');
clickParametersBus.Elements(end+1) = createBusElement('hmmClickSpeedMax', 1, 'single', 'fixed');

