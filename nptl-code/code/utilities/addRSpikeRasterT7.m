function R = addSpikeRasterT7(R)
% R = addSpikeRasterT7(R)
%
% adds T7 spikeRaster

thresholds = [-80*ones(1, 96) -95*ones(1, 96)]';

R = addRSpikeRaster(R, thresholds);
