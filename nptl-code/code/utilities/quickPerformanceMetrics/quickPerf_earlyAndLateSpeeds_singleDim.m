function [figh, result] = quickPerf_earlyAndLateSpeeds_singleDim( blockNum, varargin )
% Plots speed for each dimension, aligned to start of the trial as well as first target
% acquire. Works for cursorTask blocks. This variant looks at speeds
% individually in each dimension.
%
% Also records peak speed for each trial and then outputs mean peak speed. Note that peak
% speed is calculated from the startEvent to endEvent
%
% Sergey Stavisky, 7 February 2017
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

%% Dev continue from here
taskType = R(1).startTrialParams.taskType; % center-out-and-back or Gridlike

%% Get the data
R = AddTimesTargetEntry( R );
% restrict to successful trials
R = R([R.isSuccessful]);


% Preallocate
numTrials = numel( R );
numDims = size( R(1).cursorPosition, 1 );
result.startDat = nan( numTrials, msFromStart, numDims );
result.endDat =  nan( numTrials, msFromEnd, numDims );
result.peakSpeedDat = nan( numTrials, numDims ); % record peak speed for each trial

for iTrial = 1 : numTrials
    % convert positions to speeds 
    mySpeed = abs( diff( R(iTrial).cursorPosition' ) );
    startEventInd = R(iTrial).(startEvent)-1;
    endEventInd = R(iTrial).(endEvent)-1;
    % analysis epoch of interest
    result.peakSpeedDat(iTrial,:) = max( mySpeed(startEventInd:endEventInd) );
    result.startDat(iTrial,:,:) = mySpeed(startEventInd:startEventInd+msFromStart-1,:);
    result.endDat(iTrial,:,:) = mySpeed(endEventInd-msFromEnd:endEventInd-1,:);  
end

%% Compute means
result.meanStartSpeed = squeeze( mean( result.startDat, 1 ) );
result.meanEndSpeed = squeeze( mean( result.endDat, 1 ) );
result.meanPeakSpeed = mean( result.peakSpeedDat, 1 );

fprintf(' Peak mean speed of block %i was %s\n', blockNum, mat2str( result.meanPeakSpeed, 3 ) );

for iDim = 1 : numDims
    legStr{iDim} = sprintf( 'Dim%i', iDim ); % used for legend
end

%% Plot
if showPlot
   figh = figure;
   axStart = subplot( 1,2,1 );
   plot(  1:msFromStart, result.meanStartSpeed );
   ylabel('Speed (m/ms)')
   xlabel( sprintf('ms from %s', startEvent ) );
   
   axEnd = subplot( 1,2,2 );
   plot(  -msFromEnd+1:1:0, result.meanEndSpeed );   
   legend( legStr )
   xlabel( sprintf('ms from %s', endEvent ) );
   
   linkaxes( [axStart axEnd], 'y' )
   ylim([0 max(result.meanPeakSpeed)]);
   
   titlestr = sprintf('Early and Late Speeds Block%i', blockNum);
   set( figh, 'Name', titlestr );  
end

end
