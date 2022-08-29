datasets = {
    'osim2d_cursorJump_0-5_noAdapt','osim2d';
    'osim2d_cursorJump_0-5_vmrLong','osim2d';
    'osim2d_cursorJump_standardBump','osim2d';
    'osim2d_cursorJump_standardBump_longDelay_smallerTimeConstant','osim2d';
    'osim2d_cursorJump_standardBump_longDelay_smallerTimeConstant_recTan','osim2d';
    'osim2d_cursorJump_recTan_bigUnitCost_noNoise_highUnitCost','osim2d';
    'osim2d_cursorJumpBig_recTan_bigUnitCost_noNoise_highUnitCost','osim2d';
    'Monk/J_2015-06-19_packaged','monk'
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)

    if strcmp(datasets{datasetIdx,2},'osim2d')
        dat = cell(9,1);
        for x=0:8
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
        timeOffset = 100;
    else
        timeOffset = -20;
    end
    
    %%
    %coding
    if strfind(datasets{datasetIdx,1}, 'osim2d_cursorJump')
        outerIdx = 2:2:length(trialStartIdx);
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset,1:3);
        targList = unique(targ,'rows');
        targCodes = (1:length(outerIdx))';
        
        codeSets = {[1, 1+8*3, 1+8*7], [2, 2+8*4, 2+8*8], [3, 3+8*5, 3+8*1], [4, 4+8*6, 4+8*2], ...
            [5, 5+8*7, 5+8*3], [6, 6+8*8, 6+8*4], [7, 7+8*1, 7+8*5], [8, 8+8*2, 8+8*6]};
        %codeSets = {[1+8*3, 1+8*7], [2+8*4, 2+8*8], [3+8*5, 3+8*1], [4+8*6, 4+8*2], ...
        %    [5+8*7, 5+8*3], [6+8*8, 6+8*4], [7+8*1, 7+8*5], [8+8*2, 8+8*6]};
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
    
    figure('Position',[100   416   830   689]);
    for setIdx=1:length(codeSets)
        codeList = unique(codeSets{setIdx});
        plotIdx = outerIdx(ismember(targCodes, codeSets{setIdx}));        
        [~,colorIdx] = ismember(targCodes, codeSets{setIdx});
        colorIdx = colorIdx(colorIdx~=0);
        
        colors = hsv(length(codeSets{setIdx}))*0.8;
        
        subplot(nPerSide, nPerSide, setIdx);
        hold on;
        for trlIdx=1:length(plotIdx)
            loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
            if any(loopIdx>length(posDist)) || any(loopIdx<1)
                continue;
            end

            plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 1.0,'LineStyle',':','Color',colors(colorIdx(trlIdx),:));
            plot(posReal(loopIdx,1), posReal(loopIdx,2),'LineWidth', 1.0,'Color',colors(colorIdx(trlIdx),:));
        end
        plot(targList(:,1), targList(:,2), 'ro');
        axis equal;
    end
    saveas(gcf,[saveDir filesep 'traj.png'],'png');
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
    for setIdx=1:length(codeSets)
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
            save([saveDir filesep 'comp_' num2str(compIdx) '_dPCA'],'dPCA_out','avgSpeed_long');
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
    
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[392         170        1206         924]);
    for unitIdx=1:length(plotUnitIdx)
        subplot(5,5,unitIdx);
        hold on;
        for x=1:size(featAvg{1},2)
            plot(timeAxis,squeeze(featAvg{1}(plotUnitIdx(unitIdx),x,:)),'LineWidth',2,'Color',colors(x,:));
        end
        
        axis tight;  
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, [avgSpeed_long_c, avgSpeed_long_p] );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Unit Activation');
        title(['Unit ' num2str(plotUnitIdx(unitIdx))]);
    end
    saveas(gcf,[saveDir filesep 'unitExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'unitExamples.svg'],'svg');
    
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
    plotStartIdx = trialStartIdx(outerIdx);
    colors = jet(length(plotStartIdx))*0.8;
    
    figure('Position',[392         873        1043         221]);
    for musIdx=1:length(musToPlot)
        subplot(1,3,musIdx);
        hold on;
        for x=1:length(plotStartIdx)
            loopIdx = plotStartIdx(x) + windowIdx + timeOffset;
            plot(timeAxis, squeeze(envState(loopIdx,actIdx(musToPlot(musIdx)))),'LineWidth',2,'Color',colors(x,:));
        end
        axis tight;   
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, [avgSpeed_long_c, avgSpeed_long_p] );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Muscle Activation');
        title(musNames{musToPlot(musIdx)});
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

