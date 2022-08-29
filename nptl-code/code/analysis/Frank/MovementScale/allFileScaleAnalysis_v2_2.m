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
    
    %%
    %PSTHs
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
    %PSTHs of behavior
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
    %for each array do dPCA
    chanSets = {1:96, 97:192, 1:192};
    arrayCodes = {'M1','PMd','all'};
    for arrayIdx=1:length(arrayCodes)

        smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{arrayIdx}), 5);  
        
        %%
        %single factor dPCA
        margNamesShort = {'Dir','CI'};
        
        if strcmp(datasets{d,4},'3ring')
            conSets = {data.innerRingCodes(1:2:end), data.middleRingCodes(1:2:end), data.outerRingCodes(1:2:end)};
        elseif strcmp(datasets{d,4},'denseVert') || strcmp(datasets{d,4},'denseHorz')
            conSets = {[2 13],[3 14],[4 15],[5 16],[6 17],[7 18],[8 19],[9 20],[10 21],[11 22]};
        else
            conSets = {1:8,9:16,17:24};
        end
            
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

        useIdx = ismember(data.targCodes(useTrials), horzcat(data.dirGroups{:}));

        dPCA_all = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
        [~,fHandles] = oneFactor_dPCA_plot_mag( dPCA_all, (timeWindow(1):timeWindow(2))*(5/1000), newLineArgs, margNamesShort, speedSignal );
        close(fHandles(2:end));

        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        saveas(gcf,[saveDir filesep 'dPCA_allDir_' arrayCodes{arrayIdx} '.png'],'png');
        
        %%
        %two-factor distance x direction dPCA 
        if strcmp(datasets{d,4},'3ring')
            useIdx = find(useIdx);
            newCon = zeros(size(psthOpts.trialConditions(useIdx),1),2);
            for t=1:size(newCon,1)
                if ismember(psthOpts.trialConditions(useIdx(t)),data.innerRingCodes)
                    newCon(t,2) = 1;
                    [~,newCon(t,1)] = ismember(psthOpts.trialConditions(useIdx(t)),data.innerRingCodes);
                elseif ismember(psthOpts.trialConditions(useIdx(t)),data.middleRingCodes)
                    newCon(t,2) = 2;
                    [~,newCon(t,1)] = ismember(psthOpts.trialConditions(useIdx(t)),data.middleRingCodes);
                elseif ismember(psthOpts.trialConditions(useIdx(t)),data.outerRingCodes)
                    newCon(t,2) = 3;
                    [~,newCon(t,1)] = ismember(psthOpts.trialConditions(useIdx(t)),data.outerRingCodes);
                end
            end
        else
            useIdx = find(useIdx);
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
        end
        
        facNames = {'Dir', 'Dist', 'CI', 'Dist x Dir'};
        dPCA_all_2 = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), newCon, timeWindow, 0.02, facNames );
        
        if strcmp(datasets{d,4},'3ring')
            lineArgs_2fac = cell(16,3);
            colors = hsv(16)*0.8;
            ls = {':','--','-'};
            for distIdx=1:3
                for targIdx=1:16
                    lineArgs_2fac{targIdx, distIdx} = {'LineWidth',2,'Color',colors(targIdx,:),'LineStyle',ls{distIdx}};
                end
            end
        else
            lineArgs_2fac = cell(10,2);
            lineArgs_2fac(:,1) = newLineArgs(1:10);
            lineArgs_2fac(:,2) = newLineArgs(11:20);
        end
        yAxesFinal = twoFactor_dPCA_plot( dPCA_all_2, (timeWindow(1):timeWindow(2))*(5/1000), lineArgs_2fac, facNames, 'sameAxes', speedSignal );
        
        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        saveas(gcf,[saveDir filesep 'dPCA_allDir_2fac_' arrayCodes{arrayIdx} '.png'],'png');
        
        %%
        %mPCA
        margGroupings = {{1, [1 3]}, {2, [2 3]}, {[1 2],[1 2 3]}, {3}};
        margNames = {'Direction','Distance','Dir x Dist','Time'};
        %margGroupings = {{1, [1 3]}, {2, [2 3], [1 2],[1 2 3]}, {3}};
        %margNames = {'Distance','Direction','Time'};
        
        opts_m.margNames = margNames;
        opts_m.margGroupings = margGroupings;
        opts_m.nCompsPerMarg = 3;
        opts_m.makePlots = true;
        opts_m.nFolds = 10;
        opts_m.readoutMode = 'parametric';
        opts_m.alignMode = 'rotation';
        opts_m.nResamples = 10;
        
        newConReorder = newCon;
        [~,~,newConReorder(:,1)] = unique(newConReorder(:,1));
        reducedIdx = ismember(newConReorder(:,1),[1,5,10]); 
        
        [~,~,newConReorder(reducedIdx,1)] = unique(newConReorder(reducedIdx,1));
        
        mPCA_out = apply_mPCA_general( smoothData, psthOpts.trialEvents(useIdx(reducedIdx)), ...
                newConReorder(reducedIdx,[2 1]), [40, 160], 0.005, opts_m );
        
    end %array
    clear data;
end
