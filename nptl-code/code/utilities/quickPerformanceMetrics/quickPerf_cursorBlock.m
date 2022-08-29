function stat = quickPerf_cursorBlock( blockNum )
% Gives quick feedback on the performance of the most recent cursor block,
% or the block specified by the input (which can be a block number or a
% whole path.)
%
% For now it includes both center-->out and out-->center trials in its
% calculations. We may consider ??
%
% Sergey Stavisky, 10 January 2017
% modified by Beata Jarosiewicz, later in Jan

% Get full path 
global modelConstants

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
taskType = R(1).startTrialParams.taskType;
stat = CursorTaskSimplePerformanceMetrics( R );




% DIFFERENT METRICS DEPENDING ON TASK TYPE
switch taskType
    case {cursorConstants.TASK_CENTER_OUT, cursorConstants.TASK_PINBALL, cursorConstants.TASK_RANDOM }
        fprintf('Block %i (%.1f minutes): %i/%i trials (%.1f%%) successful. %.1f successes per minute.\n', ...
            blockNum, stat.blockDuration/60, stat.numSuccess, stat.numTrials, 100*stat.numSuccess/stat.numTrials, ...
            stat.successPerMinute );
        fprintf(' mean TTT = %.1fms, mean dialIn = %.1fms\n', nanmean( stat.TTT ), nanmean( stat.dialIn ) );
        fprintf(' %.1f%% successfully acquired on first target entry. Path efficiency = %.3f\n', ...
            100*stat.fractionSuccessOnFirstTry, nanmean( stat.pathEfficiency) );
        if isfield( stat, 'numIncorrectClicks' ) && any(~isnan( stat.numIncorrectClicks ) )
            fprintf(' %.2f incorrect clicks on average successful trial\n', mean( stat.numIncorrectClicks ) );
        else
            % not a click block. 
        end
        % Report single-dimension path efficiencies
        if size( stat.pathEfficiencyEachDim, 2 ) <= 4 %doesn't work for 5D
            for iDim = 1 : size( stat.pathEfficiencyEachDim, 2 )
               fprintf(' P.E. Dim%i: %.4g\n', ...
                   iDim, nanmean( stat.pathEfficiencyEachDim(:,iDim) ) )
            end
        end
        
    case {cursorConstants.TASK_GRIDLIKE, cursorConstants.TASK_RAYS, cursorConstants.TASK_FCC}
         fprintf('Block %i (%.1f minutes): %i/%i trials successful. %i dictionary. %.3f bits per second.\n', ...
            blockNum, stat.blockDuration/60, stat.numSuccess, stat.numTrials, stat.dictionarySize, stat.bitRate )
    
    
    otherwise
        error('quickPerf_cursorBlock not set for tasktype %i', taskType )
end


end


% figure out how to run a shell command in python

% xset -dpms
% can confirm with xset q

% fdisk -l 
% df -h
% dd if=oldOne of=newOne bs=1M