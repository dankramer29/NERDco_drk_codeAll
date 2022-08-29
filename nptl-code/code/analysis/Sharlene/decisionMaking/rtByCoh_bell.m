% make RT distribution plots 
 
for i = 1:length(aggR)
%calculate signed coh: 
% aggR(i).BC.coh = [];
% aggR(i).HM.coh = [];

if i < 6
    aggR(i).BC.sCoh = (2.*(aggR(i).BC.stimCondMatrix(aggR(i).BC.stimOnset,4)) - 225)./225;
end
    aggR(i).HM.sCoh = (2.*(aggR(i).HM.stimCondMatrix(aggR(i).HM.stimOnset,4)) - 225)./225;
end
allSCoh = unique(aggR(2).HM.sCoh);
%%
rtDist(length(allSCoh)).HM = [];
rtDist(length(allSCoh)).BC = [];
for sesh = 1:length(aggR)
    %eliminate last trial if it wasn't completed: 
    if length(aggR(sesh).HM.moveOnset) < length(aggR(sesh).HM.trialStart)
        aggR(sesh).HM.sCoh(end) = [];
    end
    if (sesh < 6) && (length(aggR(sesh).BC.moveOnset) < length(aggR(sesh).BC.trialStart))
        aggR(sesh).BC.sCoh(end) = [];
    end
for coh = unique(aggR(sesh).HM.sCoh)'
    cohIdx = find(allSCoh == coh); 
    rtDist(cohIdx).HM = [rtDist(cohIdx).HM, aggR(sesh).HM.moveOnset(aggR(sesh).HM.sCoh == coh)- aggR(sesh).HM.stimOnset(aggR(sesh).HM.sCoh == coh)];
    if sesh < 6
    rtDist(cohIdx).BC = [rtDist(cohIdx).BC, aggR(sesh).BC.moveOnset(aggR(sesh).BC.sCoh == coh)- aggR(sesh).BC.stimOnset(aggR(sesh).BC.sCoh == coh)];
    end
end
end
%% 
figure(1);
figure(2);
for coh = 1:length(rtDist)
    figure(1)
%    plot(allSCoh(coh), nanmean(rtDist(coh).HM), '*k', 'LineWidth', 2, 'MarkerSize', 10)
     errorbar(allSCoh(coh), nanmedian(rtDist(coh).HM).*20, nanmedian(rtDist(coh).HM).*20 - quantile(rtDist(coh).HM.*20, .25), quantile(rtDist(coh).HM.*20, .75) - nanmedian(rtDist(coh).HM).*20, 'Color', 'k')
     hold on;
    % plot(allSCoh(coh), nanmean(rtDist(coh).HM).*20, '*k', 'LineWidth', 2, 'MarkerSize', 10) 
     plot(allSCoh(coh), nanmedian(rtDist(coh).HM).*20, '*b', 'LineWidth', 2, 'MarkerSize', 10) 
     figure(2)
     errorbar(allSCoh(coh), nanmedian(rtDist(coh).BC).*20,  nanmedian(rtDist(coh).BC).*20 - quantile(rtDist(coh).BC.*20, .25), quantile(rtDist(coh).BC.*20, .75) -  nanmedian(rtDist(coh).BC).*20, 'Color', 'k')
     hold on;
    % plot(allSCoh(coh), nanmean(rtDist(coh).BC).*20, '*k', 'LineWidth', 2, 'MarkerSize', 10) 
     plot(allSCoh(coh), nanmedian(rtDist(coh).BC).*20, '*b', 'LineWidth', 2, 'MarkerSize', 10) 
end
figure(1)
title('RT - HM, Median + IQR');
axis square
figure(2)
title('RT - BC,  Median + IQR');
axis square    