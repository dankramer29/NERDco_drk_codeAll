% Plot3Dtrajectories.m
%
% Plots 3D NPTL trajectories.
%
% USAGE: [ figh ] = Plot3Dtrajectories( R, varargin )
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
% Created by Sergey Stavisky on 27 Jan 2017

function [ figh, axh, h ] = Plot3Dtrajectories( R, varargin )
    def.axh = [];
    def.LineWidth = 1;
    def.plotEveryNms = 10; % downsamples to not have too many points
    def.showClicks = true; % if clicks are enabled in this task, they will be drawn.
    def.clickColor = [1 0 1];
    def.clickMarker = 'o';
    def.clickSize = 5^2;
    def.clickLineWidth = 1;
    def.showTarget = false; % if true, will draw a sphere where the target is.
    def.targetRadius = []; % if set, will draw targets at this radius. If empty will be actual target acquisition radius

    def.colors = []; % should be numel(R) x 3 RGB matrix. If provided, will color each trial according to this color. 
                     % Note, each target's trials are plotted together so won't support different colors for
                     % different trials to this target. It just takes the first one.
    assignargs( def, varargin );
    
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
    workspaceh = Draw3Dworkspace('axh', axh, ...
        'workspaceX', R(1).startTrialParams.workspaceX, ...
        'workspaceY', R(1).startTrialParams.workspacey, ... % due to stupid typo.. 
        'workspaceZ', R(1).startTrialParams.workspaceZ);

    % I'll assign colors by target.
    [targetIdx, uniqueTargets, angle, distFromZero] = SortTrialsBy3Dtarget( R );
    targetColors = ThreeDCoordinateColors( uniqueTargets ); % used if colors not specified. Looks nice!
  
    % Loop through the trials and plot them
    % Plot each group together
    for iTarg = 1 : size( uniqueTargets,1 );
        

        
        
        % Assemble X, Y, Z matrices which have all of this group's trial's positions
        myTrials = targetIdx == iTarg;
        myTrialPos =  arrayfun( @(x) x.cursorPosition, R(myTrials), 'UniformOutput', false);
        N = numel(myTrialPos);
        % need to preallocate 
        maxSamples = max( cellfun(@(x) size(x,2), myTrialPos) );
        X = nan( maxSamples,N);
        Y = X;
        Z = X;
        for iTrial = 1 : N
            samples = size( myTrialPos{iTrial},2);
            X(1:samples,iTrial) = myTrialPos{iTrial}(1,:);
            Y(1:samples,iTrial) = myTrialPos{iTrial}(2,:);
            Z(1:samples,iTrial) = myTrialPos{iTrial}(3,:);           
        end
        % downsample
        X = X(1:plotEveryNms:end,:);
        Y = Y(1:plotEveryNms:end,:);
        Z = Z(1:plotEveryNms:end,:);
        
        if isempty( colors )
             myColor = targetColors(iTarg,: );   
        else            
            myColor = colors( myTrials, : );
            % pick just 1.
            if any( ~EqRow( myColor, myColor(1,:)) )
                warning('Detected more than one color to one target. This is ignored, using first trial''s color');
            end
            myColor = myColor(1,:);
        end
        
        % now plot them
        h{iTarg} = plot3( X, Y, Z, 'Color', myColor, 'LineWidth', 1 );
        
        % Draw the target
        if showTarget
           myPos =  uniqueTargets(iTarg,:);
           % note that uses first trial to this target's effective radius (which will be accurate
           % even if cursor radius counted
           if isempty( targetRadius )
               trialInd = find( myTrials, 1 );
               myR = R(trialInd);
               myR = AddTimesTargetEntry( myR );
               myR.timeLastTargetEntry = myR.timesTargetEntry(end);
               myRadius = norm( myR.cursorPosition([1:3], myR.timeLastTargetEntry) - myPos' ); % effective radius
           else
               myRadius = targetRadius;
           end
           [targX, targY, targZ] = sphere;
           htarg = surf( myRadius.*targX+myPos(1), myRadius.*targY+myPos(2), myRadius.*targZ+myPos(3), ...
               'FaceColor', 'none', 'FaceAlpha', 0, 'EdgeColor',  myColor, 'EdgeAlpha', 0.5 );
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