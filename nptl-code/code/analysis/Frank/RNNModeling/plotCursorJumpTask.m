datasets = {
    'osim2d_cursorJump_0-5_noAdapt','osim2d';
    'osim2d_cursorJump_0-5_vmrLong','osim2d';
    'osim2d_cursorJump_sooner','osim2d';
    'osim2d_cursorJump_vmrLong','osim2d';
    'Monk/J_2015-06-19_packaged','monk'
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)

    if strcmp(datasets{datasetIdx,2},'osim2d')
        dat = cell(8,1);
        for x=0:7
            dat{x+1} = load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '_' num2str(x) '.mat']);
        end

        fields = {'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'};
        allDat = struct();
        for f=1:length(fields)
            allDat.(fields{f}) = [];
            for x=1:length(dat)
                if x==1
                    allDat.(fields{f}) = dat{x}.(fields{f});
                    if f==1
                        allDat.trialStartIdx = dat{x}.trialStartIdx;
                    end
                else
                    if f==1
                        allDat.trialStartIdx = [allDat.trialStartIdx, dat{x}.trialStartIdx+length(allDat.rnnState)];
                    end
                    if strcmp(fields{f},'rnnState')
                        allDat.(fields{f}) = cat(2, allDat.(fields{f}), dat{x}.(fields{f}));
                    else
                        allDat.(fields{f}) = [allDat.(fields{f}); dat{x}.(fields{f})];
                    end
                end
            end
        end
        for f=1:length(fields)
            eval([fields{f} ' = allDat.(fields{f});']);
        end
        trialStartIdx = allDat.trialStartIdx+1;
    else
        load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '.mat']);
    end
        
    saveDir = [rootSaveDir datasets{datasetIdx,1}];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim2d')
        posIdx = [47,48];
        actIdx = [16,20,24,28,32,36]+1;
        musToPlot = [1,2,5];
        plotUnitIdx = 1:25;
        musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};        
    end
    
    if strfind(datasets{datasetIdx,1}, 'osim')
        %osim
        posDist = distEnvState(:,posIdx);
        posReal = envState(:,posIdx);
        targ = controllerInputs(:,1:3);
        vel = diff(posReal)/0.01;
    else
        %monk
        rnnState = neural;
        posDist = cursorPos;
        posReal = handPos;
        controllerOutputs = [];
        controllerInputs = [];
    end
    
    %%
    if strfind(datasets{datasetIdx,1}, 'osim2d_cursorJump')
        timeOffset = 50;
    else
        timeOffset = -20;
    end
    timeOffset = 50;
    
    %%
    %coding
    if strfind(datasets{datasetIdx,1}, 'osim2d_cursorJump')
        outerIdx = 2:2:length(trialStartIdx);
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset,1:3);
        targList = unique(targ,'rows');
        targCodes = (1:length(outerIdx))';
        
        codeSets = cell(8,1);
        for c=1:length(codeSets)
            codeSets{c} = c:8:length(trialStartIdx);
        end
        cleanIdx = find(ismember(targCodes,1:8));
        perturbIdx = find(~ismember(targCodes,1:8));
    else
        codeSets = {[1 2 3],[4 5 6]};
        outerIdx = 1:length(trialStartIdx);
        targList = unique(targ,'rows');
        cleanIdx = find(ismember(targCodes,[1 4]));
        perturbIdx = find(~ismember(targCodes,[1 4]));
    end
    
    %%
    nPerSide = ceil(sqrt(length(codeSets)));
    
    for setIdx=3
        codeList = unique(codeSets{setIdx});
        plotIdx = outerIdx(ismember(targCodes, codeSets{setIdx})); 
        targIdx = find(ismember(targCodes, codeSets{setIdx}));
        [~,colorIdx] = ismember(targCodes, codeSets{setIdx});
        colorIdx = colorIdx(colorIdx~=0);
        
        colors = hsv(length(plotIdx))*0.8;
        
        figure;
        hold on;
        for trlIdx=1:length(plotIdx)
            loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
            if any(loopIdx>length(posDist)) || any(loopIdx<1)
                continue;
            end

            plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 2.0,'LineStyle','-','Color',colors(colorIdx(trlIdx),:));
            plot(targ(targIdx(trlIdx),1), targ(targIdx(trlIdx),2), 'ko', 'LineWidth',2,'MarkerSize',50);
            %plot(posReal(loopIdx,1), posReal(loopIdx,2),'LineWidth', 1.0,'Color',colors(colorIdx(trlIdx),:));
        end
        plot([0.17,0.17],[-0.44,-0.34]+0.13,'-k','LineWidth',2);
        axis equal;
        axis off;
        exportPNGFigure(gcf,[saveDir filesep 'traj']);
        
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
    end
    
    close all;

    %%
    %avg speed
    handSpeed = [0; matVecMag(vel,2)];
    
    avgSpeed_short_p = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx(perturbIdx))+timeOffset), [-25, 50]);
    avgSpeed_short_p = nanmean(avgSpeed_short_p)';
    
    avgSpeed_long_p = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx(perturbIdx))+timeOffset), [-25, 100]);
    avgSpeed_long_p = nanmean(avgSpeed_long_p)';
    
    avgSpeed_short_c = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx(cleanIdx))+timeOffset), [-25, 50]);
    avgSpeed_short_c = nanmean(avgSpeed_short_c)';
    
    avgSpeed_long_c = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx(cleanIdx))+timeOffset), [-25, 100]);
    avgSpeed_long_c = nanmean(avgSpeed_long_c)';
    
    %%
    for setIdx=3
        %single-factor neural
        useTrl = ismember(targCodes, codeSets{setIdx});
        
        timeWindow = [-25, 100];
        featAvg = cell(size(rnnState,1),1);

        for compIdx=1:size(rnnState,1)
            dPCA_out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(outerIdx(useTrl))+timeOffset, ...
                targCodes(useTrl), timeWindow, 0.010, {'CD','CI'} );
            close(gcf);
            featAvg{compIdx} = dPCA_out.featureAverages;

            lineArgs = cell(length(unique(targCodes(useTrl))),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                if l==1
                    ls='-';
                else
                    ls=':';
                end
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle',ls};
            end
            oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', [avgSpeed_long_c, avgSpeed_long_p]);
            exportPNGFigure(gcf, [saveDir filesep 'comp_' num2str(compIdx) '_dPCA'])
            save([saveDir filesep 'comp_' num2str(compIdx) '_dPCA'],'dPCA_out','avgSpeed_long_c');
            
            %3D plot
            modeNames = {'all','meanSubtract'};
            for meanSubtractMode=1:2
                neuralAct = featAvg{compIdx};
                if meanSubtractMode==2
                    neuralAct = neuralAct - mean(neuralAct,2);
                end

                rs = reshape(neuralAct,size(featAvg{compIdx},1),[])';
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(rs);
                score = SCORE(:,1:3);
                score = reshape(score', 3, size(featAvg{compIdx},2), size(featAvg{compIdx},3));

                figure('Position',[680   827   847   271]);
                ax1 = subplot(1,2,1);
                hold on
                for conIdx=1:size(score,2)
                    tmp = squeeze(score(:,conIdx,:))';
                    colors = hsv(size(score,2))*0.8;
                    plot3(tmp(:,1), tmp(:,2), tmp(:,3), 'o','Color',colors(conIdx,:));
                end

                ax2 = subplot(1,2,2);
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

        %%
        if ~isempty(controllerOutputs)
            dPCA_out = apply_dPCA_simple( squeeze(controllerOutputs), trialStartIdx(outerIdx(useTrl))+timeOffset, ...
                targCodes(useTrl), timeWindow, 0.010, {'CD','CI'}, 6 );
            lineArgs = cell(length(unique(targCodes(useTrl))),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', [avgSpeed_long_c, avgSpeed_long_p]);
            exportPNGFigure(gcf, [saveDir filesep 'mus_dPCA']);
        end

        %%
        close all;
    end
    
    %%
    %unit activation
    timeWindow = [-25, 100];
    timeAxis = 0.01*(timeWindow(1):timeWindow(2));
    windowIdx = timeWindow(1):timeWindow(2);
    plotUnitIdx = [3 4 11];
    plotStartIdx = trialStartIdx(outerIdx);
    
    for compIdx=1:length(featAvg)
        figure('Position',[392   573   251   521]);
        for unitIdx=1:length(plotUnitIdx)
            subtightplot(3,1,unitIdx,[0.03,0.01]);
            hold on;
            for x=1:size(featAvg{compIdx},2)
                plot(timeAxis,squeeze(featAvg{compIdx}(plotUnitIdx(unitIdx),x,:)),'LineWidth',2,'Color',colors(x,:));
            end

            axis tight;  
            plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
            plotBackgroundSignal( timeAxis, avgSpeed_long_p );

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
    if isempty(controllerOutputs)
        continue;
    end
    
    %%
    %muscle trajectory plots
    trialStartIdx = double(trialStartIdx);
    plotStartIdx = trialStartIdx(outerIdx);
    nPerSide = ceil(sqrt(length(plotStartIdx)));
    
    figure('Position',[46          39        1300        1066]);
    for x=1:length(plotStartIdx)
        startIdx = plotStartIdx(x);
        loopIdx = startIdx + windowIdx + timeOffset;
        
        subplot(nPerSide,nPerSide,x);
        hold on;
        plot(timeAxis, envState(loopIdx,actIdx),'LineWidth',2);
        axis tight;
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
    end
    saveas(gcf,[saveDir filesep 'allMusTraj.png'],'png');
    saveas(gcf,[saveDir filesep 'allMusTraj.svg'],'svg');
    
    %%
    %muscle activation
    useTrl = ismember(targCodes, codeSets{setIdx});
    musToPlot = [2 3 4];
    plotStartIdx = trialStartIdx(outerIdx(useTrl));
    colors = hsv(length(plotStartIdx))*0.8;
    
    figure('Position',[392   573   251   521]);
    for musIdx=1:length(musToPlot)
        subtightplot(3,1,musIdx,[0.03,0.01]);
        hold on;
        for x=1:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset;
            plot(timeAxis, squeeze(envState(loopIdx,actIdx(musToPlot(musIdx)))),'LineWidth',2,'Color',colors(x,:));
        end
        axis tight;   
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, avgSpeed_long_p );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',22);
        xlabel('Time (s)');
        ylabel('Muscle Activation');
        title(musNames{musToPlot(musIdx)});
        yLimits = get(gca,'YLim');
        if musIdx==length(plotUnitIdx)
            plot([0,0.5],[yLimits(1), yLimits(1)]+abs(diff(yLimits))*0.1,'-k','LineWidth',2)
        end
        axis off;
    end
    saveas(gcf,[saveDir filesep 'musActExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'musActExamples.svg'],'svg');
    
    %%
    %muscle excitation
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[392         873        1043         221]);
    for musIdx=1:length(musToPlot)
        subplot(1,3,musIdx);
        hold on;
        for x=1:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset;
            plot(timeAxis, squeeze(controllerOutputs(loopIdx,musToPlot(musIdx))),'LineWidth',2,'Color',colors(x,:));   
        end
        axis tight;
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, [avgSpeed_long_c, avgSpeed_long_p] );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Muscle Excitation');
        title(musNames{musToPlot(musIdx)});
    end
    saveas(gcf,[saveDir filesep 'musExcExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'musExcExamples.svg'],'svg');
    
    %%
    close all;
end

%%
compareSets = {'osim2d_cursorJump_0-5_noAdapt', 'Monk/J_2015-06-19_packaged'};

for setIdx=1:size(compareSets,1)
    modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'comp_' num2str(1) '_dPCA']);
    monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'comp_' num2str(1) '_dPCA']);
    
    %time offset
    timeOffset = 4;
    
    figure
    hold on
    plot(zscore(modelData.avgSpeed_long(1:(end-timeOffset))));
    plot(zscore(monkData.avgSpeed_long((timeOffset+1):end)));
    
    areas = {'M1','PMd'};
    for areaIdx = 1:length(areas)
        %canon corr
        modelData = load([rootSaveDir compareSets{setIdx,1} filesep 'comp_' num2str(areaIdx) '_dPCA']);
        monkData = load([rootSaveDir compareSets{setIdx,2} filesep 'comp_' num2str(areaIdx) '_dPCA']);
            
        %monk_fa = monkData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        %model_fa = modelData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        monk_fa = monkData.dPCA_out.featureAverages(:,:,1:(end-timeOffset));
        model_fa = modelData.dPCA_out.featureAverages(:,:,(timeOffset+1):end);
        
        monkData_unroll = monk_fa(:,:)';
        modelData_unroll = model_fa(:,:)';
        
        nCon = size(monk_fa,2);
        nTimeSteps = size(monk_fa,3);
        nDimToCompare = 10;

        [j_COEFF, j_SCORE, LATENT, TSQUARED, j_EXPLAINED, MU] = pca(monkData_unroll);
        [m_COEFF, m_SCORE, LATENT, TSQUARED, m_EXPLAINED, MU] = pca(modelData_unroll);

        [A,B,R,U,V,STATS] = canoncorr(j_SCORE(:,1:nDimToCompare),m_SCORE(:,1:nDimToCompare));

        var_J = j_SCORE(:,1:nDimToCompare)*A;

        U = U';
        U = reshape(U, [nDimToCompare,nCon,nTimeSteps]);

        V = V';
        V = reshape(V,  [nDimToCompare,nCon,nTimeSteps]);
        
        lineArgs = cell(nCon,1);
        targColors = hsv(nCon)*0.8;
        for t=1:nCon
            lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
        end

        figure('Position',[680           1         504        1099]);
        for dimIdx=1:nDimToCompare
            subplot(nDimToCompare,2,dimIdx*2-1);
            hold on;
            for x=1:nCon
                plot(squeeze(U(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;

            subplot(nDimToCompare,2,dimIdx*2);
            hold on;
            for x=1:nCon
                plot(squeeze(V(dimIdx,x,:)),lineArgs{x}{:});
            end
            axis tight;
        end
        title(mean(R));
        %saveas(gcf, [saveDir setNames{setIdx} '_CC_' areas{areaIdx} '.png'],'png');
    end
end

