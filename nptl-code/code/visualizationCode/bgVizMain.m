function stats=bgVizMain()
MAX_PACKET_SIZE = 1400;

global networkParams;
global screenParams;
global taskParams;

controlSock = networkParams.controlSock;

disp('in bgVizMain')


%% bgviz has two states - init, where it waits for format packets, and task loop, where it presents the incoming data packets
INIT_STATE = 1;
TASK_STATE = 2;

global vizState;
vizState = INIT_STATE;

breakMain = 0;

% try
while(~breakMain)
    switch vizState
        case INIT_STATE
            %% continually check for format packets
            fPacket = getLatestFormatPacket();
            if ~isempty(fPacket)
                disp('Found a format packet. Setting up Task.')
                
                pause(0.1);
                %% sop up all the format packets (first 100ms of task initialization)
                fPacketTmp = getLatestFormatPacket();
                while ~isempty(fPacketTmp)
                    fPacket = fPacketTmp;
                    fPacketTmp = getLatestFormatPacket();
                end
                
                pFormat = parseFormatPacket(fPacket);
                taskParams.taskName = pFormat.taskName;
                taskParams.versionId = pFormat.versionId;
                taskParams.packetFormat = pFormat;
                taskParams.emptyPacket = makeEmptyPacket(pFormat);
                HideCursor();
                
                switch lower(taskParams.taskName) % note that there's a 'lower' call here
                    case 'movementcue'
                        initializeMovement();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'cursor'
                        initializeCursor();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'fitts'
                        initializeFitts();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'sequence'
                        initializeSequence();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'viztest'
                        initializeVizTest();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'linux'
                        initializeLinux();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'keyboard'
                        initializeKeyboard();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'robot'
                        initializeRobot();
                        sendFormatAck();
                        vizState = TASK_STATE;
                    case 'symbol'
                        initializeSymbol();
                        sendFormatAck();
                        vizState = TASK_STATE;    
                    case 'decision' %SF 4/9/18
                        initializeDecision();  %SF 4/9/18
                        sendFormatAck();  %SF 4/9/18
                        vizState = TASK_STATE;    %SF 4/9/18    
                    case 'rsg' 
                        initializeRSG(); 
                        sendFormatAck();  
                        vizState = TASK_STATE;                        
                    otherwise
                        disp(['dont know how to handle task ' taskParams.taskName]);
                end
            end
            
        case TASK_STATE
            stats = runTask();
            % exited out of the task. go back to init
            vizState = INIT_STATE;
            ShowCursor();
        otherwise
            error('invalid state...?')
            ShowCursor();
    end
end
%  catch exception
%    cleanup();
%    rethrow(exception);
%  end
cleanup();

function cleanup()
    %pnet(dataSock, 'close');
    pnet(controlSock, 'close');
    %  PsychPortAudio('close')
    Priority(screenParams.oldPriority);
end

function sendFormatAck()
    returnSock = networkParams.returnSock;
    pnet(returnSock,'write',uint32(1));
    if ~pnet(returnSock,'writepacket')
        error('couldnt write return packet')
    end
    
end


function pOut = getLatestFormatPacket()
    numBytes = pnet(controlSock, 'readpacket');
    if ~numBytes
        %% no new packets, return empty one
        pOut = [];
        return
    end
    %% there are new packets, so read until we get the last one
    pOut = pnet(controlSock, 'read', MAX_PACKET_SIZE, 'uint8')';
    
    pTmp = pOut;
    while(~isempty(pTmp))
        pOut = pTmp;
        pTmp = pnet(controlSock, 'read', MAX_PACKET_SIZE, 'uint8')';
    end
    
end


end
