% assign the variable you want to binnedR:
binnedR = binnedR_HM;
%binnedR = binnedR_BC;
%% find the transitions to align "movement onset" to
binnedR_All.rawSpikes = [];
binnedR_All.stimCondMatrix = [];
binnedR_All.state = [];
binnedR_All.effPosX = [];
binnedR_All.effPosY = [];
binnedR_All.zSpikes = [];
binnedR_All.meanSSpikes = [];
for i = 1:length(binnedR)
    binnedR_All.rawSpikes = [binnedR_All.rawSpikes; binnedR(i).rawSpikes];
    binnedR_All.zSpikes = [binnedR_All.zSpikes; binnedR(i).zScoreSpikes];
    binnedR_All.meanSSpikes = [binnedR_All.meanSSpikes; binnedR(i).meanSubtractSpikes];
    binnedR_All.stimCondMatrix = [binnedR_All.stimCondMatrix; binnedR(i).stimCondMatrix];
    binnedR_All.state = [binnedR_All.state; binnedR(i).state]; 
    binnedR_All.effPosX = [binnedR_All.effPosX; binnedR(i).effectorCursorPos(:,1)]; 
    binnedR_All.effPosY = [binnedR_All.effPosY; binnedR(i).effectorCursorPos(:,2)];
end
%% 
trialStartIdx = find(abs(diff(binnedR_All.stimCondMatrix(:,4)))>0);
numTrials = length(trialStartIdx);
moveOnset = nan(ceil(numTrials/2),1);
coh = nan(ceil(numTrials/2),1);
trialCount = 0;
for i = 1:2:numTrials
    %based on state change
    trialCount = trialCount + 1;
    if i < numTrials-1
        moveStart = find(binnedR_All.state(trialStartIdx(i):trialStartIdx(i+2)) == 17, 1, 'last');
        if ~isempty(moveStart)
            moveOnset(trialCount) = trialStartIdx(i) + moveStart;
            coh(trialCount) = binnedR_All.stimCondMatrix(moveOnset(trialCount),4);
        else
            moveOnset(trialCount) = nan;
            coh(trialCount) = nan;
            %   trialCount = trialCount - 1; %overwrite this on the next iteration
        end
    else
        moveStart = find(binnedR_All.state(trialStartIdx(i):end) == 17, 1, 'last');
        if ~isempty(moveStart)
            moveOnset(trialCount) = trialStartIdx(i) + moveStart;
            coh(trialCount) = binnedR_All.stimCondMatrix(moveOnset(trialCount),4);
        else
            moveOnset(trialCount) = nan;
            coh(trialCount) = nan;
        end
    end
end
% moveOnset(isnan(moveOnset)) = [];
% coh(isnan(moveOnset)) = [];

unsignedCoh = abs((2.*coh - 225)/225);
badTrl = isnan(unsignedCoh);
unsignedCoh(badTrl) = [];
moveOnset(badTrl) = [];
out = apply_dPCA_simple(binnedR_All.rawSpikes, moveOnset, unsignedCoh, [-50, 50], 0.02, {'CohD', 'CohI'})
%% plot it
nBins = length(unique(unsignedCoh))
lineArgs = cell(nBins,1);
colors = parula(nBins)*0.8;
for l=1:nBins
    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle','-'};
end
yAx = oneFactor_dPCA_plot(out, [-50:50], lineArgs, {'Coherence Dependent', 'Coherence Independent'}, 'sameAxes')
%% PSTH-it
% assign and split by target
psth = zeros(192, 4, length(unique(unsignedCoh)), length([-75:50]));
count = zeros(4, length(unique(unsignedCoh)));
UCohIdx = unique(unsignedCoh);
tgt = zeros(1, length(unsignedCoh)); 
for trial = 1:length(moveOnset)
    if binnedR_All.stimCondMatrix(moveOnset(trial),1) == 1
        if binnedR_All.effPosY(moveOnset(trial)+3) > 0
            tgt(trial) = 1; %up
        else
            tgt(trial) = 2; %down
        end
    else
        if binnedR_All.effPosX(moveOnset(trial)+3) > 0
            tgt(trial) = 3; %right
        else
            tgt(trial) = 4; %left
        end
    end
    count(tgt(trial), UCohIdx == unsignedCoh(trial)) = count(tgt(trial), UCohIdx == unsignedCoh(trial))+1;
    for unit = 1:192
        psth(unit, tgt(trial), UCohIdx == unsignedCoh(trial), :) = squeeze(psth(unit, tgt(trial),  UCohIdx == unsignedCoh(trial), :)) + ...
            (binnedR_All.rawSpikes(moveOnset(trial)-75:moveOnset(trial)+50, unit))*50; %make it in Hz, make it an average
    end
end
%% 2-factor dPCA:
% unsignedCoh(tgt >= 3) = [];
% moveOnset(tgt >= 3) = [];
% tgt(tgt>=3) = [];
nBins1 = length(unique(unsignedCoh));
nBins2 = length(unique(tgt));
lineArgs = cell(nBins1, nBins2);
colors = parula(nBins1)*0.8;
%colors{1} = parula(nBins1)*0.8;
%colors{2} = hot(nBins2)*0.8;
lineStyles = {'-', '-.', ':', '--'};
for f1 = 1:nBins1 %factors
for f2=1:nBins2
    lineArgs{f1,f2} = {'Color',colors(f1,:),'LineWidth',2,'LineStyle',lineStyles{f2}};
end
end
out2 = apply_dPCA_simple(binnedR_All.zSpikes, moveOnset, [unsignedCoh, tgt'], [-75, 25], 0.02, {'Coh', 'Targ', 'CI', 'Inter'})
yAx2 = twoFactor_dPCA_plot(out2, [-75:25], lineArgs, {'Coherence', 'Target', 'CI', 'Interaction'}, 'sameAxes')
%% plot em
cohColors = [255,255,204;...
    199,233,180;...
    127,205,187;...
    65,182,196;...
    29,145,192;...
    34,94,168;...
    12,44,132]./255;
keepIdx = zeros(1,192);
for unit = 1:192
    ymax = max([max(max(squeeze(psth(unit, 1, :, :))'./count(1,:))), max(max(squeeze(psth(unit, 2, :, :))'./count(2,:))),...
        max(max(squeeze(psth(unit, 3, :, :))'./count(3,:))), max(max(squeeze(psth(unit, 4, :, :))'./count(4,:)))]);
    if ymax > 4
        figure;
        for cIdx = 1:size(psth,3)
            subplot(3,3,2)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 1, cIdx, :))./count(1,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 1, cIdx, :))./count(1,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            %axis tight;
            axis([0 126 0 ymax])
            title(['Unit #', num2str(unit)]);
            
            subplot(3,3,4)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 4, cIdx, :))./count(4,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 4, cIdx, :))./count(4,cIdx))], 'Color', 'r')
            % line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            
            subplot(3,3,6)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 3, cIdx, :))./count(3,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            %line([75 75], [0 max(squeeze(psth(unit, 3, cIdx, :))./count(3,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            
            subplot(3,3,8)
            ax = gca;
            ax.ColorOrderIndex = cIdx;
            plot(squeeze(psth(unit, 2, cIdx, :))./count(2,cIdx), 'LineWidth', 2, 'Color', cohColors(cIdx,:))
            hold on;
            % line([75 75], [0 max(squeeze(psth(unit, 2, cIdx, :))./count(2,cIdx))], 'Color', 'r')
            line([75 75], [0 ymax], 'Color', 'r')
            ax.XTick = 0:25:125;
            ax.XTickLabel = [-75:25:50].*20;
            axis([0 126 0 ymax])
            xlabel('Time to Movement Onset (ms)')
        end
        
        subplot(3,3,4)
        line([75 75], [0 ymax], 'Color', 'r')
        legend([num2str(round(UCohIdx.*100)); 'MO'])
        
        keepIdx(unit) = input('Is it a keeper? 1 = y/0 = n: ');
        if keepIdx(unit)
            print(['unit', num2str(unit), '_HM0418'], '-fillpage', '-dpdf');
        end
        close all;
    end
end
