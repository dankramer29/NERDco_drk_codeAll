% take activity that precedes movement onset and decode target direction
% psth is unit x numTargs x numCoh x time 
% concatenate by units and targ or coh
psthPre = 75;
windowEarly = 600/20; %ms before movement onset start/ 20 ms per bin;
windowLate  = 100/20; %ms before movement onset end / 20 ms per bin; 
numTargs = 4;

%binnedR_All = binRBC2; 
windowedFR = nan(length(binnedR_All.tgt),size(binnedR_All.rawSpikes,2)*3); 
tempAll = [binRHM1, binRHM2, binRHM3];
trialCount = 0; 
for structIdx = 1:length(tempAll)
for trial = 1:length(tempAll(structIdx).tgt)
    trialCount = trialCount + 1; 
    windowedFR(trialCount, (192*(structIdx-1)+1):(192*structIdx)) = nanmean(tempAll(structIdx).rawSpikes(tempAll(structIdx).speedMO(trial)-windowEarly:tempAll(structIdx).speedMO(trial)-windowLate,:),1);
end
end
% these are all single-trial **values**: 
binnedR_All.uCoh = [binRHM1.uCoh; binRHM2.uCoh; binRHM3.uCoh];
binnedR_All.tgt = [binRHM1.tgt, binRHM2.tgt, binRHM3.tgt]'; 
binnedR_All.speedRT =   [binRHM1.speedRT; binRHM2.speedRT; binRHM3.speedRT];

UCohIdx = unique(binnedR_All.uCoh);
tgt = binnedR_All.tgt;
%
% make a super matrix of all target/coh combos: 
superMat = [tgt, binnedR_All.uCoh, windowedFR]; 
[B, idx] = sortrows(superMat);
%% build test and train specific PSTHes 
% split into random groups:  
for selTarg = 1:numTargs
RTbins = [20:20:300]; 
cohs = unique(binnedR_All.uCoh); 
trialRTbin = zeros(1,length(tgt)); 
trainTrials =find((binnedR_All.tgt == selTarg) & binnedR_All.uCoh > UCohIdx(2)); %day 1 doesn't have 0.004
%get random subset of trials to train and test on: 
testTrialsIdx = randperm(length(trainTrials), floor(length(trainTrials) / 5)); % 20% test trials
testTrials = trainTrials(testTrialsIdx); 
trainTrials(testTrialsIdx) = [];
%windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.rawSpikes,2)); 
for trial = 1:length(binnedR_All.tgt)
  %  windowedFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.speedMO(trial)-windowEarly:binnedR_All.speedMO(trial)-windowLate,:),1);
    if ~isnan(binnedR_All.speedRT(trial))
        if binnedR_All.speedRT(trial) < RTbins(1)
            trialRTbin(trial) = 1; 
        else
            trialRTbin(trial) = find(RTbins <= binnedR_All.speedRT(trial), 1, 'last');
        end
    else
        trialRTbin(trial) = nan;
    end
end
% eliminate unused RTBins:
% killIdx = [];
% for i = 1:length(RTbins)
%     if sum(trialRTbin == i) < 5
%         killIdx = [killIdx, i];
%     end
% end
% RTbins(killIdx) = [];
%% train on train trials
table_All = array2table(windowedFR(trainTrials,:)); 
classLabelTarg = binnedR_All.tgt(trainTrials)';  
classLabelCoh  = binnedR_All.uCoh(trainTrials);  
classLabelRT = trialRTbin(trainTrials'); %binnedR_All.speedRT(trainTrials); 

Mdl_targ = fitcnb(table_All, classLabelTarg);
Mdl_coh  = fitcnb(table_All, classLabelCoh);
%Mdl_RT  = fitcnb(table_All, classLabelRT);
%% test on test trials

predictedTarg = predict(Mdl_targ, windowedFR(testTrials,:) ); 
predictedCoh  = predict(Mdl_coh,  windowedFR(testTrials,:) );
%predictedRT  = predict(Mdl_RT,  windowedFR(testTrials,:) );
actualTarg = binnedR_All.tgt(testTrials)'; 
actualCoh = binnedR_All.uCoh(testTrials); 
%actualRT = trialRTbin(testTrials)'; 
classifierAccuracy_targs = sum(predictedTarg == actualTarg)/length(predictedTarg);
classifierAccuracy_cohs  = sum(predictedCoh  == actualCoh)/length(predictedCoh);
%classifierAccuracy_RTs  = sum(predictedRT  == actualRT)/length(predictedRT);
%% confusion matrices forever
cmat_targ = zeros(length(unique(actualTarg))); 
cmat_coh = zeros(length(unique(actualCoh)));
targMat = [actualTarg, predictedTarg];
cohMat = floor([actualCoh, predictedCoh].*100);
% pushing = n x 2 matrix- column 1 = actual, column 2 = observed
responses = [];
for i = unique(targMat(:,1))'
    responses = targMat(targMat(:,1)== i, 2); 
    for j = unique(targMat(:,1))'
        cmat_targ(i, j) = sum(logical(responses == j)) / length(responses);
    end
    responses = [];
end

responses = [];
cohMatIdx = unique(cohMat(:,1));
for i = 1:length(cohMatIdx)
    responses = cohMat(cohMat(:,1)== cohMatIdx(i), 2); 
    for j = 1:length(cohMatIdx)
        cmat_coh(i, j) = sum(logical(responses == cohMatIdx(j))) / length(responses);
    end
    responses = [];
end

%figure;
subplot(1,2,1)
imagesc(cmat_targ); 
colormap pink;
axis square; 
title('Target Location Decoding')
subplot(1,2,2)
imagesc(cmat_coh); 
colormap pink;
axis square; 
title('Coherence Decoding')
cohAcc(selTarg,1) = classifierAccuracy_cohs;
end
%pause

%cmat_coh_all = cmat_coh_all + cmat_coh; 
%cmat_tgt_all = cmat_tgt_all + cmat_targ; 


% % subplot(1,3,3)
