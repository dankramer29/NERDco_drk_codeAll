% CursorTaskVid2D.m
%
% Given an NPTL cursor task R struct of a 2D cursor task, it will generate a video of it.
% NOTE: Seems to do wonky things if multiple monitors are in use. Thus, render with a
% single-monitor setup.
%
% USAGE: [ out ] = CursorVid( R, plottedSignal, varargin )
%
% EXAMPLE:
%n
% INPUTS:
%     R                         R struct of trials to be plotted. Will look bizarre if not
%                               contiguious, but that's the user's problem.
%     filename                  Full path and name of the file to save. MUST be .avi or
%     mp4
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%
% OUTPUTS:
%     none                       
%
% Created by Sergey D. Stavisky on 13 Mar 2019
% Stanford Neural Prosthetics Translational Laboratory

function [ out ] = CursorTaskVid2D( R, filename, varargin )
  

    % Important
    def.plotDims = [1 2]; % 2D task
    def.posField = 'cursorPosition';
    def.fps = 30; % Video frame rate. Very important.
    def.successFailSounds = true; %
    def.audioStream = []; % if non-empty, will play this audio. The audiotrack isn't in trials, it's just free-running
                         % and this function just samples from it for each frame until either the audio track is
                         % empty, or the video of R stuct of trials have all been rendered.

    % Workspace - leave empty to autoget
    def.myxlim = []; % px
    def.myylim = []; % px
    
    def.tmax = Inf; % can manually specify that the video has a set length. 
    
    % Content
    def.showWinbox = false; % show the target acquisition boundary
    def.annotateTime = true; % set to false if you don't want seconds in top right corner
    def.annotateTrial = true; % set to false if you don't want trial number in top left
    def.annotateSuccessRate = true; % set to false if you don't want success rate in top left

    
    % Aesthetics
    def.backgroundColor = [0 0 0];
    def.winboxColor = [.5 .5 .5];
    def.textColor = [1 1 1];
    def.cursorColor = [1 1 1]; % White is default NPTL cursor color. Can override what R struct specifies, for visibility. Set to empty
                                % to use what R struct specified
    def.cursorAlpha = 1;
    def.targetAlpha = 1;
    def.targetColorNotHover = [0 255 255]./255; % target is aqua when active
    def.cursorRadius = 22.5;
    def.targetColorHover = [255 133 0]./255; % target is orange when cursor is over it.
    def.twoD = true; % plot fully 2D
    def.sphereVertices = 100; % how pretty to draw the spheres
    def.hasLighting = true; % makes things look 3D
    def.FontName = 'Monaco'; %monospaced highly suggested
    def.FontSize = 18; 
    
    % bunch of technical video stuff
    def.Quality = 90;
    def.widthPixels = []; % height is then set according by aspect ratio dervied from chanMap
%     def.widthPixels = 480; % height is then set according by aspect ratio dervied from chanMap
    def.heightPixels = []; % if nonzero, width is set by aspect ratio
    
    def.HOLDSTATE = 4; % for when to color target
    
    assignargs( def, varargin );
    
    %% Get some things from the task
    if isempty( myxlim )
        myxlim = double( R(1).startTrialParams.workspace(:,plotDims(1)) );
    end
    if isempty( myylim )
        myylim = double( R(1).startTrialParams.workspace(:,plotDims(2)) );
    end
    
    %% Initialize
    AIP = successFailSounds | ~isempty( audioStream ); % audio input port property

    if AIP        
        % Use vide.VideoFileWriter to make audiovideo file
        writerObj = vision.VideoFileWriter( filename, 'FileFormat', 'AVI', ...
        'AudioInputPort', AIP, 'Quality', Quality);        
        writerObj.FrameRate = fps;
%           writerObj = vision.VideoFileWriter( filename, 'FileFormat', 'MPEG4', ...
%             'AudioInputPort', true, 'Quality', Quality);       
    else
        % Use VideoWriter (built-in MATLAB class) to make the video
        writerObj = VideoWriter( filename );
        writerObj.FrameRate = fps;
        try
            writerObj.Quality = Quality; % wont work for some video profiles
        catch
        end
        open( writerObj );
    end
    
    % TOTAL TIME 
    tott = numel( [R.clock] )/1000; % in seconds
    tott = min( [tott, tmax] ); % allows manually setting it to be shorter
    stepSec = 1 / fps;
    
  
    % these guys increment as we step through
    tGlobal = 0;
    tTrial = 0; 
    currTrial = 1;
    frameNum = 0;
    
    
    % initialize the figure and axes
    figh = figure;
    set( figh, 'Color', backgroundColor );
    % generate axes
    axh = axes;
    set( axh, 'XTick', [], 'YTick', [], 'Color', backgroundColor, 'XColor', backgroundColor, 'YColor', backgroundColor );     % make the axes invisble
    % set limits 
    set( axh, 'XLim', myxlim, 'YLim', myylim, 'Position', [0 0 1 1]  );
    
    
    % set aspect ratio based on figure limits
    width = range( xlim );
    height = range( ylim );
    if isempty( widthPixels )
        wPix = width;
    else
        wPix = widthPixels;
        hPix =  ceil( (height/width)*wPix );
    end
    if isempty( heightPixels )
        hPix = height;
    else
        hPix = heightPixels;
        wPix =  ceil( (width/height)*hPix );
    end
    
    initPosition = get( figh, 'Position' );
    initPosition(1:2) = [1,1]; % put into corner
    set( figh, 'Units', 'pixels', 'Position', [initPosition(1), initPosition(2) wPix, hPix])
    set( axh, 'Units', 'pixels', 'Position', [1 1 wPix hPix] )

    pause(0.1); % for some reason its not happy otherwise.


    % It's faster to create and update the objects than redraw them each time
    % initialize target and cursor
    target.xy = R(1).posTarget(plotDims);
    target.size = repmat( R(1).startTrialParams.targetDiameter/2, 2, 1 ); % divide by 2 since size is used as a radius here
    if showWinbox
        target.winbox = R(1).startTrialParams.winBox(1:2);
    end
    % am I in target or out of target? This determines target's color
    if R(1).state(1) == HOLDSTATE
        target.color = targetColorHover;
    else
        target.color = targetColorNotHover;
    end
    if twoD
         hTarget = rectangle(  'Position', [(target.xy-target.size)' target.size'.*2 ], 'Curvature', [1 1], ...
        'LineWidth', 2, 'EdgeColor', target.color, 'FaceColor', target.color);
    else
        [target.ddd.x, target.ddd.y, target.ddd.z] = sphere( sphereVertices );
        target.ddd.x = target.ddd.x*target.size(1) + target.xy(1);
        target.ddd.y = target.ddd.y*target.size(1) + target.xy(2);
        target.ddd.z = target.ddd.z*target.size(1) + -70;
        hTarget = surface(target.ddd.x,target.ddd.y, target.ddd.z, ...
            'FaceColor', target.color, 'EdgeColor', 'none', 'FaceAlpha', cursorAlpha);
    end

    % Plot winbox
    if showWinbox
        % draw the winbox
        hWinbox = rectangle(  'Position', [(target.xy-target.winbox)' target.winbox'.*2], 'Curvature', [0 0], ...
            'LineWidth', 1, 'EdgeColor', winboxColor, 'LineStyle', '--');
    end
    
    % plot cursor
    cursor.xy = R(1).(posField)(plotDims,1);
    % TODO: look for individual trial cursor radius if that becomes an available field
    %     cursor.size = R(1).startTrialParams.sizeCursor(1:2);
    cursor.size = repmat( cursorRadius, 2, 1 );
    if isempty( cursorColor )
        cursor.color = R(1).startTrialParams.colorCursor./256;
    else
        cursor.color = cursorColor;
    end
    if twoD
        hCursor = rectangle(  'Position', [(cursor.xy-cursor.size)' cursor.size'.*2 ], 'Curvature', [1 1], ...
            'LineWidth', 2, 'EdgeColor', cursor.color, 'FaceColor', cursor.color);        
    else
        % draw the sphere as a surface
        [cursor.ddd.x, cursor.ddd.y, cursor.ddd.z] = sphere( sphereVertices );
        cursor.ddd.x = cursor.ddd.x*cursor.size(1) + cursor.xy(1);
        cursor.ddd.y = cursor.ddd.y*cursor.size(1) + cursor.xy(2);
        cursor.ddd.z = cursor.ddd.z*cursor.size(1) + 0;
        hCursor = surface(cursor.ddd.x,cursor.ddd.y, cursor.ddd.z, ...
            'FaceColor', cursor.color, 'EdgeColor', 'none', 'FaceAlpha', cursorAlpha);
        
        if hasLighting
            lighth = light('Position',[200 200 50], 'Style','infinite');
            set(hCursor, 'SpecularColorReflectance', 0.1, 'AmbientStrength', 1, ...
                'DiffuseStrength', 1, 'BackFaceLighting', 'lit')
            set( hTarget, 'SpecularColorReflectance', 0.1, 'AmbientStrength',1, ...
                'DiffuseStrength', 1,'BackFaceLighting', 'lit');
            
        end
    end


    % get the true limits - shouldnt have cahnged unless axis equal was used (don't do it)
    truexlim = get( axh, 'XLim' );
    trueylim = get( axh, 'YLim' );
  
    % Annotations
    if annotateTime
        th = text( truexlim(2), trueylim(2),   sprintf('%*.1fs', ceil( tott/10 )+2, tGlobal ) , ...
            'FontSize', FontSize, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', ...
            'Color', textColor, 'FontName', FontName);
    end
    if annotateTrial
        trialh = text( truexlim(1), trueylim(2),   sprintf('trial %i', 1 ) , ...
            'FontSize', FontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
            'Color', textColor, 'FontName', FontName);
    end
    if annotateSuccessRate
        srh = text( truexlim(1), trueylim(2)-0.06*range( myylim ),   sprintf('' ) , ...
            'FontSize', FontSize, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
            'Color', textColor, 'FontName', FontName); % empty at start
    end
    
    audioPtr = 1; % where audio points to (if it's used);
    numSuccessful = 0; % for tracking success rate

    %% Big loop across time steps
    while tGlobal < tott        
        % Where in time (and which trial) are we?
        frameNum = frameNum + 1;
        
        prevTrialLength = numel( R(currTrial).clock )/1000;
        while tTrial > prevTrialLength % rollover to next trial
            numSuccessful = numSuccessful + R(currTrial).isSuccessful;
            
            
            tTrial = tTrial - prevTrialLength;
            currTrial = currTrial + 1;
            fprintf(' trial %i total time is now %.3f\n', currTrial, tGlobal) % DEV
            prevTrialLength = numel( R(currTrial).clock )/1000;
            
            % update target (once per trial)
            target.xy = R(currTrial).posTarget(plotDims);
            target.size = repmat( R(currTrial).startTrialParams.targetDiameter/2, 2, 1 ); % divide by 2 since size is used as a radius here         
         
            % Update winbox (once per trial)
            if showWinbox
                target.winbox = R(currTrial).startTrialParams.winBox(1:2);
                % draw the winbox
                set( hWinbox, 'Position', [(target.xy-target.winbox)' target.winbox'.*2], 'Curvature', [0 0], ...
                    'LineWidth', 1, 'EdgeColor', winboxColor, 'LineStyle', '--');
            end          
            % Update performance/trial count text
            if annotateTrial
                set( trialh, 'String',  sprintf('trial %i', currTrial ) );
            end
            if annotateSuccessRate
                set( srh, 'String',  sprintf('%-3.0f%% success rate', 100*numSuccessful/(currTrial-1) ) );
            end
        end

        
        
        % current time in the trial, in MS
        currMS = max([floor( tTrial.*1000 ),1]); % min so indexes start at 1
        
        
        % update target
        target.xy = R(currTrial).posTarget(plotDims);
        target.size = repmat( R(currTrial).startTrialParams.targetDiameter/2, 2, 1 ); % divide by 2 since size is used as a radius here
        if showWinbox
            target.winbox = R(currTrial).startTrialParams.winBox(1:2);
        end
        % am I in target or out of target? This determines target's color
        if R(currTrial).state(currMS) == HOLDSTATE
            target.color = targetColorHover;
        else
            target.color = targetColorNotHover;
        end
 
               
        if twoD
            set( hTarget, 'Position', [(target.xy-target.size)' target.size'.*2 ], 'Curvature', [1 1], ...
                'LineWidth', 2, 'EdgeColor', target.color, 'FaceColor', target.color);
        else
            [target.ddd.x, target.ddd.y, target.ddd.z] = sphere( sphereVertices );
            target.ddd.x = target.ddd.x*target.size(1) + target.xy(1);
            target.ddd.y = target.ddd.y*target.size(1) + target.xy(2);
            target.ddd.z = target.ddd.z*target.size(1) + -70;
            set( hTarget, 'XData', target.ddd.x, 'YData', target.ddd.y, 'ZData', target.ddd.z, ...
                'FaceColor', target.color );
        end
 
        % update  cursor       
        cursor.xy = R(currTrial).(posField)(plotDims,currMS);
        cursor.size = repmat( cursorRadius, 2, 1 );
        if isempty( cursorColor )
            cursor.color = R(currTrial).startTrialParams.colorCursor./256;
        else
            cursor.color = cursorColor;
        end
        if twoD
             set( hCursor, 'Position', [(cursor.xy-cursor.size)' cursor.size'.*2 ], 'Curvature', [1 1], ...
                 'LineWidth', 2, 'EdgeColor', cursor.color, 'FaceColor', cursor.color);
        else
            [cursor.ddd.x, cursor.ddd.y, cursor.ddd.z] = sphere( sphereVertices );
            cursor.ddd.x = cursor.ddd.x*cursor.size(1) + cursor.xy(1);
            cursor.ddd.y = cursor.ddd.y*cursor.size(1) + cursor.xy(2);
            cursor.ddd.z = cursor.ddd.z*cursor.size(1) + 0;
            set( hCursor, 'XData', cursor.ddd.x, 'YData', cursor.ddd.y, 'ZData', cursor.ddd.z, ...
                'FaceColor', cursor.color );
        end
        
        % Update time
        if annotateTime
            set( th, 'String', sprintf('%*.1fs', ceil( tott/10 )+2, tGlobal ) );
        end

        

        % Add this frame to the movie 
        drawnow;
        frame = getframe( axh ); 
        if AIP
            myAudio = audioStream.dat(audioPtr:audioPtr + round(audioStream.Fs*stepSec)-1);

            step( writerObj, frame.cdata, myAudio); % write with no audio
%             step( writerObj, frame.cdata ); % write with no audio
            audioPtr = audioPtr + round(audioStream.Fs*stepSec);

        else
            writeVideo( writerObj, frame );
        end
        
        tGlobal = tGlobal + stepSec;
        tTrial = tTrial + stepSec;
    end

    
    
    % Finish out the video
    if AIP
        release( writerObj );
    else
        close( writerObj );
    end
end