%name, linear blocks, nonlinear blocks
datasets = {'t5.2017.09.25',[5 9],[6 7 8]
    't5.2017.10.04',[10]};

paths = getFRWPaths();
addpath(genpath(paths.codePath));

allDistLin = [];
allDistNonlin = [];
allSpeedLin = [];
allSpeedNonlin = [];
allMovTimesLin = [];
allMovTimesNonlin = [];
allSuccessLin = [];
allSuccessNonlin = [];

allDialLin = [];
allDialNonlin = [];
allTransLin = [];
allTransNonlin = [];

for d=1:size(datasets,1 )
    dataset = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1}];
    saveDir = [paths.dataPath filesep 'Derived' filesep 'nonlinearGain' filesep datasets{d,1}];
    mkdir(saveDir);
  
    %%
    cd(dataset);
    global modelConstants;
    modelConstants = modelDefinedConstants();

    sessionPath = modelConstants.sessionRoot;
    if ~exist([sessionPath 'Analysis' filesep 'Model Optimization'],'dir')
        mkdir([sessionPath 'Analysis' filesep 'Model Optimization']);
    end
    flDir = [sessionPath modelConstants.dataDir 'FileLogger/'];

    blockNums = [datasets{d,2}, datasets{d,3}];
    R = [];
    for b=1:length(blockNums)
        R = [R, onlineR(loadStream([flDir num2str(blockNums(b)) '/'], blockNums(b)))];
    end
    load([sessionPath 'Data' filesep 'Filters' filesep R(1).decoderD.filterName '.mat']);

    %%
    st = zeros(size(R));
    for t=1:length(R)
        st(t) = R(t).startTrialParams.blockNumber;
    end

    removeTrl = false(size(R));
    for b=1:length(blockNums)
        trlIdx = find(st==blockNums(b));
        removeTrl(trlIdx(1))=true;
    end
    keepTrl = ~removeTrl;

    movTime = [R.trialLength]/1000;
    dialTime = zeros(size(movTime));
    transTime = zeros(size(dialTime));
    
    for x=1:length(R)
        if isempty(R(x).timeFirstTargetAcquire/1000)
            transTime(x) = movTime(x);
            dialTime(x) = nan;
        else
            transTime(x) = R(x).timeFirstTargetAcquire/1000;
            dialTime(x) = movTime(x) - transTime(x) - 1.0;
        end
    end
    
    colors = hsv(length(blockNums));

    figure
    hold on
    for b=1:length(blockNums)
        trlIdx = find(st==blockNums(b) & keepTrl);
        plot(trlIdx, movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
    end
    xlabel('Trial #');
    ylabel('Trial Time (s)');
    set(gca,'LineWidth',1.5,'FontSize',16);
    saveas(gcf,[saveDir filesep 'movTime.png'],'png');

    %%
    nonlinIdx = ismember(st,datasets{d,3});
    linIdx = ismember(st,datasets{d,2});
    keepTrl = keepTrl & (nonlinIdx | linIdx);

    figure
    anova1(movTime(keepTrl), nonlinIdx(keepTrl));
    set(gca,'LineWidth',1.5,'FontSize',16,'XTickLabel',{'Linear','Nonlinear'});
    ylabel('Trial Time (s)');

    nBins = 4000;
    distAvg = [];
    speedAvg = [];
    for t=1:length(R)
        tmpDist = matVecMag(bsxfun(@plus, R(t).cursorPosition(1:4,:), - R(t).posTarget(1:4))',2);
        tmpSpeed = matVecMag([0 0 0 0; diff(R(t).cursorPosition(1:4,:)')],2)*1000;
        idxToPull = 1:min(length(tmpSpeed),nBins);

        newDistRow = nan(1, nBins);
        newDistRow(idxToPull) = tmpDist(idxToPull);

        newSpeedRow = nan(1, nBins);
        newSpeedRow(idxToPull) = tmpSpeed(idxToPull);

        distAvg = [distAvg; newDistRow];
        speedAvg = [speedAvg; newSpeedRow];
    end

    timeAxis = (1:nBins)/1000;

    figure('Position',[680   766   838   332]);
    subplot(1,2,1);
    hold on;
    plot(timeAxis, nanmedian(distAvg(linIdx & keepTrl,:)),'b','LineWidth',2);
    plot(timeAxis, nanmedian(distAvg(nonlinIdx & keepTrl,:)),'r','LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('Distance (m)');

    subplot(1,2,2);
    hold on;
    plot(timeAxis, nanmedian(speedAvg(linIdx,:)),'b','LineWidth',2);
    plot(timeAxis, nanmedian(speedAvg(nonlinIdx,:)),'r','LineWidth',2);
    set(gca,'LineWidth',1.5,'FontSize',16);
    xlabel('Time (s)');
    ylabel('Speed (m/s)');
    saveas(gcf,[saveDir filesep 'distanceAndSpeed.png'],'png');
    
    allDistLin = [allDistLin; distAvg(linIdx & keepTrl,:)];
    allDistNonlin = [allDistNonlin; distAvg(nonlinIdx & keepTrl,:)];
    allSpeedLin = [allSpeedLin; speedAvg(linIdx,:)];
    allSpeedNonlin = [allSpeedNonlin; speedAvg(nonlinIdx,:)];
    allMovTimesLin = [allMovTimesLin; movTime(keepTrl & linIdx)'];
    allMovTimesNonlin = [allMovTimesNonlin; movTime(keepTrl & nonlinIdx)'];
    
    isSuccessful = [R.isSuccessful];
    allSuccessLin = [allSuccessLin; isSuccessful(keepTrl & linIdx)'];
    allSuccessNonlin = [allSuccessNonlin; isSuccessful(keepTrl & nonlinIdx)'];
    
    allDialLin = [allDialLin; dialTime(keepTrl & linIdx)'];
    allDialNonlin = [allDialNonlin; dialTime(keepTrl & nonlinIdx)'];
    
    allTransLin = [allMovTimesLin; transTime(keepTrl & linIdx)'];
    allTransNonlin = [allMovTimesNonlin; transTime(keepTrl & nonlinIdx)'];
    
    %%
    for t=1:length(R)
        R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand, model.thresholds');
    end

    opts.filter = false;
    data = unrollR_generic(R, 20, opts);

    decoder = model.K([2 4 6 8],1:192)/(1-model.alpha);
    decoder = bsxfun(@times, decoder, model.invSoftNormVals(1:192)');

    decFeatures = (data.spikes/50)*(15/20);
    decFeatures = bsxfun(@plus, decFeatures, -mean(decFeatures));

    neuralPush = (decFeatures * decoder')*1000/model.beta;

    isSuccTrl = [R.isSuccessful];
    fTargFits = cell(length(blockNums),1);
    for b=1:length(blockNums)
        trlIdx = (st==blockNums(b)) & isSuccTrl;
        loopIdx = expandEpochIdx([data.reachEvents(trlIdx,2)+10, data.reachEvents(trlIdx,3)]);
        fTargFits{b} = fitFTarg(data.targetPos(loopIdx,1:4) - data.cursorPos(loopIdx,1:4), neuralPush(loopIdx,:), 0.1, 10);
    end

    figure
    hold on
    for b=1:length(blockNums)
        plot(fTargFits{b}(:,1), fTargFits{b}(:,2), '-o', 'LineWidth', 2, 'Color', colors(b,:));
    end
    legend(mat2stringCell(blockNums));
    saveas(gcf,[saveDir filesep 'controlPolicy.png'],'png');

    %%
    fContrib = bsxfun(@times, decFeatures, matVecMag(decoder',2)');
    fContrib = gaussSmooth_fast(fContrib, 10)*1000/model.beta;

    biasEst = [R.xkModBiasEst]';
    biasEst = biasEst(1:20:end,2:2:8)*1000/model.beta;

    figure
    imagesc(abs(decFeatures)',[0 2]);

    figure
    subplot(1,2,1);
    hold on
    plot(biasEst,'LineWidth',2);

    subplot(1,2,2);
    hold on
    plot(matVecMag(biasEst,2),'LineWidth',2);

    figure
    hold on
    plot(matVecMag(biasEst,2)*14,':','LineWidth',2,'Color',[0.5 0.5 0.5]);
    for b=1:length(blockNums)
        trlIdx = find(st==blockNums(b) & keepTrl);
        plot(data.reachEvents(trlIdx,2), movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
    end
    xlabel('Trial Start');
    ylabel('Trial Time (s)');
    set(gca,'LineWidth',1.5,'FontSize',16);
    saveas(gcf,[saveDir filesep 'movTime.png'],'png');

    figure
    hold on
    imagesc(fContrib',[0 0.1]);
    plot(biasEst*100 + 100,'LineWidth',3);

    figure
    hold on
    for b=1:length(blockNums)
        trlIdx = find(st==blockNums(b) & keepTrl);
        plot(trlIdx, movTime(trlIdx), 'o', 'Color', colors(b,:), 'MarkerFaceColor',colors(b,:));
    end
    
    %%
    close all;

end

%%
%average over both days with CI
%[mn, ~, CI] = normfit(allDistLin)
saveDir = [paths.dataPath filesep 'Derived' filesep 'nonlinearGain'];
mkdir(saveDir);
    
allDat = {allDistLin, allDistNonlin, allSpeedLin, allSpeedNonlin};
allCI = cell(4,1);
for x=1:length(allDat)
    disp(x);
    allCI{x} = zeros(size(allDat,2),2);
    for t=1:size(allDat{x},2)
        tmp = allDat{x}(:,t);
        tmp(isnan(tmp)) = [];
        [pval_or_rej,methname,allCI{x}(t,1),allCI{x}(t,2)] = quantile_inf(tmp,[],0.5,0,0,0.05);
    end
end

for x=3:4
    allDat{x}(:,1) = allDat{x}(:,2);
    allCI{x}(1,:) = allCI{x}(2,:);
end

xAxisNorm = linspace(0,1.2,100);
tDist = 10;

figure('Position',[680         871        1055         227]);
subplot(1,3,1);
hold on;
plot([xAxisNorm(1), xAxisNorm(end)], [0,0.056235]*1.2*100/tDist, '--k','LineWidth',2);
plot(xAxisNorm, 100*0.092832*(xAxisNorm.^(2.5))/tDist, '-b','LineWidth',2);
xlabel('Input Speed (normalized)');
ylabel('Output Speed (TD/s)');
set(gca,'LineWidth',1.5,'FontSize',16);
xlim([xAxisNorm(1), xAxisNorm(end)]);

subplot(1,3,2);
hold on;

plot(timeAxis(1:20:end), 100*nanmedian(allDat{1}(:,1:20:end))/tDist,'Color',[0.8 0 0],'LineWidth',2);
fHandle = errorPatch( timeAxis(1:20:end)', 100*allCI{1}(1:20:end,:)/tDist, 'r', 0.2 );

plot(timeAxis(1:20:end), 100*nanmedian(allDat{2}(:,1:20:end))/tDist,'Color',[0 0 0.8],'LineWidth',2);
fHandle = errorPatch( timeAxis(1:20:end)', 100*allCI{2}(1:20:end,:)/tDist, 'b', 0.2 );

plot(get(gca,'XLim'), 100*[R(1).startTrialParams.targetDiameter, R(1).startTrialParams.targetDiameter]/2/tDist, '--k','LineWidth',1);
set(gca,'YScale','log');
set(gca,'YTick',[0.1,1.0]);
set(gca,'LineWidth',1.5,'FontSize',16);
ylim([0.075,1.2]);
xlabel('Time (s)');
ylabel('Distance from\newlineTarget (Normalized)');
%ylim([1, 12]);

subplot(1,3,3);
hold on;

plot(timeAxis(1:20:end), 100*nanmedian(allDat{3}(:,1:20:end))/tDist,'Color',[0.8 0 0],'LineWidth',2);
fHandle = errorPatch( timeAxis(1:20:end)', 100*allCI{3}(1:20:end,:)/tDist, 'r', 0.2 );

plot(timeAxis(1:20:end), 100*nanmedian(allDat{4}(:,1:20:end))/tDist,'Color',[0 0 0.8],'LineWidth',2);
fHandle = errorPatch( timeAxis(1:20:end)', 100*allCI{4}(1:20:end,:)/tDist, 'b', 0.2 );

set(gca,'LineWidth',1.5,'FontSize',16);
xlabel('Time (s)');
ylabel('Speed (TD/s)');

set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w','Renderer','painters');
saveas(gcf,[saveDir filesep 'distanceAndSpeed_bothDays.png'],'png');
saveas(gcf,[saveDir filesep 'distanceAndSpeed_bothDays.svg'],'svg');

%%
[h,p]=ttest2(allMovTimesLin, allMovTimesNonlin);

disp('Movement Time');
disp(['Nonlin: ' num2str(mean(allMovTimesNonlin))]);
disp(['Lin: ' num2str(mean(allMovTimesLin))]);
disp(p);

%%
tb = zeros(2);
tb(1,1) = sum(allSuccessLin);
tb(1,2) = sum(allSuccessNonlin);
tb(2,1) = sum(~allSuccessLin);
tb(2,2) = sum(~allSuccessNonlin);

[h,p,stats] = fishertest(tb);

disp('Success Rate');
disp(['Nonlin: ' num2str(mean(allSuccessNonlin))]);
disp(['Lin: ' num2str(mean(allSuccessLin))]);
disp(p);

%%
[h,p]=ttest2(allDialLin, allDialNonlin);
disp('Dial Time');
disp(['Nonlin: ' num2str(nanmean(allDialNonlin))]);
disp(['Lin: ' num2str(nanmean(allDialLin))]);
disp(p);

%%
[h,p]=ttest2(allTransLin, allTransNonlin);
disp('Trans Time');
disp(['Nonlin: ' num2str(nanmean(allTransNonlin))]);
disp(['Lin: ' num2str(nanmean(allTransLin))]);
disp(p);

%%
colors = [0 0 0.8; 0.8 0 0;];
barColors = 0.5*colors + 0.5*ones(size(colors));
statNames = {'Success %','Translation Time (s)','Dial-in Time (s)'};
dat = {{allSuccessNonlin, allSuccessLin},{allTransNonlin, allTransLin},{allDialNonlin, allDialLin}};

figure('Position',[198   654   865   236]);
for statIdx = 1:length(statNames)
    subplot(1,5,statIdx);
    hold on
    for t=1:2
        [height, ~, CI] = normfit(dat{statIdx}{t}(~isnan(dat{statIdx}{t})));
        rectangle('Position',[t-0.4 0 0.8 height],'FaceColor',barColors(t,:),'LineWidth',1);
        errorbar(t,height,height-CI(1),CI(2)-height,'k','LineWidth',1);
    end
    xlim([0 2]+0.5);
    ylabel(statNames{statIdx});
    set(gca,'XTick',1:2,'XTickLabel',{'Nonlinear','Linear'},'XTickLabelRotation',45);
    set(gca,'LineWidth',1);
    set(gca,'FontSize',14);
end
exportPNGFigure(gcf, [saveDir filesep 'perfBar']);

% 
% %%
% allDat = {allDistLin, allDistNonlin, allSpeedLin, allSpeedNonlin};
% allCI = cell(4,1);
% for x=1:length(allDat)
%     disp(x);
%     allCI{x} = zeros(size(allDat,2),2);
%     for t=1:size(allDat{x},2)
%         tmp = allDat{x}(:,t);
%         tmp(isnan(tmp)) = [];
%         [~,~,allCI{x}(t,:)] = normfit(tmp);
%     end
% end
% 
% for x=3:4
%     allDat{x}(:,1) = allDat{x}(:,2);
%     allCI{x}(1,:) = allCI{x}(2,:);
% end
% 
% figure('Position',[680         871        1055         227]);
% subplot(1,3,1);
% hold on;
% plot([xAxisNorm(1), xAxisNorm(end)], [0,0.056235]*1.2*100/tDist, '--k','LineWidth',2);
% plot(xAxisNorm, 100*0.092832*(xAxisNorm.^(2.5))/tDist, '-b','LineWidth',2);
% xlabel('Input Speed (normalized)');
% ylabel('Output Speed (TD/s)');
% set(gca,'LineWidth',1.5,'FontSize',16);
% xlim([xAxisNorm(1), xAxisNorm(end)]);
% 
% subplot(1,3,2);
% hold on;
% 
% plot(timeAxis, 100*nanmean(allDat{1})/tDist,'Color',[0 0 0.8],'LineWidth',2);
% fHandle = errorPatch( timeAxis', 100*allCI{1}/tDist, 'b', 0.2 );
% 
% plot(timeAxis, 100*nanmean(allDat{2})/tDist,'Color',[0.8 0 0],'LineWidth',2);
% fHandle = errorPatch( timeAxis', 100*allCI{2}/tDist, 'r', 0.2 );
% 
% plot(get(gca,'XLim'), 100*[R(1).startTrialParams.targetDiameter, R(1).startTrialParams.targetDiameter]/2/tDist, '--k');
% set(gca,'YScale','log');
% set(gca,'LineWidth',1.5,'FontSize',16);
% xlabel('Time (s)');
% ylabel('Distance (Normalized)');
% %ylim([1, 12]);
% 
% subplot(1,3,3);
% hold on;
% 
% plot(timeAxis, 100*nanmean(allDat{3})/tDist,'Color',[0 0 0.8],'LineWidth',2);
% fHandle = errorPatch( timeAxis', 100*allCI{3}/tDist, 'b', 0.2 );
% 
% plot(timeAxis, 100*nanmean(allDat{4})/tDist,'Color',[0.8 0 0],'LineWidth',2);
% fHandle = errorPatch( timeAxis', 100*allCI{4}/tDist, 'r', 0.2 );
% 
% set(gca,'LineWidth',1.5,'FontSize',16);
% xlabel('Time (s)');
% ylabel('Speed (TD/s)');
% saveas(gcf,[saveDir filesep 'distanceAndSpeed_bothDays.png'],'png');
% saveas(gcf,[saveDir filesep 'distanceAndSpeed_bothDays.svg'],'svg');
