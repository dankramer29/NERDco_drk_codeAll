function [rates,stds] = getRestRate(R, toKeep, thresh, binsize)
% GETRESTRATE    
% 
% [rates,stds] = getRestRate(R, toKeep, thresh, binsize)

    for nt = 1:length(R)
        trialEnd = length(R(nt).clock);
        restPeriod = R(nt).restCue:trialEnd;
        
        restPeriod=restPeriod(end-toKeep+1:end);
        
        rest(nt).spikes = R(nt).minAcausSpikeBand(:,restPeriod);
    end
    
    allspikes = [rest.spikes];
    
    for nc = 1:size(allspikes,1)
        allspikes(nc,:)=allspikes(nc,:)<thresh(nc);
    end
    
    sumspikes = cumsum(allspikes,2);
    binned = diff(sumspikes(:,1:binsize:end),1,2) * 1000 / binsize;
    
    rates = mean(binned,2);
    stds = std(binned,0,2);
