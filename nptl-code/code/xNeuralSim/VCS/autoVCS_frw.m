function autoVCS_frw(neuralScale, doAutoClick)

%automatically simulate velocity-tuned neural activity that can complete
%the cursor task in closed-loop

%% 1.0 User Settings

    % set IP address and port numbers
    % ********************************************************************

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
    % ********************************************************************

%% 2.0 Initialization
    if nargin<1
        neuralScale = .5;
        doAutoClick = 1;
    elseif nargin<2
        doAutoClick = 1;
    end
    S.neuralScale = neuralScale;
    S.doAutoClick = doAutoClick;
    S.timerSamplePeriod = 0.05; % sampling rate of simulator
    S.mouseGain = 160; % normalize mouse output to [-.5 .5] Jan 2017
    S.figPos = get(0,'screensize');
    
    % create figure
    S.fig = figure('menubar','none', ...
        'toolbar','none', 'numbertitle','off', ...
        'Name','Velocity Control Simulator');
    axis off
    S.ax = gca;
    set(S.fig,'color','k')
    text(.1,.6,'auto-VCS','color','w','fontsize',50,...
        'fontangle','italic');
    text(-.05,.3,'Press ESCAPE to stop the application',...
        'color','w','fontsize',20);
    
    % use figure UserData to pass click and keystroke data around
    set(S.fig,'UserData',[0 0]); % [click stop]
    
    % set event callback functions            
    % mouse click
    set(S.fig,'WindowButtonDownFcn', ...
        {@MouseClickFcn, S});
    % mouse release
    set(S.fig,'WindowButtonUpFcn', ...
        {@MouseReleaseFcn, S});
    % key press
    set(S.fig,'WindowKeyPressFcn', ...
        {@KeyHitFcn, S});
    
    % init UDP (pnet) connections
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
    
%% 3.0 Main Loop (Timer Function)

    function VCSloop(obj, event, S)
    
        % check for program stop command
        uData = get(S.fig,'UserData'); % [click stop]
         
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
        onTarget = (errMag <= td/2);
        isClicking = single((uData(1) | onTarget) & S.doAutoClick);
        
        %ARTIFICIAL BIAS
        cVec(1) = cVec(1) + 0.3;
        disp(cVec);
        %pause;
        
        nDim = length(cVec);
        udpData = zeros(1,7);
        udpData(1) = t;
        velIdx = [2 3 4 6 7];
        udpData(velIdx(1:nDim)) = cVec*S.neuralScale; %scale down to make it noisier
        udpData(5) = isClicking;
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

        uData = get(S.fig, 'UserData');
        uData(1) = 1;  % click on
        disp('CLICK')
        set(S.fig, 'UserData', uData);
        
    function MouseReleaseFcn(obj,event,S)
        % callback fcn upon mouse click event
        uData = get(S.fig, 'UserData');
        uData(1) = 0; % click off
        disp('RELEASE')
        set(S.fig, 'UserData', uData);
        
    function KeyHitFcn(obj,event,S)
            
        % callback fcn upon key press event

        uData = get(S.fig, 'UserData');

        if strcmp(event.Key,'escape') % if escape is pressed
            uData(2) = 1; % send stop message to timer
        end

        set(S.fig, 'UserData', uData);
    
    
