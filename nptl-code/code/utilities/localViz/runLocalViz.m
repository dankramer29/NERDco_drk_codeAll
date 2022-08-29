function runLocalViz

global modelConstants
mc = modelConstants;
DATA_RECV_PORT = mc.screen.DATA_RECV_PORT;%50114;
CTRL_RECV_PORT = mc.screen.CTRL_RECV_PORT;%50112;
ACK_DEST_PORT = mc.screen.ACK_DEST_PORT;%50890;
ACK_SEND_PORT = mc.screen.ACK_SEND_PORT;%50216;
% taskParams.packetReceiveFunc = @udpLocalScreenReceiver;
% taskParams.packetReceiveFunc('STOP');
% taskParams.packetReceiveFunc('START');


global localVizVars
if isfield(localVizVars,'controlsock')
    c=localVizVars.controlsock;
    if ~isempty(c)
        try
            pnet(c, 'close');
        catch
            %dont really care
        end
    end
end

if isfield(localVizVars,'datasock')
    c=localVizVars.datasock;
    if ~isempty(c)
        try
            pnet(c, 'close');
        catch
            %dont really care
        end
    end
end


controlsock = pnet('udpsocket', CTRL_RECV_PORT);
if controlsock == -1
    error('failed to create a control socket');
end
localVizVars.READ_TIMEOUT = 0.001;
pnet(controlsock, 'setreadtimeout', localVizVars.READ_TIMEOUT);


localVizVars.controlsock = controlsock;
localVizVars.datasock = [];
localVizVars.const.init_state = 0;
localVizVars.const.task_state = 1;
localVizVars.const.end_state = 2;

localVizVars.state = 0;
localVizVars.figNum = 1123;

localVizVars.timerObj = timer('BusyMode','drop','ExecutionMode','fixedRate','Period',0.1,'TasksToExecute',inf,...
     'TimerFcn',@localViz ,'ErrorFcn',@localVizError);
start(localVizVars.timerObj);

localVizVars.isRunning = true;
