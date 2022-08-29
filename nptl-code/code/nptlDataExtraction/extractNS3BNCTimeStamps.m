function siTot=extractNS3BNCTimeStamps(nevPref)
    
    NS3 = openNSx([nevPref '.ns3'],'read');
    zeroOne = uint32(1431655765); % the bits of this number alternate between 0 and 1
    
    %% how to find the start of a frame:
    %%    find four 'zeroOne's in a row
    
    %% if NS3.Data is a cell array, then this is a file with pauses/startup synchronization.
    if ~iscell(NS3.Data)
        NS3Data{1} =NS3.Data;
    else
        NS3Data = NS3.Data;
    end

    for nc = 1:length(NS3Data)
        %% skip segments that are <10 seconds long - these are likely NSP startup synch periods
        if size(NS3Data{nc},2) < 10*2000
            continue
        end
        %% first find a '1'
        data = (NS3Data{nc}>0.5e4);
        
        timerStartInd = min(find(data));
        %% cerebus is sampling at 2khz. discard every other sample
        dataShift{1} = data(timerStartInd:2:end);
        dataShift{2} = data(timerStartInd+1:2:end);

        cbStartTime = (timerStartInd)/2;

        %% now do a sliding window until we find four zeroOnes in a row - The middle of this
        %%    is the transition between one frame and the next
        fourZeroOnes = repmat(fliplr(['0' dec2bin(zeroOne)] == '1'), [1 4]);
        %% for some reason there is a 16bit blank spot in the 'fourZeroOnes' signal being output
        %fourZeroOnes(64+(1:16))=0;
        %% nope, not anymore

        startingTimePoint = 0;
        numBlocks = 0;
        while startingTimePoint < length(dataShift{1})-length(fourZeroOnes)
            xpcStartInd = getStartingTimePoint(dataShift{1},startingTimePoint);
            thisBlockData=1;
            if isempty(xpcStartInd)
                xpcStartInd = getStartingTimePoint(dataShift{2},startingTimePoint);
                thisBlockData = 2;
            end
            
            if ~isempty(xpcStartInd)
                startingTimePoint = xpcStartInd+1;
                xpcEndInd = getEndingTimePoint(dataShift{thisBlockData},xpcStartInd+192-65);
            end
            
            if exist('xpcEndInd','var') & ~isempty(xpcEndInd) ...
                    & (xpcStartInd+192<=xpcEndInd)
                numBlocks = numBlocks+1;
                blockStarts(numBlocks) = xpcStartInd; 
                blockEnds(numBlocks) = xpcEndInd;
                datasetToUse(numBlocks) = thisBlockData;
                startingTimePoint = xpcEndInd;
            else
                if ~isempty(xpcStartInd)
                    startingTimePoint = startingTimePoint+1;
                else
                    startingTimePoint = length(dataShift{thisBlockData});
                end
            end
        end

        if numBlocks
            for nn = 1:numBlocks
                xpcStartInd = blockStarts(nn);
                xpcEndInd = blockEnds(nn);
                
                frameStarts = xpcStartInd:192:xpcEndInd;
                cbStartTimes = cbStartTime+frameStarts;
                
                bnLogicals = false(length(frameStarts-1),32);
                fsInds = 64+(0:31);
                thisBlockData = datasetToUse(nn);
                bnLogicals = fliplr(dataShift{thisBlockData}(repmat(frameStarts(:),[1 32]) + ...
                                              repmat(fsInds(:)',[length(frameStarts) 1])));
                
                %% this no longer seems necessary
                %    bnLogicals = circshift(bnLogicals,[0 16]);
                
                blockNums = bin2dec(char(bnLogicals+'0'));
                %blockNums = bin2dec(char(bnLogicals(:,1:16)+'0'));
                
                fsInds = 64+32+(0:31);
                clockLogicals = fliplr(dataShift{thisBlockData}(repmat(frameStarts(:),[1 32]) + ...
                                                 repmat(fsInds(:)',[length(frameStarts) 1])));
                %% this no longer seems necessary
                %clockLogicals = circshift(clockLogicals, [0 16]);
                clocks = bin2dec(char(clockLogicals+'0'));
                
                synchInfo.cbTimeMS = cbStartTime+frameStarts(:)-1;
                synchInfo.cerebusTime = synchInfo.cbTimeMS*30;
                synchInfo.blockId = blockNums(:);
                synchInfo.xpcTime = clocks(:);
                synchInfo.NEVnum = nc;
                
                if ~exist('siTot','var') | length(siTot) < nc
                    siTot(nc) = synchInfo;
                else
                    siTot(nc).cbTimeMS = [siTot(nc).cbTimeMS(:); synchInfo.cbTimeMS(:)];
                    siTot(nc).cerebusTime = [siTot(nc).cerebusTime(:); synchInfo.cerebusTime(:)];
                    siTot(nc).blockId = [siTot(nc).blockId(:); synchInfo.blockId(:)];
                    siTot(nc).xpcTime = [siTot(nc).xpcTime(:); synchInfo.xpcTime(:)];
                    siTot(nc).NEVnum = [siTot(nc).NEVnum(:);synchInfo.NEVnum(:)];
                end
            end
        end
    end
    
    if ~exist('siTot','var')
        siTot = [];
    end
    

    function stp = getStartingTimePoint(dat,nStart)
        for nn = nStart:length(dat)-length(fourZeroOnes)
            if dat(nn+(1:length(fourZeroOnes))) == fourZeroOnes
                stp = nn+65;
                return;
            end
            stp = [];
        end
    end
    
    function etp = getEndingTimePoint(dat,nStart)
        nn = nStart;
        etp = [];
        while nn < length(dat)-length(fourZeroOnes)
            if dat(nn+(1:length(fourZeroOnes))) == fourZeroOnes
                etp = nn+65 - 192;
            else
                return
            end
            nn = nn+192;
        end
    end
end

