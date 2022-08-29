function flipTime = robotUpdateAfterEachXPCpacket(data)
% Created 10 February 2017
% Updated June 2017 to accomodate Will robot code.
% Initially a clone of cursorSetupScreen.m, but things will diverge and so
% this is the place to do that.
%
% SDS, BJ

global taskParams;
global redisCon;
global ROBOT_HOME

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

% Critical keys
% Will's code
HAND_VELOCITY_KEY = 'scl::robot::kinovajaco6::sensors::dq';
REQUEST_ID_KEY = 'scl::robot::kinovajaco6::sensors::request_id'; % checks if it's been updated, else ignores command
MULTIPLY_VELOCITY_FACTOR = 1000; % xPC velocities are scaled this much
MULTIPLY_ROTATION_FACTOR = 10000; % xPC rotational velocities are scaled this much
%% all the relevant info is in the "data" field of the packet, deconstruct it

% paramaters for sclarm
% axis for arm in sim world: left is +y, up is +z, out of monitor is +x
% MOVE these out to some central palce
% armTargetPosScale = double(1/1280).*(1/4); % temporary
armTargetPosScale = 1; % temporary

switch taskParams.engineType
    case EngineTypes.VISUALIZATION
                    
        flipTime = 0; % not useful because this is not PTB
        m.packetType = data.state;
        global screenParams;
        cursorAlpha = 1;
        
        %hard-coded color params (BJ: is this part only needed for SLC-CURSOR?)
        red = [255 0 0 ];
        grey = [100 100 100];
        blue = [0 153 153];
        green = [00 204 00];
        aqua = [0 255 255];
        orange = [255 133 0];
        yellow = [153 153 25];
        purple = [100 0 100];
        white = [255 255 255];
        
        %BJ: SCL flip is so we can render the cursor in SCL to help keep
        %track of what's going on.
        sclFlip1 = double(-1); % first element of SCL vectors 
        sclFlip2 = double(-1); % second element of SCL vectors
        sclFlip3 = double(-1); % third element of SCL vectors
        sclFlip4 = double(1);  % fourth element of SCL vectors. Rotation around world Z axis. Positive means right side goes down (clockwise) 
        
        armFlip1 = double(-1); % first element of SCL vectors 
        armFlip2 = double(-1); % second element of SCL vectors
        armFlip3 = double(-1); % third element of SCL vectors
        armFlip4 = double(1);  % fourth element of SCL vectors. Rotation around world Z axis. Positive means right side goes down (clockwise) 
        armFlip5 = double(-1); % fifth element of SCL vectors. Rotation arund hammer long axis coordinate angle in YZ plane. Positive means top comes out of screen.
        armFlip6 = double(-1); % sixth element of SCL vectors. Rotation around  coordinate angle in YZ plane. Positive means top comes out of screen.

        %         fprintf('Output type %i\n',  uint16(data.outputType) ) % DEV
        
        %% MAIN.
        if uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_ROBOT)
            % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%                          SCL-ROBOT
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
       
            
            
            % doesn't do anything since there's no target
            currentTargetColor = currentTargetColor./255; %SCL uses 0 to 1
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
                            
                            % Target becomes a rectangular prism
                            redisCon.set('bmi_target_shape', sprintf('%0.3f', 1 ) );
                            targetSize = double(data.targetDiameter) * armTargetPosScale;
                            targetSizeSecondary = targetSize / smallerDimsFactor;
                            targetAlpha = 1;
                            % Create 3D extent target too. This is another object which
                            % shows the spatial extent of our target. SDS March 2017
                            
                           
                            redisCon.set('bmi_sphere_enabled_2',  0)
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
            redisCon.set('bmi_target_color', sprintf('%0.3f %0.3f %0.3f %0.3f', currentTargetColor(1), currentTargetColor(2), currentTargetColor(3), ...
                targetAlpha ));
            
 

            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     CURSOR
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            redisCon.set('bmi_center_enabled', 0) % no second cursor
            for iCursor = 1 : 1  % no second cursor for robot tasks.
               
                
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
                        if ~any( ~isnan( data.cursorPosition(:,2) ) )
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
                        end
                end
                
                % sclCursorPos is temporary for just this cursor
                sclCursorPos(1) = double(data.cursorPosition(1,iCursor))*armTargetPosScale*armFlip1; % horizontal. Positive means right.
                sclCursorPos(2) = double(data.cursorPosition(2,iCursor))*armTargetPosScale*armFlip2; % vertical. Positive means down
                sclCursorPos(3) = double(data.cursorPosition(3,iCursor))*armTargetPosScale*armFlip3; % Depth. positive means out towards viewer
                
                
                %% -----------------------------------------------------
                % Will to Jaco interface specific stuff
                % ------------------------------------------------------
                % This is the key stuff. Note that xPC 
                % Dimension mapping. For xPC dimensions, I mean what we see on
                % the monitor given what happens in recorded velocity/positions.
                % For sign for Robot, I mean what REDIS value sign
                % translate to what direction movement in the real world.
                % DIM | xPC                            |     Robot
                % ----+------------------------------|----------
                %  1  |horiz. (+1 == right)          | horiz. (+1 == left) ('x')
                %  2  |vert.  (+1 == down)           | forw/back (+1 == towards base) ('y')            
                %  3  |depth  (+1 == towards viewer) | up/down (+1 == up) 'z')
                %  4  |rotate XY (+1 == clockwise)   | wrist rotate (+1 == CCW ('rotation x')
                %  5  |
           
                handVelocity(1) = MULTIPLY_VELOCITY_FACTOR .* double( data.cursorVelocity(1) ) *(-1);
                handVelocity(3) = MULTIPLY_VELOCITY_FACTOR .* double( data.cursorVelocity(2) ) * (-1); % note element switch
                handVelocity(2) = MULTIPLY_VELOCITY_FACTOR .* double( data.cursorVelocity(3) ) *(1); % note element switch
              
                
                if numDims > 3
                    sclCursorPos(4) = double(data.cursorPosition(4,iCursor))*armTargetPosScale*sclFlip4; % Wrist rotation (rot1). Around z (in-out of screen) axis.
                    handVelocity(4) =  MULTIPLY_ROTATION_FACTOR .* double( data.cursorVelocity(4) ) *(-1);
                end
                
                if numDims > 4
                    sclCursorPos(5) = double(data.cursorPosition(5,iCursor))*armTargetPosScale*armFlip5; % Wrist rotation (rot1). Around z (in-out of screen) axis.
                    handVelocity(5) = MULTIPLY_ROTATION_FACTOR .* double( data.cursorVelocity(5) ) *(1);
                else
                    sclCursorPos(5) = 0; % Dim not in use, render as 0 azimuth
                    handVelocity(5) = double( 0 ); 
                end
                
                if numDims > 5
                    sclCursorPos(6) = double(data.cursorPosition(6,iCursor))*armTargetPosScale*armFlip6;
                    handVelocity(6) =  MULTIPLY_ROTATION_FACTOR .* double( data.cursorVelocity(6) ) *(1);
                else
                    sclCursorPos(6) = 0;
                    handVelocity(6) = double( 0 );
                end
                
                % Cursor Color - overloaded to also mean fingers open or close
                cursorColor = double( data.cursorColors(:,1) )./255;
               
                if cursorColor(1) > 0.9
                    fingerOpenState = int8( 1 ) ;
                else
                    fingerOpenState = int8( 0 ) ;
                end
                


                % Send command to Will's code:
                fprintf('Writing %7.5f %7.5f %7.5f %7.5f %7.5f %d to %s\n', ...
                     handVelocity(1), handVelocity(2), handVelocity(3), handVelocity(4), handVelocity(5), ...
                     fingerOpenState, HAND_VELOCITY_KEY );
                 
                redisCon.set(HAND_VELOCITY_KEY, sprintf('%0.5f %0.5f %0.5f %0.5f %0.5f %d', ...
                     handVelocity(1), handVelocity(2), handVelocity(3), handVelocity(4), handVelocity(5), fingerOpenState ) );
                redisCon.set(REQUEST_ID_KEY, sprintf('%0.5f', data.clock ) );
                
                % SCL graphics so we can see what xPC thinks it's
                % commanding
                redisCon.set(cursorColorKey, sprintf('%0.3f %0.3f %0.3f %0.3f', cursorColor(1), cursorColor(2), cursorColor(3), ...
                    thisCursorAlpha) );
                
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
                end 
            end
            % CURSOR SHAPE AND SIZE
            redisCon.set(cursorShapeKey, sprintf('%0.3f', cursorShape ) );
            
            flipTime = 0; % not useful because this is not PTB
            
            
            
        elseif uint16(data.outputType) == uint16(cursorConstants.OUTPUT_TYPE_SCLCURSOR) % Cursor task, but rendered in SCL
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
         
            
            currentTargetColor = currentTargetColor./255; %SCL uses 0 to 1
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
                            
                            % Target becomes a rectangular prism
                            redisCon.set('bmi_target_shape', sprintf('%0.3f', 1 ) );
                            targetSize = double(data.targetDiameter) * armTargetPosScale;
                            targetSizeSecondary = targetSize / smallerDimsFactor;
                            targetAlpha = 1;
                            % Create 3D extent target too. This is another object which
                            % shows the spatial extent of our target. SDS March 2017
                            redisCon.set('bmi_sphere_enabled_2',  0)
                   
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
            redisCon.set('bmi_target_color', sprintf('%0.3f %0.3f %0.3f %0.3f', currentTargetColor(1), currentTargetColor(2), currentTargetColor(3), ...
                targetAlpha ));
            
            
            
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            %     CURSOR
            % %%%%%%%%%%%%%%%%%%%%%%%%%%
            
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
                        if ~any( ~isnan( data.cursorPosition(:,2) ) )
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
                
                % sclCursorPos is temporary for just this cursor
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
                redisCon.set(cursorColorKey, sprintf('%0.3f %0.3f %0.3f %0.3f', cursorColor(1), cursorColor(2), cursorColor(3), ...
                    thisCursorAlpha) );
                
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
                end
                
            end
            % CURSOR SHAPE AND SIZE
            redisCon.set(cursorShapeKey, sprintf('%0.3f', cursorShape ) );
            

            %toc(taskParams.startTime);
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

