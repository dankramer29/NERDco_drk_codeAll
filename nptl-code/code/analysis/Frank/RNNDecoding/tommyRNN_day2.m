%24 25
%32
blockSets = {[5 6 7 8 9],[10 11 12 14 15 16];
    [17 18 19 20 21 29],[24 25 26 27 28];
    [30 31],[32];
    };
slcDir = '/Users/frankwillett/Data/tommyRNN2/';
colors = [1.0 0 0;
    0 0 1.0];
cWeight = [1,0.75,0.5];
lHandles = zeros(size(blockSets));

figure
for setIdx=1:size(blockSets,1)
    for decType=1:2
        bSet = blockSets{setIdx,decType};
        if isempty(bSet)
            continue
        end
        
        acqStats = zeros(length(bSet),3);
        gainStats = zeros(length(bSet),1);
        for bNum=1:length(bSet)
            slc = LoadSLC(bSet(bNum),slcDir);
            tPos = slc.task.goal.values(:,1:2);

            breakIdx = [1; find(any(diff(tPos)~=0,2))];
            acqTime = breakIdx(2:end)-breakIdx(1:(end-1));
            acqTime = acqTime*0.02;

            [acqStats(bNum,1),~,acqStats(bNum,2:3)] = normfit(acqTime);
            
            gainStats(bNum) = nanmean(slc.task.velPostGain);
        end
        
        [~,bestCon] = min(acqStats(:,1));
       
        gainStats = (gainStats/gainStats(bestCon));
        [~,orderIdx] = sort(gainStats,'ascend');

        gsOrder = gainStats(orderIdx);
        acqStatsOrder = acqStats(orderIdx,:);
        
        hold on;
        
        if range(gsOrder)<1e-05
            %lHandles(setIdx, decType) = plot(gsOrder, acqStatsOrder(:,1),'o','Color',colors(decType,:)*cWeight(setIdx),'LineWidth',3);
            errorbar(gsOrder+linspace(-0.05,0.05,length(gsOrder))', acqStatsOrder(:,1), acqStatsOrder(:,2)-acqStatsOrder(:,1), acqStatsOrder(:,1)-acqStatsOrder(:,3), 'o', 'Color',colors(decType,:)*cWeight(setIdx),'LineWidth',2);  
        else
            lHandles(setIdx, decType) = plot(gsOrder, acqStatsOrder(:,1),'Color',colors(decType,:)*cWeight(setIdx),'LineWidth',3);
            errorPatch(gsOrder, acqStatsOrder(:,2:3), colors(decType,:)*cWeight(setIdx), 0.2);  
        end
    end
end

set(gca,'FontSize',16,'LineWidth',2);
%set(gca,'XScale','log');
xlabel('Gain Scaling');
ylabel('Avg. Acquire Time (s)');
axis tight;

legend(lHandles(1,:), {'Kalman','LSTM'});