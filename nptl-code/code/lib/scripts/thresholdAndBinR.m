function T = thresholdAndBinR(R, channels, thresholds, dt, delayMotor)

T = struct;
for i = 1:length(R)
    raster = zeros([length(channels) size(R(i).minSpikeBand,2)]);
    for ich = 1:length(channels)
        ch = channels(ich);
        thresh = thresholds(ich);
        if(thresholds(ich) < 0)
            raster(ich, :) = R(i).minSpikeBand(ch,:) < thresh;
        else
            raster(ich, :) = R(i).maxSpikeBand(ch,:) > thresh;
        end
    end
    
    sumRaster = cumsum(raster');
    T(i).Z = diff(sumRaster(1:dt:end-delayMotor, :))';
    
    T(i).dt = dt;
    T(i).T = size(T(i).Z, 2);
    
    
end


    


    