datasets = {'osim4d_velCost_0','osim3d';
    'osim2d_centerOut_0','osim2d';
    'osim2d_cursorJump','osim2d';
    'osim2d_cursorJump_sooner','osim2d';
    'osim2d_cursorJump_vmrLong','osim2d';
    'Jenkins/J_centerOut_packaged','monk2d';
    };
rootSaveDir = '/Users/frankwillett/Data/Derived/armControlNets/';

for datasetIdx=1:length(datasets)
    if strfind(datasets{datasetIdx,1}, 'osim2d_cursorJump')
        dat = cell(8,1);
        for x=0:7
            dat{x+1} = load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '_' num2str(x) '.mat']);
        end
        
        fields = {'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'};
        allDat = struct();
        for f=1:length(fields)
            allDat.(fields{f}) = [];
            for x=1:8
                if x==1
                    allDat.(fields{f}) = dat{x}.(fields{f});
                    if f==1
                        allDat.trialStartIdx = dat{x}.trialStartIdx(6:7);
                    end
                else
                    if f==1
                        allDat.trialStartIdx = [allDat.trialStartIdx, dat{x}.trialStartIdx(6:7)+length(allDat.rnnState)];
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
        trialStartIdx = allDat.trialStartIdx;
        trialStartIdx = [1, trialStartIdx(1:(end-1))];
    else
        load(['/Users/frankwillett/Data/armControlNets/' datasets{datasetIdx,1} '.mat']);
    end
        
    addpath('/Users/frankwillett/Downloads/CaptureFigVid/CaptureFigVid/');
    saveDir = [rootSaveDir datasets{datasetIdx,1}];
    mkdir(saveDir);
    
    if strcmp(datasets{datasetIdx,2},'osim3d')
        posIdx = [10,11,12];
        actIdx = [40,44,48,52,56,60,64,68,72,76,80,84,88,92,96,100,104,108,112,116,120,124,128]+1;
        musNames = {'DELT1','DELT2','DELT3','SUPSP','INFSP','SUBSC','TMIN','TMAJ','PECM1','PECM2','PECM3','LAT1','LAT2','LAT3','CORB',...
            'TRIlong','TRIlat','TRImed','ANC','BIClong','BICshort','BRA','BRD'};
        musToPlot = [2,5,12];
        plotUnitIdx = [1,2,3];
    elseif strcmp(datasets{datasetIdx,2},'osim2d')
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
        targ = controllerInputs(:,1:3);
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
    if strcmp(datasets{datasetIdx,1}, 'osim2d_cursorJump_vmrLong')
        timeOffset = 100;
    elseif strfind(datasets{datasetIdx,1}, 'osim')
        timeOffset = 50;
    else
        timeOffset = -20;
    end
    
    %%
    %coding
    if strfind(datasets{datasetIdx,1}, 'osim2d_cursorJump')
        outerIdx = 2:2:length(trialStartIdx);
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset,1:3);
        targCodes = (1:8)';
        targList = zeros(8,3);
    elseif strfind(datasets{datasetIdx,1}, 'osim')
        outerIdx = 2:2:length(trialStartIdx);
        targ = controllerInputs(trialStartIdx(outerIdx)+timeOffset,1:3);
        [targList, ~, targCodes] = unique(targ, 'rows');
    else
        outerIdx = 1:length(trialStartIdx);
    end
    
    %%
    plotIdx = outerIdx;

    if size(pos,2)==2
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
    else
        figure;
        hold on;
        for trlIdx=1:length(plotIdx)
            if plotIdx(trlIdx)==length(trialStartIdx)
                loopIdx = trialStartIdx(plotIdx(trlIdx)):length(posDist);
            else
                loopIdx = trialStartIdx(plotIdx(trlIdx)):trialStartIdx(plotIdx(trlIdx)+1);
            end
            plot3(posDist(loopIdx,1), posDist(loopIdx,2), posDist(loopIdx,3), 'LineWidth', 2.0);
        end
        plot3(targList(:,1), targList(:,2), targList(:,3), 'ro');
        axis equal;

        OptionZ.FrameRate=15;OptionZ.Duration=5.5;OptionZ.Periodic=true;
        CaptureFigVid([0,10;-360,10], 'noiseHardened',OptionZ)
    end

    %%
    %avg speed
    handSpeed = [0; matVecMag(vel,2)];
    avgSpeed_short = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 50]);
    avgSpeed_short = nanmean(avgSpeed_short)';
    
    avgSpeed_long = triggeredAvg(double(handSpeed), double(trialStartIdx(outerIdx)+timeOffset), [-25, 100]);
    avgSpeed_long = nanmean(avgSpeed_long)';
    
    %%
    %single-factor neural
    timeWindow = [-25, 100];
    featAvg = cell(size(rnnState,1),1);
    
    for compIdx=1:size(rnnState,1)
        dPCA_out = apply_dPCA_simple( squeeze(rnnState(compIdx,:,:)), trialStartIdx(outerIdx)+timeOffset, ...
            targCodes, timeWindow, 0.010, {'CD','CI'} );
        featAvg{compIdx} = dPCA_out.featureAverages;
        
        lineArgs = cell(length(unique(targCodes)),1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);
        
        saveas(gcf,[saveDir filesep 'comp_' num2str(compIdx) '_dPCA.png'],'png');
        saveas(gcf,[saveDir filesep 'comp_' num2str(compIdx) '_dPCA.svg'],'svg');
        
        %ortho prep space?
        X = orthoPrepSpace( dPCA_out.featureAverages, 2, 4, 1:32, 33:125 );
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

        jPCA_params.normalize = true;
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
        saveas(gcf, [saveDir setNames{setIdx} 'jPCA.png'],'png');
    end
    close all;
    
    %%
    dPCA_out = apply_dPCA_simple( squeeze(controllerOutputs), trialStartIdx(outerIdx)+timeOffset, ...
        targCodes, timeWindow, 0.010, {'CD','CI'}, 6 );
    lineArgs = cell(length(targList),1);
    colors = jet(length(lineArgs))*0.8;
    for l=1:length(lineArgs)
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
    end
    oneFactor_dPCA_plot( dPCA_out,  0.01*(timeWindow(1):timeWindow(2)), lineArgs, {'CD','CI'}, 'zoom', avgSpeed_long);

    saveas(gcf,[saveDir filesep 'mus_dPCA.png'],'png');
    saveas(gcf,[saveDir filesep 'mus_dPCA.svg'],'svg');
    
    %%
    %unit activation
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
    saveas(gcf,[saveDir filesep 'unitExamples.png'],'png');
    saveas(gcf,[saveDir filesep 'unitExamples.svg'],'svg');
    
    %%
    if isempty(controllerOutputs)
        continue;
    end
    
    %%
    timeWindow = [-25, 100];
    timeAxis = 0.01*(timeWindow(1):timeWindow(2));
    windowIdx = timeWindow(1):timeWindow(2);
    
    %%
    %muscle trajectory plots
    trialStartIdx = double(trialStartIdx);
    plotStartIdx = trialStartIdx(outerIdx);
    
    figure('Position',[46          39        1300        1066]);
    for x=1:length(plotStartIdx)
        startIdx = plotStartIdx(x);
        loopIdx = startIdx + windowIdx + timeOffset;
        
        subplot(5,6,x);
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
        plotBackgroundSignal( timeAxis, avgSpeed_long );
        
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
