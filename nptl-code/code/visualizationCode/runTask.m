function stats = runTask()
MAX_PACKET_SIZE = 200;

global networkParams;
global screenParams;
global taskParams;

%dataSock = networkParams.dataSock;

%% keep track of data packet statistics
tmult = 10000;
numPacketsRead = 0;
flipTime = uint32(0);

taskParams.quit = false;
taskParams.lastXpcClock = 0;
taskParams.reinitializeScreen = false;

tic;
disp('Starting task loop');
returnTime = 0;
while ~taskParams.quit
    %% read the latest packet
    packet = taskParams.packetReceiveFunc(uint32(flipTime));%getLatestDataPacket();
    if ~isempty(packet)
        %% convert packet into useful data
        data = parseDataPacket(packet, taskParams.packetFormat, taskParams.emptyPacket);
        %if data.clock ~= taskParams.lastXpcClock && GetSecs()-returnTime > 0.001 %0.004
        if data.clock ~= taskParams.lastXpcClock
            if ~numPacketsRead
                taskParams.startTime = GetSecs();%tic;
            end
            taskParams.lastXpcClock = data.clock;
            numPacketsRead = numPacketsRead+1;
            taskParams.lastPacketTime = GetSecs();
            
            %% send this data to the proper handler,
            %%   handler will set up the upcoming screen and wait for flip if relevant
            
            flipTime = taskParams.handlerFun(data); % this is where the vizualization update function is called after each packet
            returnTime = GetSecs();
        end
        %% 5 second timeout
        if GetSecs()- taskParams.lastPacketTime > 1 %% viz timeout period (seconds)
            taskParams.quit = true;
            disp('Timeout');
        end
    end
    %pause(0.002);
end


disp('Leaving task loop');
sca;
if isfield(data, 'outputType') && uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_ROBOT)
    % specific for sclarm robot control
     global modelConstants;
     modelDefinedConstants();
     redisCon = redis();
     redisCon.set('bmi_decode_vel', '0.0 0.0 0.0');
     redisCon.set('scl_pos_ee_des', modelConstants.robot.zeroPosition);
     redisCon.set('bmi_robot_state', 0);
     redisCon.delete();
end
    
ShowCursor();
screenParams.drawn = false;

%% clear these keyboard-related variables
if isfield(screenParams,'offScreen')
    rmfield(screenParams,'offScreen');
end
if isfield(screenParams,'q')
    rmfield(screenParams,'q');
end

% switch taskParams.engineType
%     case EngineTypes.VISUALIZATION
%         Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
%         [vblts SOT FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
% end
stats.numPacketsRead = numPacketsRead;

