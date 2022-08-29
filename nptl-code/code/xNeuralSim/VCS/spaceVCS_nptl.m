function spaceVCS()

% Velocity-Control Simulator (using space mouse input device)
%
% Function: sends velocity and click commands to simulink system based on
% the mouse position and click state

% created by Dan Bacher (original Mouse version 12/7/2009)
% space mouse version created 04/13/2010
% updated by Sergey Stavisky 08/13/2016 to work at NPTL rigH

%% 1.0 User Settings

    % set IP address and port numbers
    % ********************************************************************
    %remoteIP = '192.168.137.1';
    %remoteIP = '128.148.107.69'; % Sergey Desktop
    %remoteIP = '128.148.107.72'; % Dan's workstation
    
    remoteIP = '192.168.137.255'; % broadcast to any IP
    %remoteIP = '192.168.137.82'; % DLR CPU direct robot control
                                 
    
    remotePort = 49255;   % VCS in xPC model.       
    
    % target port, default = 5555 for now
    %remotePort = 1001; % for direct DLR robot control
  
    % localIP
    %getXpcIPs = getMyIP('192.168.10.255');
    getXpcIPs = getMyIP('192.168.137.255');
    if ~isempty(getXpcIPs{1})
        localIP = getXpcIPs{1};
    else
        getAnyIP = getMyIP;
        localIP = getAnyIP{1};
    end

    
    
    localPort = 49454;            % NPTL
    
    % receive data from BG2D
    gamePort = 49501;
    % ********************************************************************

%% 2.0 Initialization

    S.timerSamplePeriod = 0.05; % sampling rate of simulator
    S.mouseGain = 160; % normalize mouse output to [-.5 .5] Jan 2017
%     S.mouseGain = 320; % pre Jan 2017 way
    S.figPos = get(0,'screensize');
    
    % create figure
    S.fig = figure('menubar','none', ...
        'toolbar','none', 'numbertitle','off', ...
        'Name','Velocity Control Simulator');
    axis off
    S.ax = gca;
    set(S.fig,'color','k')
    text(.1,.6,'space-VCS','color','w','fontsize',50,...
        'fontangle','italic');
    text(-.05,.3,'Press ESCAPE to stop the application',...
        'color','w','fontsize',20);
    
    % use figure UserData to pass click and keystroke data around
    set(S.fig,'UserData',[0 0]); % [click stop]
    
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
    
    % START SIMULATOR
    Mouse3D('start'); % start space mouse actxserver
    clc;
    start(timer_h)
    disp('Velocity Control Simulator: started')
    
%% 3.0 Main Loop (Timer Function)

    function VCSloop(obj, event, S)
    
    % INITIALIZE
        
        % initialize variables
        persistent t vel % place holder for time stamp
        if isempty(t); t = 0; end
        if isempty(vel); vel = [0 0 0]; end
        
        udpData = zeros(1,6); % [t x y z click rot1]
        velocity = [0 0 0];       
        clickState = 0;
        
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
            
    % EXECUTE
    
        % increment time stamp / counter
        t = t+1;
        
        % get user data
        uData = get(S.fig,'UserData'); % [click stop]
        
        % get space mouse data
        M = Mouse3D('get');       
        velocity = M.pos./S.mouseGain;
%         if any( velocity )
%             keyboard
%         end
       
        % if you also want rotations use:
        rotation = M.rot;
        % rotate CW/CCW
        rot1 = rotation(2)/2; % divide by half so it ranges from [-0.5 0.5]
        % tilt forward/back 
        rot2 = -rotation(1)/2; % divide by half so it ranges from [-0.5 0.5]
%         rot2 = 0; % makes 4D testing easier
        
        % DEV
%         rot1 = 0.25 * rot1;
        velocity = [1*velocity(1), -1*velocity(2), 1*velocity(3)];

        
        % get click status
        clickState = uData(1);
        
        udpData = [t velocity clickState rot1 rot2]; % standard
        disp(udpData(2:end))
        
        %velocity = velocity .* 0.4;
        %udpData = [21 t velocity clickState zeros(1,8)];
        %disp(udpData(3:6));
        
        try 
            SendUDP(S.socket,udpData);        
        catch
            stop(timerfind);
            delete(timerfind);
            CloseUDP(S.socket);
            close all;
            clear all;
            fprintf('Velocity Control Simulator: Aborted\n'); 
            fprintf('*** UDP send failed... Check network connection\n');
            return;
        end
        
        % update user data to reset click state
        set(S.fig,'UserData',uData);
        
        % check for program stop command
        stopCheck = uData(2);
        if stopCheck
            disp('Velocity Control Simulator: stopped')
            stop(timerfind); % stop timer
            delete(timerfind); % delete timer
            CloseUDP(S.socket); % close UDP pnet connections
            
            close; % close figure
            clear all;
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
    
    
