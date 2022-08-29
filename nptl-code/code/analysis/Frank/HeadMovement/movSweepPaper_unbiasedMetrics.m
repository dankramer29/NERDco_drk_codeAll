%%
outDir = '/Users/frankwillett/Data/Derived/MovementSweep/SuppFigBias';
mkdir(outDir);

%%
trialNums = [5, 20];
nReps = 1000;
distances = linspace(0,10,50);
distanceEst = zeros(length(trialNums),length(distances),nReps);
distanceEstUnbiased = zeros(length(trialNums),length(distances),nReps);
nDim = 100;

for t=1:length(trialNums)
    for distIdx=1:length(distances)
        nTrials = trialNums(t);
        for n=1:nReps
            data1 = randn(nTrials,nDim);
            data2 = (distances(distIdx)/sqrt(nDim)) + randn(nTrials,nDim);
            
            distanceEst(t,distIdx,n) = norm(mean(data1)-mean(data2));
            distanceEstUnbiased(t,distIdx,n) = lessBiasedDistance( data1, data2 );
        end
    end
end

%%
colors = [0.8 0 0;
    0 0 0.8];
lHandles = zeros(2,1);

figure('Position',[680   838   659   260]);
for t=1:length(trialNums)
    subplot(1,length(trialNums),t);
    hold on;
    
    [mn,sd,CI] = normfit(squeeze(distanceEst(t,:,:))');
    [mn_un,sd_un,CI_un] = normfit(squeeze(distanceEstUnbiased(t,:,:))');
    
    lHandles(1)=plot(distances, mn, 'Color', colors(1,:), 'LineWidth', 2);
    lHandles(2)=plot(distances, mn_un, 'Color', colors(2,:), 'LineWidth', 2);
    plot([0,max(distances)],[0,max(distances)],'--k','LineWidth',2);
    
    errorPatch( distances', [mn'-sd', mn'+sd'], colors(1,:), 0.2 );
    errorPatch( distances', [mn_un'-sd_un', mn_un'+sd_un'], colors(2,:), 0.2 );
    
    title([num2str(trialNums(t)) ' Trials']);
    xlabel('True Distance');
    ylabel('Estimated Distance');
    
    if t==2
        legend(lHandles, {'Standard','Cross-Validated'},'Box','Off');
    end
    ylim([-3,13]);
    set(gca,'FontSize',16,'LineWidth',2);
end

saveas(gcf,[outDir filesep 'distanceEst.png'],'png');
saveas(gcf,[outDir filesep 'distanceEst.svg'],'svg');

%%
trialNums = [5, 20];
nReps = 1000;
corrVals = linspace(0,1,50);
corrEst = zeros(length(trialNums),length(distances),nReps);
corrEstUnbiased = zeros(length(trialNums),length(distances),nReps);
nDim = 100;

for t=1:length(trialNums)
    for corrIdx=1:length(distances)
        nTrials = trialNums(t);
        for n=1:nReps
            u1 = randn(1,nDim);
            u1 = u1 - mean(u1);
            u1 = u1 / norm(u1);
            
            u2 = randn(1,nDim);
            u2 = u2 - mean(u2);
            u2 = u2 - (u1*u2')*u1;
            u2 = u2 / norm(u2);
            u2 = u2*sqrt(1-corrVals(corrIdx)^2) + u1*corrVals(corrIdx);
            
            data1 = 5*u1+randn(nTrials,nDim);
            data2 = 5*u2+randn(nTrials,nDim);
            
            corrEst(t,corrIdx,n) = corr(mean(data1)', mean(data2)');
            
            unbiasedMag1 = lessBiasedDistance( data1, zeros(size(data1)), true );
            unbiasedMag2 = lessBiasedDistance( data2, zeros(size(data2)), true );
            
            mn1 = mean(data1);
            mn2 = mean(data2);
            corrEstUnbiased(t,corrIdx,n) = (mn1-mean(mn1))*(mn2-mean(mn2))'/(unbiasedMag1*unbiasedMag2);
        end
    end
end

%%
colors = [0.8 0 0;
    0 0 0.8];
lHandles = zeros(2,1);

figure('Position',[680   838   659   260]);
for t=1:length(trialNums)
    subplot(1,length(trialNums),t);
    hold on;
    
    [mn,sd,CI] = normfit(squeeze(corrEst(t,:,:))');
    [mn_un,sd_un,CI_un] = normfit(squeeze(corrEstUnbiased(t,:,:))');
    
    lHandles(1)=plot(corrVals, mn, 'Color', colors(1,:), 'LineWidth', 2);
    lHandles(2)=plot(corrVals, mn_un, 'Color', colors(2,:), 'LineWidth', 2);
    plot([0,max(corrVals)],[0,max(corrVals)],'--k','LineWidth',2);
    
    errorPatch( corrVals', [mn'-sd', mn'+sd'], colors(1,:), 0.2 );
    errorPatch( corrVals', [mn_un'-sd_un', mn_un'+sd_un'], colors(2,:), 0.2 );
    
    title([num2str(trialNums(t)) ' Trials']);
    xlabel('True Correlation');
    ylabel('Estimated Correlation');
    
    if t==2
        legend(lHandles, {'Standard','Cross-Validated'},'Box','Off');
    end
    ylim([-0.2,1.2]);
    set(gca,'FontSize',16,'LineWidth',2);
end

saveas(gcf,[outDir filesep 'corrEst.png'],'png');
saveas(gcf,[outDir filesep 'corrEst.svg'],'svg');
