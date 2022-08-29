function flipTime = cursorSetupScreen(data)
global taskParams;
global redisCon;

persistent lastFrameWiaText; %text must be on for two frames before showing, to prevent flickering
persistent screenKilled;
persistent countUp; % DEV
if isempty( countUp )
    countUp = 1;
else
    countUp = countUp + 1;
end
if isempty(screenKilled)
    screenKilled = false;
    lastFrameWiaText = 0;
end

% SDS August 2016: these apply to the PTB faux-3D. SCL doesn't care about
% these.
DEPTH_LIMITS = [-500 500]; % used to scale the size of cursors/targets based on their depth coordinate
SCALE_RANGE = [0.5 2];    % sizes will go from [0.5 to 1.5] with depth of
% 0 corresponding to scale of 1.

% DD Flag to make cursor invisible or not
MakeCursorInvisible = 0;

%% multiclick: click numbers or images:                                           
% persistent multiClickImageFlag %= 1; %SNF to add an option later to make this dynamic
% multiClickImageFlag = 1; %SNF this should not be necessary 
% % these colors will be used to indicate which click target is requested in
% % the non-delay multitask 
% multiClickColors =  [[255 24   29];... index/right hand: red
%                      [255 0   255];...%[129 15  124];... middle/right foot: magenta
%                      [140 150 198];... middle/thumb/left foot: lilac
%                      [99  169 226]]./255; % pinky/left hand: light blue %r - plum - intermediate gray - blue 
%% 5D Options
fiveD_compensateDim6 = true; % if true, will counter-rotate in sixth dimension to 
                             % give smoother movements
% NOTE: If a vertically oriented rod is the display object, this will be
% ignored, otherwise perceptually it's as if we've switched azimuth and
% elevation.
%%
% snf is suspicious of this empty cell and wonders if the contents
% accidentally got deleted? 
%% all the relevant info is in the "data" field of the packet, deconstruct it
armTargetPosScale = 1; % We're now using meters as our fundamental position unit so no scaling needed
armFlip1 = double(-1); % first element of SCL vectors (horizontal). Positive scl coord means LEFT
armFlip2 = double(-1); % second element of SCL vectors (vertical). Positive means DOWN.
armFlip3 = double(-1); % third element of SCL vectors (depth). Positive means OUT of screen.
armFlip4 = double(1);  % fourth element of SCL vectors. Rotation around world Z axis. Positive means right side goes down (clockwise) 
armFlip5 = double(-1); % fifth element of SCL vectors. Rotation arund hammer long axis coordinate angle in YZ plane. Positive means top comes out of screen. 
armFlip6 = double(-1); % sixth element of SCL vectors. Rotation around  coordinate angle in YZ plane. Positive means top comes out of screen. 

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
        
        m.packetType = data.state;
        global screenParams;
        cursorAlpha = 1;

        red = [255 0 0 ];
        grey = [100 100 100];
        blue = [0 153 153];
        green = [00 255 00];
        aqua = [0 255 255];
        orange = [255 133 0];                
        yellow = [153 153 25];
        purple = [255 50 255];     % making it more of a pink color for ease of vision   
        white = screenParams.white;
        mp = screenParams.midpoint;
        cursorOutline=3; %% in pixels (for PTB mode only
        % color scheme for multiple simulatenous cursors
        if uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR) % Cursor task, but rendered in SCL
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%                          SCL-CURSOR
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
            % Get dimensionality of task. A lot of graphics options depend
            % on this.
            numDims = double( data.numDisplayDims );  
            splitDimensions = boolean( data.splitDimensions ); % very different behavior when in split dimensions mode
            if splitDimensions
                % makes for more intuitive mapping compared to 4D cursor
                armFlip3 = double(1); % third element of SCL vectors (depth). Positive means OUT of screen.
                armFlip4 = double(-1);  % fourth element of SCL vectors. Rotation around world Z axis. Positive means right side goes down (clockwise)
            end
            
            
%             fprintf('splitDimensions == %g\n', splitDimensions);
%             keyboard
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
            thetaZ_xPC_limit = 0.13;  % XY plane angle/elevation (spherical coordinates)
            thetaZ_radian_limits = deg2rad(86); % beyond 90, each visual representation is not unique. Add another 10 degrees to
                            % be perceptually safe. 
            thetaX_xPC_limit_radian_limits = thetaZ_xPC_limit; %YZ plane angle/azimuth (spherical coordinates)
            thetaX_xPC_limit = deg2rad(67); % avoids visual gimbal lock near poles
%             thetaX_xPC_limit = deg2rad(86);
             
            thetaY_xPC_limit_radian_limits = thetaZ_xPC_limit; %XZ plane angle/azimuth (spherical coordinates)
            thetaY_xPC_limit = thetaZ_radian_limits;
            
            if ~screenKilled, sca; end
            
            if isempty(redisCon)
                redisCon = redis();%'localhost', 6379);
            end
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     ENABLE OBJECTS WE CARE ABOUT
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            redisCon.set('bmi_cursor_enabled', 1); % show the cursor
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
                case 'r'
                     currentTargetColor = red;
                case 'b'
                    currentTargetColor = blue;
                case 'n' % special, means aura should be colored but target stays aqua
                    currentTargetColor = aqua;
            end
            % We have the ability to color target aura differently.
            if targetColorStr == 'n' && logical( data.showXYZaura )
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
                    switch numDims                        
                        case {4,5}
                            
                            sclTargPos(4) = double(data.currentTarget(4))*armTargetPosScale*armFlip4; % wrist rotate (around z axis)
                            if numDims > 4
                                sclTargPos(5) =  double(data.currentTarget(5))*armTargetPosScale*armFlip5; % wrist rotate (around z axis)
                            else
                                sclTargPos(5) = 0;
                            end
                            if numDims > 6
                                sclTargPos(6) =  double(data.currentTarget(6))*armTargetPosScale*armFlip6; % wrist rotate (around z axis)
                            else
                                sclTargPos(6) = 0;
                            end
                            
                            if splitDimensions == false % standard 1 cursor mode
                                % Target becomes a rectangular prism
                                redisCon.set('bmi_target_shape', sprintf('%0.3f', 1 ) );
                                targetSize = double(data.targetDiameter) * armTargetPosScale;
                                targetSizeSecondary = targetSize / smallerDimsFactor;
                                targetAlpha = 1;
                                % Create 3D extent target too. This is another object which
                                % shows the spatial extent of our target. SDS March 2017
                                
                                % XYZ EXTENT "AURA" (Sphere)
                                auraSize = targetSize/2; % radius
                                if logical( data.showXYZaura )
                                    redisCon.set('bmi_sphere_enabled_2',  1);  % make 1 to show aura
                                    redisCon.set('bmi_sphere_position_2', sprintf('%0.4f %0.4f %0.4f',  sclTargPos(1), sclTargPos(2), sclTargPos(3) ) );
                                    redisCon.set('bmi_sphere_radius_2', sprintf('%0.3f %0.3f %0.3f', auraSize, auraSize, auraSize) );  % 3 elements for box, but only frist is used for sphere
                                    redisCon.set('bmi_sphere_color_2', sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                                        currentAuraColor(1),  currentAuraColor(2),  currentAuraColor(3), xyzTargetTransparency   ) );
                                else
                                    redisCon.set('bmi_sphere_enabled_2',  0)
                                end
                                %
                                % Target rotation
                                % See the equivalent section of the Cursor rotation
                                % code for an explanation of the math. -Sergey
                                % March 22 2017
                                theta_Z = ( sclTargPos(4) / thetaZ_xPC_limit)*thetaZ_radian_limits; % in radians
                                theta_X = ( sclTargPos(5) / thetaX_xPC_limit_radian_limits)*thetaX_xPC_limit; %  in radians
                                %                             theta_Y = ( sclTargPos(6) / thetaY_xPC_limit_radian_limits)*thetaY_xPC_limit; % azimuth, in radians
                                theta_Y = 0;
                                
                                
                                s = [0, 1, 0]; % this is the pointing vector in spherical coordinates
                                [d(2), d(1), d(3)] = sph2cart(theta_Z,theta_X, 1); % note echanged order because we define XY as azimuth
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
                                R_total = [ u^2 + (1-u^2)*cos(theta),  u*v*(1-cos(theta)) - w*sin(theta),  u*w*(1-cos(theta)) + v*sin(theta) ;
                                    u*v*(1-cos(theta)) + w*sin(theta),  v^2 + (1-v^2)*cos(theta),  v*w*(1-cos(theta))-u*sin(theta) ;
                                    u*w*(1-cos(theta))-v*sin(theta),  v*w*(1-cos(theta)) + u*sin(theta),  w^2+(1-w^2)*cos(theta) ];
                                
                                if ismember( data.displayObject, [uint8( cursorConstants.OBJECT_ROD ), uint8( cursorConstants.OBJECT_SPHERE )] )
                                    % for a vertical rod, doing the compensation makes it perceptually wrong.
                                    % it only makes sense, as it currently
                                    % acts, for a horizontal oriented object.
                                    fiveD_compensateDim6 = false;
                                end
                                
                                if fiveD_compensateDim6 && numDims > 4
                                    zProj = R_total*[1 0 0]';
                                    a = zProj(1);
                                    b = zProj(2);
                                    c = zProj(3);
                                    u = d(1); % coounteract prevous negative
                                    v = d(2);
                                    w = d(3);
                                    %                        A = a*u*w + b*v*w + c*w^2;
                                    A = 0;
                                    B = a*u*w + b*v*w - c*(1-w^2);
                                    C = a*v - b*u;
                                    compTheta = atan( -B/C );
                                    Rcomp = [ u^2 + (1-u^2)*cos(compTheta),  u*v*(1-cos(compTheta)) - w*sin(compTheta),  u*w*(1-cos(compTheta)) + v*sin(compTheta) ;
                                        u*v*(1-cos(compTheta)) + w*sin(compTheta),  v^2 + (1-v^2)*cos(compTheta),  v*w*(1-cos(compTheta))-u*sin(compTheta) ;
                                        u*w*(1-cos(compTheta))-v*sin(compTheta),  v*w*(1-cos(compTheta)) + u*sin(compTheta),  w^2+(1-w^2)*cos(compTheta) ];
                                    R_total = Rcomp*R_total;
                                end
                                redisCon.set('bmi_target_rotation', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                                    R_total ) );
                                switch data.displayObject
                                    case {uint8( cursorConstants.OBJECT_ROD ), uint8( cursorConstants.OBJECT_SPHERE ) } % if accidentally set to sphere, do rod anyway.
                                        % ROD with a bulge at the end
                                        bulgeGirth = 1.15; % how much larger the bulge is than the rod
                                        
                                        % set position and size of the main rod.
                                        redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', ...
                                            sclTargPos(1), sclTargPos(2),  sclTargPos(3) ) );
                                        % note that order here is what makes it
                                        % vertical oreintation
                                        redisCon.set('bmi_target_size', sprintf('%0.3f %0.3f %0.3f', ...
                                            targetSizeSecondary, 0.9*targetSize, targetSizeSecondary) );
                                        % the 0.9 above makes it not extend past aura,
                                        % nor bulge, which looks better.
                                        
                                        % "Bulge" to disambiguate the two ends
                                        redisCon.set('bmi_box_enabled_2', 1);
                                        % Where is center of the bulge?
                                        r = (0.5-bulgeCenter)*targetSize; % radius from cursor center to the bulge center
                                        bulge = [0 r 0]*R_total; % delta r. Note r in second element makes this vertical
                                        bulgeX = bulge(1);
                                        bulgeY = bulge(2);
                                        bulgeZ = bulge(3);
                                        bulgeX = sclTargPos(1) + bulgeX; % puts it on the left end, then accounts for rotation
                                        bulgeY = sclTargPos(2) + bulgeY; % puts below rod, then accounts for rotation
                                        bulgeZ = sclTargPos(3) + bulgeZ;
                                        
                                        bulgeSize = 2*targetSize*bulgeCenter;
                                        redisCon.set('bmi_box_position_2', sprintf('%0.4f %0.4f %0.4f',  bulgeX, bulgeY, bulgeZ ) );
                                        redisCon.set('bmi_box_color_2', sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                                            currentTargetColor(1),  currentTargetColor(2),  currentTargetColor(3), targetAlpha   ) )  % RGB and alpha transparency
                                        % note that order here changes it from
                                        % horizontal oriented to vertical oriented.
                                        redisCon.set('bmi_box_size_2', sprintf('%0.3f %0.3f %0.3f', ...
                                            bulgeGirth*targetSizeSecondary, bulgeSize, bulgeGirth*targetSizeSecondary) )
                                        redisCon.set('bmi_box_rotation_2', sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                                            R_total ) );
                                        
                                    case uint8( cursorConstants.OBJECT_HAMMER )
                                        % "T" HAMMER
                                        bulgeGirth = 1.15; % how much larger the bulge is than the rod
                                        
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
                                end
                                
                            elseif splitDimensions == true
                                % two cursors mode
                                targetAlpha = 0.8; % slightly transparent
                                
                                % cleanup in case switching from a dfferent
                                % task by hiding the bulge
                                 redisCon.set('bmi_box_enabled_2', 0);
                                
                                
                                % the incoming 'x', 'y', 'z', 'r1' are
                                % mapped as {x_1, y_1, x_2, y_2} where 1
                                % and 2 are the two objects
                                targetSize = (double(data.targetDiameter)./4)*armTargetPosScale; % halve the displayed radius compared to what it'd be for a single cursor
                                targetSizeSecondary = targetSize; % same thing, it's a sphere
                               
                                % Color determination - if aqua make both
                                % aqua, otherwise orange
                                if targetColorStr == 'o' 
                                    targ1Color = orange./255;
                                    targ2Color = orange./255;
                                else
                                    targ1Color = red./255;
                                    targ2Color = blue./255;
                                end
                                
                                % the two targets are ever so slightly
                                % offset in z to help be able to see both
                                % when they're overlayed

                                % Cursor 1 (red) 
                                redisCon.set('bmi_target_shape', sprintf('%0.3f', 0 ) );
                                redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', sclTargPos(1), sclTargPos(2) , -0.01 ) );
                                redisCon.set('bmi_target_size', sprintf('%0.3f %0.3f %0.3f', targetSize, targetSizeSecondary, targetSizeSecondary) );  % 3 elements for box, but only frist is used for sphere
                                redisCon.set('bmi_target_color', sprintf('%0.3f %0.3f %0.3f %0.3f', targ1Color(1), targ1Color(2), targ1Color(3), ...
                                    targetAlpha ));
            
                                % Cursor 2 (blue)
                                redisCon.set('bmi_sphere_enabled_2', 1);
                                redisCon.set('bmi_sphere_shape_2', sprintf('%0.3f', 0 ) );
                                redisCon.set('bmi_sphere_position_2', sprintf('%0.4f %0.4f %0.4f', sclTargPos(3), sclTargPos(4) , 0.01 ) );
                                redisCon.set('bmi_sphere_radius_2', sprintf('%0.3f %0.3f %0.3f', targetSize, targetSizeSecondary, targetSizeSecondary) );  % 3 elements for box, but only frist is used for sphere
                                redisCon.set('bmi_sphere_color_2', sprintf('%0.3f %0.3f %0.3f %0.3f', targ2Color(1), targ2Color(2), targ2Color(3), ...
                                    targetAlpha ));
                            end
                            
                        case 3
                            targetSize = (0.5*double(data.targetDiameter)) * armTargetPosScale; % radius
                            targetSizeSecondary = targetSize; % same thing, it's a sphere
                            % SPHERE
                            redisCon.set('bmi_target_shape', sprintf('%0.3f', 0 ) );
                            redisCon.set('bmi_target_position', sprintf('%0.4f %0.4f %0.4f', sclTargPos(1), sclTargPos(2) , sclTargPos(3) ) );
                            targetSize = (double(data.targetDiameter)./2)*armTargetPosScale;
                            redisCon.set('bmi_sphere_enabled_2', 0); % no aura
                            % Set Target Size
                            redisCon.set('bmi_target_size', sprintf('%0.3f %0.3f %0.3f', targetSize, targetSizeSecondary, targetSizeSecondary) );  % 3 elements for box, but only frist is used for sphere
                            % hide bulge
                            redisCon.set('bmi_box_enabled_2', 0);
                    end
            end
            % Target Color
            if ~splitDimensions % colors done differently for split targets
                redisCon.set('bmi_target_color', sprintf('%0.3f %0.3f %0.3f %0.3f', currentTargetColor(1), currentTargetColor(2), currentTargetColor(3), ...
                    targetAlpha ));
            end
 

% % %%%%%%%%%%%%%%%%%%%%%%%%%%
%     CURSOR
% %%%%%%%%%%%%%%%%%%%%%%%%%%
            % Make 1:1 to not have ghost cursor
            for iCursor = 1 : 2
                % Cursor 1 is the normal cursor.
                % Cursor 2 is a second
                % cursor, which is currently only used in RAYS to show
                % which target the cursor is currently closest to.
                switch iCursor
                    case 1
                        cursorColorKey = 'bmi_cursor_color';
                        cursorPositionKey = 'bmi_cursor_position';
                        cursorSizeKey = 'bmi_cursor_size';
                        cursorShapeKey = 'bmi_cursor_shape';
                        cursorBulgeEnableKey = 'bmi_box_enabled_3';
                        cursorBulgePositionKey ='bmi_box_position_3';
                        cursorBulgeColorKey = 'bmi_box_color_3';
                        cursorBulgeSizeKey = 'bmi_box_size_3';
                        cursorBulgeRotationKey = 'bmi_box_rotation_3';
                        cursorRotationKey = 'bmi_cursor_rotation';
                        thisCursorAlpha = cursorAlpha;
                        
                    case 2
                        if ~any( ~isnan( data.cursorPosition(:,2) ) ) && splitDimensions == false
                            % no second cursor
                            redisCon.set('bmi_center_enabled', 0); % hide the second cursor
                            redisCon.set('bmi_box_enabled_4', 0 ); % hid its bulge too
                            continue % don't do the rest of this code
                        else
                            redisCon.set('bmi_center_enabled', 1); %show it
                            cursorColorKey = 'bmi_center_color';
                            cursorPositionKey = 'bmi_center_position';
                            cursorSizeKey = 'bmi_center_size';
                            cursorShapeKey = 'bmi_center_shape';
                            cursorBulgeEnableKey = 'bmi_box_enabled_4';
                            cursorBulgePositionKey ='bmi_box_position_4';
                            cursorBulgeColorKey = 'bmi_box_color_4';
                            cursorBulgeSizeKey = 'bmi_box_size_4';
                            cursorBulgeRotationKey = 'bmi_box_rotation_4';
                            cursorRotationKey = 'bmi_center_rotation';
                            thisCursorAlpha = 0.5*double( data.cursorAlpha2 )/100 ;
                            %
                        end
                end
                
                % sclCursorPos is for just this cursor (it is rewritten
                % when looping across the next cursor).
                sclCursorPos(1) = double(data.cursorPosition(1,iCursor))*armTargetPosScale*armFlip1; % horizontal. Positive means right.
                sclCursorPos(2) = double(data.cursorPosition(2,iCursor))*armTargetPosScale*armFlip2; % vertical. Positive means down
                sclCursorPos(3) = double(data.cursorPosition(3,iCursor))*armTargetPosScale*armFlip3; % Depth. positive means out towards viewer
                
                if numDims > 3
                    sclCursorPos(4) = double(data.cursorPosition(4,iCursor))*armTargetPosScale*armFlip4; % Wrist rotation (rot1). Around z (in-out of screen) axis.
                end
                if numDims > 4
                    sclCursorPos(5) = double(data.cursorPosition(5,iCursor))*armTargetPosScale*armFlip5; % Wrist rotation (rot1). Around z (in-out of screen) axis.
                else
                    sclCursorPos(5) = 0; % Dim not in use, render as 0 azimuth
                end
                if numDims > 5
                    sclCursorPos(6) = double(data.cursorPosition(6,iCursor))*armTargetPosScale*armFlip6;
                else
                    sclCursorPos(6) = 0;
                end
                
                % Cursor Color               
                cursorColor = double( data.cursorColors(:,1) )./255;
                % Cursor dimensions
                switch numDims
                    case 3 % sphere
                        cursorSize = (double(data.cursorDiameter)./2)*armTargetPosScale;
                        cursorSizeSecondary = cursorSize; %irrelevant.
                        cursorShape = 0;  % Cursor shape: 0 == sphere, 1 == box
                        redisCon.set(cursorPositionKey, sprintf('%0.4f %0.4f %0.4f',  sclCursorPos(1), sclCursorPos(2), sclCursorPos(3) ) );
                        redisCon.set(cursorSizeKey, sprintf('%0.3f %0.3f %0.3f', cursorSize, cursorSizeSecondary, cursorSizeSecondary) );  % 3 elements for box, only first is used for sphere
                        redisCon.set(cursorBulgeEnableKey, 0); % disables bulge
                        
                    case {4, 5} % Rod or "Hammer"
                        
                        if splitDimensions == false  % standard 1 cursor mode
                            cursorShape = 1; % box
                            
                            theta_Z = ( sclCursorPos(4) / thetaZ_xPC_limit)*thetaZ_radian_limits; % elevation, in radians
                            theta_X = ( sclCursorPos(5) / thetaX_xPC_limit_radian_limits)*thetaX_xPC_limit; % azimuth, in radians
                            theta_Y = 0; % not used
                            %                     theta_Y =  ( sclCursorPos(6) / thetaY_xPC_limit_radian_limits)*thetaY_xPC_limit; %
                            %
                            s = [0, 1, 0]; % this is the pointing vector in spherical coordinates
                            [d(2), d(1), d(3)] = sph2cart(theta_Z,theta_X, 1); % note echanged order because we define XY as azimuth
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
                            R_total = [ u^2 + (1-u^2)*cos(theta),  u*v*(1-cos(theta)) - w*sin(theta),  u*w*(1-cos(theta)) + v*sin(theta) ;
                                u*v*(1-cos(theta)) + w*sin(theta),  v^2 + (1-v^2)*cos(theta),  v*w*(1-cos(theta))-u*sin(theta) ;
                                u*w*(1-cos(theta))-v*sin(theta),  v*w*(1-cos(theta)) + u*sin(theta),  w^2+(1-w^2)*cos(theta) ];
                            % --------------------------------
                            %   WOBBLE COMPENSATION
                            % --------------------------------
                            if ismember( data.displayObject, [uint8( cursorConstants.OBJECT_ROD ), uint8( cursorConstants.OBJECT_SPHERE )] )
                                % for a vertical rod, doing the compensation makes it perceptually wrong.
                                % it only makes sense, as it currently
                                % acts, for a horizontal oriented object.
                                fiveD_compensateDim6 = false;
                            end
                            if fiveD_compensateDim6 && numDims > 4
                                zProj = R_total*[1 0 0]';
                                a = zProj(1);
                                b = zProj(2);
                                c = zProj(3);
                                u = d(1); % coounteract prevous negative
                                v = d(2);
                                w = d(3);
                                %                        A = a*u*w + b*v*w + c*w^2;
                                A = 0;
                                B = a*u*w + b*v*w - c*(1-w^2);
                                C = a*v - b*u;
                                compTheta = atan( -B/C );
                                Rcomp = [ u^2 + (1-u^2)*cos(compTheta),  u*v*(1-cos(compTheta)) - w*sin(compTheta),  u*w*(1-cos(compTheta)) + v*sin(compTheta) ;
                                    u*v*(1-cos(compTheta)) + w*sin(compTheta),  v^2 + (1-v^2)*cos(compTheta),  v*w*(1-cos(compTheta))-u*sin(compTheta) ;
                                    u*w*(1-cos(compTheta))-v*sin(compTheta),  v*w*(1-cos(compTheta)) + u*sin(compTheta),  w^2+(1-w^2)*cos(compTheta) ];
                                R_total = Rcomp*R_total;
                            end
                            redisCon.set(cursorRotationKey, sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                                R_total ));
                            
                            switch data.displayObject
                                case {uint8( cursorConstants.OBJECT_ROD ), uint8( cursorConstants.OBJECT_SPHERE )  } % if accidentally set to sphere, do rod anyway.
                                    % ROD with a bulge at the end
                                    bulgeGirth = 1.15; % how much larger the bulge is than the rod
                                    
                                    cursorSize = double(data.cursorDiameter) * armTargetPosScale;
                                    cursorSizeSecondary = cursorSize / smallerDimsFactor;
                                    cursorShape = 1; % box
                                    
                                    % set position and size of the main rod.
                                    redisCon.set(cursorPositionKey, sprintf('%0.4f %0.4f %0.4f', ...
                                        sclCursorPos(1), sclCursorPos(2),  sclCursorPos(3) ) );
                                    % note that order here is what makes it
                                    % vertical oreintation
                                    redisCon.set(cursorSizeKey, sprintf('%0.3f %0.3f %0.3f', ...
                                        cursorSizeSecondary, 0.9*cursorSize, cursorSizeSecondary) );
                                    % the 0.9 above makes it not extend past aura,
                                    % nor bulge, which looks better.
                                    
                                    % "Bulge" to disambiguate the two ends
                                    redisCon.set(cursorBulgeEnableKey, 1);
                                    % Where is center of the bulge?
                                    r = (0.5-bulgeCenter)*cursorSize; % radius from cursor center to the bulge center
                                    bulge = [0 r 0]*R_total; % delta r. Note r in second element makes this vertical
                                    bulgeX = bulge(1);
                                    bulgeY = bulge(2);
                                    bulgeZ = bulge(3);
                                    bulgeX = sclCursorPos(1) + bulgeX; % puts it on the left end, then accounts for rotation
                                    bulgeY = sclCursorPos(2) + bulgeY; % puts below rod, then accounts for rotation
                                    bulgeZ = sclCursorPos(3) + bulgeZ;
                                    
                                    bulgeSize = 2*cursorSize*bulgeCenter;
                                    redisCon.set(cursorBulgePositionKey, sprintf('%0.4f %0.4f %0.4f',  bulgeX, bulgeY, bulgeZ ) );
                                    redisCon.set(cursorBulgeColorKey, sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                                        cursorColor(1),  cursorColor(2),  cursorColor(3), thisCursorAlpha   ) )  % RGB and alpha transparency
                                    % note that order here changes it from
                                    % horizontal oriented to vertical oriented.
                                    redisCon.set(cursorBulgeSizeKey, sprintf('%0.3f %0.3f %0.3f', ...
                                        bulgeGirth*cursorSizeSecondary, bulgeSize, bulgeGirth*cursorSizeSecondary) )
                                    redisCon.set(cursorBulgeRotationKey, sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                                        R_total ) );
                                    
                                case uint8( cursorConstants.OBJECT_HAMMER )
                                    % "T" HAMMER
                                    bulgeGirth = 1.15; % how much larger the bulge is than the rod
                                    
                                    cursorSize = double(data.cursorDiameter) * armTargetPosScale;
                                    cursorSizeSecondary = cursorSize / smallerDimsFactor;
                                    % Set the cursor's position. To have a |-- construction
                                    % (non-overlapping objects), I actually offset it to
                                    % the right a bit.
                                    handleXYZ = [bulgeCenter*cursorSize 0 0]*R_total;
                                    redisCon.set(cursorPositionKey, sprintf('%0.4f %0.4f %0.4f',   sclCursorPos(1)-handleXYZ(1),  sclCursorPos(2)-handleXYZ(2),  sclCursorPos(3)+handleXYZ(3) ) );
                                    redisCon.set(cursorSizeKey, sprintf('%0.3f %0.3f %0.3f', (1-2*bulgeCenter)*cursorSize, cursorSizeSecondary, cursorSizeSecondary) );  % 3 elements for box, only first is used for sphere
                                    
                                    % "Bulge" to disambiguate the two ends
                                    redisCon.set(cursorBulgeEnableKey, 1);
                                    % Where is center of the bulge?
                                    % here's the effect of rotation. This assumes an upward
                                    % rod is being rotated
                                    r = (0.5-bulgeCenter)*cursorSize; % radius from cursor center to the bulge center
                                    bulge = [r 0 0]*R_total; % delta r
                                    bulgeX = bulge(1);
                                    bulgeY = bulge(2);
                                    bulgeZ = bulge(3);
                                    
                                    bulgeX = sclCursorPos(1) + bulgeX; % puts it on the left end, then accounts for rotation
                                    bulgeY = sclCursorPos(2) + bulgeY; % puts below rod, then accounts for rotation
                                    bulgeZ = sclCursorPos(3) + bulgeZ;
                                    bulgeSize = 2*cursorSize*bulgeCenter;
                                    redisCon.set(cursorBulgePositionKey, sprintf('%0.4f %0.4f %0.4f',  bulgeX, bulgeY, bulgeZ ) );
                                    redisCon.set(cursorBulgeColorKey, sprintf('%0.3f %0.3f %0.3f %0.3f', ...
                                        cursorColor(1),  cursorColor(2),  cursorColor(3), cursorAlpha   ) );  % RGB and alpha transparency
                                    redisCon.set(cursorBulgeSizeKey, sprintf('%0.3f %0.3f %0.3f', bulgeSize, bulgeHeight*cursorSize, bulgeGirth*cursorSizeSecondary ) )  % 3 elements for width,height,depth
                                    redisCon.set(cursorBulgeRotationKey, sprintf('%0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f %0.3f', ...
                                        R_total ) );
                            end
                        elseif splitDimensions == true
                            % two cursors mode
                            % cleanup in case switching from a dfferent
                            % task by hiding the bulge
                            redisCon.set(cursorBulgeEnableKey, 0);                            
                            cursorSize = 0.25 * double(data.cursorDiameter) * armTargetPosScale; % half the normal sphere size
                            cursorSizeSecondary = cursorSize; % irrelevant
                            cursorShape = 0;  % Cursor shape: 0 == sphere, 1 == box
                            switch iCursor
                                case 1
                                    myXY = [sclCursorPos(1) sclCursorPos(2)];
                                    cursorColor = red./255;      
                                    thisCursorAlpha = 1; % both cursors opaque
                                case 2               
                                    % now don't actually want to read from
                                    % cursor2 sent over from xPC, but
                                    % rather elements 3,4 of cursor 1.
                                    sclCursorPos(3) = double(data.cursorPosition(3,1))*armTargetPosScale*armFlip3; % Depth. positive means out towards viewer
                                    sclCursorPos(4) = double(data.cursorPosition(4,1))*armTargetPosScale*armFlip4; % Rot1. positive means out towards viewer

                                    myXY = [sclCursorPos(3) sclCursorPos(4)];
                                    cursorColor = blue./255;
                                    thisCursorAlpha = 1; % both cursors opaque
                            end
                            
                            redisCon.set(cursorPositionKey, sprintf('%0.4f %0.4f %0.4f',  myXY(1), myXY(2), 0 ) );
                            redisCon.set(cursorSizeKey, sprintf('%0.3f %0.3f %0.3f', cursorSize, cursorSizeSecondary, cursorSizeSecondary) );  % 3 elements for box, only first is used for sphere
 
                        end
                        
                end 
                
                % CURSOR SHAPE AND COLOR
                redisCon.set(cursorShapeKey, sprintf('%0.3f', cursorShape ) );
                redisCon.set(cursorColorKey, sprintf('%0.3f %0.3f %0.3f %0.3f', cursorColor(1), cursorColor(2), cursorColor(3), ...
                    thisCursorAlpha) );
                
            end
%             flipTime = GetSecs()- taskParams.startTime;  
            flipTime = 0; % not useful because this is not PTB
            %toc(taskParams.startTime);
                    
            
        elseif uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_CURSOR)% standard PTB cursor task
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%                         PyschToolbox Cursor
 % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            numTargToPlot = min(data.numTargets, size(data.targetInds,2));
            if ~screenParams.drawn | data.numTargets ~= taskParams.numTargets | ...
                    any(taskParams.targetInds(:,1:numTargToPlot) ~= data.targetInds(:,1:numTargToPlot)) | ...
                    taskParams.targetDiameter ~= data.targetDiameter
                
                taskParams.numTargets = data.numTargets;
                taskParams.targetInds = data.targetInds(:,1:numTargToPlot);
                taskParams.taskType = data.taskType;
                
                %% if center-out, add center target
                taskParams.targetDiameter = data.targetDiameter;
                screenParams.multisample=1;
                initializeScreen(true);
                Screen('Preference', 'VisualDebugLevel', 1); %SNF to make splash screen black
   
                Screen('BlendFunction', screenParams.whichScreen, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); 
                DrawFormattedText(screenParams.whichScreen, ['Block: ' num2str(data.blockNumber)], 'center',10,screenParams.white);
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
                %% if center-out, add center target 
                targetsLocal = taskParams.targetInds;
                if (taskParams.taskType == cursorConstants.TASK_CENTER_OUT)
                    targetsLocal(:,end+1) = 0;
                end
                
                %%draw background if we have one
                if uint8(data.displayObject) == uint8(cursorConstants.BACKGROUND_QUAD_CARDINAL)
                    bgImage = imread('/home/nptl/code/visualizationCode/cursorTask/Task_1_Directional.png');
                    Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                elseif uint8(data.displayObject) == uint8(cursorConstants.BACKGROUND_QUAD_JOINTS)
                    bgImage = imread('/home/nptl/code/visualizationCode/cursorTask/Task_2_Joint.png');
                    Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                elseif uint8(data.displayObject) == uint8(cursorConstants.BACKGROUND_QUAD_CARDINAL_JOINTS)
                    bgImage = imread('/home/nptl/code/visualizationCode/cursorTask/Task_3_32Target_Updated_v1.png');
                    Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                elseif uint8(data.displayObject) == uint8(cursorConstants.BACKGROUND_DUAL_JOYSTICK)
                    bgImage = imread('/home/nptl/code/visualizationCode/cursorTask/Task_4_Dual_Joystick.png');
                    Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                elseif uint8(data.displayObject) == uint8(cursorConstants.BACKGROUND_QUAD_CARDINAL_CLOSER)
                    bgImage = imread('/home/nptl/code/visualizationCode/cursorTask/Task_5_Cardinal_Closer.png');
                    Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                end
                
                %% draw the targets on the offscreen
                %if data.numTargets<=16
                if data.numTargets<=16 || (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))%sf says why limit this here? 
                for nt = 1:size(targetsLocal,2)
                    currentTargetCoords = double(targetsLocal(1:2,nt))+mp(:);
                    currentTargetBoundingRect = [currentTargetCoords - double(taskParams.targetDiameter)/2; currentTargetCoords + double(taskParams.targetDiameter)/2];
                    Screen('FillOval', screenParams.offScreen(1).screen, grey, currentTargetBoundingRect, 100);
                end
                
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
                % the below colors are used in SCL, but get sent over from
                % the game. To maintain compatibility, they are listed
                % below here. I'll just switch this to our new colors.
                case 'a'
                    currentTargetColor = aqua;
                case 'o'
                    currentTargetColor = orange;
                case 'n' % special, means aura should be colored but target stays aqua
                    currentTargetColor = aqua;
            end
            
            %if in imagine mode, don't turn the color orange when the
            %autoplay cursor acquires the target invisbly
            if isfield(data,'wiaCode') && data.wiaCode==2
                disp(data.wiaCode);
                currentTargetColor = aqua;
            end
            
            drawTwoTargets = any(data.currentTarget(3:4)~=0);
            
            currentTargetCoords = double(data.currentTarget(1:2)) + mp(:);
            currentTargetCoords2 = double(data.currentTarget(3:4)) + mp(:);
            nextTargetCoords = double(data.nextTarget(1:2)) + mp(:);
            cursorColors = double(data.cursorColors);
            
            currentTargetBoundingRect = [currentTargetCoords - targetDiameter/2; currentTargetCoords + targetDiameter/2];
            currentTargetBoundingRect2 = [currentTargetCoords2 - targetDiameter/2; currentTargetCoords2 + targetDiameter/2];
            nextTargetBoundingRect = [nextTargetCoords - targetDiameter/2; nextTargetCoords + targetDiameter/2];
            
            switch m.packetType
                case CursorStates.STATE_INIT
                case CursorStates.STATE_PRE_TRIAL
                    %% draw background if we have one- these show the effector to click with in the center of the screen
                taskParams.nextClickTarg = data.nextClickTarg;                     
                disp(num2str(uint16(taskParams.taskType)))
                    if (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))
                        disp('Multiclick')
                        targetsLocal = taskParams.targetInds;
                        %if multiClickImageFlag %SF: this is not needed
                            %SF: changing "clickTargs" to "nextClickTarg"
                            disp(['Click Targ: ', num2str(taskParams.nextClickTarg + 1)])
                            if uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_LCLICK)
                             %   bgImage = imread('/home/nptl/code/visualizationCode/imageBank/rightLegLeft.png');
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click1.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_RCLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click2.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_2CLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click3.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_SCLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click4.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            else %no background, show center target.
                                targetsLocal(:,end+1) = 0;
%                                 bgImage = imread('/home/nptl/code/visualizationCode/imageBank/blank_background.png');
%                                 Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
                                targetColorStr = 'p';
                                disp('Center, no bkgnd')
                            end
                        %else %otherwise, just display numbers 1-4.
                        %    DrawFormattedText(screenParams.offScreen(1), num2str(taskParams.nextClickTarg), 'center',10,screenParams.white);
                        %end
                        %SF added the gray targets back in:
                        if data.numTargets<=16 || (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))%sf says why limit this here?
                            for nt = 1:size(targetsLocal,2)
                                currentTargetCoords = double(targetsLocal(1:2,nt))+mp(:);
                                currentTargetBoundingRect = [currentTargetCoords - double(taskParams.targetDiameter)/2; currentTargetCoords + double(taskParams.targetDiameter)/2];
                                Screen('FillOval', screenParams.offScreen(1).screen, grey, currentTargetBoundingRect, 100);
                            end
                        end
                    else
                        disp(['Task Type thinks it is: ', num2str(data.taskType)])
                    end

                case CursorStates.STATE_CENTER_TARGET
                    if drawTwoTargets
                        Screen('FillOval', whichScreen, [0; 204; 102;], currentTargetBoundingRect2, 100);
                    end
                    Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
                case CursorStates.STATE_FINGER_MOVED
                    if drawTwoTargets
                        Screen('FillOval', whichScreen, [0; 204; 102;], currentTargetBoundingRect2, 100);
                    end
                    Screen('FillOval', whichScreen, green, currentTargetBoundingRect, 100);
                case CursorStates.STATE_SUCCESS
                    %Screen('FillOval', whichScreen, red, currentTargetBoundingRect, 100);
                     %SF: Present center target and blank the background image
                     if (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))
                        Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
                     end
                case CursorStates.STATE_FAIL
                    %mp = currentTargetCoords;
                    %failCoords = [mp(1)-targetDiameter/2 mp(2)-targetDiameter/2 mp(1)+targetDiameter/2 mp(2)+targetDiameter/2];
                    %Screen('FillRect', whichScreen, red, failCoords);
                     %SF: Present center target and blank the background
                     %image but only for multiclick! 
                     if (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))
                        Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
                     end
                case CursorStates.STATE_NEW_TARGET %adding the images here in case they're missed in pre_trial
                     if (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))
                        disp('Multiclick')
                        targetsLocal = taskParams.targetInds;
                        %if multiClickImageFlag %SF: this is not needed
                            %SF: changing "clickTargs" to "nextClickTarg"
                            disp(['Click Targ: ', num2str(taskParams.nextClickTarg + 1)])
                            if uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_LCLICK)
                             %   bgImage = imread('/home/nptl/code/visualizationCode/imageBank/rightLegLeft.png');
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click1.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_RCLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click2.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_2CLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click3.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
                            elseif uint16(taskParams.nextClickTarg + 1) == uint16(DiscreteStates.CLICK_SCLICK)
                                bgImage = imread('/home/nptl/code/visualizationCode/imageBank/click4.png');
                                Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
                                targetColorStr = 'y';
%                             else %no background, show center target.
%                                 targetsLocal(:,end+1) = 0;
%                                 bgImage = imread('/home/nptl/code/visualizationCode/imageBank/blank_background.png');
%                                 Screen('PutImage', screenParams.offScreen(1).screen, bgImage, [0 0 mp(1)*2 mp(2)*2]);
%                                 Screen('FillRect', screenParams.offScreen(1).screen, screenParams.backgroundIndexColor);
%                                 targetColorStr = 'p';
%                                 disp('Center, no bkgnd')
                            end
                        %SF added the gray targets back in:
                        if data.numTargets<=16 || (uint32(data.taskType) == uint32(cursorConstants.TASK_MULTICLICK))%sf says why limit this here?
                            for nt = 1:size(targetsLocal,2)
                                currentTargetCoords = double(targetsLocal(1:2,nt))+mp(:);
                                currentTargetBoundingRect = [currentTargetCoords - double(taskParams.targetDiameter)/2; currentTargetCoords + double(taskParams.targetDiameter)/2];
                                Screen('FillOval', screenParams.offScreen(1).screen, grey, currentTargetBoundingRect, 100);
                            end
                        end
                     end
                    Screen('FillOval', whichScreen, red, nextTargetBoundingRect, 100);
                case {CursorStates.STATE_MOVE, CursorStates.STATE_MOVE_CLICK, CursorStates.STATE_RECENTER_DELAY}
                    %%  logic to make cursor invisible DD DEO
                    %cursorColors = zeros(size(double(data.cursorColors))) + 255;
                    %%
                    if drawTwoTargets
                        Screen('FillOval', whichScreen, [0; 204; 102;], currentTargetBoundingRect2, 100);
                    end
                    Screen('FillOval', whichScreen, currentTargetColor, currentTargetBoundingRect, 100);
                case {CursorStates.STATE_FINGER_LIFTED}
                    DrawFormattedText(whichScreen, 'Finger lifted', 'center', mp(2)-300, white);
                case {CursorStates.STATE_ACQUIRE, CursorStates.STATE_HOVER}
                    if drawTwoTargets
                        Screen('FillOval', whichScreen, orange, currentTargetBoundingRect2, 100);
                    end
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
            
            %%
            %label targets with numbers
            if data.drawNumbersOnTargets==1 
                for nt = 1:data.numTargets
                    currentTargetCoords = double(data.targetInds(1:2,nt))+mp(:);
                    Screen('DrawText', screenParams.whichScreen, num2str(nt), currentTargetCoords(1)-15, currentTargetCoords(2)-15, [255 255 255]); 
                end
            end
            
            %%
            %draw upcoming target
            %if ~all(data.upcomingTarget==single(-1))
            %    currentTargetCoords = double(data.upcomingTarget)+mp(:);
            %    currentTargetBoundingRect = [currentTargetCoords - double(taskParams.targetDiameter)/2; currentTargetCoords + double(taskParams.targetDiameter)/2];
            %    Screen('FrameOval', screenParams.whichScreen, [255 200 100], currentTargetBoundingRect, 5);
            %end
   
            %% Draw the Cursor
            for nc = 1:size(data.cursorPosition,2)
                if all(~isnan(data.cursorPosition(:,nc)))
                    %if in imagine mode, don't draw the autoplay cursor
                    if isfield(data,'wiaCode') && data.wiaCode==2 && nc==1
                        continue;
                    end
                    
                    cursorPos = double(data.cursorPosition(1:3,nc)); % grab the 3d coordinates
                    cursorPos(1:2) = cursorPos(1:2) + mp(:); % horizontal and vertical midpoint
                    drawnDiameter = double(data.cursorDiameter); % scaled-by-depth diameter
                    drawnCursorOutline = cursorOutline;
                    % DD this is where you add logic to draw cursor with
                    % border or without depending on haptics( set a flag
                    % that will toggle this and save it before executing)
                    if MakeCursorInvisible ~= 1
                        drawCursorWithBorder(screenParams,screenParams.whichScreen,...
                        cursorPos, drawnDiameter, cursorColors(1:end,nc), drawnCursorOutline);
                    end
                end
            end
            
            %% show speed instruction
            if m.packetType==CursorStates.STATE_NEW_TARGET && isfield(data,'speedCode') && data.speedCode~=0
                speedText = {'Slow','Medium','Fast'};
                %speedText = {'Slow','Fast'};
                DrawFormattedText(screenParams.whichScreen, speedText{data.speedCode},'center',420,screenParams.white);
            end
            
            %%
            %show WIA instruction
            if m.packetType==CursorStates.STATE_NEW_TARGET && isfield(data,'wiaCode') && data.wiaCode~=0
                if lastFrameWiaText==1 && data.showWiaText
                    wiaText = {'Prepare to Watch','Prepare to Imagine','Prepare to Do'};
                    DrawFormattedText(screenParams.whichScreen, wiaText{data.wiaCode},'center',480,screenParams.white);
                end
                lastFrameWiaText = 1;
            elseif (m.packetType==CursorStates.STATE_MOVE || m.packetType==CursorStates.STATE_ACQUIRE ||  m.packetType==CursorStates.STATE_HOVER ) ...
                    && isfield(data,'wiaCode') && (data.wiaCode==2 || data.wiaCode==3)
                if lastFrameWiaText==1  && data.showWiaText
                    if all(data.currentTarget(1:2)==0)
                        %T5 found the "return" text to be distracting
                        %DrawFormattedText(screenParams.whichScreen, 'Return','center',400,screenParams.white);
                    else
                        DrawFormattedText(screenParams.whichScreen, 'Go','center',480,screenParams.white);
                    end
                end
                lastFrameWiaText = 1;
            else
                lastFrameWiaText = 0;
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
                    %if ~isfield(data,'wiaCode') || data.wiaCode~=2 %don't play sounds for imagined movements
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.successSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                    %end
                case CursorStates.SOUND_STATE_FAIL
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.failSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_GO
                    PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.goSound);
                    PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                case CursorStates.SOUND_STATE_OVER_TARGET
                    if ~isfield(data,'wiaCode') || data.wiaCode~=2 %don't play sounds for imagined movements
                        PsychPortAudio('FillBuffer', soundParams.audioHandle, soundParams.overSound);
                        PsychPortAudio('Start', soundParams.audioHandle, 1, 0, 0);
                    end
            end
        end
end

