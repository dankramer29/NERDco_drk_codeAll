function out=calcBitrate(R)
% CALCBITRATE    
% 
% out=calcBitrate(R)


a = allKeyboards();
q = a(R(1).startTrialParams.keyboard);
numKeys = q.keys(1).numKeys;

totalTime = double(R(end).endcounter-R(1).startcounter)/1000;

numTrials = numel(R);

stp = [R.startTrialParams];
numSuccess=sum([R.selected]==[stp.cuedTarget]);
numFailures = numTrials-numSuccess;
bits = log2(numKeys) * (numSuccess - numFailures);

disp(sprintf('%gx%g: %g trials, %g correct, %02.1f%%, %.1f seconds -> %.2f bits/sec', ...
        sqrt(numKeys), sqrt(numKeys), numTrials, numSuccess, double(numSuccess)/double(numTrials)*100, totalTime, ...
        bits / totalTime));
