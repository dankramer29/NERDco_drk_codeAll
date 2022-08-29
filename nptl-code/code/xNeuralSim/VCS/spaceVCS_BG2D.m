function spaceVCS_BG2D()

% Velocity-Control Simulator (using space mouse input device)
%
% Function: sends velocity and click commands to simulink system based on
% the mouse position and click state

% created by Dan Bacher (original Mouse version 12/7/2009)
% space mouse version created 04/13/2010

%% 1.0 User Settings

    % set IP address and port numbers
    % ********************************************************************
    %remoteIP = '192.168.137.1';
    %remoteIP = '128.148.107.69'; % Sergey Desktop
    %remoteIP = '128.148.107.72'; % Dan's workstation
    remoteIP = '255.255.255.255'; % broadcast to any IP
                                 
    
    remotePort = 51401;           % target port, default = 5555 for now
    
    localPort = 5554;            % local port, keep at 5554
    
    startStopPort = 8001;
    % ********************************************************************

%% 2.0 Initialization

    S.timerSamplePeriod = 0.05; % sampling rate of simulator
    %S.mouseGain = 160; % normalize mouse output to [-.5 .5]
    S.mouseGain = 400;
    %S.figPos = get(0,'screensize');
    
    % create figure
%     S.fig = figure('menubar','none', ...
%         'toolbar','none', 'numbertitle','off', ...
%         'Name','Velocity Control Simulator');
%     axis off
%     S.ax = gca;
%     set(S.fig,'color','k')
%     text(.1,.6,'space-VCS','color','w','fontsize',50,...
%         'fontangle','italic');
%     text(-.05,.3,'Press ESCAPE to stop the application',...
%         'color','w','fontsize',20);
    
    % use figure UserData to pass click and keystroke data around
    %set(S.fig,'UserData',[0 0]); % [click stop]
    
    % init UDP (pnet) connections
    pnet('closeall')
    S.socket = InitUDPsender(localPort,remoteIP,remotePort);
    S.startStopSocket = InitUDPsender(8010,remoteIP,startStopPort);
    
    % create timer object
    sim_timer_h = timer('TimerFcn',{@VCSloop, S}, ...
        'BusyMode','drop','TasksToExecute',inf, ...
        'ExecutionMode','FixedRate', 'Period', S.timerSamplePeriod, ...
        'StartDelay', S.timerSamplePeriod);        
    
    % START SIMULATOR
    Mouse3D('start'); % start space mouse actxserver
    clc;
    start(sim_timer_h)
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
            % mouse click
%             set(S.fig,'WindowButtonDownFcn', ...
%                 {@MouseClickFcn, S});
%             % key press
%             set(S.fig,'WindowKeyPressFcn', ...
%                 {@KeyHitFcn, S});
            
    % EXECUTE
    
        % increment time stamp / counter
        t = t+1;
        
        % get user data
        %uData = get(S.fig,'UserData'); % [click stop]
        
        % get space mouse data
        M = Mouse3D('get');       
        velocity = M.pos./S.mouseGain;         
        
        spaceState = velocity(3); % use up/down as stop/click commands
        
        % get click status
%         clickState1 = uData(1);
%         if clickState1
%             uData(1) = 0; % reset mouse click state
%         end
        
        % use space mouse push down as click
        if spaceState < -.9
            clickState = 1;
        else
            clickState = 0;
        end
        
        clickState = clickState;
        
        velocity = velocity./30;
        udpData = [t velocity clickState];
        disp(udpData)
        try 
            SendUDP(S.socket,udpData);        
        catch
            stop(timerfind);
            delete(timerfind);
            CloseUDP(S.socket);
            CloseUDP(S.startStopSocket);
            close all;
            clear all;
            fprintf('Velocity Control Simulator: Aborted\n'); 
            fprintf('*** UDP send failed... Check network connection\n');
            return;
        end
        
        % update user data to reset click state
        %set(S.fig,'UserData',uData);
        
        % check for program stop command
        %stopCheckEsc = uData(2);
        
        if spaceState > .99
            stopCheckMouse = 1;
        else
            stopCheckMouse = 0;
        end
        
        stopCheck = stopCheckMouse;
        if stopCheck
            SendUDP(S.startStopSocket, [201 2]);
            disp('Velocity Control Simulator: stopped')
            stop(timerfind); % stop timer
            delete(timerfind); % delete timer
            CloseUDP(S.socket); % close UDP pnet connections
            CloseUDP(S.startStopSocket);
%             try 
%                 Mouse3D('stop');
%             catch
%                 disp('could not stop space mouse')
%             end
            close; % close figure
            clear all;
        end
    
%% 4.0 Callback Functions    
    
%     function MouseClickFcn(obj,event,S)
%             
%         % callback fcn upon mouse click event
% 
%         uData = get(S.fig, 'UserData');
%         uData(1) = 1;
%         disp('CLICK')
%         set(S.fig, 'UserData', uData);
%         
%     function KeyHitFcn(obj,event,S)
%             
%         % callback fcn upon key press event
% 
%         uData = get(S.fig, 'UserData');
% 
%         if strcmp(event.Key,'escape') % if escape is pressed
%             uData(2) = 1; % send stop message to timer
%         end
%        
%         
%         set(S.fig, 'UserData', uData);
%     
    
