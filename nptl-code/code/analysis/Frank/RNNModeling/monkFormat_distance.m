%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/utilities/'));
dataDir = '/Users/frankwillett/Data/Monk/';
datasets = {
        'JenkinsData','R_2015-10-01_1.mat','Jenkins','denseVert',[1,2]
        'JenkinsData','R_2015-09-24_1.mat','Jenkins','denseHorz',[2,3,5]
        'ReggieData','R_2017-01-15_1.mat','Reggie','denseVert',[3,5,7]
    };

speedThresh = 25;
speedMax = 1500;
timeWindow = [-500, 1500]/10;

%%
for d=1:size(datasets,1)
    %%
    %format data and produce simple PSTH
    saveDir = [dataDir 'PSTH' filesep datasets{d,2}];
    mkdir(saveDir);
    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    opts.filter = true;
    data = unrollR_generic(R, 10, opts);
    
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
    psthOpts.timeStep = 10/1000;
    %pOut = makePSTH_simple(psthOpts);
    %close all;
    
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
%     for arrayIdx=1:2
% 
%         smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{arrayIdx}), 5);  
% 
%         %for each ring...
%         if strcmp(datasets{d,4},'3ring')
%             conSets = {data.innerRingCodes(1:2:end), data.middleRingCodes(1:2:end), data.outerRingCodes(1:2:end)};
%         elseif strcmp(datasets{d,4},'denseVert') || strcmp(datasets{d,4},'denseHorz')
%             conSets = {[2 13],[3 14],[4 15],[5 16],[6 17],[7 18],[8 19],[9 20],[10 21],[11 22]};
%         else
%             conSets = {1:8,9:16,17:24};
%         end
% 
%         dPCA_out = cell(length(conSets),1);
%         for c=1:length(conSets)
%             useIdx = ismember(data.targCodes(useTrials), conSets{c});
%             dPCA_out{c} = apply_dPCA_simple( smoothData, psthOpts.trialEvents(useIdx), ...
%                 psthOpts.trialConditions(useIdx), timeWindow, 0.02, {'Condition-dependent', 'Condition-independent'} );
%         end
% 
%     end %array
    
    %'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'
    %[data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx), data.targetPos(loopIdx,1:2)];
    neural = zeros(2, size(psthOpts.neuralData{1},1), 96);
    neural(1,:,:) = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{1}),3);
    neural(2,:,:) = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{2}),3);

    controllerOutputs = [];
    
    pos = data.cursorPos(:,1:2);
    targ = data.targetPos(:,1:2);
    vel = data.cursorVel(:,1:2);
    
    offset = 0;
    trialStartIdx = psthOpts.trialEvents;
    targCodes = psthOpts.trialConditions;

    save(['/Users/frankwillett/Data/armControlNets/Monk/' datasets{d,2}(1:(end-4)) '_packaged.mat'], 'neural','pos','targ','trialStartIdx','vel','targCodes');
    close all;
end
