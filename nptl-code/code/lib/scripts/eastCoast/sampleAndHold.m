function [rebinned,fullLength]=sampleAndHold(binEdges,binnedValues)
% SAMPLEANDHOLD    
% 
% sampleAndHold(binEdges,binnedValues)
%
% take data that is binned with the larger bin width (with edges specifed by 'binEdges')
%    and return it at unitary bin width, with values sampled and held 
%    
% binnedValues should be N x T, where T is time (T should equal length(binEdges)-1)
    
    binEdges=binEdges-binEdges(1);
    fullLength=round(binEdges(end));
    
    
    rebinned=zeros([size(binnedValues,1) fullLength]);
    for nn=1:length(binEdges)-1
        newStart=max([1 round(binEdges(nn))+1]);
        newEnd=max([round(binEdges(nn+1)) 1]);
        
        rebinned(:,newStart:newEnd)=repmat(binnedValues(:,nn),[1 1+newEnd-newStart]);
    end
