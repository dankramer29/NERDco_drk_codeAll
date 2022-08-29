function VCS(MODE)

% Velocity-Control Simulator
%
% Function: sends velocity and click commands to simulink system based on
% the mouse position and click state
%
% USAGE: - type VCS in command window to start simulator.
%        - hit ESCAPE key to stop the simulator
%        - move mouse around figure window for position (or velocity)
%           encoding of patterned neural data
%        - click with the mouse to encode click neural pattern

% created by Dan Bacher (revised 2010.04.19)

%% 1.0 User Settings

% MODE
%   (1): mouse input mode. modulate neural signal based on mouse position
%   on the VCS figure window
%
%   (2): robot mode. a "robot" will play the game for you, always trying
%   to push the cursor toward the target, and clicking when
%   instructed to for OL
if nargin < 1
    MODE = 1;
end
S.MODE = MODE;

% paths
addpath(genpath(pwd));

% set IP address and port numbers
% ********************************************************************

% localIP
getXpcIPs = getMyIP('192.168.10.255');
if ~isempty(getXpcIPs{1})
    localIP = getXpcIPs{1};
else
    getAnyIP = getMyIP;
    localIP = getAnyIP{1};
end

%remoteIP = '192.168.137.1';
%remoteIP = '128.148.107.69'; % Sergey Desktop
%remoteIP = '128.148.107.72'; % Dan's workstation
remoteIP = '192.168.10.255'; % broadcast to any IP
if MODE == 1
    remotePort = 52002;
else
    remotePort = 49255;           % VCS in xPC model. changing port for testing
end
    %remotePort = 49500;          % simulator       % target port, default = 5555 for now
%remotePort = 1001;           % BG2D
localPort = 49444;            % local port, keep at 5554

% receive data from BG2D
gamePort = 49501;
% ********************************************************************

%% 2.0 Initialization

% initialize parameters
% use structure S to pass around variables

S.screenSize = get(0,'screensize'); % get screen dimensions
%S.figPos = S.screenSize; % set figure to full screen
% make fig small in lower right hand corner
S.figPos = [S.screenSize(3)-610 50 600 500];
S.timerSamplePeriod = 0.02; % sampling rate of simulator

% create figure
S.fig = figure('position',S.figPos, 'menubar','none', ...
    'toolbar','none', 'numbertitle','off', ...
    'Name','Velocity Control Simulator');
axis off
S.ax = gca;
set(S.fig,'color','k')
text(-.1,1,'Velocity Control Simulator','color','w', ...
    'fontsize',20,'fontangle','italic');
text(-.1,.8,'Press ESCAPE to stop the simulator', ...
    'color','w','fontsize',15);

% plot robot command position if in robot mode
if MODE >= 2
    S.robotP = plot(0,0,'ko','markerfacecolor','w','markersize',30);
    axis([-.5 .5 -.5 .5]);
    axis off;
end

% use figure UserData to pass mouse data across functions
set(S.fig,'UserData',[0 0 0 0]); % [x y click stop]

% init UDP (pnet) connections
pnet('closeall')
delete(timerfind);
S.socket = InitUDPsender(localIP, localPort,remoteIP,remotePort);
S.gameSocket = InitUDPreceiver(localIP, gamePort);

% create timer object
timer_h = timer('TimerFcn',{@VCSloop, S}, ...
    'BusyMode','drop','TasksToExecute',inf, ...
    'ExecutionMode','FixedRate', 'Period', S.timerSamplePeriod, ...
    'StartDelay', S.timerSamplePeriod);

% clear pnet text
clc;

% open cbbg to handle timestamps
% addpath(genpath('C:\Session\Software\Utilities'));
% retcode = cbbg_mex('open',2,0,1,0);

% START SIMULATOR
start(timer_h)
disp('Velocity Control Simulator: started')


%% 3.0 Main Loop (Timer Function)

function VCSloop(obj, event, S)

% INITIALIZE
 

% initialize variables
persistent t t_send vel allGameUDPdata velCmdHist robotCmd % place holder for time stamp

% storage variables -- since VCS runs more or less indefinitely, and we
% don't want to overwhelm MATLAB, we are going to pre-allocate these and
% "forget" older data. AAS 2013.02.13.

persistent sysClock nspClock nspClockFromGame nspRTT
if isempty(robotCmd); robotCmd = [0 0 0 0]; end
if isempty(t); t = 0; end
if isempty(vel); vel = [0 0 0]; end
try

dataStoreMemorySec = 120; % how many seconds of data will we hold before forgetting?
dataStoreMemoryStep = dataStoreMemorySec / S.timerSamplePeriod;

if isempty(sysClock)
    sysClock = zeros(1,dataStoreMemoryStep); % figure out a CBBG call to get this
    nspClock = zeros(1,dataStoreMemoryStep);
    nspClockFromGame = zeros(1,dataStoreMemoryStep);
    nspRTT = zeros(1,dataStoreMemoryStep); % figure out a CBBG call to get this
end

latency = 200;
numHistorySteps = ceil((latency/1000)/S.timerSamplePeriod);
cmdHistSteps = 5;
MAX_LENGTH = 18;
if isempty(allGameUDPdata); allGameUDPdata = zeros(numHistorySteps,MAX_LENGTH); end
if isempty(velCmdHist); velCmdHist = zeros(cmdHistSteps,3); end % THIS IS HARDCODED FOR 3D - DB & AAS 2012.12.07

    udpData = zeros(1,5); % [t x y z click]
    velocity = [0 0 0];
    clickState = 0;
    
    % set event callback functions
    % mouse movement
    set(S.fig,'WindowbuttonMotionFcn', ...
        {@MouseMoveFcn, S});
    % mouse click
    set(S.fig,'WindowButtonDownFcn', ...
        {@MouseClickFcn, S});
    % key press
    set(S.fig,'WindowKeyPressFcn', ...
        {@KeyHitFcn, S});
    
    % EXECUTE
    
    % increment time stamp / counter
    t = t+1;
%     nspTime_current = cbbg_mex('get_nsp_timestamp');
%     fprintf('new NSP time %d\n',nspTime_current)
%     nspClock = [nspClock(2:end) nspTime_current];
    
    % get mouse data
    mouseData = get(S.fig,'UserData'); % [x y click stopCmd]  
    if S.MODE == 1        
        robotCmd = [mouseData(1:2) 0 mouseData(3)];
        t_send = t;

    end
    if S.MODE >= 2
        % use "robot" to encode neural data
        % overwrite [x y click] of mouseData
        % Robot behavior: move straight toward target from current
        % position, encode click pattern when receiving click cmd
        
        % init vars

        
        % receive UDP game data
        currentGameUDPdata = ReceiveUDP(S.gameSocket,'latest');

        if ~isempty(currentGameUDPdata)
            
            allGameUDPdata = [allGameUDPdata(2:end,1:MAX_LENGTH); currentGameUDPdata(1:MAX_LENGTH)];
            
            gameUDPdata = allGameUDPdata(1,:);
            
            receivedGameTime_current = currentGameUDPdata(2); % pull timestamp from packet
            t_send = receivedGameTime_current;

            nspClockFromGame = [nspClockFromGame(2:end) receivedGameTime_current];
            cursorPos = gameUDPdata(3:5); % for 3d
            targPos = gameUDPdata(7:9); %incl 9 for 3d
            instructedClick = gameUDPdata(6);
            if S.MODE == 2
                onTargCL = gameUDPdata(16); % click if on target in CL
            elseif S.MODE == 3
                % new case for DEKA model to send "onTarg" flag to autoVCS
                    % because it actually sends more than 16 kin params
                onTargCL = gameUDPdata(18); % click if on target in CL
            end
            
            % velocity command
            dpos = (targPos - cursorPos);            
            dposMag = norm((dpos));
            if dposMag > 0
                dposNorm = dpos./dposMag;
            else
                dposNorm = [0 0 0];
            end
            distanceScalar = 1.5;
            jitter = 0; % This coefficient makes the cursor a little less static
            % (so that it doesn't stupidly get stuck in places)
            
            % We have an arbitrary power / log function on the
            % distance-to-target.
            velCmd = dposNorm .* ((dposMag) ^ .7 ) * distanceScalar;
            
            velCmd = velCmd + jitter * rand(size(velCmd));

            if norm(velCmd) > .5
                velCmd = dposNorm *.5;
            elseif norm(velCmd) < .05
                velCmd = dposNorm *.05;
            end
            
            % We need to make sure that velCmd stays inside the boundaries
            % of the playing space.

            velCmd = max(-.5,min(.5,velCmd));
                        

            velCmdHist = [velCmdHist(2:end,:); velCmd];
            
            % click command
            if instructedClick == 1 || onTargCL == 1
                clickCmd = 1;
            else
                clickCmd = 0;
            end
            
            smoothedVelCmd = mean(velCmdHist,1);
            
            % robot command
            robotCmd = [smoothedVelCmd clickCmd];
        end
        
        % update position and color of robot cursor
        set(S.robotP,'xdata',robotCmd(1),'ydata',robotCmd(2));
        
        zSize = (robotCmd(3)+.5)*20 + 20; % range of 20, min of 10
        set(S.robotP,'markersize',zSize);
        if robotCmd(end) == 1
            set(S.robotP,'markerfacecolor','g');
        else
            set(S.robotP,'markerfacecolor','w');
        end
        
        % use mouse data var to pass on command
%         mouseData([1 2 4]) = robotCmd;
    end
    
    % convert mouse position to velocity
    velocity = [robotCmd(1:3)]; % [x y z], for now z = 0
    
    % get click status
    clickState = robotCmd(4);
    if clickState
        robotCmd(4) = 0; % reset mouse click state  
        mouseData(3) = 0;
        set(S.fig,'UserData',mouseData);        
    end
    
    % define UDP array and send packet
    udpData = zeros(1,64);
    
    % hack for BG2D mode
    % add ID to packet
    % chop out Z dim
    vel2D = velocity(1:2);
    actualSendPacket = [-1 t_send vel2D clickState];  
%     disp(t_send);
    udpData(1:length(actualSendPacket)) = actualSendPacket;
    
    try
        SendUDP(S.socket,udpData);
    catch
        stop(timerfind);
        delete(timerfind);
        CloseUDP(S.socket);
        CloseUDP(S.gameSocket);
        close all;
%         clear all; % we are storing data now so we don't want this.
        fprintf('Velocity Control Simulator: Aborted\n');
        fprintf('*** UDP send failed... Check network connection\n');
        return;
    end
    
    % update mouseData to reset click state
    set(S.fig,'UserData',mouseData);
    
    % check for program stop command
    stopCheck = mouseData(4);
    if stopCheck
        disp('Velocity Control Simulator: stopped')
        stop(timerfind); % stop timer
        delete(timerfind); % delete timer
        CloseUDP(S.socket); % close UDP pnet connections
        CloseUDP(S.gameSocket);
        VCSdata.sysClock = sysClock;
        VCSdata.nspClock = nspClock;
        VCSdata.nspClockFromGame = nspClockFromGame;
        VCSdata.nspRTT = nspRTT;
        assignin('base','VCSdata',VCSdata);
%         cbbg_mex('close');
        close; % close figure
%         clear all; % we are storing data now so we don't want this.
    end
    
    %         disp(actualSendPacket)
    
catch e
   set(S.fig,'color','r')
   fprintf(['ERROR: ' e.message '\n']);
        stop(timerfind); % stop timer
        delete(timerfind); % delete timer
        CloseUDP(S.socket); % close UDP pnet connections
        CloseUDP(S.gameSocket);
end
    %% 4.0 Callback Functions
    
    function MouseMoveFcn(obj,event,S)
    
    % callback fcn upon mouse movement event
    
    pt = get(0,'PointerLocation'); % get mouse position on screen
    ptX = pt(1,1); % most recent x mouse pos
    ptY = pt(1,2); % most recent y mouse pos
    
    figPos = get(S.fig,'position');
    
    % normalize values to [-.5 .5]
    xnorm = 1.*(ptX-figPos(1))/figPos(3) - .5;
    ynorm = 1.*(ptY-figPos(2))/figPos(4) - .5;
    
    % update mouse position
    mouseData = get(S.fig, 'UserData');
    mouseData(1:2) = [xnorm ynorm];
    set(S.fig,'UserData',mouseData);
    
        function MouseClickFcn(obj,event,S)
            
            % callback fcn upon mouse click event
            
            mouseData = get(S.fig, 'UserData');
            mouseData(3) = 1;
            set(S.fig, 'UserData', mouseData);
            
            function KeyHitFcn(obj,event,S)
                
                % callback fcn upon key press event
                
                mouseData = get(S.fig, 'UserData');
                
                if strcmp(event.Key,'escape') % if escape is pressed
                    mouseData(4) = 1; % send stop message to timer
                end
                
                set(S.fig, 'UserData', mouseData);
                
                
