function dataset = formatEast2DDataset( sess, saveDir, sessDir )
    blockList = sess{2};
    
    dataset.blockList = blockList;
    dataset.targetSize = [];
    dataset.cursorSize = [];
    dataset.blockNums = [];
    dataset.sysClock = [];
    dataset.nspClocks = [];
    dataset.cursorPos = [];
    dataset.targetPos = [];
    dataset.onTarget = [];
    dataset.spikePow = [];
    dataset.decVel = [];
    dataset.decClick = [];
    dataset.TX = [];
    dataset.TX_thresh = -3.5;
    dataset.decodingClick = [];
    dataset.trialEpochs = [];
    dataset.instructedDelays = [];
    dataset.intertrialPeriods = [];
    dataset.gameNames = [];
    dataset.isSuccessful = [];
    dataset.syncSig = [];
    
    globalIdx = 1;
    
    for b=1:length(blockList)
        disp(blockList(b));
        slcPath = [sessDir filesep sess{1} filesep 'Data' filesep 'SLC Data' filesep];
        ftmp = dir([slcPath '*(' num2str(blockList(b)) ')*']);
        slc = load([slcPath ftmp(end).name]);
        
        ncsPath = [sessDir filesep sess{1} filesep 'Data' filesep 'NCS Data' filesep];
        ftmp = dir([ncsPath 'Blocks*(' num2str(blockList(b)) ')*']);
        ncs = load([ncsPath ftmp(end).name]);
        
        tsCol = find(strcmp(slc.task.auxiliary.header,'targetSize'));
        dataset.targetSize = [dataset.targetSize; slc.task.auxiliary.values(:,tsCol)]; 
        
        nLoops = size(slc.task.auxiliary.values,1);
        dataset.blockNums = [dataset.blockNums; repmat(blockList(b),nLoops,1)];
        dataset.sysClock = [dataset.sysClock; slc.clocks.sysClk];
        dataset.nspClocks = [dataset.nspClocks; [slc.clocks.nspClock, slc.clocks.nsp2Clock]];
        dataset.cursorPos = [dataset.cursorPos; slc.task.receivedKin.values(:,1:2)];
        dataset.targetPos = [dataset.targetPos; slc.task.goal.values(:,1:2)];
        
        onTargCol = find(strcmp(slc.task.auxiliary.header,'onTargetFlag'));
        dataset.onTarget = [dataset.onTarget; slc.task.auxiliary.values(:,onTargCol)];
        
        dataset.spikePow = [dataset.spikePow; slc.spikePower.values];
        dataset.TX = [dataset.TX; slc.ncTX.values];
        
        dataset.decVel = [dataset.decVel; slc.task.decodedKin(:,1:2)];
        dataset.decClick = [dataset.decClick; slc.task.decodedState];
        dataset.decodingClick = [dataset.decodingClick; sum(slc.task.decodedState~=0)>5];
        
        dataset.syncSig = [dataset.syncSig; slc.clocks.syncPulse];
        
        %simple segmentation
        targChangeIdx = find(any(abs(diff(slc.task.goal.values(:,1:2)))>0,2))+1;
        newTrials = [targChangeIdx, [targChangeIdx(2:end)-1; nLoops]] + globalIdx;
        globalIdx = globalIdx + nLoops;
        dataset.trialEpochs = [dataset.trialEpochs; newTrials];
        
        %game type
        dataset.gameNames = [dataset.gameNames, {ncs.singleBlock.sGInt.GameName}];
    end
    
    dataset.instructedDelays = nan(size(dataset.trialEpochs));
    dataset.intertrialPeriods = nan(size(dataset.trialEpochs)); 
    
    save([saveDir filesep sess{1} '.mat'],'dataset');
end

