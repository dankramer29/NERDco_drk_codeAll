addpath(genpath('/net/home/chethan/code/Q/utilities'));
clear
sessions = wristIndexDatasets();
whichSessions = 1:length(sessions);

%sessions = radial8Datasets();
%whichSessions = 1:length(sessions);

dt = 10;
rmsMult = -3.5;

includeInward = false;
addLFP = false;

totStart = tic;
for nn = whichSessions
    tic;
    datestr = sessions(nn).date;
    blocks1 = sessions(nn).touchpad;
    
    R = [];
    for nb = 1:length(blocks1)
        rstr = ['/net/derivative/R/Q/' datestr '/R_' num2str(blocks1(nb))];
        R1 = load(rstr);
        [R1.R.blockNum] = deal(blocks1(nb));
        blocks(nb).xpcStart = min([R1.R.clock])-1000;
        blocks(nb).xpcEnd = max([R1.R.clock])+1000;
        R = [R(:); R1.R(:)];
    end
    clear blocks1;
    
    %% load all the relevant continuous data
    allBlocks = unique([R.blockNum]);
    for nb = 1:length(allBlocks)
        blocks(nb).id = allBlocks(nb);
        tic;
        %% load continuous (cursorpos) data
        c3=loadvar(...
            ['/net/derivative/stream/Q/' datestr '/' num2str(allBlocks(nb))],...
            'continuous');
        toc;
        tic;
        %% load spike data
        c1=loadvar(...
            ['/net/derivative/stream/Q/' datestr '/spikeband/' num2str(allBlocks(nb))],...
            'spikeband');
        toc;
        if addLFP
            tic;
            %% load LFP data
            c2=loadvar(...
                ['/net/derivative/stream/Q/' datestr '/lfpband/' num2str(allBlocks(nb))],...
                'lfpband');
            toc;
        end
        
        
        starts = [min(c1.clock) blocks(nb).xpcStart];
        ends = [max(c1.clock) blocks(nb).xpcEnd];
        if exist('c2','var')
            starts = [starts(:);min(c2.clock)];
            ends = [starts(:);max(c2.clock)];
        end
        startTot = max(starts);
        endTot = min(ends);
        
        startInd3 = find(c3.clock==startTot);
        endInd3 = find(c3.clock==endTot);
        blocks(nb).c.clock = c3.clock(startInd3:endInd3,1);
        blocks(nb).c.cursorPosition = c3.cursorPosition(startInd3:endInd3,:);
        
        startInd1 = find(c1.clock==startTot);
        endInd1 = find(c1.clock==endTot);
        
        blocks(nb).c.xpcClock = c1.clock(startInd1:endInd1,1);
        blocks(nb).c.minSpikeBand = c1.minSpikeBand(startInd1:endInd1,:);
        blocks(nb).c.meanSquared = c1.meanSquared(startInd1:endInd1,:);
        blocks(nb).c.meanSquaredChannel = c1.meanSquaredChannel(startInd1:endInd1,1);

        if exist('c2','var')
            startInd2 = find(c2.clock==startTot);
            endInd2 = find(c2.clock==endTot);
            blocks(nb).c.gamma = c2.gamma(startInd2:endInd2,:);
        end
    end

    clear R1 c1 c2;
    
    %% get targets
    targets = double([R.posTarget]);
    prevTargets = double([R.lastPosTarget]);
    targetsi = targets(2,:)+sqrt(-1)*targets(1,:);
    centerOut = abs(targetsi)>0;
    isSuccessful = [R.isSuccessful];
    
    Rout = R(centerOut & isSuccessful);
    speedThreshold = 1;
    [alignedOut,positionsOut, rawDataOut] = alignByCondition(Rout,blocks,datestr,rmsMult,speedThreshold);

    if includeInward
        Rin = R(~centerOut & isSuccessful);
        for nt = 1:length(Rin)
            Rin(nt).posTarget = Rin(nt).lastPosTarget;
        end
        alignedIn = alignByCondition(Rin,blocks,datestr);
        %% combine the outward and inward data
        alignedInOut = [alignedOut(:); alignedIn(:)];
    else
        alignedInOut = alignedOut(:);
        positionsInOut = positionsOut(:);
        rawDataInOut = rawDataOut(:);
    end
    
    if ~exist('aligned','var')
        aligned = alignedInOut;
        positions = positionsInOut;
        rawData = {};
    else
        for nc = 1:length(alignedInOut)
            aligned(nc).A = [aligned(nc).A alignedInOut(nc).A];
            if isfield(aligned(nc),'G')
                aligned(nc).G = [aligned(nc).G alignedInOut(nc).G];
            end
            
            positions(nc).x = [positions(nc).x; positionsInOut(nc).x];
            positions(nc).y = [positions(nc).y; positionsInOut(nc).y];
        end
    end
    rawData{end+1} = rawDataInOut;
    toc;
end

disp('total time:');
toc(totStart);