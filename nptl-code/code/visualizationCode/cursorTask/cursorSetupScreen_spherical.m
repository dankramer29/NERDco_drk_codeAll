function flipTime = cursorSetupScreen(data)
global taskParams;
global redisCon;

persistent screenKilled;
persistent countUp; % DEV
if isempty( countUp )
    countUp = 1;
else
    countUp = countUp + 1;
end
if isempty(screenKilled)
    screenKilled = false;
end

% SDS August 2016: these apply to the PTB faux-3D. SCL doesn't care about
% these.
DEPTH_LIMITS = [-500 500]; % used to scale the size of cursors/targets based on their depth coordinate
SCALE_RANGE = [0.5 2];    % sizes will go from [0.5 to 1.5] with depth of
% 0 corresponding to scale of 1.




%% all the relevant info is in the "data" field of the packet, deconstruct it
armTargetPosScale = 1; % We're now using meters as our fundamental position unit so no scaling needed



armFlip1 = double(-1); % first element of SCL vectors (horizontal). Positive scl coord means LEFT
armFlip2 = double(-1); % second element of SCL vectors (vertical). Positive means DOWN.
armFlip3 = double(-1); % third element of SCL vectors (depth). Positive means OUT of screen.
armFlip4 = double(1);  % fourth element of SCL vectors. Spherical coordinate angle in XY plane. Positive means right side goes down (clockwise) 
armFlip5 = double(-1); % fifth element of SCL vectors. Spherical coordinate angle in YZ plane. Positive means top comes out of screen. 




switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        
        m.packetType = data.state;
        global screenParams;
        cursorAlpha = 1;

        red = [255 0 0 ];
        grey = [100 100 100];
        blue = [0 153 153];
        green = [00 204 00];
        aqua = [0 255 255];
        orange = [255 133 0];
        
        
        yellow = [153 153 25];
        purple = [100 0 100];       
        white = screenParams.white;
        mp = screenParams.midpoint;
        cursorOutline=3; %% in pixels (for PTB mode only
        
       
        if uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR) % Cursor task, but rendered in SCL
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%                          SCL-CURSOR
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Get dimensionality of task. A lot of graphics options depend
            % on this.
            numDims = double( data.numDisplayDims );  % I'm going to want to pull
%             fprintf('numDims = %i\n', numDims );
           
            % Aesthetic parameters for 4D, where the targets and cursor are
            % rectangular prisms.
            smallerDimsFactor = 4; % the short dimensions are this much shorter
                                   % than the target diameter specified by
                                   % xPC
            % "bulge" orients in space. Think of it as a mallet head on the
            % left, the pipe in : |----    
%             rodWidth = 0.7; % fraction of XYZ acceptance window rod spans
            bulgeCenter = 0.10; % fraction from left of target or cursor rod.   
            bulgeGirth = 1.15; % how much larger the bulge is than the rod
            bulgeHeight = 0.8; % fraction of rod width that is the bulge's height
            xyzTargetTransparency = 0.25; % we use a translucent sphere (or cube in Gridlike)
            % to show the spatial extent of the target, in addition to a
            % more opaque oriented rod. This parameter sets that
            % transparency.
                                   
            % scale rotation coordinates (which go from -0.13 to 0.13) to
            % radians. A received rtation dim value of this much means maximum clockwise rotation.
            % Negative means counter-clockwise% make sure this is matched to what's going on in xPC world
            % 0 dim4 coordinate means horizontal to viewer, i.e. no
            % rotation along z (in-out of screen) axis.
            % 0 dim5 coordinate means flat along screen, i.e. no rotation
            % in or out of screen.
            thetaXY_xPC_limit = 0.13;  % XY plane angle/elevation (spherical coordinates)
            thetaXY_radian_limits = deg2rad(86); % beyond 90, each visual representation is not unique. Add another 10 degrees to
                            % be perceptually safe. 
            thetaYZ_xPC_limit_radian_limits = thetaXY_xPC_limit; %XZ plane angle/azimuth (spherical coordinates)
            thetaYZ_xPC_limit = thetaXY_radian_limits;
            if ~screenKilled, sca; end
            
            if isempty(redisCon)
                redisCon = redis();%'localhost', 6379);
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     ENABLE OBJECTS WE CARE ABOUT
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            redisCon.set('bmi_cursor_enabled', 1); % show the cursor
            redisCon.set('bmi_center_enabled', 0); % hide the rigC second cursor
            redisCon.set('bmi_target_enabled', 1); % show the target
            
            
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     TARGET
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            targetColorStr = char(data.targetColor);
            switch targetColorStr
                case 'a'
                    currentTargetColor = aqua;
                case 'o'
                    currentTargetColor = orange;
                case 'g'
                    currentTargetColor = green;
                case 'y'
                    currentTargetColor = green; % these are click-targets, but we're making them green
                case 'p'
                    currentTargetColor = purple;
                case 'b'
                    currentTargetColor = blue;
                case 'n' % special, means aura should be colored but target stays aqua
                    currentTargetColor = aqua;
            end
            % We have the ability to color target aura differently.
            if targetColorStr == 'n'
                currentAuraColor = orange;
            else
                currentAuraColor = currentTargetColor;
            end
                
            currentTargetColor = currentTargetColor./255; %SCL uses 0 to 1
            currentAuraColor = currentAuraColor./255;
            sclTargPos(1) = double(data.currentTarget(1))*armTargetPosScale*armFlip1; % horizontal pos
            sclTargPos(2) = double(data.currentTarget(2))*armTargetPosScale*armFlip2;  % vertical pos
            sclTargPos(3) = double(data.currentTarget(3))*armTargetPosScale*armFlip3; % depth pos
            
            % Target shape: 0 == sphere, 1 == box
            switch data.taskType
                case 5 %gridlike variant, draw target as cube
                    redisCon.set('bmi_target_shape', sprintf('%0.3f', 1 ) );
                    targetSize = double(data.targetDiameter) * armTargetPosScale;
                    targetAlpha = 0.7;
                    redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', sclTargPos(1), sclTargPos(2) , sclTargPos(3) ) );

                
                otherwise % nonGridlike cursor task variants
                    targetAlpha = 1;    
                    if numDims > 3                        
                        sclTargPos(4) = double(data.currentTarget(4))*armTargetPosScale*armFlip4; % wrist rotate (around z axis)
                        if numDims > 4
                             sclTargPos(5) =  double(data.currentTarget(5))*armTargetPosScale*armFlip5; % wrist rotate (around z axis)
                        else
                            sclTargPos(5) = 0;
                        end

                        % Target becomes a rod.
                        redisCon.set('bmi_target_shape', sprintf('%0.3f', 1 ) ); 
                        targetSize = double(data.targetDiameter) * armTargetPosScale;
                        targetSizeSecondary = targetSize / smallerDimsFactor;
                        targetAlpha = 1;
                        % Create 3D extent target too. This is another object which
                        % shows the spatial extent of our target. SDS March 2017
                       
                        % XYZ EXTENT "AURA" (Sphere)
                        auraSize = targetSize/2; % radius
                        redisCon.set('bmi_sphere_enabled_2', 1);  % make 1 to show aura
                        redisCon.set('bmi_sphere_position_2', sprintf('%0.4f %0.4f %0.4f',  sclTargPos(1), sclTargPos(2), sclTargPos(3) ) );
                        redisCon.set('bmi_sphere_radius_2', sprintf('%0.3f %0.3f %0.3f', auraSize, auraSize, auraSize) );  % 3 elements for box, but only frist is used for sphere
                        redisCon.set('bmi_sphere_color_2', sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                            currentAuraColor(1),  currentAuraColor(2),  currentAuraColor(3), xyzTargetTransparency   ) );  
%                        
                        % Target rotation
                        % See the equivalent section of the Cursor rotation
                        % code for an explanation of the math. -Sergey
                        % March 12 2017
                  
                        theta_XY = ( sclTargPos(4) / thetaXY_xPC_limit)*thetaXY_radian_limits; % elevation in radians
                        theta_YZ = ( sclTargPos(5) / thetaYZ_xPC_limit_radian_limits)*thetaYZ_xPC_limit; % azimuth in radians
                        s = [0, 1, 0];
                        [d(2), d(1), d(3)] = sph2cart(theta_XY,theta_YZ, 1); % note echanged order because we define XY as azimuth
                        d(1) = -d(1); % to accomodate the flipped sign of the SCL y axis
                        theta = acos(s*d'); % smallest angle between s and d.
                        orthoVec = cross(s,d);
                        if any( orthoVec ) % so it doesn't nan out at 0,0,0                           
                            orthoVec = orthoVec./norm(orthoVec);
                        end
                        u = orthoVec(1);
                        v = orthoVec(2);
                        w = orthoVec(3);
                        R_total = [ u^2 + (1-u^2)*cos(theta),  u*v*(1-cos(theta)) - w*sin(theta),  u*w*(1-cos(theta)) + v*sin(theta) ;
                            u*v*(1-cos(theta)) + w*sin(theta),  v^2 + (1-v^2)*cos(theta),  v*w*(1-cos(theta))-u*sin(theta) ;
                            u*w*(1-cos(theta))-v*sin(theta),  v*w*(1-cos(theta)) + u*sin(theta),  w^2+(1-w^2)*cos(theta) ];
                 
%                         fprintf('Target is %5.3f, %5.3f, %5.3f, %5.3f, %5.3f\n', ...
%                             data.currentTarget(1), data.currentTarget(2), data.currentTarget(3), data.currentTarget(4), data.currentTarget(5) );
                        
%                         fprintf('theta_XY=%.3f, theta_YZ=%.3f, end is %s\n', ...
%                             theta_XY, theta_YZ, mat2str( R_total ) );
                        redisCon.set('bmi_target_rotation', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                           R_total ) );
                       handleXYZ = [bulgeCenter*targetSize 0 0]*R_total;
                       redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', sclTargPos(1)-handleXYZ(1), sclTargPos(2)-handleXYZ(2) , sclTargPos(3)+handleXYZ(3) ) );
                       % Set Target Size
                       redisCon.set('bmi_target_size', sprintf('%0.3f %0.3f %0.3f', (1-2*bulgeCenter)*targetSize, targetSizeSecondary, targetSizeSecondary) );  % width, height, depth

                        % "Bulge" to make it an "L" turned CCW 90' like this: --^
                        redisCon.set('bmi_box_enabled_2', 1);
                        % Where is center of the bulge?
                        r = (0.5-bulgeCenter)*targetSize; % radius from target center to the bulge center
                        bulge = [r 0 0]*R_total; % delta r
                            
                        bulgeX = sclTargPos(1) + bulge(1); % puts it on the left end, then accounts for rotation
                        bulgeY = sclTargPos(2) + bulge(2);
                        bulgeZ = sclTargPos(3) + bulge(3);
                        bulgeSize = 2*targetSize*bulgeCenter;
                        redisCon.set('bmi_box_position_2', sprintf('%0.4f %0.4f %0.4f',  bulgeX, bulgeY, bulgeZ ) );
                        redisCon.set('bmi_box_color_2', sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                            currentTargetColor(1),  currentTargetColor(2),  currentTargetColor(3), targetAlpha   ) );  % RGB and alpha transparency
                        redisCon.set('bmi_box_size_2', sprintf('%0.3f %0.3f %0.3f', bulgeSize, bulgeHeight*targetSize,  bulgeGirth*targetSizeSecondary) )  % width/height/depth
                        redisCon.set('bmi_box_rotation_2', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                            R_total ) );
                   
                    else
                        targetSize = (0.5*double(data.targetDiameter)) * armTargetPosScale; % radius
                        targetSizeSecondary = targetSize; % same thing, it's a sphere
                        % SPHERE                       
                        redisCon.set('bmi_target_shape', sprintf('%0.3f', 0 ) );
                        redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', sclTargPos(1), sclTargPos(2) , sclTargPos(3) ) );
                        targetSize = (double(data.targetDiameter)./2)*armTargetPosScale;
                        redisCon.set('bmi_sphere_enabled_2', 0); % no aura
                        % Set Target Size
                        redisCon.set('bmi_target_size', sprintf('%0.3f %0.3f %0.3f', targetSize, targetSizeSecondary, targetSizeSecondary) );  % 3 elements for box, but only frist is used for sphere

                    end
                    
            end
            

            % Target Color
            redisCon.set('bmi_target_color', sprintf('%0.3f %0.3f %0.3f %0.3f', currentTargetColor(1), currentTargetColor(2), currentTargetColor(3), ...
                targetAlpha ));
            
 

            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     CURSOR
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            sclCursorPos(1) = double(data.cursorPosition(1))*armTargetPosScale*armFlip1; % horizontal. Positive means right.
            sclCursorPos(2) = double(data.cursorPosition(2))*armTargetPosScale*armFlip2; % vertical. Positive means down
            sclCursorPos(3) = double(data.cursorPosition(3))*armTargetPosScale*armFlip3; % Depth. positive means out towards viewer
            
            if numDims > 3
                sclCursorPos(4) = double(data.cursorPosition(4))*armTargetPosScale*armFlip4; % Wrist rotation (rot1). Around z (in-out of screen) axis.
            end
            if numDims > 4
                sclCursorPos(5) = double(data.cursorPosition(5))*armTargetPosScale*armFlip5; % Wrist rotation (rot1). Around z (in-out of screen) axis.
            else
                sclCursorPos(5) = 0; % Dim not in use, render as 0 azimuth
            end
            
            % Cursor Color
            cursorColor = double( data.cursorColors(:,1) )./255;
            redisCon.set('bmi_cursor_color', sprintf('%0.3f %0.3f %0.3f %0.3f', cursorColor(1), cursorColor(2), cursorColor(3), ...
                cursorAlpha) );
            
            % Cursor dimensions
            switch numDims
                case 3 % sphere
                    cursorSize = (double(data.cursorDiameter)./2)*armTargetPosScale;
                    cursorSizeSecondary = cursorSize; %irrelevant.
                    cursorShape = 0;  % Cursor shape: 0 == sphere, 1 == box
                    redisCon.set('bmi_cursor_position', sprintf('%0.4f %0.4f %0.4f',  sclCursorPos(1), sclCursorPos(2), sclCursorPos(3) ) );
                    redisCon.set('bmi_cursor_size', sprintf('%0.3f %0.3f %0.3f', cursorSize, cursorSizeSecondary, cursorSizeSecondary) );  % 3 elements for box, only first is used for sphere

                case {4, 5, 6} % rectangular prism
                    cursorSize = double(data.cursorDiameter) * armTargetPosScale;
                    cursorSizeSecondary = cursorSize / smallerDimsFactor;
                    cursorShape = 1; % box
                    
                    theta_XY = ( sclCursorPos(4) / thetaXY_xPC_limit)*thetaXY_radian_limits; % elevation, in radians
                    theta_YZ = ( sclCursorPos(5) / thetaYZ_xPC_limit_radian_limits)*thetaYZ_xPC_limit; % azimuth, in radians
                    % Calculate *EXTRINSIC* rotation with respect to the
                    % world. This means that there is not an order
                    % dependency on the different rotation dimensions. If
                    % we want a more biobimetic Euler rotation, there are
                    % different maths for that.
                    % See
                    % inside.mines.edu/fs_home/gmurray/ArbitraryAxisRotation
                    % -Sergey March 10 2017
                    % It's relatively straightforward to extend this to 6D
                    % roation of necessary, just assume our starting vector
                    % is [1,1,0] and go through same trigonometry in yz
                    % plane.
                    % 
                    % Recall that theta_XY is such positive means right side goes up
                    % (clockwise around Z axis)
                    % and theta_YZ is such that positive means right side
                    % goes into screen
                    % Assume we have starting orienting vector [0,1,0]
                    s = [0, 1, 0]; % this is right
                    % these angles now bring it to:
                    % (these are in SCL coordinates, so there's some sign
                    % flipping)         
                    % theta_XY is spherical elevation. If just
                    % 4D this is angle on XZ plane, otherwise it's really
                    % elevation.
                    % theta_YZ is sphereical azimuth: angle on XY plane.
                    % This is fifth dimension
                    % Note the -sin ( ) in there is to accomodate the
                    % flipped sign of the SCL y axis
%                     d = [cos(theta_XY)*cos(theta_YZ), -sin(theta_XY), cos(theta_XY)*sin(theta_YZ)];
                    [d(2), d(1), d(3)] = sph2cart(theta_XY,theta_YZ, 1); % note echanged order because we define XY as azimuth
                    d(1) = -d(1); % to accomodate the flipped sign of the SCL y axis

                    % what's the angle between origin s=[1,0,0] and new
                    % vector.
                    theta = acos(s*d'); % smallest angle between s and d.
                    % what's a vector orthogonal to both s and d?
                    orthoVec = cross(s,d);
                    if any( orthoVec ) % so it doesn't nan out at 0,0,0
                        orthoVec = orthoVec./norm(orthoVec);
                    end
                    u = orthoVec(1);
                    v = orthoVec(2);
                    w = orthoVec(3);
                    % since [u,v,w] has length 1, this is a simplified
                    % equation
                    R_total = [ u^2 + (1-u^2)*cos(theta),  u*v*(1-cos(theta)) - w*sin(theta),  u*w*(1-cos(theta)) + v*sin(theta) ;
                                u*v*(1-cos(theta)) + w*sin(theta),  v^2 + (1-v^2)*cos(theta),  v*w*(1-cos(theta))-u*sin(theta) ;
                                u*w*(1-cos(theta))-v*sin(theta),  v*w*(1-cos(theta)) + u*sin(theta),  w^2+(1-w^2)*cos(theta) ];      
                    redisCon.set('bmi_cursor_rotation', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                        R_total ));

                    % Set the cursor's position. To have a |-- construction
                    % (non-overlapping objects), I actually offset it to
                    % the right a bit.
                    handleXYZ = [bulgeCenter*cursorSize 0 0]*R_total;
                    redisCon.set('bmi_cursor_position', sprintf('%0.4f %0.4f %0.4f',   sclCursorPos(1)-handleXYZ(1),  sclCursorPos(2)-handleXYZ(2),  sclCursorPos(3)+handleXYZ(3) ) );
                    redisCon.set('bmi_cursor_size', sprintf('%0.3f %0.3f %0.3f', (1-2*bulgeCenter)*cursorSize, cursorSizeSecondary, cursorSizeSecondary) );  % 3 elements for box, only first is used for sphere

                    
                    % "Bulge" to disambiguate the two ends
                    redisCon.set('bmi_box_enabled_3', 1);
                    % Where is center of the bulge?
                    % here's the effect of rotation. This assumes an upward
                    % rod is being rotated
                    r = (0.5-bulgeCenter)*cursorSize; % radius from cursor center to the bulge center
                    bulge = [r 0 0]*R_total; % delta r
                    bulgeX = bulge(1);
                    bulgeY = bulge(2);
                    bulgeZ = bulge(3);
%                     [bulgeY, bulgeX, bulgeZ] = sph2cart( theta_XY+pi/2, theta_YZ, r );
%                     bulgeX= bulgeX;% no sign needed because SCL has POSITIVE means LEFT
%                     bulgeY=bulgeY; % because SCL has POSITIVE means DOWN

%                     bulgeY = bulgeY -(0.5-bulgeCenter)*cursorSize; % offset back to 0 at neutral [theta_XY,theta_YZ] = [0.0]
%                     bulgeX = bulgeX -(0.5-bulgeCenter)*cursorSize; % put at left edge
                    bulgeX = sclCursorPos(1) + bulgeX; % puts it on the left end, then accounts for rotation
                    bulgeY = sclCursorPos(2) + bulgeY; % puts below rod, then accounts for rotation
                    bulgeZ = sclCursorPos(3) + bulgeZ;
                    bulgeSize = 2*cursorSize*bulgeCenter;
                    redisCon.set('bmi_box_position_3', sprintf('%0.4f %0.4f %0.4f',  bulgeX, bulgeY, bulgeZ ) );
                    redisCon.set('bmi_box_color_3', sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                        cursorColor(1),  cursorColor(2),  cursorColor(3), cursorAlpha   ) );  % RGB and alpha transparency
                    redisCon.set('bmi_box_size_3', sprintf('%0.3f %0.3f %0.3f', bulgeSize, bulgeHeight*cursorSize, bulgeGirth*cursorSizeSecondary ) )  % 3 elements for width,height,depth
                    redisCon.set('bmi_box_rotation_3', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                        R_total ) );
                   
            end
            
            % CURSOR SHAPE AND SIZE
            redisCon.set('bmi_cursor_shape', sprintf('%0.3f', cursorShape ) );

            flipTime = GetSecs()- taskParams.startTime; 
            %toc(taskParams.startTime);
                
            
            
        elseif uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_CURSOR)% standard PTB cursor task
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%                         PyschToolbox Cursor
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if ~screenParams.drawn | data.numTargets ~= taskParams.numTargets | ...
                    any(taskParams.targetInds ~= data.targetInds(:,1:data.numTargets)) | ...
                    taskParams.targetDiameter ~= data.targetDiameter
                taskParams.numTargets = data.numTargets;
                taskParams.targetInds = data.targetInds(:,1:data.numTargets);
                taskParams.taskType = data.taskType;
                %% if center-out, add center target
                taskParams.targetDiameter = data.targetDiameter;
                screenParams.multisample=1;
                initializeScreen(true);
                Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
                Screen('FillRect', screenParams.whichScreen, screenParams.backgroundIndexColor);
                [vblts, SOT, FTS]=Screen('Flip', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                %         [vblts SOT FTS]=Screen('AsyncFlipBegin', screenParams.whichScreen, 0, 0, 0); % actually present stimulus
                screenKilled = false;
                %% open anoffscreen window
                screenParams.offScreen(1).screen = Screen('OpenOffscreenWindow',...
                    0,screenParams.backgroundIndexColor,...
                    [],[],[],screenParams.multisample);
                
                %% blank the screen
                Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
                taskParams.lastPacketTime = GetSecs();
                
                targetsLocal = taskParams.targetInds;
                numTargetsLocal = taskParams.numTargets;
                if (taskParams.taskType == cursorConstants.TASK_CENTER_OUT)
                    targetsLocal(:,end+1) = 0;
                    numTargetsLocal = numTargetsLocal+1;
                end
                %% draw the targets on the offscreen
                for nt = 1:numTargetsLocal
                    currentTargetCoords = double(targetsLocal(1:2,nt))+mp(:);
                    % SDS August 2016. Change the size of the targets to
                    % simulate depth.
                    myDepth = double( targetsLocal(3,nt) );
                    myScale = ((myDepth - DEPTH_LIMITS(1) )/ (DEPTH_LIMITS(2)-DEPTH_LIMITS(1)) ) * ...
                        (SCALE_RANGE(2)-SCALE_RANGE(1))+SCALE_RANGE(1);
                    if myScale > SCALE_RANGE(2) % so it doesnt get too big/small even if decoder messes up
                        myScale = SCALE_RANGE(2);
                    elseif myScale < SCALE_RANGE(1)
                        myScale = SCALE_RANGE(1);
                    end
                    %                 fprintf('target %i: myDepth = %g, myScale = %g\n', ...
                    %                     nt, myDepth, myScale );
                    
                    currentTargetBoundingRect = [currentTargetCoords - myScale.*double(taskParams.targetDiameter)/2; currentTargetCoords + myScale.*double(taskParams.targetDiameter)/2];
                    Screen('FillOval', screenParams.offScreen(1).screen, grey, currentTargetBoundingRect, 100);
                end
                screenParams.drawnTime = GetSecs();
            end
            whichScreen = screenParams.whichScreen;
            Screen('CopyWindow',screenParams.offScreen(1).screen,screenParams.whichScreen);
            HideCursor(whichScreen);
            Screen('HideCursorHelper',screenParams.whichScreen);
            targetDiameter = double(data.targetDiameter);
            targetColorStr = char(data.targetColor);
            
            switch targetColorStr
                case 'g'
                    currentTargetColor = green;
                case 'y'
                    currentTargetColor = yellow;
                case 'p'
                    currentTargetColor = purple;
                case 'b'
                    currentTargetColor = blue;
            end
            
            
            cursorDiameter = double(data.cursorDiameter);
            currentTargetCoords = double(data.currentTarget(1:2)) + mp(:);
            nextTargetCoords = double(data.nextTarget(1:2)) + mp(:);
            cursorColors = double(data.cursorColors);
            
            % Faux-depth of current target
            % SDS August 2016. Change the size of the current target to
            % simulate depth.
            myDepth = double( data.currentTarget(3) );
            myScale = ((myDepth - DEPTH_LIMITS(1) )/ (DEPTH_LIMITS(2)-DEPTH_LIMITS(1)) ) * ...
                (SCALE_RANGE(2)-SCALE_RANGE(1))+SCALE_RANGE(1);
            if myScale > SCALE_RANGE(2) % so it doesnt get too big/small even if decoder messes up
                myScale = SCALE_RANGE(2);
            elseif myScale < SCALE_RANGE(1)
                myScale = SCALE_RANGE(1);
            end
            currentTargetBoundingRect = [currentTargetCoords - myScale*targetDiameter/2; currentTargetCoords + myScale*targetDiameter/2];
            
            % Faux-depth of next target
            myDepth = double( data.nextTarget(3) );
            myScale = ((myDepth - DEPTH_LIMITS(1) )/ (DEPTH_LIMITS(2)-DEPTH_LIMITS(1)) ) * ...
                (SCALE_RANGE(2)-SCALE_RANGE(1))+SCALE_RANGE(1);
            if myScale > SCALE_RANGE(2) % so it doesnt get too big/small even if decoder messes up
                myScale = SCALE_RANGE(2);
            elseif myScale < SCALE_RANGE(1)
                myScale = SCALE_RANGE(1);
            end
            nextTargetBoundingRect = [nextTargetCoords - myScale*targetDiameter/2; nextTargetCoords + myScale*targetDiameter/2];
            
            switch m.packetType
                case CursorStates.STATE_INIT
                case CursorStates.STATE_PRE_TRIAL
                case CursorStates.STATE_CENTER_TARGET
                    Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
                case CursorStates.STATE_FINGER_MOVED
                    Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
                case CursorStates.STATE_SUCCESS
                    %Screen('FillOval', whichScreen, red, currentTargetBoundingRect, 100);
                case CursorStates.STATE_FAIL
                    %mp = currentTargetCoords;
                    %failCoords = [mp(1)-targetDiameter/2 mp(2)-targetDiameter/2 mp(1)+targetDiameter/2 mp(2)+targetDiameter/2];
                    %Screen('FillRect', whichScreen, red, failCoords);
                case CursorStates.STATE_NEW_TARGET
                    Screen('FillOval', whichScreen, blue, nextTargetBoundingRect, 100);
                case {CursorStates.STATE_MOVE, CursorStates.STATE_MOVE_CLICK, CursorStates.STATE_RECENTER_DELAY}
                    Screen('FillOval', whichScreen, currentTargetColor, currentTargetBoundingRect, 100);
                case {CursorStates.STATE_FINGER_LIFTED}
                    DrawFormattedText(whichScreen, 'Finger lifted', 'center', mp(2)-300, white);
                case {CursorStates.STATE_ACQUIRE, CursorStates.STATE_HOVER}
                    Screen('FillOval', whichScreen, currentTargetColor, currentTargetBoundingRect, 100);
                    
                case CursorStates.STATE_END
                    taskParams.quit = true;
                    
                case {CursorStates.STATE_SCORE_PAUSE, CursorStates.STATE_SCORE_TARGET}
                    localAcquired = data.localAcquired;
                    localTotal = data.localTotal;
                    localAcqTime = data.localAcqTime;
                    inputType = uint16(data.inputType);
                    taskType = uint16(data.taskType);
                    
                    
                    if inputType == uint16(cursorConstants.INPUT_TYPE_DECODE_V) || taskType==uint16(cursorConstants.TASK_NEURAL_OUT_MOTOR_BACK)
                        localScore = max(450 - floor(localAcqTime/10),25);
                    else
                        localScore = max(150 - floor(localAcqTime/10),25);
                    end
                    
                    localAcqHeight = mp(2)-300;
                    localScoreHeight = mp(2)-200;
                    %                 acqDisplay = sprintf('Acquired: %2.0f%%', 100*single(localAcquired) / single(localTotal));
                    %                 localScoreDisplay = sprintf('Score: %g', localScore);
                    %                 DrawFormattedText(whichScreen, acqDisplay, 'center', localAcqHeight, white);
                    %                 DrawFormattedText(whichScreen, localScoreDisplay, 'center', localScoreHeight, white);
                    DrawFormattedText(whichScreen, 'Pause', 'center', localAcqHeight, white);
                    
                    if  m.packetType == CursorStates.STATE_SCORE_TARGET
                        Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
                    end
                otherwise
                    disp('dont understand this state')
            end
            
            %% Draw the Cursor
            for nc = 1:size(data.cursorPosition,2)
                if all(~isnan(data.cursorPosition(:,nc)))
                    cursorPos = double(data.cursorPosition(1:3,nc)); % grab the 3d coordinates
                    cursorPos(1:2) = cursorPos(1:2) + mp(:); % horizontal and vertical midpoint
                    % SDS Dec 2016: the faux-3D is now handled inside drawCursorWithBorder
                    % SDS Augsut 2016: Faux 3D by changing size
%                     myDepth = double( data.cursorPosition(3,nc) );
%                     myScale = ((myDepth - DEPTH_LIMITS(1) )/ (DEPTH_LIMITS(2)-DEPTH_LIMITS(1)) ) * ...
%                         (SCALE_RANGE(2)-SCALE_RANGE(1))+SCALE_RANGE(1);
%                     if myScale > SCALE_RANGE(2) % so it doesnt get too big/small even if decoder messes up
%                         myScale = SCALE_RANGE(2);
%                     elseif myScale < SCALE_RANGE(1)
%                         myScale = SCALE_RANGE(1);
%                     end
                    drawnDiameter = double(data.cursorDiameter); % scaled-by-depth diameter
                    drawnCursorOutline = cursorOutline;
                    
                    
                    drawCursorWithBorder(screenParams,screenParams.whichScreen,...
                        cursorPos, drawnDiameter, cursorColors(1:end,nc), drawnCursorOutline);
                    %cursorBoundingRect = [cursorPos - cursorDiameter/2; cursorPos+cursorDiameter/2];
                    %Screen('FillOval', whichScreen, cursorColors(1:end,nc), cursorBoundingRect, 100);
                end
            end
            %% show the block number
            if (GetSecs() - screenParams.drawnTime) < 5
                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
            end
            
            [vblts, SOT, FTS]=Screen('Flip', whichScreen, 0, 0, 0); % actually present stimulus
            flipTime = FTS - taskParams.startTime;%toc(taskParams.startTime);
        else
             % SDS Dec 8 2016: it hangs out here until xPC starts a
             % task with a proper outputType.
             flipTime = GetSecs()- taskParams.startTime;  % or should this be nothing?
        end
        %% end switch between different output types
        
    case EngineTypes.SOUND
        global soundParams;
        flipTime = 0;
        if data.lastSoundTime ~= soundParams.lastSoundTime
            soundParams.lastSoundTime = data.lastSoundTime;
            m.packetType = data.lastSoundState;
            switch m.packetType
                case CursorStates.SOUND_STATE_SUCCESS
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.successSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_FAIL
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_GO
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.goSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_OVER_TARGET
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.overSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
            end
        end
end

%% displayCursor
%Screen('DrawDots', whichScreen, cursorPos, cursorDiameter, white,[0 0], 1);

