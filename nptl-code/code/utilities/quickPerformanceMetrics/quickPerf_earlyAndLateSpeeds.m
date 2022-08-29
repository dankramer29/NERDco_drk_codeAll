function [figh, result] = quickPerf_earlyAndLateSpeeds( blockNum, varargin )
% Plots speed (total across all dimensions), aligned to start of the trial as well as first target
% acquire. Works for cursorTask blocks.
%
% Also records peak speed for each trial and then outputs mean peak speed. Note that peak
% speed is calculated from the startEvent to endEvent
%
% Sergey Stavisky, 5 April 2017
%
% INPUT:
%     blockNum     block number you want to plot speeds for. Can also be a full path to a
%                  file logger directory.
% OUTPUTS:
%    figh             Figure handle showing the speed profiles
%    result           Data that goes into the speed profiles
%
 

% Get full path 
global modelConstants
def.msFromStart = 500; % how many ms to grab aligned to start event
def.startEvent = 'timeTargetOn';
def.msFromEnd = 500; % how many ms aligned to end event
def.endEvent = 'timeFirstTargetEntry';
def.showPlot = true; % set to false to just get the data but don't plot it
def.preGain = true; % by default, show the pre-gained speed.
assignargs( def, varargin );

% Input can either be a block number, or 
if nargin < 1
    % if no input, use most recent (by timestamp of file) block
    fileLoggerRoot = [modelConstants.sessionRoot, 'Data/FileLogger/'];
    in = dir( fileLoggerRoot );
    in = in(3:end); % first two elements are '..' and '.'
    dateNums = [in.datenum];
    [~,ind] = max( dateNums );
    blockNum = str2num( in(ind).name );
    fprintf('Will analyze most recent block, %g\n', blockNum );
    fileLoggerDir = sprintf('Data/FileLogger/%i', blockNum);
    fileLoggerDirFull = [modelConstants.sessionRoot, fileLoggerDir];
else
    % specified block    
    if isnumeric( blockNum )
        fileLoggerDir = sprintf('Data/FileLogger/%g', blockNum);
        fileLoggerDirFull = [modelConstants.sessionRoot, fileLoggerDir];

    else % BJ: if a whole path was given instead of just a block number, use 
         % that path, then convert input blockNum to a block number so 
         % it's interpreted correctly downstream
         fileLoggerDirFull = blockNum;
         [~, blockNumChar] = fileparts(blockNum); 
         blockNum = str2double(blockNumChar);  
    end
end

R = onlineR( parseDataDirectoryBlock( fileLoggerDirFull ) );
% throw out first trial
R = R(2:end);

taskType = R(1).startTrialParams.taskType; % center-out-and-back or Gridlike


if preGain
    if any( [R.powerGain] ~= 1 )
        fprintf(2, '[%s] WARNING: preGain speeds requested but nonlinear gain was on. This code does not yet undo powerGain\n')
    end
end

%% Get the data
R = AddTimesTargetEntry( R );
% restrict to successful trials
R = R([R.isSuccessful]);


% Preallocate
numTrials = numel( R );
% infer task dimensionality.
allTargets = [R.posTarget];
% validDims = find( sum( abs( allTargets ), 2 ) );
codeDims = size( R(1).cursorPosition, 1 ); % compiled dimensionality, may be greater than task dim
result.startDat = nan( numTrials, msFromStart );
result.endDat =  nan( numTrials, msFromEnd );
result.peakSpeedDat = nan( numTrials, 1 ); % record peak speed for each trial

if taskType == double( cursorConstants.TASK_RAYS)
    % RAYS probably won't ahve cursor actually enter target boundary
    endEvent = 'timeFirstTargetAcquire';
end
    


for iTrial = 1 : numTrials
    % convert positions to speeds 
    posDiff =  diff( R(iTrial).cursorPosition(1:codeDims,:)' );
    if preGain
        posDiff = posDiff ./ R(iTrial).gain(:,2:end)';
    end
    
    mySpeed = abs( posDiff );
    % convert to speed across all dimensions
    mySpeed = sqrt( nansum( mySpeed.^2,2 ) );
    startEventInd = R(iTrial).(startEvent)-1;
    endEventInd = R(iTrial).(endEvent)-1;
    if endEventInd < msFromEnd  % this trial's target entry too short
        continue
    end
    % analysis epoch of interest
    result.startDat(iTrial,:) = mySpeed(startEventInd:startEventInd+msFromStart-1,:);
    if ~isnan( endEventInd )
        result.peakSpeedDat(iTrial,:) = max( mySpeed(startEventInd:endEventInd) );
        result.endDat(iTrial,:) = mySpeed(endEventInd-msFromEnd:endEventInd-1,:);
    end
end

%% Compute means
result.meanStartSpeed = nanmean( result.startDat, 1 );
result.meanEndSpeed =  nanmean( result.endDat, 1 );
result.meanPeakSpeed = nanmean( result.peakSpeedDat, 1 );

fprintf(' Peak mean speed of block %i was %s\n', blockNum, mat2str( result.meanPeakSpeed, 3 ) );

%% Plot
if showPlot
   figh = figure;
   axStart = subplot( 1,2,1 );
   plot(  1:msFromStart, result.meanStartSpeed );
   ylabel('Speed (m/ms)')
   xlabel( sprintf('ms from %s', startEvent ) );
   
   axEnd = subplot( 1,2,2 );
   plot(  -msFromEnd+1:1:0, result.meanEndSpeed );   
   xlabel( sprintf('ms from %s', endEvent ) );
   
   linkaxes( [axStart axEnd], 'y' )
   ylim([0 max(result.meanPeakSpeed)]);
   
   titlestr = sprintf('Early and Late Speeds Block%i', blockNum);
   if preGain
       titlestr = [titlestr, ' pre-gain'];
   else
       titlestr = [titlestr, ' post-gain'];
   end
   set( figh, 'Name', titlestr );  
end

end
