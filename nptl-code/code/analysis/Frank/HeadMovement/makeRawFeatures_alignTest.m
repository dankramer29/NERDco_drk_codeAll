dataset = load('/Users/frankwillett/Data/BG Datasets/movementSweepDatasets/t7.2013.08.23/Data/SLC Data/SLCdata_2013_0823_165406(4).mat');
dataset = dataset.SLCdata;

features = load('/Users/frankwillett/features/t7.2013.08.23 Whole body cued movts, new cable (TOUCH)/4 LFP.mat');

nArrays = 2;
offset = zeros(nArrays,1);
arrayChanSets = {1:96,97:192};
for a=1:nArrays
    spikePowFeature = features.bandPowAllArrays{a}{1};
    slcSpikePow = dataset.spikePower.values(:,arrayChanSets{a});
    
    chanLags = zeros(size(spikePowFeature,2),1);
    for chan=1:size(spikePowFeature,2)
        [r,lags]=xcorr(spikePowFeature(:,chan), slcSpikePow(:,chan),'none');
        [~,maxIdx] = max(r);
        chanLags(chan) = lags(maxIdx);
    end
    offset(a) = median(chanLags);
end

nArrays = 2;
arrayChans = {1:96, 97:192};
for a=1:nArrays
    sp_ns = lfp_ns5.bandPowAllArrays{a}{1};
    if offset(a)>0
        sp_ns = sp_ns((offset(a)+1):end,:);
        endIdx = min(length(loopIdx), length(sp_ns));
        sp(loopIdx(1:endIdx),arrayChans{a}) = sp_ns(1:endIdx,:);
        for t=1:size(tx_ns5.binnedTX,2)
            tx_ns = tx_ns5.binnedTX{a,t};
            tx_ns = tx_ns((offset(a)+1):end,:);
            endIdx = min(length(loopIdx), length(tx_ns));
            tx(loopIdx(1:endIdx),arrayChans{a},t) = tx_ns(1:endIdx,:);
        end
    elseif offset(a)<0
        error('Negative offset, figure this out');
    end
end