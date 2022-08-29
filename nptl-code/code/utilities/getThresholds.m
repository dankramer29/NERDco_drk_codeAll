function [thresholds] = getThresholds(R)
% GETTHRESHOLDS    
% 
% [thresholds] = getThresholds(R)

if isfield(R(1),'meanSquared')
    meanSquared = [R.meanSquared];
    meanSquaredChannel = [R.meanSquaredChannel];
else
    meanSquared = [R.meanSquaredAcaus];
    meanSquaredChannel = [R.meanSquaredAcausChannel];

end

numCh = max(meanSquaredChannel');

for narray = 1:numel(numCh)
    for ch = 1:numCh(narray)
        thresholds(ch +(narray-1)*double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)) = ...
            sqrt(mean(meanSquared(narray,meanSquaredChannel(narray,:) == ch)));
    end
end

    