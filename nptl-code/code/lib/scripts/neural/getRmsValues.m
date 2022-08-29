function rms = getRmsValues(nsxFile, useTimes, filterType, useCAR)

switch class(useTimes)
    case 'double'
        disp('Assuming input time values are in seconds')
        cerebusSampleInds = useTimes*30000;
    case 'uint32'
        disp('Assuming input time values are cerebus sample indices');
        cerebusSampleInds = useTimes;
    otherwise
        disp(useTimes);
        assert(false, 'Dont know how to handle this');
end

if ~exist('filterType','var')
    filterType = 'spikesmedium';
end

if ~exist('useCAR','var')
    useCAR = true;
end


ns5 = openNSx(nsxFile, 'read', ['t:' num2str(cerebusSampleInds(1)) ':' num2str(cerebusSampleInds(2))]);
% Apply common average referencing
ns5.Data = single(ns5.Data');
% 
% if useCAR
%     ns5.Data = ns5.Data - mean(ns5.Data, 2) * ones(1, size(ns5.Data, 2));
% end
% 

if isempty(filterType)
    spikeBandData = ns5.Data;
else
    switch lower(filterType)
        case 'spikesmedium'
            % Spike Band filter (may want to change this or have it selectable via param)
            filt = spikesMediumFilter();
        case 'spikeswide'
            filt = spikesWideFilter();
        case 'spikesnarrow'
            filt = spikesNarrowFilter();
    end
    
    filt.PersistentMemory = true; % allow successive filtering
    spikeBandData = filt.filter(ns5.Data);
end

if useCAR
    spikeBandData = spikeBandData - mean(spikeBandData, 2) * ones(1, size(spikeBandData, 2));
end

rms = std(spikeBandData(1:end, :));
