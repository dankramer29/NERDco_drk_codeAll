% CursorTaskSimplePerformanceMetrics.m
%
% Computes some simple performance metrics about 
% Operates under different rules between standard center-out-and-back Cursor Task (e.g.
% Radial 26 Target Task) and Gridlike task.
%
% Returns values for all trials, with nans for trials where a certain
% metric doens't make sense.
%
% NOTE: I haven't gone through this and made sure it does reasonable things for mixed
% click and dwell blocks. Right now, it assumes that if .startTrialParams.clickSource 
% is cursorConstants.TARGET_TYPE_CLICK, then it is a click selection trial. Though actually I think 
% with the way I caclulate .timeFirstTargetEntry and .trialLength as successful end of
% trial, it probably will just work out fine for a hold selection in a click-enabled
% block.
%
% USAGE: [ stat ] = CursorTaskSimplePerformanceMetrics( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         NPTL R struct. This should be just one block, otherwise
%                               things like block duration will be nonsensical.
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     stat                      structure with a bunch of metrics.
%
% Created by Sergey Stavisky on 27 Jan 2017

function [ stat ] = CursorTaskSimplePerformanceMetrics( R, varargin )


def.radiusCounts = false; % cursor radius counts for target acquisition (discontinued when we went to 4D)
assignargs( def, varargin );

taskType = R(1).startTrialParams.taskType;

% Is this one block or multiple blocks?
blockEachTrial = arrayfun( @(x) x.startTrialParams.blockNumber, R );
blocksPresent = unique( blockEachTrial );
if numel( blocksPresent ) > 1
    % Multiple blocks, calculate the duration of each and then add those
    % for the overall blocks' duration.
    for iBlock = 1 : numel( blocksPresent )
        firstTrialThisBlock = find( blockEachTrial== blocksPresent(iBlock), 1, 'first');
        lastTrialThisBlock = find( blockEachTrial== blocksPresent(iBlock), 1, 'last');
        stat.blockDurationEachBlock(iBlock) = double( (R(lastTrialThisBlock).clock(end) )- double(R(firstTrialThisBlock).clock(1)))/1000 ;  % convert from ms to s
    end    
    stat.blockDuration = sum( stat.blockDurationEachBlock );
else
    % just one block, calculating its duration is easy
    stat.blockDuration = double( (R(end).clock(end) )- double(R(1).clock(1)))/1000 ;  % convert from ms to s
end
    
stat.blockNumber = blocksPresent;



% Stats common to gridlike and cursor task

% TODO: should I ignore last trial when it comes to a halt on its own?
stat.numTrials = numel(R);
stat.numSuccess = nnz([R.isSuccessful]);
stat.numFailure = nnz(~[R.isSuccessful]);
stat.successPerMinute = stat.numSuccess / (stat.blockDuration/60);

sucTrials = logical([R.isSuccessful]);

% time to target
stat.TTT = [R.trialLength]'; %this already skips timeTargetOn
stat.TTT(~sucTrials) = nan;


% Record target diameter
stat.targetDiameter = arrayfun( @(x) x.startTrialParams.targetDiameter, R )';

% Add when the target was first entered.
R = AddTimesTargetEntry( R );

% Different handling for click versus non-click
if any( arrayfun(@(x) x.startTrialParams.clickSource == cursorConstants.TARGET_TYPE_CLICK, R) )
    % There are click trials
    R = AddTimeSuccessfulClick( R );
end

N = numel( R );
stat.dialIn = nan( N,1 );
stat.numIncorrectClicks = nan( N, 1 );
stat.timeToClickAfterFirstTargetEntry = nan( N, 1 );
for i = 1 : numel( R )
    if ~R(i).isSuccessful
        % nan for failure trials
        stat.dialIn(i) = nan;
        try
            % only works if click trial
            stat.numIncorrectClicks(i) = numel( R(i).timeIncorrectClick ); % can still be done
            stat.timeToClickAfterFirstTargetEntry(i) = nan;
        catch
            
        end
        continue
    end
    
    if taskType == double(cursorConstants.TASK_RAYS )
        % ain't no clicks, no calculating dialIn.
    
    elseif R(i).startTrialParams.clickSource == cursorConstants.TARGET_TYPE_CLICK  
        % CLICK SELECTION
        % If these are click trials, dial is in time between first and last target entry
        stat.dialIn(i) =  R(i).timesTargetEntry(end)-R(i).timesTargetEntry(1);
        % Also record number of incorrect clicks.
        stat.numIncorrectClicks(i) = numel( R(i).timeIncorrectClick );
        % BJ: also record the amount of time it took to succesfully click-acquire the target after the first target entry: 
        try
            stat.timeToClickAfterFirstTargetEntry(i) =  R(i).clickTimes(end) - R(i).timeFirstTargetAcquire;
        catch
        end
    else
        % DWELL SELECTION
        % if these are dwell trials, dial in is different between last target acquire time and
        % first target acquire time
        stat.dialIn(i) = R(i).timeLastTargetAcquire - R(i).timeFirstTargetAcquire;
    end
end
    
stat.fractionSuccessOnFirstTry = nnz( stat.dialIn==0 )/numel( stat.dialIn(sucTrials) );




% DIFFERENT METRICS DEPENDING ON TASK TYPE
switch taskType
    case {cursorConstants.TASK_CENTER_OUT, cursorConstants.TASK_PINBALL, cursorConstants.TASK_RANDOM }
        % Path Efficiency 
        
        R = AddCursorPathEfficiency( R, 'radiusCounts', radiusCounts ); % specify whether to include cursor radius in determining shortest path
        stat.pathEfficiency = [R.pathEfficiency]';
        stat.pathEfficiencyEachDim = [R.pathEfficiencyEachDim]';
        stat.distanceTraveledEachDim = [R.distanceTraveledEachDim];
        stat.straightDistanceStartToTarget = [R.straightDistanceStartToTarget];
        stat.trajDistance = [R.trajDistance];
        stat.cuedDistanceToTarget = [R.cuedDistanceToTarget];
    case cursorConstants.TASK_GRIDLIKE
        validDims = logical( R(1).startTrialParams.gridTilesEachDim );      
        stat.dictionarySize = prod( double( R(1).startTrialParams.gridTilesEachDim(validDims) ) )-1; % minus 1 because need a delete key
        stat.bits = log2( stat.dictionarySize) * (stat.numSuccess - stat.numFailure);
        stat.bitRate = stat.bits / stat.blockDuration; 
        
    case cursorConstants.TASK_RAYS   
        stat.dictionarySize = double( R(i).startTrialParams.numTargets-1 );
        stat.bits = log2( stat.dictionarySize) * (stat.numSuccess - stat.numFailure);
        stat.bitRate = stat.bits / stat.blockDuration; 
        
        R = AddRAYSpathEfficiency( R, 'radiusCounts', radiusCounts ); % specify whether to include cursor radius in determining shortest path
        stat.pathEfficiency = [R.pathEfficiency]';
      
    case cursorConstants.TASK_FCC
        stat.dictionarySize = double( R(i).startTrialParams.numTargets-1 );
        stat.bits = log2( stat.dictionarySize) * (stat.numSuccess - stat.numFailure);
        stat.bitRate = stat.bits / stat.blockDuration; 
        
    otherwise
        error('CursorTaskSimplePerformanceMetrics not set for tasktype %i', taskType )
end


end
