dataDir = 'C:\Users\Frank\Documents\Big Data\Monk';
datasets = {'JenkinsData','R_2016-02-02_1.mat','Jenkins'

    };

%%
for d=1:length(datasets)
    %%
    %format data and produce simple PSTH
    saveDir = ['C:\Users\Frank\Documents\Big Data\Monk\' datasets{d,1} filesep 'PSTH' filesep datasets{d,2}];
    mkdir(saveDir);
    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    data = unrollR_co( R, 20, datasets{d,3} );
    
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 1;
    psthOpts.neuralData = {zscore(data.spikes_bin)};
    psthOpts.trialEvents = data.reachEvents_ds;
    psthOpts.timeWindow = [-15 50];
    psthOpts.trialConditions = data.trlCodes;
    psthOpts.conditionGrouping = {data.innerRingCodes, data.middleRingCodes, data.outerRingCodes};
    colors = hsv(16)*0.8;
    innerIdx = 1;
    middleIdx = 1;
    outerIdx = 1;
    for c=1:49
        if ismember(c, data.outerRingCodes)
            psthOpts.lineArgs{c} = {'Color',colors(outerIdx,:)};
            outerIdx = outerIdx + 1;
        end
        if ismember(c, data.middleRingCodes)
            psthOpts.lineArgs{c} = {'Color',colors(middleIdx,:)};
            middleIdx = middleIdx + 1;
        end
        if ismember(c, data.innerRingCodes)
            psthOpts.lineArgs{c} = {'Color',colors(innerIdx,:)};
            innerIdx = innerIdx + 1;
        end
    end
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = saveDir;
    featLabels = cell(192,1);
    for f=1:96
        featLabels{f} = ['A' num2str(f)];
        featLabels{f+96} = ['B' num2str(f)];
    end
    psthOpts.featLabels = featLabels;
    psthOpts.prefix = 'Sinigle';
    pOut = makePSTH_simple(psthOpts);
    
    %%
    %behavior
    cursorVel = [0 0; diff(data.cursorPos_ds(:,1:2))]*50;
    zSpikes = zscore(data.spikes_bin);
    
    trainIdx = expandEpochIdx([psthOpts.trialEvents, psthOpts.trialEvents+50]);
    coef = buildLinFilts(cursorVel(trainIdx,:), zSpikes(trainIdx,:), 'standard');
    predVel = zSpikes*coef;
    
    poBehavior = psthOpts;
    poBehavior.neuralData{1} = [cursorVel, matVecMag(cursorVel,2), predVel];
    poBehavior.featLabels = {'X Vel','Y Vel','Speed','Dec X','Dec Y'};
    poBehavior.prefix = 'Kin';
    pOutB = makePSTH_simple(poBehavior);
    
    %%
    %apply dPCA and produce it's default plot
    if strcmp(datasets{d,3},'Jenkins')
        chanSet = 1:96;
    else
        chanSet = 97:192;
    end
    smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSet), 1);  
    
    %for each three target set...
    colors = parula(3);
    newLineArgs = cell(3,1);
    for c=1:3
        newLineArgs{c} = {'Color',colors(c,:)};
    end
    
    varRatios = zeros(length(data.outerRingCodes),1);
    modScales = cell(length(data.outerRingCodes),1);
    for dirIdx=1:length(data.outerRingCodes)
        conSet = [data.outerRingCodes(dirIdx), data.middleRingCodes(dirIdx), data.innerRingCodes(dirIdx)];
        useIdx = ismember(data.trlCodes, conSet);
        
        outTmp = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), psthOpts.trialConditions(useIdx), [-25 50], 0.02, {'Condition-dependent', 'Condition-independent'} );
        modScales{dirIdx} = oneFactor_dPCA_plot_mag( outTmp, psthOpts.timeWindow, newLineArgs, margNamesShort );
        close all;
        
        tmpVar = outTmp.explVar.componentVar(outTmp.whichMarg==1);
        varRatios(dirIdx) = tmpVar(1)/tmpVar(2);
    end
    
    figure
    hold on
    for m=13:13
        plot(modScales{m}{1,1}*sign(modScales{m}{1,1}(1)),'-o','MarkerSize',4);
    end
    
    delTable = zeros(length(modScales),2);
    for m=1:length(modScales)
        delTable(m,1) = modScales{m}{1,1}(2)-modScales{m}{1,1}(1);
        delTable(m,2) = modScales{m}{1,1}(3)-modScales{m}{1,1}(2);
    end
  
    %%

    outerIdx = ismember(data.trlCodes, data.outerRingCodes);
    remapVec = zeros(49,1);
    remapVec(data.outerRingCodes) = 1:16;
    outAll = apply_dPCA_simple( smoothData, psthOpts.trialEvents(outerIdx), remapVec(psthOpts.trialConditions(outerIdx)), [-25 50], 0.02, {'Condition-dependent', 'Condition-independent'} );
    
    %%
    %produce our own plot, where it is easier to control colors and style
    margNamesShort = {'Dir','CI'};
    newLineArgs = cell(16,1);
    for c=1:16
        newLineArgs{c} = {'Color',colors(c,:)};
    end
    
    oneFactor_dPCA_plot( outAll, psthOpts.timeWindow,newLineArgs, margNamesShort );
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[saveDir filesep 'dPCA_all.png'],'png');
    saveas(gcf,[saveDir filesep 'dPCA_all.svg'],'svg');
    
    %%
end
