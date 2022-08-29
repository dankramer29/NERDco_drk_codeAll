function R = onlineSpikeRaster(R)
if isfield(R(1),'minSpikeBand')
    lastRMS = zeros(size(R(1).minSpikeBand,1),1);
    allRMS = sqrt([R.meanSquared]);
    allRMSinds = [R.meanSquaredChannel];
    for nc = 1:size(lastRMS,1)
        lastRMS(nc) = allRMS(min(find(allRMSinds==nc)));
    end
    
    for nt = 1:length(R)
        R(nt).rms = zeros(size(R(nt).minSpikeBand));
        for nn = 1:size(R(nt).minSpikeBand,2)
            if R(nt).meanSquaredChannel(nn)
                lastRMS(R(nt).meanSquaredChannel(nn)) = sqrt(R(nt).meanSquared(nn));
            end
            R(nt).rms(:,nn) = lastRMS;
        end
    end
else
    lastRMS = zeros(size(R(1).minAcausSpikeBand,1),1);
    allRMS = sqrt([R.meanSquaredAcaus]);
    allRMSinds = [R.meanSquaredAcausChannel];
    for nc = 1:96 %size(lastRMS,1)
        lastRMS(nc) = allRMS(min(find(allRMSinds==nc)));
    end
    
    for nt = 1:length(R)
        R(nt).rms = zeros(size(R(nt).minAcausSpikeBand));
        for nn = 1:size(R(nt).minAcausSpikeBand,2)
            if R(nt).meanSquaredAcausChannel(nn)
                lastRMS(R(nt).meanSquaredAcausChannel(nn)) = sqrt(R(nt).meanSquaredAcaus(nn));
            end
            R(nt).rms(:,nn) = lastRMS;
        end
    end
end
