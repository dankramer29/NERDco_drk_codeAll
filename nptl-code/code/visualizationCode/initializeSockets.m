function initializeSockets()
global taskParams;
global networkParams;

READ_TIMEOUT = 0.001;

pnet('closeall')

disp('opening sockets')

mc = modelDefinedConstants();

%xPChost = '192.168.30.4';
xPChost = sprintf('%g.%g.%g.%g',mc.peripheral.xPCip);

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        %% this setting does nothing, it's defined in udpScreenReceiver
        DATA_RECV_PORT = mc.screen.DATA_RECV_PORT;%50114;
        CTRL_RECV_PORT = mc.screen.CTRL_RECV_PORT;%50112;
        ACK_DEST_PORT = mc.screen.ACK_DEST_PORT;%50890;
        ACK_SEND_PORT = mc.screen.ACK_SEND_PORT;%50216;
        taskParams.packetReceiveFunc = @udpScreenReceiver;
    case EngineTypes.SOUND
        %% this setting does nothing, it's defined in udpSoundReceiver
        DATA_RECV_PORT = mc.sound.DATA_RECV_PORT;
        CTRL_RECV_PORT = mc.sound.CTRL_RECV_PORT;%50112;
        ACK_DEST_PORT = mc.sound.ACK_DEST_PORT;%50890;
        ACK_SEND_PORT = mc.sound.ACK_SEND_PORT;%50216;
        taskParams.packetReceiveFunc = @udpSoundReceiver;
end
%% just do a udpScreenReceiver('STOP') here for paranoia
%    udpScreenReceiver('STOP')
%    udpScreenReceiver('START');
taskParams.packetReceiveFunc('STOP');
taskParams.packetReceiveFunc('START');

controlsock = pnet('udpsocket', CTRL_RECV_PORT);
if controlsock == -1
    error('failed to create a control socket');
end
pnet(controlsock, 'setreadtimeout', READ_TIMEOUT);

networkParams.controlSock = controlsock;



returnSock = pnet('udpsocket', ACK_SEND_PORT);
if returnSock == -1
    error('failed to create a return socket');
end
pnet(returnSock, 'udpconnect', xPChost, ACK_DEST_PORT);

networkParams.returnSock = returnSock;
