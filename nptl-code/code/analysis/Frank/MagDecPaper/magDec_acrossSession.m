%%
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

plotDir = [paths.dataPath '/CaseDerived/psth/'];

sessionList = { 't8','t8.2016.07.15_Cart2D_Replay',[12:18 21],'centerOut','case3d';
    't9','t9.2016.08.01 Intention Estimator Comparison',[4:12],'centerOut','twigs';
    't10','t10.2017.04.03 PMd vs M1',[6 8 10 12 14 16 18 20],'centerOut_PMDvsMI','radial2015'
    't5','t5.2016.09.28',[4 6],'centerOut','centerOut_t5'
    
    't8','t8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp',[4:11],'fittsImmediate','case3d'
    't9','t9.2016.08.11 CLAUS GP & Kalman',[8 10 13 15],'fittsImmediate','brownTwigs'
    't10','t10.2016.08.24 Claus Kalman',[8 12 15 22 31 37],'fittsImmediate','brownTwigs'
    't5','t5.2016.09.28',[7 8 9 10],'fittsImmediate','grid_t5'
    };
featureTypes = {'ncTX and SpikePower','Sorted','ncTX'};

%%
for featureIdx=1:2

    plotIdx = [8 5 6 7];
    sColors = hsv(length(plotIdx))*0.8;
    lHandles = zeros(length(plotIdx),1);
    
    figure('Position',[624   681   366   297]);
    hold on
    for s=1:length(plotIdx)
        saveDir = [plotDir sessionList{plotIdx(s),2} ' ' sessionList{plotIdx(s),4} filesep featureTypes{featureIdx}];
        load([saveDir filesep 'xValSpeedDec'],'csWeight','speedSummary');
        
        lHandles(s)=plot(csWeight, speedSummary(:,1), 'Color', sColors(s,:), 'LineWidth', 1);
        errorPatch(csWeight, speedSummary(:,2:3), sColors(s,:), 0.2);
        xlabel('||c|| Weight');
        ylabel('Near vs. Far Speed Separation');
    end
    ylim([0 2.4]);
    legend(lHandles, {'T5','T8','T9','T10'});
    set(gca,'FontSize',16,'LineWidth',1.5);
    exportPNGFigure(gcf, [plotDir 'xValSpeedDec ' featureTypes{featureIdx}]);
    
    for s=1:6
        saveDir = [plotDir sessionList{s,2} ' ' sessionList{s,4} filesep featureTypes{featureIdx}];
        load([saveDir filesep 'modelOutput.mat']);
        sigIdx = find(fullModel{1}.R2Vals>0.01);
        disp(corr(fullModel{1}.expCoef(2:end,sigIdx)'));
    end

    %%
    figure('Position',[240   610   730   278]);
    subplot(1,2,1);
    hold on

    sToPlot = [4 1 2 3];
    colors = hsv(length(sToPlot))*0.8;
    lHandles = zeros(length(sToPlot),1);

    for s=1:length(sToPlot)
        saveDir = [plotDir sessionList{sToPlot(s),2} ' ' sessionList{sToPlot(s),4} filesep featureTypes{featureIdx}];
        disp(saveDir);
        load([saveDir filesep 'model pca FVAF.mat']);

        cumExp = cumsum(pcaOut.modelCompareSummary.EXPLAINED);
        lHandles(s)=plot(0:8, [0; cumExp(1:8)]','-o','Color',colors(s,:),'LineWidth',2);
        plot(4, pcaOut.modelCompareSummary.fvafAll2, 'x','Color',colors(s,:),'LineWidth',2,'MarkerSize',12);

        allData(s,1) = pcaOut.modelCompareSummary.fvafAll2;
        allData(s,2) = cumExp(8);
        allData(s,3) = cumExp(4);
    end
    xlabel('Principal Components');
    ylabel('% Explained Variance');
    legend(lHandles,{'T5','T8','T9','T10'});
    ylim([0 100]);
    title('Center-Out Datasets');
    set(gca,'FontSize',16);

    subplot(1,2,2);
    hold on
    sToPlot = [8 5 6 7];
    colors = hsv(length(sToPlot))*0.8;
    for s=1:length(sToPlot)
        saveDir = [plotDir sessionList{sToPlot(s),2} ' ' sessionList{sToPlot(s),4} filesep featureTypes{featureIdx}];
        load([saveDir filesep 'model pca FVAF.mat']);

        cumExp = cumsum(pcaOut.modelCompareSummary.EXPLAINED);
        lHandles(s)=plot(0:8, [0; cumExp(1:8)]','-o','Color',colors(s,:),'LineWidth',2);
        plot(4, pcaOut.modelCompareSummary.fvafAll2, 'x','Color',colors(s,:),'LineWidth',2,'MarkerSize',12);

        allData(s+4,1) = pcaOut.modelCompareSummary.fvafAll2;
        allData(s+4,2) = cumExp(8);
        allData(s+4,3) = cumExp(4);
    end
    xlabel('Principal Components');
    ylabel('% Explained Variance');
    legend(lHandles,{'T5','T8','T9','T10'});
    ylim([0 100]);
    title('Random Target & Grid Datasets');
    set(gca,'FontSize',16);

    exportPNGFigure(gcf,[plotDir 'PCA Cumul ' featureTypes{featureIdx}]);
    %%
    %modelTypes = {'FMP','FP','FM','MP','F','P','M'};
    axisLabels = {'[c_x, c_y, ||c||, CIS]', '[c_x, c_y, CIS]', '[c_x, c_y, ||c||]', '[||c||, CIS]', '[c_x, c_y]','CIS','||c||'};
    colors = hsv(4)*0.8;
    mnAll = zeros(size(sessionList,1), 7);
    sToPlot = [8 5 6 7];
    lHandles = zeros(length(sToPlot),1);

    figure('Position',[127   611   641   275]);
    for s=1:length(sToPlot)
        saveDir = [plotDir sessionList{sToPlot(s),2} ' ' sessionList{sToPlot(s),4} filesep featureTypes{featureIdx}];
        load([saveDir filesep 'modelOutput.mat'],'R2Vals');

        R2norm = ((bsxfun(@times, R2Vals, 1./R2Vals(:,1))));
        if featureIdx==2
            sigCutoff = 0.005;
        elseif featureIdx==1
            sigCutoff = 0.01;
        end
        sigIdx = find(any(R2Vals>sigCutoff,2));

        hold on
        for x=1:7
            [mn,~,mnCI] = normfit(R2norm(sigIdx,x));
            mnAll(s,x) = mn;
            lHandles(s)=plot(x + (s-2.5)*0.125, mn, 'o', 'Color', colors(s,:));
            plot([x + (s-2.5)*0.125; x + (s-2.5)*0.125], mnCI, '-', 'Color', colors(s,:),'LineWidth',2);
        end
        ylabel('Normalized FVAF');
        set(gca,'XTick',1:7,'XTickLabel',axisLabels,'XTickLabelRotation',25);
        xlim([0.5 7.5]);
    end
    ylim([0 1]);
    set(gca,'FontSize',16,'LineWidth',1.5);
    for x=1:7
        plot([x+0.5,x+0.5],[0 1],'-','LineWidth',1.5,'Color',[0.7 0.7 0.7]);
    end
    legend(lHandles,{'T5','T8','T9','T10'});
    exportPNGFigure(gcf,[plotDir 'XVal FVAF ' featureTypes{featureIdx}]);

    clipLimit = 0.2;
    figure;
    hold on; 
    for s=1:length(sToPlot)
        saveDir = [plotDir sessionList{sToPlot(s),2} ' ' sessionList{sToPlot(s),4} filesep featureTypes{featureIdx}];
        load([saveDir filesep 'modelOutput.mat'],'R2Vals');
        dots = R2Vals(:,4:5);
        dots(dots>clipLimit) = clipLimit;
        plot(dots(:,1), dots(:,2), 'o', 'Color', colors(s,:), 'MarkerSize', 4); 
        
        useIdx = any(dots>0.01,2);
        disp(corr(dots(useIdx,:)));
    end
    legend({'T5','T8','T9','T10'});
    xlabel(axisLabels{4});
    ylabel(axisLabels{5});
    xlim([0 clipLimit]);
    ylim([0 clipLimit]);
    plot([0 clipLimit],[0 clipLimit],'--k');
    exportPNGFigure(gcf,[plotDir 'XVal R2 ' featureTypes{featureIdx}]);

%ylim([0 1]);
end