datasets = {'osim2d_distancesHorzVert_vmrLong_0','osim2d';
    'osim2d_distancesHorzVert_longDelay_0','osim2d';
    'osim2d_distancesHorzVert_faster_0','osim2d';
    'osim2d_distancesHorzVert_linear_0','osim2d';
    'osim2d_distancesHorzVert_linear_singleComp_0','osim2d';
    'osim2d_distancesHorzVert_sigmoidController_unitCost10_biggerInit_0','osim2d';
    'Monk/R_2015-10-01_1_packaged','monk';
    'Monk/R_2015-09-24_1_packaged','monk';
    'Monk/R_2017-01-15_1_packaged','monk';
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)

    load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '.mat']);
    saveDir = [rootSaveDir datasets{datasetIdx,1} filesep];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim2d')
        posIdx = [47,48];
        actIdx = [16,20,24,28,32,36]+1;
        musToPlot = [1,2,5];
        plotUnitIdx = [11,150,220];
        musNames = {'TRIlong','TRIlat','TRImed','BIClong','BICshort','BRA'};        
    end
    
    if strfind(datasets{datasetIdx,1}, 'osim')
        %osim
        posDist = distEnvState(:,posIdx);
        posReal = envState(:,posIdx);
        targ = controllerInputs(:,1:2);
        vel = diff(posReal)/0.01;
    else
        %monk
        rnnState = neural;
        posDist = pos;
        posReal = pos;
        controllerOutputs = [];
        controllerInputs = [];
    end
    
    %%
    %time offset
    if strfind(datasets{datasetIdx,1}, 'linear')
        timeOffset = 0;
    elseif strfind(datasets{datasetIdx,1}, 'osim')
        timeOffset = 50;
    else
        timeOffset = 20;
    end
    
    %%
    %trial coding
    if strfind(datasets{datasetIdx,1}, 'osim')
        outerIdx = 2:2:length(trialStartIdx);
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset+1,1:2);
        [targList, ~, targCodes] = unique(targ, 'rows');
        
        targCentered = targ(:,1:2) - [0.2, -0.325];
        targCenteredDist = round(matVecMag(targCentered,2)/0.001);
        targCenteredDir = targCentered./matVecMag(targCentered,2);
        targCenteredDir = round(targCenteredDir/0.001);
        
        [~,~,distCodes] = unique(targCenteredDist, 'rows');
        [dirList,~,dirCodes] = unique(targCenteredDir, 'rows');
        dirGroups = {[1,4],[2,3]};
    else
        dirGroups = {[1,2]};
        dirCodes = double(ismember(targCodes,1:11))+1;
        distCodes = targCodes;
        distCodes(distCodes>11) = distCodes(distCodes>11) - 11;

        outerIdx = find(targCodes~=0);
        targList = unique(targ,'rows');
        
        dirCodes = dirCodes(outerIdx);
        distCodes = distCodes(outerIdx);
        targCodes = targCodes(outerIdx);
    end
    
    %%
    %plot trajectories
    plotIdx = outerIdx;

    figure;
    hold on;
    for trlIdx=1:length(plotIdx)
        loopIdx = double(trialStartIdx(plotIdx(trlIdx))) + timeOffset + (1:100);
        if any(loopIdx>length(posDist))
            continue;
        end
        plot(posDist(loopIdx,1), posDist(loopIdx,2),'LineWidth', 2.0);
    end
    plot(targList(:,1), targList(:,2), 'ro');
    axis equal;
    
    %%
    %avg speed
    handSpeed = [0; matVecMag(vel,2)];
    handSpeed(handSpeed>1000)= 0;
    
    avgSpeed_short = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 50]);
    avgSpeed_short = nanmean(avgSpeed_short)';
    
    avgSpeed_long = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 100]);
    avgSpeed_long = nanmean(avgSpeed_long)';
    
    %%
    %single-factor neural
    timeWindow = [-25, 100];
    featAvg = cell(size(rnnState,1),1);
    
    for compIdx=1:size(rnnState,1)
        for dirGroupIdx=1:length(dirGroups)
            useIdx = ismember(dirCodes, dirGroups{dirGroupIdx});
            dPCA_out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(outerIdx(useIdx))+timeOffset, ...
                targCodes(useIdx), timeWindow, 0.010, {'CD','CI'} );
            featAvg{compIdx} = dPCA_out.featureAverages;

            lineArgs = cell(length(unique(targCodes(useIdx))),1);
            colors = jet(length(unique(targCodes(useIdx))))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);

            saveas(gcf,[saveDir 'comp_' num2str(compIdx) '_dPCA.png'],'png');
            saveas(gcf,[saveDir 'comp_' num2str(compIdx) '_dPCA.svg'],'svg');

            %ortho prep space?
            X = orthoPrepSpace( dPCA_out.featureAverages, 2, 4, 1:35, 36:125 );
            nDims = 6;
            nCon = size(dPCA_out.featureAverages,2);
            timeAxis = (timeWindow(1):timeWindow(2))*0.01;
            colors = hsv(nCon)*0.8;

            figure('Position',[73   209   263   893]);
            for dimIdx = 1:nDims
                subplot(nDims,1,dimIdx);
                hold on;
                for conIdx = 1:nCon
                    tmp = squeeze(dPCA_out.featureAverages(:,conIdx,:))';
                    plot(timeAxis, tmp*X(:,dimIdx),'LineWidth',2,'Color',colors(conIdx,:));
                end
                plotBackgroundSignal( timeAxis, avgSpeed_long );
                xlim([timeAxis(1), timeAxis(end)]);
                axis tight;
                plot([0,0],get(gca,'YLim'),'--k','LineWidth',2);
                set(gca,'FontSize',16,'LineWidth',2);
            end
            
            saveas(gcf,[saveDir 'comp_' num2str(compIdx) '_orthoPrep.png'],'png');
            saveas(gcf,[saveDir 'comp_' num2str(compIdx) '_orthoPrep.svg'],'svg');
            
            close all;
        end
    end
    
    %%
    %two-factor distance & direction
    dirGroupNames = {'gp1','gp2'};
    for compIdx=1:size(rnnState,1)
        for dirGroupIdx=1:length(dirGroups)
            margNames = {'Dir', 'Dist', 'CI', 'Dir x Dist'};
            useIdx = ismember(dirCodes, dirGroups{dirGroupIdx});
            
            out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(outerIdx(useIdx))+timeOffset, ...
                [dirCodes(useIdx), distCodes(useIdx)], timeWindow, 0.010, margNames );
            close(gcf);

            nDir = length(unique(dirCodes(useIdx)));
            nDist = length(unique(distCodes(useIdx)));

            lineArgs = cell(nDir, nDist);
            lStyles = {':','-'};
            distColors = jet(nDist)*0.8;
            for dirIdx=1:nDir
                for distIdx=1:nDist
                    lineArgs{dirIdx, distIdx} = {'Color',distColors(distIdx,:),'LineWidth',2,'LineStyle',lStyles{dirIdx}};
                end
            end

            yAxesFinal = twoFactor_dPCA_plot( out, 0.01*(timeWindow(1):timeWindow(2)), lineArgs, margNames, 'zoom', avgSpeed_long );
            saveas(gcf, [saveDir 'comp_' num2str(compIdx) '_' dirGroupNames{dirGroupIdx} '_2fac.png'],'png');
            close all;
        end
    end
    
    %%
    for compIdx=1:size(rnnState,1)
        %jPCA
        Data = struct();
        timeMS = round(timeAxis*1000);
        feat = squeeze(rnnState(compIdx,:,:));
        
        for n=1:size(featAvg{compIdx},2)
            trlAvg = squeeze(featAvg{compIdx}(:,n,:));
            Data(n).A = trlAvg';
            Data(n).times = timeMS;
        end

        jPCA_params.normalize = false;
        jPCA_params.softenNorm = 0;
        jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.meanSubtract = true;
        jPCA_params.numPCs = 6;  % default anyway, but best to be specific

        windowIdx = [0, 200];

        %short window
        jPCATimes = windowIdx(1):10:windowIdx(2);
        for x = 1:length(jPCATimes)
            [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
            jPCATimes(x) = Data(1).times(minIdx);
        end

        [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
        phaseSpace(Projections, jPCA_Summary);  % makes the plot
        saveas(gcf, [saveDir 'comp_' num2str(compIdx) 'jPCA.png'],'png');
    end
    close all;
        
    %%
    %unit activation
    plotUnitIdx = [1,2,3];
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[392         873        1043         221]);
    for unitIdx=1:length(plotUnitIdx)
        subplot(1,3,unitIdx);
        hold on;
        for x=1:size(featAvg{1},2)
            plot(timeAxis,squeeze(featAvg{1}(plotUnitIdx(unitIdx),x,:)),'LineWidth',2,'Color',colors(x,:));
        end
        
        axis tight;  
        plot([0, 0],get(gca,'YLim'),'--k','LineWidth',2);
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Unit Activation');
        title(['Unit ' num2str(plotUnitIdx(unitIdx))]);
    end
    saveas(gcf,[saveDir 'unitExamples.png'],'png');
    saveas(gcf,[saveDir 'unitExamples.svg'],'svg');
    
    %%
    if isempty(controllerOutputs)
        continue;
    end
    
    %%
    %muscle trajectories
    for dirGroupIdx=1:length(dirGroups)
        margNames = {'Dir', 'Dist', 'CI', 'Dir x Dist'};
        useIdx = ismember(dirCodes, dirGroups{dirGroupIdx});
        
        dPCA_out = apply_dPCA_simple( squeeze(controllerOutputs), trialStartIdx(outerIdx(useIdx))+timeOffset, ...
            targCodes(useIdx), timeWindow, 0.010, {'CD','CI'}, 6 );
        
        nCon = length(unique(targCodes(useIdx)));
        lineArgs = cell(nCon,1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);
        
        saveas(gcf,[saveDir 'mus_' dirGroupNames{dirGroupIdx} '_dPCA.png'],'png');
        saveas(gcf,[saveDir 'mus_' dirGroupNames{dirGroupIdx} '_dPCA.svg'],'svg');
    end
    
    %%
    timeWindow = [-25, 100];
    timeAxis = 0.01*(timeWindow(1):timeWindow(2));
    windowIdx = timeWindow(1):timeWindow(2);
    
    %%
    %muscle trajectory plots
    trialStartIdx = double(trialStartIdx);
    plotStartIdx = trialStartIdx(outerIdx);
    nPlotsPerSide = ceil(sqrt(length(plotStartIdx)));
    
    figure('Position',[46          39        1300        1066]);
    for x=1:length(plotStartIdx)
        startIdx = plotStartIdx(x);
        loopIdx = startIdx + windowIdx + timeOffset;
        
        subplot(nPlotsPerSide,nPlotsPerSide,x);
        hold on;
        plot(timeAxis, envState(loopIdx,actIdx),'LineWidth',2);
        axis tight;
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
    end
    saveas(gcf,[saveDir 'allMusTraj.png'],'png');
    saveas(gcf,[saveDir 'allMusTraj.svg'],'svg');
    
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
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Muscle Activation');
        title(musNames{musToPlot(musIdx)});
    end
    saveas(gcf,[saveDir 'musActExamples.png'],'png');
    saveas(gcf,[saveDir 'musActExamples.svg'],'svg');
    
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
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
        set(gca,'LineWidth',2);
        set(gca,'FontSize',16);
        xlabel('Time (s)');
        ylabel('Muscle Excitation');
        title(musNames{musToPlot(musIdx)});
    end
    saveas(gcf,[saveDir 'musExcExamples.png'],'png');
    saveas(gcf,[saveDir 'musExcExamples.svg'],'svg');
    
    %%
    close all;
end
