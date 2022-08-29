% change multiclick parameters here so they are uniform across blocks
%% closed loop 
centerTime = 500; %this is for dwell target hold (center target) which also is the recenter delay
setModelParam('holdTime', centerTime);
setModelParam('trialTimeout', 9000);
setModelParam('autoplayMovementDuration', 2250);
setModelParam('soundOnOverTarget', false);
%setModelParam('numTrials', 160); % real
setModelParam('numTrials', 64); % dev
% max task duration
setModelParam('maxTaskTime',1000*60*12);
curThresh = 0.96;
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables
setModelParam('clickHoldTime', uint16(80));

setModelParam('recenterOnSuccess', true); %SNF: skip recenter for CL trials 
setModelParam('recenterDelay',centerTime); %how long you hold on the center target 
