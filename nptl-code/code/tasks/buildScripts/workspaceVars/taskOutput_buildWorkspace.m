% taskOutput bus.
% This defines the bus 'taskOutput' which comes out of all specificTasks.
% A lot of specific fields are inside structure fields like 'continuous'
% and 'discrete', which means that every time you want to save a new task
% parameter, you do not have to edit this.
taskOutput = Simulink.Bus;
taskOutput.Elements(end+1) = createBusElement('flushFiles', 1, 'boolean', 'fixed');
taskOutput.Elements(end+1) = createBusElement('sendFormat', 1, 'boolean', 'fixed');
taskOutput.Elements(end+1) = createBusElement('taskDetails', 1, 'Bus: fileLoggerFormat', 'fixed');
taskOutput.Elements(end+1) = createBusElement('discrete', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
taskOutput.Elements(end+1) = createBusElement('continuous', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
taskOutput.Elements(end+1) = createBusElement('screen', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
taskOutput.Elements(end+1) = createBusElement('sound', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
taskOutput.Elements(end+1) = createBusElement('asynch', 1, 'Bus: fileLoggerFormatAndData', 'fixed');
taskOutput.Elements(end+1) = createBusElement('ttl', 1, 'double', 'fixed');
taskOutput.Elements(end+1) = createBusElement('xk', [double( xkConstants.NUM_STATE_DIMENSIONS ) 1], 'double', 'fixed'); % SDS July 2016 was 2*cursorConstants.NUM_DIMENSIONS +1
taskOutput.Elements(end+1) = createBusElement('inputType', 1, 'uint16', 'fixed');
taskOutput.Elements(end+1) = createBusElement('currentTarget', [double( xkConstants.NUM_TARGET_DIMENSIONS ) 1], 'single', 'fixed');
taskOutput.Elements(end+1) = createBusElement('state', 1, 'uint16', 'fixed');
taskOutput.Elements(end+1) = createBusElement('paused', 1, 'boolean', 'fixed');
taskOutput.Elements(end+1) = createBusElement('allowStop', 1, 'boolean', 'fixed');
taskOutput.Elements(end+1) = createBusElement('resetHMM', 1, 'boolean', 'fixed');
taskOutput.Elements(end+1) = createBusElement('wiaCode', 1, 'uint16', 'fixed'); %so that we can control the duration of autplay movements during the watch condition
taskOutput.Elements(end+1) = createBusElement('speedCode', 1, 'uint16', 'fixed');
taskOutput.Elements(end+1) = createBusElement('clickTarget', 1, 'uint16', 'fixed'); %SNF for passing to decoders 
taskOutput.Elements(end+1) = createBusElement('taskType', 1, 'uint16', 'fixed'); %SNF for passing to decoders 