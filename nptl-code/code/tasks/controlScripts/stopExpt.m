function stopExpt

global tg
global modelConstants


if(strcmp(questdlg('Should I stop the experiment NOW?'), 'Yes'))
    stopLocalViz();
    udpFileWriter('Stop');
    if isempty(tg)
        error('dont know what machine is the target');
    end
    try
        -tg;
    catch
        disp('couldn''t stop model');
    end
    
    %% get the previous running block number and display it.
    try 
        bnum = getModelParam('blockNumber');
        disp(sprintf('That was block %g', bnum));
    catch
        disp('Warning: couldnt get previous block number');
    end

    %% try to log some data about that block
    logBlockData(bnum);
%     try
%         blockStopTime = now();
%         b=getBlockEntryFromLog(bnum);
%         if isempty(b)
%             warning('couldn''t find info about that last block in the log...');
%             b=struct();
%             b.blockNum = bnum;
%         end
%         b.systemStopTime = blockStopTime;
%         
%         dirname = [modelConstants.sessionRoot modelConstants.filelogging.outputDirectory num2str(bnum)];
%         stream = parseDataDirectoryBlock(dirname, {'meanTracking','neural'});
%         b.taskName = stream.taskDetails.taskName;
%         b.runtimeMS = calculateBlockRuntime(stream);
%         if isempty(stream.decoderD)
%             b.filter = []; b.discreteFilter = [];
%         else
%             b.filter = char(stream.decoderD.filterName(end,stream.decoderD.filterName(end,:)>0));
%             b.discreteFilter = char(stream.decoderD.discreteFilterName(end,stream.decoderD.discreteFilterName(end,:)>0));
%         end
%         [b.biasEstimate, b.meansEstimate] = getFinalBiasEstimate(stream);
%         updateBlockEntryInLog(bnum,b);
%     catch
%         errstr = lasterror();
%         warning('stopExpt: couldn''t log data about that block: %s', errstr.message);
%     end
    clear bnum
    
    % reboot xpc because of xpc model loading / starting / resetting
    % weirdness,  2016-08-24
%    pause(2);
%    tg.reboot;
    
    % reset viz & sound because, broken - Paul 2016/10/04
    resetVizAndSound;

    switch modelConstants.cerebus.cbmexVer
        case '601'
            cbmexfun = @cbmex_601;
        case '603'
            cbmexfun = @cbmex_603;
        case '605'
            cbmexfun = @cbmex_605;
        case '60502'
            cbmexfun = @cbmex_605; % HACK HACK HACK HACK
    end

    % do we want to us central and log ns5s ?
    do_nsp_filerecord = true; %% TEMP HACK TO AVOID NSP FILERECORD 
    if modelConstants.isSim % don't try filerecorder for simulator
        do_nsp_filerecord = false;
    end

if do_nsp_filerecord
    switch modelConstants.rig
        case 't6'
            cbmexfun('fileconfig','','',0); % stop file recorder
            % close cbmex
            cbmexfun('close');
        case 't5'
            try % try catch because without Cerebii (rigH) this fails.
                % close cbmex
                cbmexfun('fileconfig','','',0,'instance',1); % stop file recorder
                % close cbmex
                cbmexfun('close','instance',1);
                % close cbmex
                cbmexfun('fileconfig','','',0,'instance',2); % stop file recorder
                % close cbmex
                cbmexfun('close','instance',2);
            catch
                
            end
        case 't9'
            cbmexfun('fileconfig','','',0); % stop file recorder
            % close cbmex
            cbmexfun('close');
            cbmexfun('fileconfig','','',0,'instance',1); % stop file recorder
            % close cbmex
            cbmexfun('close','instance',1);
    end
end    
    if strcmp(modelConstants.rig,'t7') && ~modelConstants.isSim
        %% start up an rsync to nptl2
        rsyncToNptl2();
    end
    
    %% delayed params updates - commented out by CP, 2014-10-15
    % global remoteParamTimerObj
    % stop(remoteParamTimerObj);
    
end
