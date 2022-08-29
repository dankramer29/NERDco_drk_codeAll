function [ R ] = addSortedRaster(R, packaged, blockList)
    nUnits = size(packaged.unitIdentity,1);

    for t=1:length(R)
        disp(t);
        R(t).spikeRaster = zeros(nUnits, length(R(t).clock));
        [~,blockIdx] = ismember(R(t).blockNum, blockList);
        for n=1:nUnits
            arrayIdx = packaged.unitIdentity(n,2);
            trlSpikesIdx = packaged.spikeTimesPerBlock{n}{blockIdx} >= R(t).firstCerebusTime(arrayIdx,1)/30 & ...
                packaged.spikeTimesPerBlock{n}{blockIdx} <= R(t).lastCerebusTime(arrayIdx,end)/30;
            trlSpikes = packaged.spikeTimesPerBlock{n}{blockIdx}(trlSpikesIdx);
            if ~isempty(trlSpikes)
                rastCounts = histc(trlSpikes, [R(t).firstCerebusTime(arrayIdx,:), R(t).lastCerebusTime(arrayIdx,end)+1]/30);
                R(t).spikeRaster(n,:) = rastCounts(1:(end-1));
            end
        end
    end
end
