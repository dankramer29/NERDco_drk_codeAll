%% model constants
global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

%% model tunable parameters
pause = createTunableParameter(true, 'boolean');
blockNumber = createTunableParameter(0, 'uint32');
stateParams = Simulink.Bus;
stateParams.Elements(end+1) = createBusElement('pause', 1, 'boolean', 'fixed');
stateParams.Elements(end+1) = createBusElement('blockNumber', 1, 'uint32', 'fixed');


%% cerebusData Bus
cerebusBroadband = Simulink.Bus;
cerebusBroadband.Elements(end+1) = createBusElement('cerebusFrame', [30 modelConstants.cerebus.numCerebusChannels], 'int16', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('outputValid', 1, 'boolean', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('firstCerebusTime', 1, 'uint32', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('lastCerebusTime', 1, 'uint32', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('sampleTimes', 50, 'uint32', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('numSamples', 1, 'uint32', 'fixed');
cerebusBroadband.Elements(end+1) = createBusElement('chainSize', 1, 'uint16', 'fixed');


rereferencingType = createTunableParameter(uint8(rigHardwareConstants.REREFERENCE_COMMON_AVG), 'uint8');


%% cerebusData Bus
cerebusData = Simulink.Bus;

%cerebusData.Elements(end+1) = createBusElement('numSpikePackets', 1, 'uint16', 'fixed');
%cerebusData.Elements(end+1) = createBusElement('spikePackets', [modelConstants.cerebus.maxSpikesInMS modelConstants.cerebus.spikePacketDataSize], 'uint8', 'fixed');
%cerebusData.Elements(end+1) = createBusElement('spikeTimes', [modelConstants.cerebus.maxSpikesInMS 1], 'uint32', 'fixed');
%cerebusData.Elements(end+1) = createBusElement('spikeCount', [modelConstants.cerebus.numCerebusChannels 1], 'uint8', 'fixed');

cerebusData.Elements(end+1) = createBusElement('numSamples', 1, 'uint32', 'fixed');
cerebusData.Elements(end+1) = createBusElement('samples', [modelConstants.cerebus.maxSamplesInMS modelConstants.cerebus.numCerebusChannels], 'int16', 'fixed');
cerebusData.Elements(end+1) = createBusElement('sampleTimes', [modelConstants.cerebus.maxSamplesInMS 1], 'uint32', 'fixed');

cerebusData.Elements(end+1) = createBusElement('firstCerebusTime', 1, 'uint32', 'fixed');
cerebusData.Elements(end+1) = createBusElement('lastCerebusTime', 1, 'uint32', 'fixed');

processedNeural = Simulink.Bus;
processedNeural.Elements(end+1) = createBusElement('meanSquared', 1, 'single', 'fixed');
processedNeural.Elements(end+1) = createBusElement('meanSquaredChannel', 1, 'uint8', 'fixed');
processedNeural.Elements(end+1) = createBusElement('minSpikeBand', [1 modelConstants.cerebus.numCerebusChannels], 'single', 'fixed');
processedNeural.Elements(end+1) = createBusElement('minSpikeBandInd', [1 modelConstants.cerebus.numCerebusChannels], 'uint8', 'fixed');
processedNeural.Elements(end+1) = createBusElement('maxSpikeBand', [1 modelConstants.cerebus.numCerebusChannels], 'single', 'fixed');
processedNeural.Elements(end+1) = createBusElement('maxSpikeBandInd', [1 modelConstants.cerebus.numCerebusChannels], 'uint8', 'fixed');
processedNeural.Elements(end+1) = createBusElement('outputValid', 1, 'boolean', 'fixed');



%% networkOutput Bus OLD MODEL
formatAndPacket = Simulink.Bus;
formatAndPacket.Elements(end+1) = createBusElement('data', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
formatAndPacket.Elements(end+1) = createBusElement('dataLen', 1 , 'uint16', 'fixed');
formatAndPacket.Elements(end+1) = createBusElement('format', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
formatAndPacket.Elements(end+1) = createBusElement('formatLen', 1 , 'uint16', 'fixed');
formatAndPacket.Elements(end+1) = createBusElement('send', 1, 'boolean', 'fixed');

networkOutput = Simulink.Bus;
networkOutput.Elements(end+1) = createBusElement('flushFiles', 1, 'boolean', 'fixed');
networkOutput.Elements(end+1) = createBusElement('taskDetails', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
networkOutput.Elements(end+1) = createBusElement('taskDetailsLen', 1 , 'uint16', 'fixed');
networkOutput.Elements(end+1) = createBusElement('discrete', 1, 'Bus: formatAndPacket', 'fixed');
networkOutput.Elements(end+1) = createBusElement('continuous', 1, 'Bus: formatAndPacket', 'fixed');
networkOutput.Elements(end+1) = createBusElement('screen', 1, 'Bus: formatAndPacket', 'fixed');
networkOutput.Elements(end+1) = createBusElement('sound', 1, 'Bus: formatAndPacket', 'fixed');
networkOutput.Elements(end+1) = createBusElement('sendFormat', 1, 'boolean', 'fixed');
networkOutput.Elements(end+1) = createBusElement('neural', 1, 'Bus: formatAndPacket', 'fixed');

%% networkOutput Bus NEW MODEL
fileLoggerData = Simulink.Bus;
fileLoggerData.Elements(end+1) = createBusElement('data', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
fileLoggerData.Elements(end+1) = createBusElement('dataLen', 1 , 'uint16', 'fixed');
fileLoggerData.Elements(end+1) = createBusElement('fileName', [1 20] , 'uint8', 'fixed');
fileLoggerData.Elements(end+1) = createBusElement('send', 1, 'boolean', 'fixed');

fileLoggerFormat = Simulink.Bus;
fileLoggerFormat.Elements(end+1) = createBusElement('format', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
fileLoggerFormat.Elements(end+1) = createBusElement('formatLen', 1 , 'uint16', 'fixed');
fileLoggerFormat.Elements(end+1) = createBusElement('fileName', [1 20] , 'uint8', 'fixed');


fileLoggerFormatAndData = Simulink.Bus;
fileLoggerFormatAndData.Elements(end+1) = createBusElement('format', 1, 'Bus: fileLoggerFormat', 'fixed');
fileLoggerFormatAndData.Elements(end+1) = createBusElement('data', 1, 'Bus: fileLoggerData', 'fixed');


peripheralData = Simulink.Bus;
peripheralData.Elements(end+1) = createBusElement('data', modelConstants.network.maxUDPDataSize, 'uint8', 'fixed');
peripheralData.Elements(end+1) = createBusElement('dataLen', 1 , 'uint16', 'fixed');
peripheralData.Elements(end+1) = createBusElement('receive', 1, 'boolean', 'fixed');

global xpcConstants
xpcConstants.LFPRMSperiod = modelConstants.LFPRMSperiod;
xpcConstants.RMSperiod = modelConstants.RMSperiod;
xpcConstants.cerebus = modelConstants.cerebus;
