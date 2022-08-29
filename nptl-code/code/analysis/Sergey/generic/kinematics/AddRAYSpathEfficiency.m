% AddRAYSpathEfficiency.m
%
% This is a path efficency function which is specific for the RAYS task.
% The key difference is that the shortest possible path isn't all the way
% to the target, but rather, is to the decision boundary, which is
% specified in R(i).startTrialParams.
%
% Furthermore, a path efficiency can be given even for failed trials based
% on the path taken (to the wrong target) relative to the shortest path to t
% correct target. This lets me, for example, see how efficient the
% participant was in this task compared to a regular 4D cursor task,
% without the confound of only selecting for successful trials which almost
% by definition have a high path efficiency.
%
% Dervied from AddCursorPathEfficiency.m, but modified.
%
% USAGE: [ R ] = AddRAYSpathEfficiency( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         NPTL R struct
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     R                         NPTL R struct with new field with default name
%                              .pathEfficiency
%
% Created by Sergey Stavisky on 13 July 2017 using MATLAB version 9.0.0.341360 (R2016a)
%
% N

 function [ R ] = AddRAYSpathEfficiency( R, varargin )
    def.newFieldName = 'pathEfficiency'; % default name
    def.startEvent = 'timeGoCue'; % start trajectories from this time
    
    def.endEvent = 'timeSelection';    % end trajectories from here. I need to add this
    def.posDims = []; % by default, will infer dimensions that matter from the target set.
    def.radiusCounts = false; % cursor radius counts for target acquisition (discontinued when we went to 4D)
    assignargs( def, varargin );
    
    taskType = R(1).startTrialParams.taskType;
    if taskType ~= double( cursorConstants.TASK_RAYS )
        error('This data does not appear to have startTrialParams.taskType RAYS.\n')
    end
    
    
    % I'l be needing .timeSelection which doesn't already exist. I get it from
    % when the state turns to success or failure    
    for i = 1 : numel( R )        
        R(i).timeSelection = find( ismember( R(i).state, [double( CursorStates.STATE_SUCCESS ), double(CursorStates.STATE_FAIL) ] ), 1, 'first' );
    end
    

    if isempty( posDims )
        % Smart identification of which dims matter
        allTargets = cell2mat( arrayfun( @(x) x.posTarget', R, 'UniformOutput', false )' );
        for iDim = 1 : size( allTargets, 2 )
           if numel( unique( allTargets(:,iDim) ) ) > 1
               % this is an active dimension
               posDims(end+1) = iDim;
           end
        end
    end

     % Loop through trials
    for i = 1 : length( R )
        % Initialize all fields so they exist
        R(i).(newFieldName) = nan;
        R(i).straightDistanceStartToTarget = nan;
        R(i).trajDistance = nan;
        R(i).pathEfficiencyEachDim = nan(numel( posDims ),1  );
        R(i).distanceTraveledEachDim = nan(numel( posDims ),1  );
        R(i).shortestPossibleDistanceEachDim = nan(numel( posDims ),1  );
        R(i).cuedDistanceToTarget = nan;
        
        % Get the trajectory distance that was taken
        startInd = R(i).(startEvent);
        endInd = R(i).(endEvent);
        traj = double( R(i).cursorPosition(posDims,startInd:endInd) );         
        trajDistance = sum( sqrt( sum( diff(traj,1,2).^2, 1 ) ) ); % this will be numerator
        
        % Compute the straight line distance to the target edge.
        % For RAYS this is trivial, as it's just the decision distance,
        % which I set using the overloaded parameter targetRotDiameter
        R(i).cuedDistanceToTarget = 0.5 * R(i).startTrialParams.targetRotDiameter;     
           
            
        targetPos = R(i).posTarget(posDims);
    
        
        straightDistanceStartToTarget =  R(i).cuedDistanceToTarget;
      
        
        % From these, compute Path efficiency and Distance Ratio
        R(i).straightDistanceStartToTarget = straightDistanceStartToTarget;
        R(i).trajDistance = trajDistance;
        R(i).(newFieldName) = straightDistanceStartToTarget / trajDistance;

        % ------------------------------------------------------
        % Since dimension cursor path efficiency
        %-------------------------------------------------------
        % Calculate what the closest point on the target boundary would be.
        % Note that this doesn't really make a ton of sense, because it
        % gives zero efficiency for dimensions where the shortest distance
        % is 0 because the target is e.g. in direction [0 0 0 1]

        % calculate point on the target bou8ndary sphere
        % (start position) + tv * straightDistanceStartToTarget
        % where tv is norm-1 vector pointing towards the target
        % from start location
        startPos = zeros( size( targetPos ) ); % assume start at 0 always
        tv = targetPos - startPos;
        tv = tv ./ norm( tv );
        closestBoundary = startPos + tv .*  straightDistanceStartToTarget;

        
        % How far did cursor travel in each dimension?
        distanceTraveledEachDim = sum( abs( diff(traj,1,2) ), 2 );
        shortestPossibleDistanceEachDim = abs( closestBoundary-startPos );
        R(i).pathEfficiencyEachDim = shortestPossibleDistanceEachDim./distanceTraveledEachDim;
        R(i).distanceTraveledEachDim = distanceTraveledEachDim;
        R(i).shortestPossibleDistanceEachDim = shortestPossibleDistanceEachDim; 
    end
    
end