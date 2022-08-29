% AddCursorPathEfficiency.m
%
% This is the NPTL path efficency function. Don't confuse it with addPathEfficiency.m
% (which is for rigC). Given an R struct, will add a new field to each trial giving the
% path efficiency
%
% By default distance covered is comptued from timeTargetOn to timeLastTargetAcquire.
% Straight line distance is from cursor position at timeTargetOn to center of target,
% minus target radius.
% Staright line distance is from trajectory start to boundary when going straight towards
% target.
%
% Returns NaN for unsuccesful trials
%
% Relevant reference is Incorporating feedback from multiple sensory modalities enhances brain???machine
% interface control (Suminki 2010)
%
% USAGE: [ R ] = AddCursorPathEfficiency( R, varargin )
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
%                             .pathEfficiency
%
% Created by Sergey Stavisky on 02 Feb 2017 using MATLAB version 8.5.0.197613 (R2015a)

 function [ R ] = AddCursorPathEfficiency( R, varargin )
    def.newFieldName = 'pathEfficiency'; % default name
    def.startEvent = 'timeGoCue'; % start trajectories from this time
    def.endEvent = 'timeLastTargetEntry';    % end trajectories from here. 
    def.posDims = []; % by default, will infer dimensions that matter from the target set.
    def.radiusCounts = false; % cursor radius counts for target acquisition (discontinued when we went to 4D)
    assignargs( def, varargin );
    
    % I'l be needing .timeLastTargetEntry which typically doesn't exist. I get it from
    % .timesTargetEntry
    switch endEvent
        case 'timeLastTargetEntry'
            if ~isfield( R, 'timeLastTargetEntry' )
                if ~isfield( R, 'timesTargetEntry' )
                    R = AddTimesTargetEntry( R );
                end
                for i = 1 : numel( R )
                    if isempty( R(i).timesTargetEntry )
                        R(i).timeLastTargetEntry = [];
                    else
                        R(i).timeLastTargetEntry = R(i).timesTargetEntry(end);
                    end
                end
            end
        case 'timeFirstTargetEntry'
            if ~isfield( R, 'timeFirstTargetEntry' )
                R = AddTimesTargetEntry( R );
            end
            for i = 1 : numel( R )
                if isempty( R(i).timesTargetEntry )
                    R(i).timeFirstTargetEntry = [];
                else
                    R(i).timeFirstTargetEntry = R(i).timesTargetEntry(1);
                end
            end
        otherwise
            % hope it exists, otherwise hello error
    end
    


    if isempty( posDims )
        % Smart identifyication of which dims matter
        if size( R(1).posTarget, 1 ) > 1 % i think at some point these got transposed; this makes it redundant
            allTargets = [R.posTarget]'; % SDS July 3 2018: not sure why below line was there, this seems better
%             allTargets = cell2mat( arrayfun( @(x) x.posTarget, R, 'UniformOutput', false ) )';
        else
            allTargets = cell2mat( arrayfun( @(x) x.posTarget', R, 'UniformOutput', false )' );
        end
        for iDim = 1 : size( allTargets, 2 )
           if numel( unique( allTargets(:,iDim) ) ) > 1
               % this is an active dimension
               posDims(end+1) = iDim;
           end
        end
    end

    if numel( posDims ) > 3
%         keyboard
        % TODO: Think about whether path efficiency really makes sense with rotation, especially
        % since the units are different.
        % SDS March 1 2017: I made the units on the same scale, so yes for
        % now it's fine to just continue.
        
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
        % Make sure that the trial was successful, if not return NaN
        if ~R(i).isSuccessful
            continue;
        end
        
        % Get the trajectory distance that was taken
        startInd = R(i).(startEvent);
        endInd = R(i).(endEvent);
        traj = double( R(i).cursorPosition(posDims,startInd:endInd) );         
        trajDistance = sum( sqrt( sum( diff(traj,1,2).^2, 1 ) ) ); % this will be numerator
        
        % Compute the straight line distance to the target edge.
        % This assumes a spherical target.    
        try
            R(i).cuedDistanceToTarget = norm(R(i).posTarget(posDims) - R(i).lastPosTarget(posDims));
        catch
            R(i).cuedDistanceToTarget = nan; % happens for first trial
        end
        targetPos = R(i).posTarget(posDims);
        winRad = R(i).startTrialParams.targetDiameter/2;
        if radiusCounts
            % Crap, unfortunately cursor radius wasn't recorded in
            % discrete params. But we can infer it based on distance
            % between cursor and target when acquisition happened.
            entryDistance = norm(R(i).cursorPosition(posDims,R(i).timeLastTargetEntry) - targetPos );
            cursorRad = entryDistance - winRad;
        else
            cursorRad = 0;
        end
        
        straightDistanceStartToTarget = sqrt( sum( (traj(:,1) - targetPos).^2 ) ) - winRad - cursorRad;
        % If the straight line distance is less than winRad, this is a nonsesne trial because
        % cursor started inside the target. NaN it. 
        if straightDistanceStartToTarget <= winRad
            R(i).(newFieldName) = NaN;
            continue;
        end
        
        % From these, compute Path efficiency and Distance Ratio
        R(i).straightDistanceStartToTarget = straightDistanceStartToTarget;
        R(i).trajDistance = trajDistance;
        R(i).(newFieldName) = straightDistanceStartToTarget / trajDistance;

        % ------------------------------------------------------
        % Single dimension cursor path efficiency
        %-------------------------------------------------------
        % Be careful when using this metric, it often does not really make
        % sense (in aprticular, for trials where the required movement does
        % not use all of the dimensions much, the straight line distance
        % for these dimensions is close to zero and thus the PE for those signle
        % dimensions is nonsense.)
        
        % Calculate what the closest point on the target boundary would be.
        taskType = R(1).startTrialParams.taskType;
        switch taskType
            case {cursorConstants.TASK_CENTER_OUT, cursorConstants.TASK_PINBALL, cursorConstants.TASK_RANDOM}
                
                if numel( posDims ) > 4
                    fprintf(2, sprintf('[%s] Skipping single-dim efficiency until you implement closestBoundary with multiple radii\n', ...
                        mfilename ) )
                    continue;
                end
                % calculate point on the target boundary sphere
                % (start position) + tv * straightDistanceStartToTarget
                % where tv is norm-1 vector pointing towards the target
                % from start location
                startPos = R(i).cursorPosition(posDims,startInd);
                tv = targetPos - startPos;
                tv = tv ./ norm( tv );
                closestBoundary = startPos + tv .*  straightDistanceStartToTarget;
                
            case TASK_GRIDLIKE
                % 
                keyboard % Rectangular. Should be straightforward, just look at cursorDiameter
        end
        
        % How far did cursor travel in each dimension?
        distanceTraveledEachDim = sum( abs( diff(traj,1,2) ), 2 );
        shortestPossibleDistanceEachDim = abs( closestBoundary-startPos );
        R(i).pathEfficiencyEachDim = shortestPossibleDistanceEachDim./distanceTraveledEachDim;
        R(i).distanceTraveledEachDim = distanceTraveledEachDim;
        R(i).shortestPossibleDistanceEachDim = shortestPossibleDistanceEachDim; 
    end
    
end