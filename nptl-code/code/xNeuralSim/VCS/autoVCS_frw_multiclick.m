function autoVCS_frw_multiclick(neuralScale, doAutoClick)
%automatically simulate velocity-tuned neural activity that can complete
%the cursor task in closed-loop
%% set some macros:
%these are used to determine the size of udpData
% global num_cont_dims   = 5;  % number of continuous dimensions to get from space mouse
% global num_disc_dims   = 4;  % number of distinct clicks to read in
% global num_t_dims      = 1;     % I don't know what this is for but it's necessary I guess?
% global velIdx = [2 3 4 6 7]; %SNF: this is hideous, why are we like this??
% global clkIdx = [5 8 9 10]; %SNF: D':
%% 1.0 User Settings
% set IP address and port numbers
remoteIP = '192.168.137.255'; % broadcast to any IP
remotePort = 49255;   % VCS in xPC model.
% localIP
getXpcIPs = getMyIP('192.168.137.255');
if ~isempty(getXpcIPs{1})
    localIP = getXpcIPs{1};
else
    getAnyIP = getMyIP;
    localIP = getAnyIP{1};
end
% NPTL
localPort = 49454;
% receive data from screen
gameFormattingPort = 50112;
gameDataPort = 50114;
%% 2.0 Initialization
if nargin<1
    neuralScale = .5;
    doAutoClick = 0; 
elseif nargin<2
    doAutoClick = 0; 
end
S.neuralScale = neuralScale;
S.doAutoClick = doAutoClick;
S.timerSamplePeriod = 0.05; % sampling rate of simulator
S.mouseGain = 160; % normalize mouse output to [-.5 .5] Jan 2017
%% create and initialize figure window
S.figPos = get(0,'screensize');
S.fig = figure( 'menubar','none', ...
                'toolbar','none', 'numbertitle','off', ...
                'Name','Velocity Control Simulator');
axis off
S.ax = gca;
set(S.fig,'color','k')
text(.1,.6,'auto-VCS','color','w','fontsize',50,...
    'fontangle','italic');
text(-.05,.3,'Press ESCAPE to stop the application',...
    'color','w','fontsize',20);
%% use figure UserData to pass click and keystroke data around
set(S.fig,'UserData',[0 0]); % [click, stop]
%% set event callback functions
% mouse click
set(S.fig,'WindowButtonDownFcn', ...
    {@MouseClickFcn, S});
% mouse release
set(S.fig,'WindowButtonUpFcn', ...
    {@MouseReleaseFcn, S});
% key press
set(S.fig,'WindowKeyPressFcn', ...
    {@KeyHitFcn, S});
% key release
set(S.fig,'WindowKeyReleaseFcn', ...
    {@KeyReleaseFcn, S});
%% init UDP (pnet) connections
pnet('closeall')
delete(timerfind);
S.socket = InitUDPsender(localIP, localPort,remoteIP,remotePort);
S.dataSocket = InitUDPreceiver(localIP, gameDataPort);
S.formatSocket = InitUDPreceiver(localIP, gameFormattingPort);
% create timer object
timer_h = timer('TimerFcn',{@VCSloop, S}, ...
                'BusyMode','drop','TasksToExecute',inf, ...
                'ExecutionMode','FixedRate', 'Period', S.timerSamplePeriod, ...
                'StartDelay', S.timerSamplePeriod);
% START SIMULATOR
start(timer_h)
disp('Velocity Control Simulator: started')
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3.0 Main Loop (Timer Function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function VCSloop(obj, event, S)
 num_cont_dims   = 2;  % number of continuous dimensions to get from space mouse
 num_disc_dims   = 4;  % number of distinct clicks to read in
 num_t_dims      = 1;     % I don't know what this is for but it's necessary I guess?
    % check for program stop command
    uData = get(S.fig,'UserData'); 
    stopCheck = uData(2);
    if stopCheck
        disp('Velocity Control Simulator: stopped')
        stop(timerfind); % stop timer
        delete(timerfind); % delete timer
        CloseUDP(S.socket); % close UDP pnet connections
        CloseUDP(S.dataSocket);
        CloseUDP(S.formatSocket);

        close; % close figure
        clear all;
        return;
    end

    % initialize variables
    persistent packetFormat
    persistent t
    persistent gameData

    if isempty(t)
        t = 0;
    end

    fPacket = ReceiveUDP(S.formatSocket, 'latest', 'uint8');
    if ~isempty(fPacket)
        packetFormat = parseFormatPacket(fPacket);
        %disp('--- Got format packet ----');
    end
    if isempty(packetFormat)
        return;
    end

    dPacket = ReceiveUDP(S.dataSocket, 'latest', 'uint8');
    if ~isempty(dPacket)
        gameData = parseDataPacket(dPacket, packetFormat,  makeEmptyPacket(packetFormat));
    end
    if isempty(gameData)
        return;
    end

    errVec = double(gameData.currentTarget) - double(gameData.cursorPosition(:,1));
    errMag = sqrt(sum(errVec.^2));

    if strcmp(packetFormat.taskName,'cursor')
        workspaceSize = 0.1;
    elseif strcmp(packetFormat.taskName,'fitts')
        workspaceSize = 500;
    end

    if errMag>workspaceSize
        pushMag = 1;
    else
        pushMag = sqrt(errMag/workspaceSize);
    end
    cVec = (errVec/errMag)*pushMag;
    cVec(isnan(cVec)) = 0;

    %click
    if isfield(gameData,'targetDiameter')
        td = gameData.targetDiameter;
    else
        td = gameData.currentTargetDiameter;
    end
    
    if isfield(gameData, 'clickTarget') 
        autoClickTarg = gameData.clickTarget; 
    else
        autoClickTarg =  1; 
    end
   % S.doAutoClick = 0; 
    onTarget = (errMag <= td/2);
    %isClicking = single((uData(1) | onTarget) & S.doAutoClick);
    % save the click target as the click in auto 
    if onTarget && S.doAutoClick %override the user if it's on auto
        clicking = autoClickTarg; 
        fprintf('Click = %d\n', clicking);
    elseif uData(1) %unless the user has clicked off-target, then it's whatever the user entered
        clicking = uData(1);
        fprintf('Click = %d\n', clicking);
    else
        clicking = 0; 
    end

    %ARTIFICIAL BIAS
    cVec(1) = cVec(1) + 0.3;
%     disp(cVec);
    %pause;

    nDim = length(cVec);
    %        udpData = zeros(1,7);
    udpData = zeros(1,(num_t_dims + num_cont_dims + num_disc_dims));
    udpData(1) = t;
    velIdx = [2 3 4 6 7]; %looks like someone made this "3D + click" and then added 2 more dims
    udpData(velIdx(1:nDim)) = cVec*S.neuralScale; %scale down to make it noisier
    %SNF: now overwrite the last 4 indices with click: 
    clicked = zeros(1,4); 
    if clicking 
        clicked(clicking) = 1; 
    end
    udpData((num_t_dims + num_cont_dims +1):end) = clicked; 
    disp(udpData(2:end)); 
   % udpData(5) = uData(1); %uData(1) should always be returning which of the clicks or dwell 
   % udpData(5) = clicking;
    t = t+1;

    % update user data to reset click state
    set(S.fig,'UserData',uData);

    try
        SendUDP(S.socket,udpData);
        %disp(udpData);
    catch
        stop(timerfind);
        delete(timerfind);
        CloseUDP(S.socket);
        CloseUDP(S.dataSocket);
        CloseUDP(S.formatSocket);

        close all;
        clear all;
        fprintf('Velocity Control Simulator: Aborted\n');
        fprintf('*** UDP send failed... Check network connection\n');
        return;
    end
%% 4.0 Callback Functions
function MouseClickFcn(obj,event,S)
% callback fcn upon mouse click event
%     uData = get(S.fig, 'UserData');
%     uData(1) = 1;  % click on
    disp('CLICK, not saving this')
%     set(S.fig, 'UserData', uData);

function MouseReleaseFcn(obj,event,S)
% callback fcn upon mouse click event
%     uData = get(S.fig, 'UserData');
%     uData(1) = 0; % click off
    disp('RELEASE, not saving this')
%     set(S.fig, 'UserData', uData);

function KeyHitFcn(obj,event,S)
% callback fcn upon key press event
% SNF: this assumes someone hit esc to stop or 1-4 for click targets 
    uData = get(S.fig, 'UserData');
    fprintf(['KEY : ', event.Key, '\n']);
    if strcmp(event.Key,'escape') % if escape is pressed
        uData(2) = 1; % send stop message to timer
    else    % BOLD ASSUMPTION ALERT! This assumes you hit a number key. 
        if strcmp(event.Key(1), 'n') %if the numpad was used
            uData(1) = str2double(event.Key(7)); %get the number
        else                        % if you used the numbers above the letters
            uData(1) = str2double( event.Key ); %one of the clicks executed
        end
    end
    set(S.fig, 'UserData', uData);

function KeyReleaseFcn(obj, event, S)
% assumes a user released 1-4. we don't care when they release esc    
    disp('KEY RELEASED')
    uData = get(S.fig, 'UserData');
    uData(1) = 0; % whatever click it was is now off
    set(S.fig, 'UserData', uData); 