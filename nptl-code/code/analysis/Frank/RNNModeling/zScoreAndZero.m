function [ timeSeries ] = zScoreAndZero( timeSeries )
    timeSeries = zscore(timeSeries);
    timeSeries = timeSeries - timeSeries(1,:);
end

