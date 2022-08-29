function enableSpeedScaling(spread)

setModelParam('hmmSpeedScalingBins',0:0.05:0.45');
x=[ zeros(1,3)+0.5-spread 0.5-spread/2 0.5 0.5+spread/2 zeros(1,4)+0.5+spread;
    zeros(1,3)+0.5+spread 0.5+spread/2 0.5 0.5-spread/2 zeros(1,4)+0.5-spread;
    ones(1,10)];
setModelParam('hmmSpeedScalingPs',x);
setModelParam('hmmSpeedScalingEnable',true);