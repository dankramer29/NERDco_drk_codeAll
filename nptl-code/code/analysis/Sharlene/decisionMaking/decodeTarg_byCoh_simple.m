% decode choice as a function of coherence/RT over time in trials
% aligned to stim onset, 0:300 ish ms
% split targets by up/dow or left/right: 
psthPre = 75;
windowEarly = 100/20;   %ms before decode event onset start/ 20 ms per bin;
windowLate  = 300/20;   %ms before decode event onset end / 20 ms per bin; 
stimEarly = floor(-40/20);    %ms before stimOnset
stimLate = floor(500/20);      %ms after stimOnset
numTargs = 4; %in any trial, there are only two options 

%% get observations: 
%windowedFR = zeros(length(binnedR_All.tgt)*(windowLate-windowEarly),size(binnedR_All.zSpikes,2));
windowedFR = zeros(length(binnedR_All.tgt)*(windowLate-windowEarly),size(binnedR_All.zSpikes,2));
tgt = zeros(size(windowedFR,1),1);
coh = zeros(size(tgt));
rt = zeros(size(tgt));
trialNum = zeros(size(tgt));
ts = 0;
for trial = 1:length(binnedR_All.tgt)
    % windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.speedMO(trial)-windowEarly:binnedR_All.speedMO(trial)-windowLate,:),1);
    if ~isnan(binnedR_All.stimOnset(trial))
        for windStep = windowEarly:windowLate
            ts = ts+1;
            tgt(ts) = binnedR_All.tgt(trial);
            coh(ts) = binnedR_All.uCoh(trial);
            rt(ts) = binnedR_All.speedRT(trial);
            trialNum(ts) = trial;
             windowedFR(ts, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windStep:binnedR_All.stimOnset(trial)+windStep+5,:),1);
           % windowedFR(ts, :) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windStep,:);
        end
%     else
%         windowedFR(ts, :) = nan;
    
    end
%     if ~isnan(binnedR_All.speedRT(trial))
%         if binnedR_All.speedRT(trial) < RTbins(1)
%             trialRTbin(trial) = 1; 
%         else
%             trialRTbin(trial) = find(RTbins <= binnedR_All.speedRT(trial), 1, 'last');
%         end
%     else
%         trialRTbin(trial) = nan;
%     end
end
%% build U/D classifier: 
%tgt = binnedR_All.tgt; 
%UDtrials = find(tgt <= 2);
%trainTrialsUD = find(tgt <= 2); 
table_AllUD = array2table(windowedFR(tgt<=2,:)); 
classLabelTargUD = tgt(tgt<=2);  
Mdl_targUD = fitcnb(table_AllUD, classLabelTargUD);
%%  build L/R classifier
%trainTrialsLR = find(tgt > 2); 
table_AllLR = array2table(windowedFR(tgt>2,:)); 
classLabelTargLR = tgt(tgt>2);  
Mdl_targLR = fitcnb(table_AllLR, classLabelTargLR);
%% 
%superMat = [[trialNum(tgt<3), coh(tgt<3),tgt(tgt<3),  targPredUD]; [trialNum(tgt>=3), coh(tgt>=3), tgt(tgt>=3),  targPredLR]];
% sum(superMat(:,3) == superMat(:,4))/size(superMat,1)
% prediction = nan(max(superMat(:,1)), ceil((1+windowLate-windowEarly)));
% coherence = nan(max(superMat(:,1)),1);
% targAxis = nan(max(superMat(:,1)), 1);
% for trial = unique(superMat(:,1))'
%     prediction(trial, :) = superMat(superMat(:,1) == trial, 3) == superMat(superMat(:,1) == trial, 4);
%     coherence(trial) = binnedR_All.uCoh(trial); 
%     targAxis(trial) = binnedR_All.stimCondMatrix(binnedR_All.stimOnset(trial),1); 
% end
%% test U/D: 
%sWind = stimEarly:stimLate; % in sliding 20 ms bins
accOverTime = zeros(2, 1+stimLate-stimEarly); 
tcount = 0;
predictedTargUD = nan(length(unique(trialNum(tgt<=2))), 1+stimLate-stimEarly); 
for trial = unique(trialNum(tgt <= 2))'
    tcount = tcount +1;
        if ~isnan(binnedR_All.stimOnset(trial))    
            windCount = 0; 
    for sWind = stimEarly:stimLate
            windCount = windCount + 1;
        predictedTargUD(tcount, windCount) = predict(Mdl_targUD, nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial) + sWind :binnedR_All.stimOnset(trial) + sWind+1, :)) );
    end 
   end
end
%%
tcount = 0;
%predictedTargLR = nan(length(trainTrialsLR), stimLate); 
predictedTargLR = nan(length(unique(trialNum(tgt > 2))), 1+stimLate-stimEarly); 
for trial = unique(trialNum(tgt > 2))' %trainTrialsLR
    tcount = tcount +1;
    if ~isnan(binnedR_All.stimOnset(trial))
        windCount = 0; 
        for sWind = stimEarly:stimLate
            windCount = windCount + 1;
            predictedTargLR(tcount, windCount) = predict(Mdl_targLR, nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial) + sWind:binnedR_All.stimOnset(trial) + sWind+1 , :)) );
        end
    end
end
%% accuracy by trial
UDtrials = unique(trialNum(tgt <= 2)); 
LRtrials = unique(trialNum(tgt >2)); 
trialTgtUD = binnedR_All.tgt(UDtrials)'; %(binnedR_All.tgt <= 2);
trialTgtLR = binnedR_All.tgt(LRtrials)';
accOverTime(1,:) = nansum(predictedTargUD == trialTgtUD) / nansum(length(trialTgtUD));
accOverTime(2,:) = nansum(predictedTargLR == trialTgtLR) / nansum(length(trialTgtLR));

%% accuracy by coh
actualCoh = binnedR_All.uCoh; 
actualCohUD = actualCoh(UDtrials);
actualCohLR = actualCoh(LRtrials);
accOverTime_Coh = zeros(2, length(unique(binnedR_All.uCoh)), 1+stimLate-stimEarly); 

cohCount = 0;
tempCoh = unique(actualCoh);
for currentCoh = unique(actualCoh)'  %tempCoh(1:2:end)'%unique(actualCoh)'
    cohCount = cohCount + 1;
    accOverTime_Coh(1, cohCount, :) = nansum(predictedTargUD(actualCohUD == currentCoh,:) == trialTgtUD(actualCohUD == currentCoh)) / sum(actualCohUD == currentCoh);
    accOverTime_Coh(2, cohCount, :) = nansum(predictedTargLR(actualCohLR == currentCoh,:) == trialTgtLR(actualCohLR == currentCoh)) / sum(actualCohLR == currentCoh);
end

%% accuracy by rt
actualRT = binnedR_All.speedRT; 
actualRTUD = actualRT(UDtrials);
actualRTLR = actualRT(LRtrials);
%RTbins = [1000:500:2000]./20;
RTbins = [0,nanmedian(actualRT)];
accOverTime_RT = zeros(2, length(RTbins), 1+stimLate-stimEarly); 
RTmed = nanmedian(actualRT);
rtCount = 0;

%for currentRT = 1:length(RTbins)  %tempCoh(1:2:end)'%unique(actualCoh)'
%    rtCount = rtCount + 1;
    accOverTime_RT(1, 1, :) = nansum(predictedTargUD((actualRTUD <= RTmed) ,:) == trialTgtUD((actualRTUD <= RTmed)) ) / sum((actualRTUD <= RTmed) );
    accOverTime_RT(2, 1, :) = nansum(predictedTargLR((actualRTLR <= RTmed) ,:) == trialTgtLR((actualRTLR <= RTmed)) ) / sum((actualRTLR <= RTmed) );
    accOverTime_RT(1, 2, :) = nansum(predictedTargUD((actualRTUD > RTmed) ,:)  == trialTgtUD((actualRTUD > RTmed)) )  / sum((actualRTUD > RTmed) );
    accOverTime_RT(2, 2, :) = nansum(predictedTargLR((actualRTLR > RTmed) ,:)  == trialTgtLR((actualRTLR > RTmed)) )  / sum((actualRTLR > RTmed) );
    %  accOverTime_RT(2, rtCount, :) = nansum(predictedTargLR((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)) ,:) == trialTgtLR((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)))) / sum((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)));
    
%     if currentRT == length(RTbins)
%         accOverTime_RT(1, rtCount, :) = nansum(predictedTargUD((actualRTUD >= RTbins(currentRT)) ,:) == trialTgtUD(actualRTUD >= RTbins(currentRT))) / sum(actualRTUD >= RTbins(currentRT));
%         accOverTime_RT(2, rtCount, :) = nansum(predictedTargLR((actualRTLR >= RTbins(currentRT)) ,:) == trialTgtLR(actualRTLR >= RTbins(currentRT))) / sum(actualRTLR >= RTbins(currentRT));
%        % accOverTime_RT(2, cohCount, :) = nansum(predictedTargLR(actualCohLR == currentCoh,:) == trialTgtLR(actualCohLR == currentCoh)) / sum(actualCohLR == currentCoh);
%     else
%         accOverTime_RT(1, rtCount, :) = nansum(predictedTargUD((actualRTUD >= RTbins(currentRT)) & (actualRTUD < RTbins(currentRT+1)) ,:) == trialTgtUD((actualRTUD >= RTbins(currentRT)) & (actualRTUD < RTbins(currentRT+1)))) / sum((actualRTUD >= RTbins(currentRT)) & (actualRTUD < RTbins(currentRT+1)));
%         accOverTime_RT(2, rtCount, :) = nansum(predictedTargLR((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)) ,:) == trialTgtLR((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)))) / sum((actualRTLR >= RTbins(currentRT)) & (actualRTLR < RTbins(currentRT+1)));
%         %accOverTime_RT(2, cohCount, :) = nansum(predictedTargLR(actualCohLR == currentCoh,:) == trialTgtLR(actualCohLR == currentCoh)) / sum(actualCohLR == currentCoh);
%     end
%end
%% plot accuracy for each decoder
figure;

plot(stimEarly:stimLate, accOverTime', 'LineWidth', 2);
axis([stimEarly stimLate  0.4 1])
ax = gca;
ax.XTick = stimEarly:abs(stimEarly):stimLate;
ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on
line([windowEarly, windowEarly], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
line([windowLate, windowLate], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
legend({'Up/Down', 'Right/Left', 'Training Window'})

%% plot split by coh
cohColors = [218,218,235;...
            188,189,220;...
            158,154,200;...
            128,125,186;...
            106,81,163;...
            74,20,134;...
            0, 0, 0]./255;
figure; 
cohCount = 1;
for currentCoh = tempCoh'
   subplot(2,2,1)
   temp = nanmean(squeeze(accOverTime_Coh(1,cohCount:cohCount+1,:)));
%   temp = squeeze(accOverTime_Coh(1,cohCount,:));
%   plot(stimEarly:stimLate,temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   plot(stimEarly:stimLate,temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   axis([stimEarly stimLate  0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
   hold on;
 
      subplot(2,2,2)
      temp = nanmean(squeeze(accOverTime_Coh(2,cohCount:cohCount+1,:)));
% temp = squeeze(accOverTime_Coh(2,cohCount,:));
 %  plot(stimEarly:stimLate, temp- nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   plot(stimEarly:stimLate, temp, 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   axis([stimEarly stimLate 0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
   hold on;
       cohCount = cohCount + 1; 
end
%% plot split by RT
rtColors = flipud([161,217,155;...
                    65,171,93;...
                    0, 0, 0]./255); 
%figure; 
rtCount = 1;
for currentRT = 1:size(accOverTime_RT,2)
   subplot(2,2,3)
%   temp = nanmean(squeeze(accOverTime_Coh(1,cohCount-1:cohCount,:)));
   temp = squeeze(accOverTime_RT(1,rtCount,:));
%   plot(stimEarly:stimLate,temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   plot(stimEarly:stimLate,temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
   axis([stimEarly stimLate  0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
   hold on;
 
      subplot(2,2,4)
 %     temp = nanmean(squeeze(accOverTime_Coh(2,cohCount:cohCount+1,:)));
   temp = squeeze(accOverTime_RT(2,rtCount,:));
%   plot(stimEarly:stimLate,temp - nanmean(temp), 'LineWidth', 2, 'Color', cohColors(cohCount,:))
   plot(stimEarly:stimLate,temp, 'LineWidth', 2, 'Color', rtColors(rtCount,:))
   axis([stimEarly stimLate 0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
   hold on;
       rtCount = rtCount + 1; 
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
 %%
%    %% decoder accuracy using 1 20 ms window, averaged by target. Chance = 50% bc each decoder only sees 2 options 
%    accOverTime(1,:) = nansum(predictedTargUD == tgt(trainTrialsUD)') / length(trainTrialsUD );
%    accOverTime(2,:) = nansum(predictedTargLR == tgt(trainTrialsLR)') / length(trainTrialsLR );
% %    accOverTime(3,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 3, :) == 3) / sum(tgt(trainTrialsLR ) == 3);
% %    accOverTime(4,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 4, :) == 4) / sum(tgt(trainTrialsLR ) == 4);
%    figure;
%    subplot(3,3,5)
%    plot(stimEarly:stimLate, accOverTime(1:2,:)', 'LineWidth', 2);
%    axis([stimEarly stimLate  0.4 1])
%    ax = gca;
%    ax.XTick = stimEarly:abs(stimEarly):stimLate; 
%    ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
%     line([windowEarly, windowEarly], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
% line([windowLate, windowLate], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
%    legend({'Up', 'Down', 'Right', 'Left', 'Training Window'})
