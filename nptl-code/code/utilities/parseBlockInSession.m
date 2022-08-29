function [R, taskDetails] =parseBlockInSession(blockNum, saveBlock, reprocess, pre, rdir)
% PARSEBLOCKINSESSION    
% 
% [R, taskDetails] =parseBlockInSession(blockNum, saveBlock, reprocess, pre, rdir)


    global modelConstants

    if ~exist('saveBlock','var')
        saveBlock = true;
    end
    if ~exist('reprocess','var')
        reprocess = false;
    end
    if ~exist('pre','var')
        pre = [modelConstants.sessionRoot '/' ];
    end
    
    %% saved Rstruct directory
%     spath = [pre 'session/data/blocks/matStructs/'];
    if ~exist('rdir','var')
        spath = [pre modelConstants.dataDir 'R/'];
    else
        spath = rdir;
    end
    
    rfn = [spath 'R_' num2str(blockNum) '.mat'];
    if exist(rfn,'file') && ~reprocess
        tmp = load(rfn);
        try
            R = tmp.R;
            taskDetails = tmp.taskDetails;
            return
        catch
            disp(['loading didnt work: ' rfn]);
        end
    end

    dpath = [pre modelConstants.dataDir 'FileLogger/'];
    [R, taskDetails] = onlineR([dpath num2str(blockNum) '/'], blockNum);
    if saveBlock
        % check for the output directory, create if it doesn't exist
        if ~isdir(spath)
            disp(['Creating directory ' spath]);
            mkdir(spath)
        end
        save(rfn, 'R', 'taskDetails');
    end
