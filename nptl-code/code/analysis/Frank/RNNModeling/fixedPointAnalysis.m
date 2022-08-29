fp0 = load('/Users/frankwillett/Data/armControlNets/fp_comp0.mat');
fp1 = load('/Users/frankwillett/Data/armControlNets/fp_comp1.mat');

datasetName = 'osim2d_radial8_2comp_vmrLong_gen5_0';
%datasetName = 'osim2d_radial8_multi_2comp_vmrLong_gen5_0';
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

load(['/Users/frankwillett/Data/armControlNets/osimModelDiagnostics/' datasetName '.mat']);
saveDir = [rootSaveDir datasetName];
mkdir(saveDir);

%%
posIdx = [47,48];
actIdx = [16,20,24,28,32,36]+1;
musToPlot = [1,2,5];
plotUnitIdx = [11,150,220];
feedbackIdx = [6,7,8,9,10,11,17,21,25,29,33,37,18,22,26,30,34,38]+1;
musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};       

%osim
posDist = distEnvState(:,posIdx);
posReal = envState(:,posIdx);
targ = controllerInputs(:,1:min(3, size(controllerInputs,2)));
vel = diff(posReal)/0.01;
potSpace = controllerReadout_W0_0;

if exist('rnnState','var')
    rnnStates = cell(size(rnnState,1),1);
    for x=1:size(rnnState,1)
        rnnStates{x} = squeeze(rnnState(x,:,:));
    end
else
    rnnStates = {};
    for x=0:9
        if exist(['rnnState_' num2str(x)],'var')
            rnnStates{end+1} = double(eval(['rnnState_' num2str(x)]));
        end
    end
end

timeOffset = 50;

%%
%trial coding
outerIdx = 2:2:length(trialStartIdx);
targ = targ(trialStartIdx(outerIdx)+timeOffset+1,:);
targList = unique(targ, 'rows');
targCodes = (1:8)';

%%
%plot trajectories
plotIdx = outerIdx;

colors = hsv(length(plotIdx))*0.8;
figure;
hold on;
plot(targList(:,1), targList(:,2), 'ko','LineWidth',2,'MarkerSize',30);
for trlIdx=1:length(plotIdx)
    loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
    if any(loopIdx>length(posDist))
        continue;
    end
    plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 3.0,'Color',colors(trlIdx,:));
end
plot([0.07,0.07],[-0.44,-0.34]+0.13,'-k','LineWidth',2);
axis equal;
axis off;
exportPNGFigure(gcf, [saveDir filesep 'trajPicture'])

centerPos = [0.2, -0.325];
dimNames = {'X Position', 'Y Position'};
figure('Position',[484   591   262   494]);
for dimIdx=1:2
    colors = hsv(length(plotIdx))*0.8;
    subplot(2,1,dimIdx);
    hold on;

    posLims = [min(posDist(:,dimIdx))-0.03, max(posDist(:,dimIdx))+0.03];
    posMiddle = mean(posLims);
    %rec = rectangle('Position',[-0.25,posLims(1),0.25,abs(diff(posLims))],'LineWidth',2,'FaceColor',[0.8 0.8 1.0],'EdgeColor',[0.8 0.8 1.0]);
    plot([0,0],posLims,'--k','LineWidth',2);
    for trlIdx=1:length(plotIdx)
        loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (-25:100);
        timeAxis = (-25:100)*0.01;
        if any(loopIdx>length(posDist))
            continue;
        end

        %make minimum jerk template
        delaySteps = 25;
        rtSteps = 6;
        travelDist = 0.1;
        travelTime = ceil((60 + 105*log(1 + travelDist/0.005))/10.0);
        fullSteps = 126;
        tau = [zeros(1,rtSteps+delaySteps), linspace(0,1,travelTime), ones(1,fullSteps-travelTime-rtSteps-delaySteps)];
        polynomial = 15*power(tau,4) - 6*power(tau,5) - 10*power(tau,3); 

        track = zeros(fullSteps,2);
        for innerDimIdx=1:2
            track(:,innerDimIdx) = centerPos(innerDimIdx) + (centerPos(innerDimIdx)-targ(trlIdx,innerDimIdx)) * polynomial;
        end

        plot(timeAxis,posDist(loopIdx,dimIdx),'LineWidth', 2.0,'Color',colors(trlIdx,:));
        plot(timeAxis,track(:,dimIdx),'--','LineWidth', 2.0,'Color',colors(trlIdx,:));
    end
    axis tight;

    for trlIdx=1:length(plotIdx)
        %plot(get(gca,'XLim'), [targ(trlIdx,dimIdx), targ(trlIdx,dimIdx)], '--', 'Color',colors(trlIdx,:),'LineWidth',2);
    end
    plot([0.0,0.0]-0.1,[-0.05,0.05]+posMiddle+0.06,'-k','LineWidth',2);

    set(gca,'YTick',[]);
    set(gca,'FontSize',16,'LineWidth',2);
    xlabel('Time (s)');
    ylabel(dimNames{dimIdx});
end
exportPNGFigure(gcf, [saveDir filesep 'trajTimeSeries']);

%%
rnnComps = {rnnStates{1}, rnnStates{2}, [rnnStates{1}, rnnStates{2}]};
rnnComps_delayAugment = rnnComps;

for x=1:length(rnnComps_delayAugment)
    rnnComps_delayAugment{x} = [rnnComps{x}(3:end,:), rnnComps{x}(2:(end-1),:), rnnComps{x}(1:(end-2),:)];
end

%plotTrl = 2:length(trialStartIdx);
%plotTrl = outerIdx;
%plotTrl = 64;
plotTrl = 16;
trialSegments = [trialStartIdx, size(rnnComps{1}, 1)];

for compIdx=1:length(rnnComps)
    modeNames = {'all','meanSubtract'};
    for meanSubtractMode=1:2
        neuralAct = rnnComps{compIdx};
        if meanSubtractMode==2
            neuralAct = neuralAct - mean(neuralAct,2);
        end

        allLoopIdx = [];
        for trlIdx=1:length(plotTrl)
            loopIdx = trialSegments(plotTrl(trlIdx)):trialSegments(plotTrl(trlIdx)+1);
            allLoopIdx = [allLoopIdx, loopIdx];
        end
        allLoopIdx(allLoopIdx>size(neuralAct,1))=[];
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(neuralAct(allLoopIdx,:),'centered',false);
        score = neuralAct * COEFF(:,1:3);
        
        figure('Position',[680   827   847   271]);
        ax1 = subplot(1,3,1);
        hold on
        colors = hsv(length(plotTrl))*0.8;
        for trlIdx=1:length(plotTrl)
            loopIdx = trialSegments(plotTrl(trlIdx)):trialSegments(plotTrl(trlIdx)+1);
            tmp = score(loopIdx,:);
            plot3(tmp(:,1), tmp(:,2), tmp(:,3), '-','Color',colors(trlIdx,:),'LineWidth',2);
        end
        axis equal;

        ax2 = subplot(1,3,2);
        hold on
        for trlIdx=1:length(plotTrl)
            loopIdx = trialSegments(plotTrl(trlIdx)):trialSegments(plotTrl(trlIdx)+1);
            tmp = score(loopIdx,:);
            
            colors = parula(size(tmp,1))*0.8;
            for t=1:size(tmp,1)
                plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
            end
        end
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(controllerOutputs(allLoopIdx,:),'centered',false);
        score = controllerOutputs * COEFF(:,1:3);
        
        ax3 = subplot(1,3,3);
        hold on
        for conIdx=1:size(score,2)
            loopIdx = trialSegments(plotTrl(trlIdx)):trialSegments(plotTrl(trlIdx)+1);
            tmp = score(loopIdx,:);
            
            colors = parula(size(tmp,1))*0.8;
            for t=1:size(tmp,1)
                plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
            end
        end

        linkprop([ax1, ax2],'View');

        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_pca3dim_' modeNames{meanSubtractMode}]);
    end
end
%%
%avg speed
timeWindow = [-25, 100];

handSpeed = [0; matVecMag(vel,2)];
avgSpeed_short = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 50]);
avgSpeed_short = nanmean(avgSpeed_short)';

avgSpeed_long = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 100]);
avgSpeed_long = nanmean(avgSpeed_long)';

%%
%collect signals
dPCA_signals = cell(0);
signalNames = cell(0);
for compIdx=1:length(rnnStates)
    dPCA_signals{end+1} = rnnStates{compIdx};
    signalNames{end+1} = ['Units_' num2str(compIdx)];
end
dPCA_signals{end+1} = zscore([controllerInputs, envState(:,feedbackIdx)]);
signalNames{end+1} = 'Inputs';

dPCA_signals{end+1} = zscore(controllerOutputs);
signalNames{end+1} = 'Mus';

%%
%single-factor neural
featAvg = cell(length(dPCA_signals),1);
for signalIdx = 1:length(dPCA_signals)
    dPCA_out = apply_dPCA_simple( dPCA_signals{signalIdx}, trialStartIdx(outerIdx)+timeOffset, ...
        targCodes, timeWindow, 0.010, {'CD','CI'}, min(20, size(dPCA_signals{signalIdx},2)) );
    exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA_defaultPlot'])
    featAvg{signalIdx} = dPCA_out.featureAverages;

    lineArgs = cell(length(unique(targCodes)),1);
    colors = jet(length(lineArgs))*0.8;
    for l=1:length(lineArgs)
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
    end
    oneFactor_dPCA_plot_pretty( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);
    set(gcf,'Position',[48         515        1333         250]);
    exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA'])

    oneFactor_dPCA_plot_pretty( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'sameAxes', avgSpeed_long);
    set(gcf,'Position',[48         515        1333         250]);
    exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_dPCA_same'])

    save([saveDir filesep signalNames{signalIdx} '_dPCA'],'dPCA_out','avgSpeed_long');

    %potent space alignment
    %psNorm = potSpace ./ matVecMag(potSpace,1);
    %wNorm = dPCA_out.W ./ matVecMag(dPCA_out.W,1);
    %alignment = wNorm'*psNorm;
    %alignment = matVecMag(alignment,2);

    %3D plot
    modeNames = {'all','meanSubtract'};
    for meanSubtractMode=1:2
        neuralAct = featAvg{signalIdx};
        if meanSubtractMode==2
            neuralAct = neuralAct - mean(neuralAct,2);
        end

        rs = reshape(neuralAct,size(featAvg{signalIdx},1),[])';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(rs);
        score = SCORE(:,1:3);
        score = reshape(score', 3, size(featAvg{signalIdx},2), size(featAvg{signalIdx},3));

        figure('Position',[680   827   847   271]);
        ax1 = subplot(1,3,1);
        hold on
        for conIdx=1:size(score,2)
            tmp = squeeze(score(:,conIdx,:))';
            colors = hsv(size(score,2))*0.8;
            plot3(tmp(:,1), tmp(:,2), tmp(:,3), 'o','Color',colors(conIdx,:));
        end

        ax2 = subplot(1,3,2);
        hold on
        for conIdx=1:size(score,2)
            tmp = squeeze(score(:,conIdx,:))';
            colors = parula(size(tmp,1))*0.8;
            for t=1:size(tmp,1)
                plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
            end
        end

        ax3 = subplot(1,3,3);
        hold on
        for conIdx=1:size(score,2)
            tmp = squeeze(score(:,conIdx,:))';
            colors = parula(size(tmp,1))*0.8;
            for t=1:size(tmp,1)
                plot3(tmp(t,1), tmp(t,2), tmp(t,3), 'o', 'Color', colors(t,:));
            end
        end
        
        linkprop([ax1, ax2],'View');

        exportPNGFigure(gcf, [saveDir filesep signalNames{signalIdx} '_pca3dim_' modeNames{meanSubtractMode}]);
    end
end
