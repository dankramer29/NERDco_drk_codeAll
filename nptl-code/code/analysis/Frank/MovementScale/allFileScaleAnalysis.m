%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));

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
for d=1:length(datasets)
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
    pOutB = makePSTH_simple(poBehavior);
    
    %%
    %for each array...
    chanSets = {1:96, 97:192};
    arrayCodes = {'M1','PMd'};
    for arrayIdx=1:2

        smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{arrayIdx}), 3);  
        margNamesShort = {'Dir','CI'};
        if strcmp(datasets{d,4},'3ring') || strcmp(datasets{d,4},'gain')
            %for each ring...
            if strcmp(datasets{d,4},'3ring')
                conSets = {data.innerRingCodes(1:2:end), data.middleRingCodes(1:2:end), data.outerRingCodes(1:2:end)};
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
            colors = hsv(8)*0.8;
            newLineArgs = cell(8,1);
            for c=1:8
                newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
            end
            for c=1:length(conSets)
                oneFactor_dPCA_plot( dPCA_out{c}, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, 'sameAxes' );
                set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
                saveas(gcf,[saveDir filesep 'dPCA_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
                saveas(gcf,[saveDir filesep 'dPCA_ring' num2str(c) '_' arrayCodes{arrayIdx} '.svg'],'svg');
            end

            figure;
            plot([0,cumsum(dPCA_out{3}.explVar.componentVar(dPCA_out{3}.whichMarg==1))],'-o','LineWidth',2);
            yLimitAuto = get(gca,'YLim');
            ylim([0 yLimitAuto(2)]);
            xlim([0 10]);
            saveas(gcf,[saveDir filesep 'dPCACum_ring' num2str(c) '_' arrayCodes{arrayIdx} '.png'],'png');
        end %ring datasets
        
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
        for dirIdx=1:length(data.dirGroups)
            useIdx = ismember(data.targCodes(useTrials), data.dirGroups{dirIdx});

            dPCA_by_dir{dirIdx} = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
            [modScales{dirIdx}, figHandles] = oneFactor_dPCA_plot_mag( dPCA_by_dir{dirIdx}, psthOpts.timeWindow, newLineArgs, margNamesShort );
            
            saveas(figHandles(1),[saveDir filesep 'dPCA_withinDir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            saveas(figHandles(2),[saveDir filesep 'dPCAMag_withinDir' num2str(dirIdx) '_' arrayCodes{arrayIdx} '.png'],'png');
            close all;

            tmpVar = dPCA_by_dir{dirIdx}.explVar.componentVar(dPCA_by_dir{dirIdx}.whichMarg==1);
            varRatios(dirIdx) = tmpVar(1)/tmpVar(2);
        end
        
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
