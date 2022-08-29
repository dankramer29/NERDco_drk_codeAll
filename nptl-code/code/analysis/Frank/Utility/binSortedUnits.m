function binSortedUnits(sortDir, R, binMs)

    %normalize features
    cerebusTime = [R.firstCerebusTime]';
    nLoops = (length(cerebusTime)/int32(binMs));
    
    trlBlockNums = zeros(size(R));
    for t=1:length(R)
        trlBlockNums(t) = R(t).startTrialParams.blockNumber;
    end
    [blockList,~,blockCode] = unique(trlBlockNums);
    nBlocks = length(blockList);
    
    allBinnedRates = zeros(nLoops, 300);
    unitChan = [];
    unitClass = [];
    globalIdx = 1;

    for c=1:192
        disp(c);
        fileName = [sortDir filesep 'chan' num2str(c) ' sorted spikes.mat'];
        if ~exist(fileName,'file')
            continue;
        end

        tmp=load(fileName);
        nUnits = max(unique(tmp.cluster_class(:,1)));
        if nUnits==0
            continue;
        end

        for n=1:nUnits
            unitChan = [unitChan; c];
            unitClass = [unitClass; n];
            globalLoopIdx = 1;
            for b=1:nBlocks
                trlIdx = find(trlBlockNums==blockList(b));
                allClocks = [R(trlIdx).firstCerebusTime]';
                if c<=96
                    clock = allClocks(:,1);
                else
                    clock = allClocks(:,2);
                end
                clock = double(clock)/30000;
                clock = clock(1:binMs:end);
                
                if b==1
                    spikeTimes = tmp.index/1000;
                else
                    spikeTimes = tmp.index/1000 - tmp.ns5Breaks(b-1)/30000;
                end
                spikeTimes = spikeTimes(tmp.cluster_class(:,1)==n);
                fr = binFiringRatesAtRBE( {{spikeTimes}}, binMS/1000, clock );
                allBinnedRates(globalLoopIdx:(globalLoopIdx+length(fr)-1),globalIdx) = fr;
                globalLoopIdx = globalLoopIdx + length(clock);
            end
            globalIdx = globalIdx + 1;
        end
    end

    allBinnedRates(:,globalIdx:end)=[];
    save([sortDir filesep 'binnedRates'],'allBinnedRates','unitChan','unitClass');
end %function