function out = bitRateMC(Rin, numClicks)

for block = 1:length(Rin) 
    R = Rin{block}; 
    delIdx = [R.clickTarget] == 0;
    out(block).trialTime = [R.trialLength]; 
    out(block).trialTime(delIdx) = [];
    out(block).success = [R.isSuccessful];
    out(block).success(delIdx) = [];
   
    out(block).numTargs = numClicks.*8; 
    out(block).bitRate = log2(out(block).numTargs-1)*max(sum(out(block).success)-sum(out(block).success == 0),0) /  (sum(out(block).trialTime) / 1000); %(sum(res(block).trialTime(res(block).success == 1)) / 1000); %should this only be of the successful trials? 
    
end
