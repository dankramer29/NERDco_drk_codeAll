function [ fr ] = binFiringRatesAtRBE( spikeTimes, binWidth, rbe )
    %this function bins spike counts to compute an estimate of firing rate
    
    %spikeTimes = cell array of spike trains
    %binWidth = width of the bin, all bins are the same width
    %rbe = time of the right bin edge for each bin
    %fr = returned firing rates
    
    %this function is slow because it allows irregularly spaced right bin
    %edges, it is much faster to assume regularly spaced bins
    %(see binFiringRates.m)
    
    %get the total number of units
    nChans = length(spikeTimes);
    nUnits = 0;
    for c=1:nChans
        a = size(spikeTimes{c},1);
        nUnits = nUnits + a;
    end
    
    %compute count in each bin
    nBins = length(rbe);
    fr = zeros(nBins,nUnits);
    unitIdx = 0;
    
    for c=1:nChans
        %disp(['Channel - ' num2str(c)]);
        nUnitsOnChan = length(spikeTimes{c});
        for n=1:nUnitsOnChan
            unitIdx = unitIdx+1;
            for b=1:nBins
                fr(b,unitIdx) = sum(spikeTimes{c}{n}<rbe(b) & spikeTimes{c}{n}>=(rbe(b)-binWidth));
            end
        end
    end

    %compute firing rate in HZ
    fr = fr/binWidth;
end

