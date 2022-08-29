% decode choice as a function of coherence/RT over time in trials
% aligned to stim onset, 0:300 ish ms
% split targets by up/dow or left/right: 
psthPre = 75;
windowEarly = 200/20;   %ms before decode event onset start/ 20 ms per bin;
windowLate  = 600/20;   %ms before decode event onset end / 20 ms per bin; 
stimEarly = floor(-200/20);    %ms before stimOnset
stimLate = floor(600/20);      %ms after stimOnset
numTargs = 4; %in any trial, there are only two options 

%% get observations: 
%windowedFR = zeros(length(binnedR_All.tgt)*(windowLate-windowEarly),size(binnedR_All.zSpikes,2));
windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
ts = 0;
for trial = 1:length(binnedR_All.tgt)
    % windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.speedMO(trial)-windowEarly:binnedR_All.speedMO(trial)-windowLate,:),1);
    if ~isnan(binnedR_All.stimOnset(trial))
    %    for windStep = windowEarly:windowLate
            ts = ts+1;
            
             windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial):binnedR_All.stimOnset(trial)+stimLate,:),1);
           % windowedFR(ts, :) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windStep,:);
    %    end
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
tgt = binnedR_All.tgt; 
UDtrials = find(tgt <= 2);
trainTrialsUD = find(tgt <= 2); 

table_AllUD = array2table(windowedFR(trainTrialsUD,:)); 
classLabelTargUD = binnedR_All.tgt(trainTrialsUD)';  
Mdl_targUD = fitcnb(table_AllUD, classLabelTargUD, 'Prior' , 'uniform');
%%  build L/R classifier
trainTrialsLR = find(tgt > 2); 
table_AllLR = array2table(windowedFR(trainTrialsLR,:)); 
classLabelTargLR = binnedR_All.tgt(trainTrialsLR)';  
Mdl_targLR = fitcnb(table_AllLR, classLabelTargLR, 'Prior' , 'uniform');
%% test U/D: 
%sWind = stimEarly:stimLate; % in sliding 20 ms bins
accOverTime = zeros(numTargs, 1+stimLate-stimEarly); 
tcount = 0;
predictedTargUD = nan(length(trainTrialsUD), stimLate); 
for trial = trainTrialsUD
    tcount = tcount +1;
        if ~isnan(binnedR_All.stimOnset(trial))    
            windCount = 0; 
    for sWind = stimEarly:stimLate
            windCount = windCount + 1;
        predictedTargUD(tcount, windCount) = predict(Mdl_targUD, binnedR_All.zSpikes(binnedR_All.stimOnset(trial) + sWind , :) );
    end 
        end
end
%%
tcount = 0;
predictedTargLR = nan(length(trainTrialsLR), stimLate); 
for trial = trainTrialsLR
    tcount = tcount +1;
    if ~isnan(binnedR_All.stimOnset(trial))
        windCount = 0; 
        for sWind = stimEarly:stimLate
            windCount = windCount + 1;
            predictedTargLR(tcount, windCount) = predict(Mdl_targLR, binnedR_All.zSpikes(binnedR_All.stimOnset(trial) + sWind , :) );
        end
    end
end
%% decoder accuracy using 1 20 ms window, averaged by target. Chance = 50% bc each decoder only sees 2 options 
   accOverTime(1,:) = nansum(predictedTargUD(tgt(trainTrialsUD) == 1, :) == 1) / sum(tgt(trainTrialsUD ) == 1);
   accOverTime(2,:) = nansum(predictedTargUD(tgt(trainTrialsUD) == 2, :) == 2) / sum(tgt(trainTrialsUD ) == 2);
   accOverTime(3,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 3, :) == 3) / sum(tgt(trainTrialsLR ) == 3);
   accOverTime(4,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 4, :) == 4) / sum(tgt(trainTrialsLR ) == 4);
   figure;
  % subplot(3,3,5)
   plot(stimEarly:stimLate, accOverTime', 'LineWidth', 2);
   axis([stimEarly stimLate  0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
    line([windowEarly, windowEarly], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
line([windowLate, windowLate], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
   legend({'Up', 'Down', 'Right', 'Left', 'Training Window'})
   %%
   %% decoder accuracy using 1 20 ms window, averaged by target. Chance = 50% bc each decoder only sees 2 options 
   accOverTime(1,:) = nansum(predictedTargUD == tgt(trainTrialsUD)') / length(trainTrialsUD );
   accOverTime(2,:) = nansum(predictedTargLR == tgt(trainTrialsLR)') / length(trainTrialsLR );
%    accOverTime(3,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 3, :) == 3) / sum(tgt(trainTrialsLR ) == 3);
%    accOverTime(4,:) = nansum(predictedTargLR(tgt(trainTrialsLR) == 4, :) == 4) / sum(tgt(trainTrialsLR ) == 4);
   figure;
 %  subplot(3,3,5)
   plot(stimEarly:stimLate, accOverTime(1:2,:)', 'LineWidth', 2);
   axis([stimEarly stimLate  0.4 1])
   ax = gca;
   ax.XTick = stimEarly:abs(stimEarly):stimLate; 
   ax.XTickLabel = [stimEarly:abs(stimEarly):stimLate].*20; %ms from stim on 
    line([windowEarly, windowEarly], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
line([windowLate, windowLate], [0 1], 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--')
   legend({'Up', 'Down', 'Right', 'Left', 'Training Window'})
%% Split by coherence level: 
    %actualTargUD = binnedR_All.tgt(trainTrialsUD);
    accOverTime_Coh = zeros(numTargs, length(unique(binnedR_All.uCoh)), 1+stimLate-stimEarly); 
    actualCoh = binnedR_All.uCoh; 
    cohCount = 0; 

    tempCoh = unique(actualCoh); 
for currentCoh = unique(actualCoh)'  %tempCoh(1:2:end)'%unique(actualCoh)'    
    cohCount = cohCount + 1; 
    ax = gca;
    ax.ColorOrderIndex = 1; 
       accOverTime(1,:) = nansum(predictedTargUD == tgt(trainTrialsUD)') / length(trainTrialsUD );
   accOverTime(2,:) = nansum(predictedTargLR == tgt(trainTrialsLR)') / length(trainTrialsLR );
   accOverTime_Coh(1, cohCount, :) = nansum(predictedTargUD(actualCoh(trainTrialsUD) == currentCoh)' == tgt(actualCoh(trainTrialsUD) == currentCoh)) / sum(actualCoh(trainTrialsUD) == currentCoh');
   
   accOverTime_Coh(2, cohCount, :) = nansum(predictedTargLR == tgt(trainTrialsLR) & (actualCoh(trainTrialsLR) == currentCoh)', :) / sum(tgt(trainTrialsLR) & (actualCoh(trainTrialsLR) == currentCoh)');

  % accOverTime_Coh(3, cohCount, :) = nansum(predictedTargLR(tgt(trainTrialsLR) == 3 & (actualCoh(trainTrialsLR) == currentCoh)', :) == 3) / sum(tgt(trainTrialsLR) == 3 & (actualCoh(trainTrialsLR) == currentCoh)');

  % accOverTime_Coh(4, cohCount, :) = nansum(predictedTargLR(tgt(trainTrialsLR) == 4 & (actualCoh(trainTrialsLR) == currentCoh)', :) == 4) / sum(tgt(trainTrialsLR) == 4 & (actualCoh(trainTrialsLR) == currentCoh)');
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
