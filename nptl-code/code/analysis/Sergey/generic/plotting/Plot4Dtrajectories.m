% Plot4Dtrajectories.m
%
% Plots high d neural trajectories, wehre dimensions 4 is rotation around z( in/out
% of the screen).
% A vertical rod (without bulge) is used to show this. The mapping from the xPC axes to
% degrees is using the same scaling currently set in cursorSetupScreen.m.
%   Since it'd be unreadable if the rod were shown at every time point, it is shown every
% N ms, where N is set by plotRodEveryNms.
%
% USAGE: [ figh ] = Plot4Dtrajectories( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%     axh      Axis handle to plot into.                          
%
% OUTPUTS:
%     figh      figure handle
%     axh       axis handle
%       h       cell array of handles to each target group's plot object
%       hClick  handles of click markers
%
% Created by Sergey Stavisky on 17 July 2017

function [ figh, axh, h ] = Plot4Dtrajectories( R, varargin )
    def.axh = [];
    def.LineWidth = 1;
    def.plotEveryNms = 15; % downsamples to not have too many points
    def.plotRodEveryNms = 200; % how often to plot the rotation rod.
    def.rodLineWidth = 1.5;
    def.cursorDrawnRadius = 0.005; % can specify a radius that the cursor bar (showing 4th dim) is. Otherwise, comes from task.

    def.showClicks = true; % if clicks are enabled in this task, they will be drawn.
    def.clickColor = [1 0 1];
    def.clickMarker = 'o';
    def.clickSize = 5^2;
    def.clickLineWidth = 1;
    def.showTarget = false;
    def.targetLineWidth = 3;
    def.startEvent = 'timeGoCue'; % start plotting here
    def.endEvent = 'timeEnd'; % will need to be created
    % these parameters should be matched to cursorSetupScreen.m, and specify how the fourth
    % coordinate (rotation1) are mapped to visual angle degrees.
    def.thetaZ_xPC_limit = 0.13;  % XY plane angle/elevation (spherical coordinates)
    def.thetaZ_radian_limits = deg2rad(86);
   
    assignargs( def, varargin );
    
    if mod( plotRodEveryNms, plotEveryNms )
        error('plotRodEveryNms must be a multiple of plotEveryNms');
    end
    
    % create the event
    if strcmp( endEvent, 'timeEnd' )
        for i = 1 : numel( R )
            R(i).timeEnd = numel( R(i).clock );
        end
    end
    
    if isempty( axh )
         figh = figure;
         figh.Color = 'w';
         axh = axes;         
         axh = SetAxesToNPTLconventions( axh ); % convert this axes into NPTL coordinate conventions
         hold on;
    else
        % an axis was fed in, so we'll use that.
        figh = get( axh, 'Parent');
        axh = SetAxesToNPTLconventions( axh );
    end
   
    % Draw the workspace. This also sets the camera angle
    if isfield( R(1).startTrialParams, 'workspace' )
        % newer data has this format
        workspaceX = R(1).startTrialParams.workspace(:,1);
        workspaceY = R(1).startTrialParams.workspace(:,2);
        workspaceZ = R(1).startTrialParams.workspace(:,3);
        workspaceR1 = R(1).startTrialParams.workspace(:,4);
        workspaceR2 = R(1).startTrialParams.workspace(:,5);
    else
        % old data had this format
        workspaceX = R(1).startTrialParams.workspaceX;
        workspaceY = R(1).startTrialParams.workspacey;
        workspaceZ = R(1).startTrialParams.workspaceZ;
        workspaceR1 = R(1).startTrialParams.workspaceR1;
        workspaceR2 = R(1).startTrialParams.workspaceR2;
    end
    workspaceh = Draw3Dworkspace('axh', axh, ...
        'workspaceX', workspaceX, ...
        'workspaceY', workspaceY, ... % due to stupid typo.. 
        'workspaceZ', workspaceZ);

    
    
    % I'll assign colors by target.
    [targetIdx, uniqueTargets, angle, distFromZero] = SortTrialsBy4Dtarget( R );        
    
    % Loop through the trials and plot them 
    targetColors = FourDCoordinateColors( uniqueTargets );
    
    h = cell(0); % line trace of XYZ trajectories
    hRod = cell(0); % bars that show rotations at certain locations
    % Plot each group together
    for iTarg = 1 : size( uniqueTargets,1 );
        myTrialInds = find( targetIdx == iTarg );

        for iTrial = 1 : numel( myTrialInds );
            myInd = myTrialInds(iTrial);
            startInd = R(myInd).(startEvent);
            endInd = R(myInd).(endEvent);
            X =  double( R(myInd).cursorPosition(1,startInd:endInd) );
            Y =  double( R(myInd).cursorPosition(2,startInd:endInd) );
            Z =  double( R(myInd).cursorPosition(3,startInd:endInd) );
            R1 = double( R(myInd).cursorPosition(4,startInd:endInd) );
            
            % downsample
            X = X(1:plotEveryNms:end);
            Y = Y(1:plotEveryNms:end);
            Z = Z(1:plotEveryNms:end);
            R1 = R1(1:plotEveryNms:end);
                    
            % now plot them
            h{end+1} = plot3( X, Y, Z, 'Color', targetColors(iTarg,:), 'LineWidth', 1 );
            
            % now plot the rotation lines, 1 trial / point at a time.
            rotSamples =  plotRodEveryNms/plotEveryNms:plotRodEveryNms/plotEveryNms:numel(X);% indexes into X,Y,Z,R1
            rotXYZ = [X(rotSamples) ;
                Y(rotSamples) ;
                Z(rotSamples)];
            rotR1 = R1(rotSamples);
            % convert all of these to angles
            theta_Z = thetaZ_radian_limits* rotR1/thetaZ_xPC_limit;
          
            theta_X = zeros( size( theta_Z ) );
            D = [];
            [D(:,2), D(:,1), D(:,3)] = sph2cart(theta_Z,theta_X,1); % vectors of y,x,z offsets
            myRadius = cursorDrawnRadius;
            rodTops = rotXYZ + myRadius.*D';
            rodBottoms = rotXYZ - myRadius.*D';
            % draw these points
            hRod{end+1} = line( [rodTops(1,:) ; rodBottoms(1,:)], [rodTops(2,:) ; rodBottoms(2,:)], [rodTops(3,:) ; rodBottoms(3,:)], ...
                'Color', targetColors(iTarg,:), 'LineWidth', rodLineWidth );
        
        end
        
    
 
        if showTarget
            theta_Z = thetaZ_radian_limits* uniqueTargets(iTarg,4)/thetaZ_xPC_limit; % in radians; 0 is vertical
            theta_X = 0; % would be used if this were 5D.
            

            myRadius = R(1).startTrialParams.targetDiameter/2; % for vizually displaying it; note that in some ways the displayed size is arbitrary, because since the target is actually 4D, it doesn't have a 3D radius.
            s = [0, 1, 0]; % this is the pointing vector in spherical coordinates
            [d(2), d(1), d(3)] = sph2cart(theta_Z,theta_X, 1); % note echanged order because we define XY as azimuth
            % now compute where the top and bottom of the target rod will be.
            rodTop = uniqueTargets(iTarg,1:3) + myRadius.*d;
            rodBottom = uniqueTargets(iTarg,1:3) - myRadius.*d;
            
            htarg{iTarg} = line( [rodTop(1) rodBottom(1)], [rodTop(2) rodBottom(2)], [rodTop(3) rodBottom(3)], ...
                'Color', targetColors(iTarg,:), 'LineWidth', targetLineWidth );
        end
    end
    
        
    if showClicks
        % are there any clicks to even try to plot?
        allClickState = [R.clickState];
        if any( allClickState )
            numClicks = numel( [R.clickTimes] );
            clickPositions = nan( numClicks, 3 );
            ptr = 1; % pointer into filling clickPositions
            % assemble cursor positions when all clicks happened.
            for iTrial = 1 : numel( R )
                myClickPos = R(iTrial).cursorPosition(:,R(iTrial).clickTimes)';
                % add these to overall matrix of click locations points
                clickPositions(ptr:ptr+size(myClickPos,1)-1,:) = myClickPos;
                ptr = ptr + size(myClickPos,1);
            end       

            % Now we're ready to plot them
            hClick = scatter3( clickPositions(:,1), clickPositions(:,2), clickPositions(:,3), clickSize, clickColor, ...
                clickMarker);
            hClick.LineWidth = clickLineWidth;
         end   
    end
    
end