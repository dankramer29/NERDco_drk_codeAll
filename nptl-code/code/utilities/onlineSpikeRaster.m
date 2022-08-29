function R = onlineSpikeRaster(R,th)
    for nt = 1:length(R)
        if isfield(R(1),'minSpikeBand')
            R(nt).spikeRaster = sparse(zeros(size(R(nt).minSpikeBand)));
            for nc = 1:length(th)
                if th(nc) > 0
                    R(nt).spikeRaster(nc,:) = R(nt).maxSpikeBand(nc,:) > th(nc);
                else
                    R(nt).spikeRaster(nc,:) = R(nt).minSpikeBand(nc,:) < th(nc);
                end
            end
        else
            
            for nc = 1:length(th)
                R(nt).spikeRaster(nc,:) = R(nt).minAcausSpikeBand(nc,:) < th(nc);
            end
        end
    end