% change multiclick parameters here so they are uniform across blocks
%% open loop 
% lower hold time for open loop
setModelParam('holdTime', 900);
setModelParam('trialTimeout', 5000);
setModelParam('autoplayMovementDuration', 1750);

%setModelParam('numTrials', 32); % dev
 setModelParam('numTrials', 128); % decoder building
% max task duration
setModelParam('maxTaskTime',1000*60*8); %SF: make it long enough to do 160 trials
