function VCS()

% Velocity-Control Simulator
%
% Function: sends velocity and click commands to simulink system based on
% the mouse position and click state

% created by Dan Bacher (revised 12/7/2009)

%% 1.0 User Settings

    % set IP address and port numbers
    % ********************************************************************
    remoteIP = '192.168.137.1';
    %remoteIP = '128.148.107.69'; % Sergey Desktop
    %remoteIP = '128.148.107.54'; % Dan's workstation
                                 
    
    remotePort = 5555;           % target port, default = 5555 for now
    
    localPort = 5554;            % local port, keep at 5554
    % ********************************************************************

%% 2.0 Initialization
    
    % initialize parameters
    % use structure S to pass around variables
    
    S.screenSize = get(0,'screensize'); % get screen dimensions
    S.figPos = S.screenSize; % set figure to full screen
    S.timerSamplePeriod = 0.1; % sampling rate of simulator
    
    % create figure
    S.fig = figure('position',S.figPos, 'menubar','none', ...
        'toolbar','none', 'numbertitle','off', ...
        'Name','Velocity Control Simulator');
    axis off
    S.ax = gca;
    set(S.fig,'color','k')
    
    % use figure UserData to pass mouse data across functions
    set(S.fig,'UserData',[0 0 0 0]); % [x y click stop]
    
    % init UDP (pnet) connections
    pnet('closeall')
    S.socket = InitUDPsender(localPort,remoteIP,remotePort);
    
    % create timer object
    timer_h = timer('TimerFcn',{@VCSloop, S}, ...
        'BusyMode','drop','TasksToExecute',inf, ...
        'ExecutionMode','FixedRate', 'Period', S.timerSamplePeriod, ...
        'StartDelay', S.timerSamplePeriod);
    
    % clear pnet text
    clc;
    
    % START SIMULATOR
    start(timer_h)
    disp('Velocity Control Simulator: started')
    
    
%% 3.0 Main Loop (Timer Function)

    function VCSloop(obj, event, S)
    
    % INITIALIZE
        
        % initialize variables
        persistent t vel % place holder for time stamp
        if isempty(t); t = 0; end
        if isempty(vel); vel = [0 0 0]; end
        
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
        
        % get mouse data
        mouseData = get(S.fig,'UserData'); % [x y click]
        
        % convert mouse position to velocity
        velocity = [mouseData(1:2) 0]; % [x y z], for now z = 0
        
        % get click status
        clickState = mouseData(3);
        if clickState
            mouseData(3) = 0; % reset mouse click state
        end
        
        % define UDP array and send packet
        udpData = [t velocity clickState];
        
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
        
        % update mouseData to reset click state
        set(S.fig,'UserData',mouseData);

        % check for program stop command
        stopCheck = mouseData(4);
        if stopCheck
            disp('Velocity Control Simulator: stopped')
            stop(timerfind); % stop timer
            delete(timerfind); % delete timer
            CloseUDP(S.socket); % close UDP pnet connections
            
            close; % close figure
            clear all;
        end
        
        %disp(udpData)
        
        
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
            
    
