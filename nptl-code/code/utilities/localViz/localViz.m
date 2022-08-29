function localViz(varargin)
MAX_PACKET_SIZE = 1500;

persistent lastPacketTime;
lastPacketTime = clock();

global modelConstants
DATA_RECV_PORT = modelConstants.screen.DATA_RECV_PORT;
global localVizVars
%localVizVars.datasock = datasock;
%localVizVars.controlsock = controlsock;

%localVizVars.init_state = 0;
%localVizVars.task_state = 1;

switch localVizVars.state
    case localVizVars.const.init_state
        %% wait for a control packet
        fPacket = getLatestControlPacket();
        if ~isempty(fPacket)
            disp('initializing local visualization!');
            
            pFormat = parseFormatPacket(fPacket);
            localVizVars.taskName = pFormat.taskName;
            localVizVars.versionId = pFormat.versionId;
            localVizVars.packetFormat = pFormat;
            localVizVars.emptyPacket = makeEmptyPacket(pFormat);
            localVizVars.state = localVizVars.const.task_state;
            localVizVars.background = [];
            localVizVars.currTask = [];
            openDataSocket();
        end
    case localVizVars.const.task_state
        %% wait for a control packet
        dPacket = getLatestDataPacket();
        if ~isempty(dPacket)
            lastPacketTime = clock();
            data = parseDataPacket(dPacket, localVizVars.packetFormat, localVizVars.emptyPacket);
            localVizVars = displayLocalViz(localVizVars,data);
        end
        if etime(clock(),lastPacketTime) > 5
            fprintf('Warning: No data from xPC in 5 seconds. Shutting down visualization. Be sure to run "stopExpt"\n');
            stopLocalViz();
        end
    case localVizVars.const.end_state
        fprintf('Task ended. Shutting down visualization. Be sure to run "stopExpt"\n');
        stopLocalViz();
end

    function pOut = getLatestControlPacket()
        numBytes = pnet(localVizVars.controlsock, 'readpacket');
        if ~numBytes
            %% no new packets, return empty one
            pOut = [];
            return
        end
        %% there are new packets, so read until we get the last one
        pOut = pnet(localVizVars.controlsock, 'read', MAX_PACKET_SIZE, 'uint8')';
        
        pTmp = pOut;
        while(~isempty(pTmp))
            pOut = pTmp;
            pTmp = pnet(localVizVars.controlsock, 'read', MAX_PACKET_SIZE, 'uint8')';
        end
        
    end

    function pOut = getLatestDataPacket()
        numBytes = pnet(localVizVars.datasock, 'readpacket');
        if ~numBytes
            %% no new packets, return empty one
            pOut = [];
            return
        end
        %% there are new packets, so read until we get the last one
        pOut = pnet(localVizVars.datasock, 'read', MAX_PACKET_SIZE, 'uint8')';
        closeDataSocket();
        openDataSocket();
    end

    function openDataSocket()
        datasock = pnet('udpsocket',DATA_RECV_PORT);
        pnet(datasock, 'setreadtimeout', localVizVars.READ_TIMEOUT);
        if datasock == -1
            error('failed to create a data socket');
        end
        localVizVars.datasock = datasock;
    end
    function closeDataSocket()
        pnet(localVizVars.datasock,'close');
    end

end