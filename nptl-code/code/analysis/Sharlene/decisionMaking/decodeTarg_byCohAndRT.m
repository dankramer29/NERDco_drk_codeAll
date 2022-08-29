% decode choice as a function of coherence/RT over time in trials
% aligned to stim onset, 0:300 ish ms
% split targets by up/dow or left/right:
%% get observations:
% set values:
psthPre = 75;
windowEarly = 0/20;   %ms before decode event onset start/ 20 ms per bin;
windowLate  = 400/20;   %ms before decode event onset end / 20 ms per bin;
stimEarly = floor(-100/20);    %ms before stimOnset
stimLate = floor(300/20);      %ms after stimOnset
numTargs = 4; %in any trial, there are only two options
k = 1; %num trials per left out chunk = numTrials / k
% prealloc
windowedFR = zeros(length(binnedR_All.tgt)*(windowLate-windowEarly),size(binnedR_All.zSpikes,2));
tgt = zeros(size(windowedFR,1),1);
coh = zeros(size(tgt));
rt = zeros(size(tgt));
trialNum = zeros(size(tgt));
ts = 0;
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
        for windStep = windowEarly:windowLate
            ts = ts+1;
            windowedFR(ts, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windStep:binnedR_All.stimOnset(trial)+windStep+10,:));
            tgt(ts) = binnedR_All.tgt(trial);
            coh(ts) = binnedR_All.uCoh(trial);
            rt(ts) = binnedR_All.speedRT(trial);
            trialNum(ts) = trial;
        end
    end
end
% build and test U/D classifier(s):
UDtrials = unique(trialNum(tgt <= 2)); %trial numbers, aka index into trial numbered things
accOverTime_All = nan(length(1:k:floor(length(UDtrials)/k)),numTargs, 1+stimLate-stimEarly);
predictedTargUD = nan(length(UDtrials), 1+stimLate-stimEarly);
tsIdx = find((tgt < 3));
table_AllUD = array2table(windowedFR(tsIdx,:));
classLabelTargUD = tgt(tsIdx); %binnedR_All.tgt(trainTrialsLR)';
Mdl_targUD = fitcnb(table_AllUD, classLabelTargUD,'KFold', numFolds);
targPredUD = Mdl_targUD.kfoldPredict;

% repeat for L/R
LRtrials = unique(trialNum(tgt >= 3)); %trial numbers, aka index into trial numbered things
predictedTargLR = nan(length(LRtrials), 1+stimLate-stimEarly);
tcount = 0;
tsIdx = find((tgt >= 3));% & (trialNum ~= testTrialsLR));
table_AllLR = array2table(windowedFR(tsIdx,:));
classLabelTargLR = tgt(tsIdx); %binnedR_All.tgt(trainTrialsLR)';
Mdl_targLR = fitcnb(table_AllLR, classLabelTargLR,'KFold', numFolds);
targPredLR = Mdl_targLR.kfoldPredict;
%%
superMat = [[trialNum(tgt<3), coh(tgt<3),tgt(tgt<3),  targPredUD]; [trialNum(tgt>=3), coh(tgt>=3), tgt(tgt>=3),  targPredLR]];
% sum(superMat(:,3) == superMat(:,4))/size(superMat,1)
prediction = nan(max(superMat(:,1)), ceil((1+windowLate-windowEarly)));
coherence = nan(max(superMat(:,1)),1);
targAxis = nan(max(superMat(:,1)), 1);
for trial = unique(superMat(:,1))'
    prediction(trial, :) = superMat(superMat(:,1) == trial, 3) == superMat(superMat(:,1) == trial, 4);
    coherence(trial) = binnedR_All.uCoh(trial); 
    targAxis(trial) = binnedR_All.stimCondMatrix(binnedR_All.stimOnset(trial),1); 
end
%%
figure;
cIdx = 0;
%cohColors = parula(6); 
cohColors = [118,42,131;...
175,141,195;...
231,212,232;...
217,240,211;...
127,191,123;...
27,120,55;...
0 0 0]./255;
tempCoh = unique(superMat(:,2))';
for targIdx = 1:2
    cIdx = 1;
    subplot(2,1,targIdx)
    for cohIdx = tempCoh(1:2:end)
       trialIdx = (targAxis == targIdx) & ((coherence == cohIdx)|(coherence == tempCoh(cIdx+1))); 
      % trialIdx = (targAxis == targIdx) & (coherence == cohIdx); 
        accuracy = nansum(prediction(trialIdx,:))/sum(trialIdx);
        plot(windowEarly:windowLate, accuracy , 'LineWidth', 2, 'Color', cohColors(cIdx,:))
        hold on;
        ax.XTick = [windowEarly:5:windowLate]+(-1*stimEarly);
        ax.XTickLabel = [windowEarly:abs(stimEarly):windowLate].*20; %ms from stim on
        ax = gca;
        cIdx = cIdx + 2;
        
    end
end
legend
%% decoder accuracy using 1 20 ms window, averaged by target. Chance = 50% bc each decoder only sees 2 options
trialTgtUD = binnedR_All.tgt(UDtrials)'; %(binnedR_All.tgt <= 2);
trialTgtLR = binnedR_All.tgt(LRtrials)';
accOverTime(1,:) = nansum(predictedTargUD == trialTgtUD) / nansum(length(trialTgtUD));
%accOverTime(2,:) = nansum(predictedTargLR == trialTgtLR) / nansum(length(trialTgtLR));
%  accOverTime(3,:) = nansum(predictedTargLR(trialTgt(LRtrials) == 3, :) == 3) / sum(trialTgt(LRtrials ) == 3);
%  accOverTime(4,:) = nansum(predictedTargLR(trialTgt(LRtrials) == 4, :) == 4) / sum(trialTgt(LRtrials) == 4);
%figure;
%subplot(3,3,5)
plot(stimEarly:stimLate, accOverTime', 'LineWidth', 2);
axis([stimEarly stimLate  0.4 1])
ax = gca;
ax.XTick = stimEarly:abs(stimEarly):stimLate;
ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
line([windowEarly, windowEarly], [0.4 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
line([windowLate, windowLate], [0.4 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
   legend({'Up/Down', 'Right/Left', 'Training Window'})
%% Split by coherence level:
%actualTargUD = binnedR_All.tgt(trainTrialsUD);
accOverTime_Coh = zeros(2, length(unique(binnedR_All.uCoh)), 1+stimLate-stimEarly);
actualCoh = binnedR_All.uCoh;
cohCount = 0;

tempCoh = unique(actualCoh);
for currentCoh = unique(actualCoh)'  %tempCoh(1:2:end)'%unique(actualCoh)'
    cohCount = cohCount + 1;
    ax = gca;
    ax.ColorOrderIndex = 1;
    accOverTime_Coh(1, cohCount, :) = nansum(predictedTargUD(trialTgt(UDtrials) == 1 & (actualCoh(UDtrials) == currentCoh)', :) == 1) / sum(trialTgt(UDtrials) == 1 & (actualCoh(UDtrials) == currentCoh)');
    
    accOverTime_Coh(2, cohCount, :) = nansum(predictedTargUD(trialTgt(UDtrials) == 2 & (actualCoh(UDtrials) == currentCoh)', :) == 2) / sum(trialTgt(UDtrials) == 2 & (actualCoh(UDtrials) == currentCoh)');
    
    %   accOverTime_Coh(3, cohCount, :) = nansum(predictedTargLR(tgt(trainTrialsLR) == 3 & (actualCoh(trainTrialsLR) == currentCoh)', :) == 3) / sum(tgt(trainTrialsLR) == 3 & (actualCoh(trainTrialsLR) == currentCoh)');
    
    %accOverTime_Coh(4, cohCount, :) = nansum(predictedTargLR(tgt(trainTrialsLR) == 4 & (actualCoh(trainTrialsLR) == currentCoh)', :) == 4) / sum(tgt(trainTrialsLR) == 4 & (actualCoh(trainTrialsLR) == currentCoh)');
end
%% plot split by coh
cohColors = flipud([242,240,247
    218,218,235
    188,189,220
    158,154,200
    128,125,186
    106,81,163
    74,20,134]./255);
%   figure;
cohCount = 1;
for currentCoh = tempCoh(1:2:end)'
    
    subplot(3,3,2)
    %   temp = nanmean(squeeze(accOverTime_Coh(1,cohCount-1:cohCount,:)));
    temp = nanmean(squeeze(accOverTime_Coh(1,cohCount:cohCount+1,:)));
    %   plot(stimEarly:stimLate,temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate,temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,4)
    temp = nanmean(squeeze(accOverTime_Coh(4,cohCount:cohCount+1,:)));
    %   plot(stimEarly:stimLate, temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,6)
    temp = nanmean(squeeze(accOverTime_Coh(3,cohCount:cohCount+1,:)));
    %   plot(stimEarly:stimLate, temp- nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,8)
    temp = nanmean(squeeze(accOverTime_Coh(2,cohCount:cohCount+1,:)));
    %  plot(stimEarly:stimLate, temp- nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    axis([stimEarly stimLate 0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    cohCount = cohCount + 2;
end
%% Split by RT:
%actualTargUD = binnedR_All.tgt(trainTrialsUD);
RTbins = [40:20:100, 150:50:300]; %lower edegs of all bins
accOverTime_RT = zeros(numTargs, length(RTbins), 1+stimLate-stimEarly);
actualRT = binnedR_All.speedRT;
rtCount = 1;
%cap the mins and max RT values
actualRT(actualRT < RTbins(1)) = RTbins(1);
actualRT(actualRT > RTbins(end)) = RTbins(end);

for currentRT = RTbins(2:end)  %tempCoh(1:2:end)'%unique(actualCoh)'
    %RT is greater than previous value, less than current value:
    
    rtIdxUD = (actualRT(trainTrialsUD) >= RTbins(rtCount))' & (actualRT(trainTrialsUD) < currentRT)';
    
    accOverTime_RT(1, rtCount, :) = nansum(predictedTargUD( (tgt(trainTrialsUD) == 1) & rtIdxUD, :) == 1) / sum([(tgt(trainTrialsUD) == 1) & rtIdxUD]);
    accOverTime_RT(2, rtCount, :) = nansum(predictedTargUD( (tgt(trainTrialsUD) == 2) & rtIdxUD, :) == 2) / sum([(tgt(trainTrialsUD) == 2) & rtIdxUD]);
    
    rtIdxLR = (actualRT(trainTrialsLR) >= RTbins(rtCount))' & (actualRT(trainTrialsLR) < currentRT)';
    
    accOverTime_RT(3, rtCount, :) = nansum(predictedTargLR( (tgt(trainTrialsLR) == 3) & rtIdxLR, :) == 3) / sum([(tgt(trainTrialsLR) == 3) & rtIdxLR]);
    accOverTime_RT(4, rtCount, :) = nansum(predictedTargLR( (tgt(trainTrialsLR) == 4) & rtIdxLR, :) == 4) / sum([(tgt(trainTrialsLR) == 4) & rtIdxLR]);
    
    rtCount = rtCount + 1;
end
%% plot split by RT
rtColors = flipud([237,248,233
    199,233,192
    161,217,155
    116,196,118
    65,171,93
    35,139,69
    0,90,50
    0, 0, 0]./255); %fastest = black
figure;
rtCount = 1;
for currentRT = RTbins(1:2:end)
    
    subplot(3,3,2)
    %   temp = nanmean(squeeze(accOverTime_Coh(1,cohCount-1:cohCount,:)));
    temp = nanmean(squeeze(accOverTime_RT(1,rtCount:rtCount+2,:)));
    %   plot(stimEarly:stimLate,temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate,temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,4)
    temp = nanmean(squeeze(accOverTime_RT(4,rtCount:rtCount+2,:)));
    %   plot(stimEarly:stimLate, temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,6)
    temp = nanmean(squeeze(accOverTime_RT(3,rtCount:rtCount+2,:)));
    %   plot(stimEarly:stimLate, temp- nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
    axis([stimEarly stimLate  0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    
    subplot(3,3,8)
    temp = nanmean(squeeze(accOverTime_RT(2,rtCount:rtCount+2,:)));
    %  plot(stimEarly:stimLate, temp- nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
    plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
    axis([stimEarly stimLate 0.4 1])
    ax = gca;
    ax.XTick = stimEarly:abs(stimEarly):stimLate;
    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
    hold on;
    rtCount = rtCount + 2;
end
