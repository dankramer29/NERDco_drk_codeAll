
%%
osimRNNDir = '/Users/frankwillett/Data/armControlNets/osim7dPipelineVal/';
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/pipelineFigure/';
mkdir(saveDir);

%%
concatMSE = [];
concatFVAF = [];
genNum = [];

for x=0:32
    fName = [osimRNNDir 'envModels_gen' num2str(x) '.mat'];
    if exist(fName,'file')
        dat = load(fName);
        concatMSE = [concatMSE; dat.MSE];
        concatFVAF = [concatFVAF; dat.FVAF];
        genNum = [genNum; x];
    end
end

%%
figure('Position',[190   719   409   230]);
hold on
plot(genNum+1,concatFVAF(:,10:12),'-o','LineWidth',2);
set(gca,'FontSize',16,'LineWidth',2);
xlabel('Generation');
ylabel('R2');
legend({'X Position','Y Position','Z Position'});

%%
figure('Position',[190   719   409   230]);
hold on
plot(genNum+1,mean(zscore(sqrt(concatMSE)),2),'-o','LineWidth',2);
axis tight;
set(gca,'FontSize',18,'LineWidth',2);
xlabel('Generation');
ylabel('Normalized\newlinePrediction Error');
title('ArmNet');

saveas(gcf,[saveDir 'reconErr_all.png'],'png');

%%
figure('Position',[190   719   409   230]);
hold on
plot(genNum+1,mean(sqrt(concatMSE(:,10:12)),2),'-o','LineWidth',2);
axis tight;
set(gca,'FontSize',16,'LineWidth',2);
xlabel('Generation');
ylabel('Prediction Error (RMSE)');

legend({'Hand Position'});
saveas(gcf,[saveDir 'reconErr_hand.png'],'png');

%%
exampleGen = [1,5,10,30];

for gen=1:length(exampleGen)
    load(['/Users/frankwillett/Data/armControlNets/osim7dPipelineVal/modelPlusController_gen' num2str(exampleGen(gen)) '_0.mat']);

    pos = envState(:,[10,12,11]);
    targ = controllerInputs(:,[1 3 2]);
    targList = unique(targ, 'rows');

    figure('Position',[680   853   368   245]);
    hold on;
    for trlIdx=1:length(trialStartIdx)
        if gen==1
            loopIdx = (trialStartIdx(plotIdx(trlIdx))+1):(trialStartIdx(plotIdx(trlIdx))+150);
        else
            loopIdx = (trialStartIdx(plotIdx(trlIdx))+50):(trialStartIdx(plotIdx(trlIdx))+150);
        end
        plot3(pos(loopIdx,1), pos(loopIdx,2), pos(loopIdx,3), 'LineWidth', 2.0);
    end
    
    %plot3(targList(:,1), targList(:,2), targList(:,3), 'o','Color',[1.0
    %0.4 0.4],'MarkerFaceColor',[1.0 0.2 0.2]);
    xlim([0.2,0.45]);
    ylim([0.2,0.40]);
    zlim([-0.40,-0.05]);
    xlabel('X (m)');
    ylabel('Z (m)');
    zlabel('Y (m)');
    view([-42.8000 26.0000]);
    axis equal;
    set(gca,'FontSize',16,'LineWidth',2,'XTick',[0.2,0.3,0.4],'YTick',[0.2,0.3,0.4],'ZTick',[-0.3,-0.2]);
    set(gca,'XLim',[0.1966    0.4521],'YLim',[0.1869    0.4380],'ZLim',[-0.3737   -0.1202]);
    
    xLimit = get(gca,'XLim');
    yLimit = get(gca,'YLim');
    zLimit = get(gca,'ZLim');
    limOffset = -0.01;
    for trlIdx=1:length(trialStartIdx)
        if gen==1
            loopIdx = (trialStartIdx(plotIdx(trlIdx))+1):(trialStartIdx(plotIdx(trlIdx))+150);
        else
            loopIdx = (trialStartIdx(plotIdx(trlIdx))+50):(trialStartIdx(plotIdx(trlIdx))+150);
        end
        plot3(repmat(xLimit(2)+limOffset, length(loopIdx), 1), pos(loopIdx,2), pos(loopIdx,3), 'LineWidth', 2.0, 'Color', [0.8 0.8 0.8]);
        plot3(pos(loopIdx,1), pos(loopIdx,2), repmat(zLimit(1)-limOffset, length(loopIdx), 1), 'LineWidth', 2.0, 'Color', [0.8 0.8 0.8]);
        plot3(pos(loopIdx,1), repmat(yLimit(2)+limOffset, length(loopIdx), 1), pos(loopIdx,3), 'LineWidth', 2.0, 'Color', [0.8 0.8 0.8]);
    end

    title(['Gen ' num2str(exampleGen(gen)+1)]);
    grid on;
    saveas(gcf,[saveDir 'example_' num2str(exampleGen(gen)+1) '.png'],'png');
    
    %set(gca,'XTickLabel',[]); set(gca,'YTickLabel',[]);
    %set(gca,'ZTickLabel',[]);
end

%%
%minimum jerk accuracy
genErr = zeros(31,1);
for gen=0:30
    fName = ['/Users/frankwillett/Data/armControlNets/osim7dPipelineVal/modelPlusController_gen' num2str(gen) '_0.mat'];
    if ~exist(fName,'file')
        continue;
    end
    load(fName);
    
    pos = envState(:,[10,12,11]);
    targ = controllerInputs(:,[1 3 2]);
    targList = unique(targ, 'rows');
    centerPos = [0.29904707, -0.21602742,  0.28752533];
    
    minJerkErr = zeros(length(trialStartIdx),3);
    for trlIdx=1:length(trialStartIdx)
        %make minimum jerk template
        rtSteps = 1;
        travelDist = 0.1;
        travelTime = ceil((60 + 105*log(1 + travelDist/0.005))/10.0);
        fullSteps = 60;
        tau = [zeros(1,rtSteps), linspace(0,1,travelTime), ones(1,fullSteps-travelTime-rtSteps)];
        polynomial = 15*power(tau,4) - 6*power(tau,5) - 10*power(tau,3); 

        track = zeros(fullSteps,3);
        for dimIdx=1:3
            track(:,dimIdx) = centerPos(dimIdx) + (centerPos(dimIdx)-controllerInputs(trialStartIdx(trlIdx)+1,dimIdx)) * polynomial;
        end

        %compare to template
        loopIdx = (trialStartIdx(plotIdx(trlIdx))+101):(trialStartIdx(plotIdx(trlIdx))+100+fullSteps);
        
        %figure
        %hold on
        %plot(track,'--','LineWidth',2.0);
        %plot(envState(loopIdx,10:12), 'LineWidth', 2.0);
        
        minJerkError(trlIdx,:) = sqrt(mean((track - envState(loopIdx,10:12)).^2));
    end
    genErr(gen+1) = mean(minJerkError(:));
end

figure('Position',[190   719   409   230]);
hold on
plot((0:30)+1,genErr*100,'-o','LineWidth',2);
set(gca,'FontSize',18,'LineWidth',2);
xlabel('Generation');
ylabel('Reaching Error\newline(RMSE cm)');
axis tight;
ylim([0,0.05]*100);
xlim([0,31]);
title('Controller RNN');
saveas(gcf,[saveDir 'trackErr.png'],'png');

%%
%example time series prediction
exampleGen = [1 5 30];
trlNum = 500;

for gen=1:length(exampleGen)
    dat = load(['/Users/frankwillett/Data/armControlNets/osim7dPipelineVal/pipelineValidationResults/envModels_gen' num2str(exampleGen(gen)) '_timeSeriesExample.mat']);

    loopIdx = ((trlNum-1)*200 + 1):(trlNum*200);
    plotDims = [10,12,11];
    colors = [1 0 0; 0 1 0; 0 0 1]*0.8;
    dimHandles = [];
    timeAxis = (1:200)*0.01;
    
    figure('Position',[157   876   501   218]);
    hold on
    for dimIdx=1:3
        trg = dat.allTargs(loopIdx,plotDims(dimIdx));
        centerValue = mean(trg);
        
        trg = trg - centerValue;
        out = dat.allOutputs(loopIdx,plotDims(dimIdx));
        out = out - centerValue;
        
        dimHandles(end+1) = plot(timeAxis, trg+dimIdx*0.0,'LineWidth',2,'Color',colors(dimIdx,:));
        plot(timeAxis, out+dimIdx*0.0,':','LineWidth',2,'Color',colors(dimIdx,:));
    end
    plot([0.2,0.2],[0.0,0.2],'-k','LineWidth',2);
    legend(dimHandles,{'X','Y','Z'},'Location','NorthEast');
    set(gca,'FontSize',18,'LineWidth',2);
    xlabel('Time (s)');
    ylim([-0.2 0.2]);
    title(['Gen ' num2str(exampleGen(gen)+1)]);
    exportPNGFigure(gcf,[saveDir 'reconExample' num2str(exampleGen(gen)+1)]);
end

