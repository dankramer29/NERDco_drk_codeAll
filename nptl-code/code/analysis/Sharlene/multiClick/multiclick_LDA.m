% training an LDA 
% W = LDA(Input,Target,Priors)
% input = neural data, channels = columns , rows = timw 
% target = clickTarg 
% make a matrix that stretches the (discrete) clickType 
clickTypeL = nan(size(binnedR_All.rawSpikes, 1),1); 

for i = 1:length(trialStarts) 
   if i < length(trialStarts)
    clickTypeL([trialStarts(i)+1:trialStarts(i+1)] - trialStarts(1)) = zeros(trialStarts(i+1)-trialStarts(i),1)+double(binnedR_All.clickType(i));  
   else
    clickTypeL([trialStarts(i)+1:end] - trialStarts(1)) = zeros(length(clickTypeL)-trialStarts(i),1)+double(binnedR_All.clickType(i)); 
   end
end
%%
halfway = floor(length(clickTypeL)/20); 
W = LDA(binnedR_All.rawSpikes(1:halfway, :), clickTypeL(1:halfway)');
L = [ones(halfway, 1), binnedR_All.rawSpikes(1:halfway, :)]*W'; 
pClass = exp(L)./(repmat(sum(exp(L),2),[1,5])); %this should give the guess of target
[prob, predictedClass] = max(pClass') ; % the guessed target and its prob
accuracy = (predictedClass'-1) == clickTypeL(1:halfway); 
% test on witheld data next? 