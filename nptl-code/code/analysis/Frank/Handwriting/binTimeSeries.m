function [ newData ] = binTimeSeries( data, binSize, summaryFun )
    if nargin<3
        summaryFun = @mean;
    end
    
    nSteps = floor(size(data,1)/binSize);
    
    sz = size(data);
    newData = zeros([nSteps, sz(2:end)]);
    
    binIdx = 1:binSize;
    for t=1:nSteps
        newData(t,:) = squeeze(summaryFun(data(binIdx,:),1));
        binIdx = binIdx + binSize;
    end
end

