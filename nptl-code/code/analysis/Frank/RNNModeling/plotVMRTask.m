datasets = {
    '30degrees_0','osim2d';
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)
    dat = cell(8,1);
    for x=0:7
        dat{x+1} = load(['/Users/frankwillett/Data/armControlNets/osim2d_vmrAdaptCentered_2comp_vmrLong_gen5_' num2str(x) '.mat']);
    end

    fields = {'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'};
    datSudden = struct();
    for f=1:length(fields)
        datSudden.(fields{f}) = [];
        for x=1:length(dat)
            if x==1
                datSudden.(fields{f}) = dat{x}.(fields{f});
                if f==1
                    datSudden.trialStartIdx = dat{x}.trialStartIdx;
                end
            else
                if f==1
                    datSudden.trialStartIdx = [datSudden.trialStartIdx, dat{x}.trialStartIdx+size(datSudden.rnnState,2)];
                end
                if strcmp(fields{f},'rnnState')
                    datSudden.(fields{f}) = cat(2, datSudden.(fields{f}), dat{x}.(fields{f}));
                else
                    datSudden.(fields{f}) = [datSudden.(fields{f}); dat{x}.(fields{f})];
                end
            end
        end
    end
        
    load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1}]); 
    saveDir = [rootSaveDir datasets{datasetIdx,1}];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim2d')
        posIdx = [47,48];
        actIdx = [16,20,24,28,32,36]+1;
        musToPlot = [1,2,5];
        plotUnitIdx = 1:25;
        musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};        
    end
    
    %osim
    rnnState = cat(2, rnnState(:,1:size(controllerOutputs,1),:), datSudden.rnnState);
    posDist = [distEnvState(:,posIdx); datSudden.distEnvState(:,posIdx)];
    posReal = [envState(:,posIdx); datSudden.envState(:,posIdx)];
    targ = [controllerInputs(:,1:2); datSudden.controllerInputs(:,1:2)];
    envState = [envState; datSudden.envState];
    vel = diff(posDist)/0.01;
    trialStartIdx = [trialStartIdx, datSudden.trialStartIdx+length(distEnvState)] + 1;

    %%
    %coding
    trialStartIdx = double(trialStartIdx);

    outerIdx = 2:2:length(trialStartIdx);
    adaptedIdx = outerIdx(25:32);
    suddenIdx = (length(trialStartIdx)-14):2:length(trialStartIdx);
    allPlotIdx = [suddenIdx, adaptedIdx];
    timeOffset = [repmat(100,1,8), repmat(50,1,8)];
    
    targ = targ(trialStartIdx(allPlotIdx)+1,1:2);
    targList = unique(targ,'rows');

    %%  
    colors = [hsv(8); hsv(8)]*0.8;
    figure;
    hold on;
    plot(targList(:,1), targList(:,2), 'ko','LineWidth',2,'MarkerSize',30);
    for trlIdx=1:length(allPlotIdx)
        loopIdx = trialStartIdx(allPlotIdx(trlIdx)) + timeOffset(trlIdx) + (1:100);
        if trlIdx<=8
            ls = ':';
        else
            ls = '-';
        end
        plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 3.0,'Color',colors(trlIdx,:),'LineStyle',ls);
    end
    plot([0.07,0.07],[-0.44,-0.34]+0.13,'-k','LineWidth',2);
    axis equal;
    axis off;
    exportPNGFigure(gcf, [saveDir filesep 'trajComparison'])

    %%
    %avg speed
    handSpeed = [0; matVecMag(vel,2)];
    outerIdx = 1:16;
    perturbIdx = suddenIdx;
    cleanIdx = adaptedIdx;
    
    avgSpeed_short_p = triggeredAvg(double(handSpeed), double(trialStartIdx(perturbIdx)+100), [-25, 50]);
    avgSpeed_short_p = nanmean(avgSpeed_short_p)';
    
    avgSpeed_long_p = triggeredAvg(double(handSpeed), double(trialStartIdx(perturbIdx)+100), [-25, 100]);
    avgSpeed_long_p = nanmean(avgSpeed_long_p)';
    
    avgSpeed_short_c = triggeredAvg(double(handSpeed), double(trialStartIdx(cleanIdx)+50), [-25, 50]);
    avgSpeed_short_c = nanmean(avgSpeed_short_c)';
    
    avgSpeed_long_c = triggeredAvg(double(handSpeed), double(trialStartIdx(cleanIdx)+50), [-25, 100]);
    avgSpeed_long_c = nanmean(avgSpeed_long_c)';
    
    %%
    %single-factor neural
    useTrl = 1:16;
    timeWindow = [-25, 100];
    featAvg = cell(size(rnnState,1),1);

    for compIdx=1:size(rnnState,1)
        dPCA_out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(allPlotIdx)+timeOffset, ...
           (1:16)', timeWindow, 0.010, {'CD','CI'} );
        close(gcf);
        featAvg{compIdx} = dPCA_out.featureAverages;
    end
    close all;

    %%
    %unit activation
    colors = [hsv(8); hsv(8)]*0.8;
    timeWindow = [-25, 100];
    timeAxis = 0.01*(timeWindow(1):timeWindow(2));
    windowIdx = timeWindow(1):timeWindow(2);
    plotUnitIdx = [3 4 11];
    plotStartIdx = trialStartIdx(allPlotIdx);
    
    for compIdx=1:length(featAvg)
        figure('Position',[392   573   251   521]);
        for unitIdx=1:length(plotUnitIdx)
            subtightplot(3,1,unitIdx,[0.03,0.01]);
            hold on;
            for x=1:2:size(featAvg{compIdx},2)
                if x<=8
                    ls = ':';
                else
                    ls = '-';
                end
                plot(timeAxis,squeeze(featAvg{compIdx}(plotUnitIdx(unitIdx),x,:)),'LineWidth',2,'Color',colors(x,:),'LineStyle',ls);
            end

            axis tight;  
            plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
            plotBackgroundSignal( timeAxis, [avgSpeed_long_c, avgSpeed_long_p] );

            set(gca,'LineWidth',2);
            set(gca,'FontSize',22);
            xlabel('Time (s)');
            ylabel('Unit Activation');
            title(['Unit ' num2str(plotUnitIdx(unitIdx))]);
            yLimits = get(gca,'YLim');
            if unitIdx==length(plotUnitIdx)
                plot([0,0.5],[yLimits(1), yLimits(1)]+abs(diff(yLimits))*0.1,'-k','LineWidth',2)
            end
            axis off;
        end
        saveas(gcf,[saveDir filesep 'unitExamples_comp' num2str(compIdx) '.png'],'png');
        saveas(gcf,[saveDir filesep 'unitExamples)comp' num2str(compIdx) '.svg'],'svg');
    end

    %%
    %muscle activation
    musToPlot = [2 3 4];
    colors = [hsv(8); hsv(8)]*0.8;
    
    figure('Position',[392   573   251   521]);
    for musIdx=1:length(musToPlot)
        subtightplot(3,1,musIdx,[0.03,0.01]);
        hold on;
        for x=1:2:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset(x);
            if x<=8
                ls = ':';
            else
                ls = '-';
            end
            plot(timeAxis, squeeze(envState(loopIdx,actIdx(musToPlot(musIdx)))),'LineWidth',2,'Color',colors(x,:),'LineStyle',ls);
        end
        axis tight;   
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, [avgSpeed_long_c, avgSpeed_long_p] );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',22);
        xlabel('Time (s)');
        ylabel('Muscle Activation');
        title(musNames{musToPlot(musIdx)});
        yLimits = get(gca,'YLim');
        if unitIdx==length(plotUnitIdx)
            plot([0,0.5],[yLimits(1), yLimits(1)]+abs(diff(yLimits))*0.1,'-k','LineWidth',2)
        end
        axis off;
    end
    saveas(gcf,[saveDir filesep 'musActExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'musActExamples.svg'],'svg');
    
    %%
    close all;
end
