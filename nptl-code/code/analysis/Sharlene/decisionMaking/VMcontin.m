function binnedR_All = VMcontin(binnedR_All)
% find trial by trial correlation between reaction time and [mean(deliberation FR) - baseline]

%these should all be embedded in the struct 
unitsIdx = mean(binnedR_All.rawSpikes).*50 > 10; %all spikes with ave FR > 10 Hz
windowEarlyMO = binnedR_All.windowEarlyMO_RT;   %ms before event onset / 20 ms per bin;
windowLateMO  = binnedR_All.windowLateMO_RT;  
windowEarlySO = binnedR_All.windowEarlySO_RT;   %ms before event onset / 20 ms per bin;
windowLateSO  = binnedR_All.windowLateSO_RT;
moveOnset = size(binnedR_All.psthMO_RT, 2) - windowLateMO;
epochLate = 500/20; % ms before movement onset to calc mean FR end. in bins
epochEarly = 1400/20; % ms before movement onset to calc mean FR start. in bins
%%
baseline = nan(size(binnedR_All.psthSO_RT, 3),size(binnedR_All.psthSO_RT, 1) );
windStartMO = nan(size(baseline)); 
meanFR = nan(size(baseline)); 
rt  =  binnedR_All.moveOnset - binnedR_All.stimOnset; %this is in BINS
cCoeff = nan(size(baseline,1),1); 
pval = nan(size(cCoeff)); 
figure;
for unit = 1:size(binnedR_All.psthSO_RT, 3)
    for trial = 1:size(binnedR_All.psthSO_RT, 1)
        if ~isnan(rt(trial)) %~isnan(binnedR_All.stimOnset(trial))
            baseline(unit, trial) = nanmean(binnedR_All.psthSO_RT(trial, 1:(-1*windowEarlySO), unit));
            windStartMO(unit, trial) = min(epochEarly, rt(trial));
            meanFR(unit, trial) = nanmean(binnedR_All.psthMO_RT(trial, (moveOnset - windStartMO) : (moveOnset - epochLate), unit)) - baseline(unit, trial);
        end
    end
    %rows are observations = units' FRs, cols = RT
    [R, P] = corrcoef(meanFR(unit,:), rt); 
    cCoeff(unit) = R(1,2); 
    pval(unit) = P(1,2); 
    R = [];
    P = [];
%     plot(meanFR(unit,:), rt, '*', 'LineWidth', 3)
%     pause
end
 figure;
hall = histogram(cCoeff, 20);
hold on
hsig = histogram(cCoeff(pval < 0.05));
hsig.BinEdges = hall.BinEdges;
ylabel('Number of Units');
xlabel('Correlation Coefficient');
sum(pval < 0.05)
binnedR_All.cCoeff = cCoeff;
binnedR_All.ccPval = pval; 
binnedR_All.epochLate = epochLate; % ms before movement onset to calc mean FR end. in bins
binnedR_All.epochEarly = epochEarly; 