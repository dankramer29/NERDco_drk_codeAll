function [minThresholds minTxInds minPvals pvalsx pvalsy] = perChannelThresholdSweep(R, T, rmsMultList)

TX = [T.X];

meanSquared = [R.meanSquared];
meanSquaredChannel = [R.meanSquaredChannel];

numCh = max(meanSquaredChannel);

Rinds = [T.trialNum];

for nch = 1:size(R(1).minSpikeBand,1)
    disp(nch)
    thresholds(nch) = sqrt(mean(meanSquared(meanSquaredChannel == nch)));
    for nrms = 1:length(rmsMultList)
        T = thresholdAndBinR(R(Rinds), nch, rmsMultList(nrms)*thresholds(nch), 50, 0);
        TZ = [T.Z];
        
        %mdl = LinearModel.fit(TX(3:4,:)', TZ(1,:)');
        keyboard
         for nn = 1:2
             h(nn) = mutualinfo(TX(2+nn,:)', TZ(1,:)');
         end
        
        ps = (mdl.anova.pValue(1:2));
        pvalsx(nch, nrms)  = ps(1);
        pvalsy(nch, nrms)  = ps(2);
    end
    
    [minx, minxind] = min(pvalsx(nch,:));
    [miny, minyind] = min(pvalsy(nch,:));
    %minThresholds(nch,:) = thresholds(nch) * rmsMultList([minxind minyind]);
    minPvals(nch,:) = [minx miny];
    if minx < miny
        minTxInds(nch) = minxind;
    else
        minTxInds(nch) = minyind;
    end
    minThresholds(nch) = thresholds(nch) * rmsMultList(minTxInds(nch));
end

