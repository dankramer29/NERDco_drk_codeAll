function z=getFiringRates(R,dt,thresh,spikefield)
% GETFIRINGRATES    
% 
% z=getFiringRates(R,dt,thresh,spikefield)

    if ~exist('spikefield','var')
        spikefield = 'minAcausSpikeBand';
    end
    
    if length(thresh) ==1
        thresh = repmat(thresh,size(R(1).(spikefield),1),1);
    end

    allData = [R.(spikefield)];
    spikes = zeros(size(allData),'single');
    for nc =1:length(thresh)
        spikes(nc,:) = allData(nc,:) < thresh(nc);
    end

    sumspikes = cumsum(spikes');
    
    z = diff(sumspikes(1:dt:end,:))';