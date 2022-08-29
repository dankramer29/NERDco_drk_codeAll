%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/utilities/'));
dataDir = '/Users/frankwillett/Data/Monk/';
datasets = {'JenkinsData','R_2016-02-02_1.mat','Jenkins','3ring',[1]
        'ReggieData','R_2017-01-19_1.mat','Reggie','3ring',[1,4,6,8,10]
        
        'JenkinsData','R_2015-10-01_1.mat','Jenkins','denseVert',[1,2]
        'JenkinsData','R_2015-09-24_1.mat','Jenkins','denseHorz',[2,3,5]
        'ReggieData','R_2017-01-15_1.mat','Reggie','denseVert',[3,5,7]
        
        'SergeyGain','J_2014-09-10.mat','Jenkins','gain',[]
        'SergeyGain','R_2014-08-24.mat','Reggie','gain',[]
    };

speedThresh = 25;
speedMax = 1500;
timeWindow = [-500, 1500]/5;

%%
for d=3:5
    %%
    %format data and produce simple PSTH
    saveDir = [dataDir 'PSTH' filesep datasets{d,2}];
    mkdir(saveDir);
    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    opts.filter = true;
    data = unrollR_generic(R, 5, opts);
    
    if strcmp(datasets{d,4},'3ring')
        data = format3ring( data );
    elseif any(strcmp(datasets{d,4},{'denseVert','denseHorz'}))
        data = formatDense( data, datasets{d,4} );
        data.dirGroups = {2:11, 13:22};
    elseif strcmp(datasets{d,4},'gain')
        data = formatGain( R, data );
    end
    
    %data = speedThreshold(data, speedThresh);
    data.moveStartIdx = data.reachEvents(:,2); 
    useTrials = filterTrials(data, datasets{d,5}, datasets{d,4}, speedMax);
    
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 5;
    psthOpts.neuralData = {zscore(data.spikes)};
    psthOpts.timeWindow = timeWindow;
    psthOpts.trialEvents = data.moveStartIdx(useTrials);
    psthOpts.trialConditions = data.targCodes(useTrials);
    
    if strcmp(datasets{d,4},'3ring')
        psthOpts.conditionGrouping = {data.innerRingCodes, data.middleRingCodes, data.outerRingCodes};
        colors = hsv(16)*0.8;
        innerIdx = 1;
        middleIdx = 1;
        outerIdx = 1;
        for c=1:48
            if ismember(c, data.outerRingCodes)
                psthOpts.lineArgs{c} = {'Color',colors(outerIdx,:),'LineWidth',2};
                outerIdx = outerIdx + 1;
            end
            if ismember(c, data.middleRingCodes)
                psthOpts.lineArgs{c} = {'Color',colors(middleIdx,:),'LineWidth',2};
                middleIdx = middleIdx + 1;
            end
            if ismember(c, data.innerRingCodes)
                psthOpts.lineArgs{c} = {'Color',colors(innerIdx,:),'LineWidth',2};
                innerIdx = innerIdx + 1;
            end
        end
    elseif any(strcmp(datasets{d,4},{'denseVert','denseHorz'}))
        psthOpts.conditionGrouping = data.dirGroups;
        colors = [parula(11)*0.8; parula(11)*0.8];
        
        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
        end
    elseif strcmp(datasets{d,4},'gain')
        psthOpts.conditionGrouping = {1:8, 9:16, 17:24};
        colors = [hsv(8)*0.8; hsv(8)*0.8; hsv(8)*0.8];

        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
        end
    end
    
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = saveDir;
    featLabels = cell(192,1);
    for f=1:96
        featLabels{f} = ['M1' num2str(f)];
        featLabels{f+96} = ['PMd' num2str(f)];
    end
    psthOpts.featLabels = featLabels;
    psthOpts.prefix = 'Sinigle';
    psthOpts.subtractConMean = true;
    psthOpts.timeStep = 5/1000;
    pOut = makePSTH_simple(psthOpts);
    close all;
    
    %%
    %behavior
    cursorVel = [0 0; diff(data.handPos(:,1:2))]*200;
    zSpikes = zscore(data.spikes);
    
    trainIdx = expandEpochIdx([psthOpts.trialEvents, psthOpts.trialEvents+200]);
    coef = zSpikes(trainIdx,:) \ cursorVel(trainIdx,:);
    predVel = zSpikes*coef;
    
    poBehavior = psthOpts;
    poBehavior.neuralData{1} = [cursorVel, matVecMag(cursorVel,2), predVel];
    poBehavior.featLabels = {'X Vel','Y Vel','Speed','Dec X','Dec Y'};
    poBehavior.prefix = 'Kin';
    poBehavior.orderBySNR = false;
    poBehavior.subtractConMean = false;
    pOutB = makePSTH_simple(poBehavior);
    
    speedSignal = squeeze((pOutB.psth{4}(:,3,1)));
    
    tmp = triggeredAvg(data.cursorSpeed, psthOpts.trialEvents(psthOpts.trialConditions==4), timeWindow);
    
    %%
    %for each array...
    chanSets = {1:96, 97:192};
    arrayCodes = {'M1','PMd'};
    for arrayIdx=1:2

        smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{arrayIdx}), 5);  
        margNamesShort = {'Dir','CI'};
        if strcmp(datasets{d,4},'3ring') || strcmp(datasets{d,4},'gain') || any(strcmp(datasets{d,4},{'denseVert','denseHorz'}))
            %for each ring...
            if strcmp(datasets{d,4},'3ring')
                conSets = {data.innerRingCodes(1:2:end), data.middleRingCodes(1:2:end), data.outerRingCodes(1:2:end)};
            elseif strcmp(datasets{d,4},'denseVert') || strcmp(datasets{d,4},'denseHorz')
                conSets = {[2 13],[3 14],[4 15],[5 16],[6 17],[7 18],[8 19],[9 20],[10 21],[11 22]};
            else
                conSets = {1:8,9:16,17:24};
            end
            
            dPCA_out = cell(length(conSets),1);
            for c=1:length(conSets)
                useIdx = ismember(data.targCodes(useTrials), conSets{c});
                dPCA_out{c} = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), ...
                    psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
            end

            %produce our own plot, where it is easier to control colors and style
            nCon = length(conSets{1});
            colors = hsv(nCon)*0.8;
            newLineArgs = cell(nCon,1);
            for c=1:nCon
                newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
            end
            yAxesFinal = cell(length(conSets),1);
            for c=1:length(conSets)
                yAxesFinal{c} = oneFactor_dPCA_plot( dPCA_out{c}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'sameAxes', speedSignal );
                set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
                saveas(gcf,[saveDir filesep 'dPCA_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_ring' num2str(c) '_' arrayCodes{arrayIdx} '.svg'],'svg');
            end
            close all;
            
            %all together
            for c=1:length(conSets)
                oneFactor_dPCA_plot( dPCA_out{c}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'sameAxes', speedSignal, yAxesFinal{end} );
                set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
                saveas(gcf,[saveDir filesep 'dPCA_link_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_link_ring' num2str(c) '_' arrayCodes{arrayIdx} '.svg'],'svg');
            end
            close all;
            
            %cross-axes
            dPCA_cross = cell(length(conSets),1);
            for c=1:length(conSets)
                dPCA_cross{c} = dPCA_out{c};
                %tmp = dPCA_cross.featureAverages(:,:);
                %mn = mean(tmp,2);
                %tmp = bsxfun(@plus, tmp, -mn);
                %dPCA_cross.featureAverages = reshape(tmp, size(dPCA_out{c}.featureAverages));
                
                crossCon = length(conSets);
                dPCA_cross{c}.whichMarg = dPCA_out{crossCon}.whichMarg;
                for axIdx=1:20
                    for conIdx=1:size(dPCA_cross{c}.Z,2)
                        dPCA_cross{c}.Z(axIdx,conIdx,:) = dPCA_out{crossCon}.W(:,axIdx)' * squeeze(dPCA_cross{c}.featureAverages(:,conIdx,:));
                    end
                end
                
                oneFactor_dPCA_plot( dPCA_cross{c}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'sameAxes', speedSignal, yAxesFinal{end} );
                set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
                saveas(gcf,[saveDir filesep 'dPCA_cross_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_cross_ring' num2str(c) '_' arrayCodes{arrayIdx} '.svg'],'svg');
            end
            close all;
            
            %put all cross-axes dimensions onto a single plot
            if strcmp(datasets{d,4},'denseVert') || strcmp(datasets{d,4},'denseHorz')
                colors = jet(length(conSets))*0.8;
                lineArgs = [];
                for c=1:length(conSets)
                    na = {{'Color',colors(c,:),'LineStyle','-','LineWidth',2},{'Color',colors(c,:),'LineStyle',':','LineWidth',2}};
                    lineArgs = [lineArgs, na];
                end

                full_dPCA = dPCA_cross{1};
                for c=1:length(conSets)
                    full_dPCA.Z = cat(2, full_dPCA.Z, dPCA_cross{c}.Z);
                end
                full_dPCA.Z(:,1:2,:) = [];

                oneFactor_dPCA_plot( full_dPCA, (timeWindow(1):timeWindow(2))*(5/1000), lineArgs, margNamesShort, 'zoomAxes', speedSignal);
                set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
                saveas(gcf,[saveDir filesep 'dPCA_cross_ringAll_' arrayCodes{arrayIdx} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_cross_ringAll_' arrayCodes{arrayIdx} '.svg'],'svg');
                
                %[~,fHandles] = oneFactor_dPCA_plot_mag( full_dPCA, (timeWindow(1):timeWindow(2))*(5/1000), lineArgs, margNamesShort, speedSignal );
            end
            
            figure;
            plot([0,cumsum(dPCA_out{3}.explVar.componentVar(dPCA_out{3}.whichMarg==1))],'-o','LineWidth',2);
            yLimitAuto = get(gca,'YLim');
            ylim([0 yLimitAuto(2)]);
            xlim([0 10]);
            saveas(gcf,[saveDir filesep 'dPCACum_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
        end %ring datasets
        
        %everything
        conList = horzcat(conSets{:});
        nCon = length(conList);
        colors = [jet(nCon/2)*0.8; jet(nCon/2)*0.8];
        for c=1:nCon
            if c>11
                ls = ':';
            else
                ls = '-';
            end
            newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls};
        end
        
%         nCon = length(horzcat(data.dirGroups{:}));
%         colors = redblue(nCon+4);
%         colors((nCon/2 +1):(nCon/2 + 4),:)=[];
%         newLineArgs = cell(nCon,1);
%         for c=1:nCon
%             newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
%         end
        useIdx = ismember(data.targCodes(useTrials), horzcat(data.dirGroups{:}));

        dPCA_all = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
        [~,fHandles] = oneFactor_dPCA_plot_mag( dPCA_all, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, speedSignal );
        close(fHandles(2:end));
        %axc = get(gcf,'Children');
        %for l=1:length(axc)
        %    set(axc(l),'Color','k');
        %end
        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        saveas(gcf,[saveDir filesep 'dPCA_allDir_' arrayCodes{arrayIdx} '.png'],'png');
        
        %%
        %two-factor distance x direction dPCA 
        useIdx = find(useIdx);
        %useIdx = find(psthOpts.trialConditions~=0);
        newCon = zeros(size(psthOpts.trialConditions(useIdx),1),2);
        for t=1:size(newCon,1)
            if psthOpts.trialConditions(useIdx(t))<=11
                newCon(t,2) = 1;
                newCon(t,1) = psthOpts.trialConditions(useIdx(t));
            else
                newCon(t,2) = 2;
                newCon(t,1) = psthOpts.trialConditions(useIdx(t)) - 11;
            end
        end
        
        facNames = {'Dist', 'Dir', 'CI', 'Dist x Dir'};
        dPCA_all_2 = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), newCon, timeWindow, 0.02, facNames );
        
        lineArgs_2fac = cell(10,2);
        lineArgs_2fac(:,1) = newLineArgs(1:10);
        lineArgs_2fac(:,2) = newLineArgs(11:20);
        yAxesFinal = twoFactor_dPCA_plot( dPCA_all_2, (timeWindow(1):timeWindow(2))*(5/1000), lineArgs_2fac, facNames, 'sameAxes', speedSignal );
        
        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        saveas(gcf,[saveDir filesep 'dPCA_allDir_2fac_' arrayCodes{arrayIdx} '.png'],'png');
        
        colors = jet(10)*0.8;
        figure
        hold on
        for x=1:10
            rectangle('Position',[-8, data.withinDirDist(x+1)-8, 16, 16], 'Curvature', [1 1], 'EdgeColor', colors(x,:), 'LineWidth', 2);
        end
        plot(0,0,'x','MarkerSize',12,'Color',[0.5 0.5 0.5],'LineWidth',3);
        axis equal;
        ylim([0 140]);
        axis off;
        
        colors = jet(10)*0.8;
        figure
        hold on
        for x=1:10
            rectangle('Position',[-8, data.withinDirDist(x+1)-8, 16, 16], 'Curvature', [1 1], 'EdgeColor', colors(x,:), 'LineWidth', 2);
            rectangle('Position',[-8, -data.withinDirDist(x+1)-8, 16, 16], 'Curvature', [1 1], 'EdgeColor', colors(x,:), 'LineWidth', 2,'LineStyle',':');
        end
        plot(0,0,'x','MarkerSize',12,'Color',[0.5 0.5 0.5],'LineWidth',3);
        axis equal;
        ylim([-140 140]);
        axis off;
        
        %%
        %apply dPCA within each direction
       
        %for each three target set...
        nDist = length(data.dirGroups{1});
        colors = jet(nDist)*0.8;
        newLineArgs = cell(nDist,1);
        for c=1:nDist
            newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
        end

        varRatios = zeros(length(data.dirGroups),1);
        modScales = cell(length(data.dirGroups),1);
        dPCA_by_dir = cell(length(data.dirGroups),1);
        R2Vals = zeros(length(data.dirGroups),1);
        for dirIdx=1:length(data.dirGroups)
            useIdx = ismember(data.targCodes(useTrials), data.dirGroups{dirIdx});

            dPCA_by_dir{dirIdx} = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
            [modScales{dirIdx}, figHandles] = oneFactor_dPCA_plot_mag( dPCA_by_dir{dirIdx}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, speedSignal );
            
            saveas(figHandles(1),[saveDir filesep 'dPCA_withinDir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(figHandles(2),[saveDir filesep 'dPCAMag_withinDir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            close all;
            
            oneFactor_dPCA_plot( dPCA_by_dir{dirIdx}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'zoomedAxes', speedSignal );
            
            tmpVar = dPCA_by_dir{dirIdx}.explVar.componentVar(dPCA_by_dir{dirIdx}.whichMarg==1);
            varRatios(dirIdx) = tmpVar(1)/tmpVar(2);
            
            [B,BINT,R,RINT,STATS] = regress(modScales{dirIdx}{1,1}, [ones(length(modScales{dirIdx}{1,1}),1), data.withinDirDist(2:end)]);
            R2Vals(dirIdx) = STATS(1);
            
            title(['R = ' num2str(R2Vals(dirIdx))]);
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA_withinDir_sameAxes_' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_withinDir_sameAxes_' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
        end
        
        %%
        %cross-dPCA
        yAxesFinal = cell(length(data.dirGroups),1);
        for dirIdx=1:length(data.dirGroups)
            yAxesFinal{dirIdx} = oneFactor_dPCA_plot( dPCA_by_dir{dirIdx}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'sameAxes', speedSignal );
        end
               
        sharedLims = cell(length(data.dirGroups),1);
        sharedLims{1} = 1.0*[min([yAxesFinal{1}{1}(1), yAxesFinal{2}{1}(1)]), max([yAxesFinal{1}{1}(2), yAxesFinal{2}{1}(2)])];
        sharedLims{2} = 1.0*[min([yAxesFinal{1}{2}(1), yAxesFinal{2}{2}(1)]), max([yAxesFinal{1}{2}(2), yAxesFinal{2}{2}(2)])];

        for dirIdx=1:length(data.dirGroups)
            oneFactor_dPCA_plot( dPCA_by_dir{dirIdx}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'zoomedAxes', speedSignal, sharedLims );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA_link_dir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_link_dir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
        end

        %cross-axes
        for dirIdx=1:length(data.dirGroups)
            dPCA_cross = dPCA_by_dir{dirIdx};
            crossCon = 2-dirIdx+1;
            dPCA_cross.whichMarg = dPCA_by_dir{crossCon}.whichMarg;
            for axIdx=1:20
                for conIdx=1:size(dPCA_cross.Z,2)
                    dPCA_cross.Z(axIdx,conIdx,:) = dPCA_by_dir{crossCon}.W(:,axIdx)' * squeeze(dPCA_cross.featureAverages(:,conIdx,:));
                end
            end

            oneFactor_dPCA_plot( dPCA_cross, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'zoomedAxes', speedSignal, sharedLims );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA_cross_dir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_cross_dir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.svg'],'svg');
        end
        
        
        %%
        nDirs = length(data.dirGroups);
        nDists = length(data.dirGroups{1});
        timeIdx = timeWindow(1):timeWindow(2);
        zeroIdx = find(timeIdx==0);
        
        for dimType = 1:2
            for dimOrder = 1:4
                figure('Position',[29         169        1090         777]);
                for dirIdxOuter=1:nDirs
                    yLimits = zeros(nDirs, 2);
                    for dirIdxInner=1:nDirs
                        tmpHandles(dirIdxInner) = subtightplot(nDirs, nDirs, (dirIdxOuter-1)*nDirs + dirIdxInner);
                        dimToPlot = find(dPCA_by_dir{dirIdxOuter}.whichMarg==dimType);
                        dimToPlot = dimToPlot(dimOrder);
                        
                        hold on;
                        for distIdx = 1:nDists
                            neuralDim = dPCA_by_dir{dirIdxOuter}.W' * squeeze(dPCA_by_dir{dirIdxInner}.featureAverages(:,distIdx,:));
                            plot(neuralDim(dimToPlot,:)', 'Color', colors(distIdx,:), 'LineWidth', 2);
                        end
                        axis tight;
                        yLimits(dirIdxInner,:) = get(gca,'YLim');
                        set(gca,'XTick',[],'YTick',[]);
                        if dirIdxInner==dirIdxOuter
                            set(gca,'color',[0.9 0.9 0.9]);
                        end
                    end
                    for dirIdxInner=1:nDirs
                        set(tmpHandles(dirIdxInner), 'YLim', [min(yLimits(:,1)), max(yLimits(:,2))]);
                        plot(tmpHandles(dirIdxInner), [zeroIdx, zeroIdx],get(gca,'YLim'),'--k','LineWidth',2);
                    end
                end
                saveas(gcf,[saveDir filesep 'xCon_' num2str(dimType) '_' num2str(dimOrder) '_' arrayCodes{arrayIdx} '.png'],'png');
            end
        end
        
        figure
        hold on
        for m=1:length(data.dirGroups)
            plot(modScales{m}{1,1}*sign(modScales{m}{1,1}(1)),'-o','MarkerSize',4);
        end
        saveas(gcf,[saveDir filesep 'modScales_' arrayCodes{arrayIdx} '.png'],'png');
            
        delTable = zeros(length(modScales),length(modScales{m}{1,1})-1);
        for m=1:length(modScales)
            for c=1:(length(modScales{m}{1,1})-1)
                delTable(m,c) = modScales{m}{1,1}(c+1)-modScales{m}{1,1}(c);
            end
        end
        
        figure
        hold on;
        plot(log(delTable(:,1)./delTable(:,2)),'LineWidth',2);
        plot(get(gca,'XLim'),[0 0],'--k');
        saveas(gcf,[saveDir filesep 'delTable_' arrayCodes{arrayIdx} '.png'],'png');
        
        close all;
    end %array
    clear data;
end
