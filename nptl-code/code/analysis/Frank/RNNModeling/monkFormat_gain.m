%apply same analysis to Sergey gain data, Nir & Saurab 3-ring and vert/horz
%dense data
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/PSTH'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/Utility'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank/dPCA'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/utilities/'));
dataDir = '/Users/frankwillett/Data/Monk/';
datasets = {
        'SergeyGain','J_2014-09-10.mat','Jenkins','gain',[]
        'SergeyGain','R_2014-08-24.mat','Reggie','gain',[]
    };

speedThresh = 25;
speedMax = 1500;
timeWindow = [-1000, 600]/10;

%%
for d=1:size(datasets,1)
    %%
    %format data and produce simple PSTH
    saveDir = [dataDir 'PSTH' filesep datasets{d,2}];
    mkdir(saveDir);
    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    opts.filter = true;
    data = unrollR_generic(R, 10, opts);
    
    data.trlGain = vertcat(R.velocityGain);
    data.centerTargetCode = 0;
    data.isOuterReach = true(length(data.targCodes),1);
    data.isConstantGain = vertcat(R.constantGain);
    
    sergeyRT = round((vertcat(R.timeStartMovement) - vertcat(R.timeTargetOn))/5);

    data.moveStartIdx = data.reachEvents(:,2) + sergeyRT;
    useTrials = filterTrials(data, datasets{d,5}, datasets{d,4}, speedMax);
    
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 5;
    psthOpts.neuralData = {zscore(data.spikes)};
    psthOpts.timeWindow = timeWindow;
    psthOpts.trialEvents = data.moveStartIdx(useTrials);
    psthOpts.trialConditions = data.targCodes(useTrials);
    
    psthOpts.conditionGrouping = {1:8, 9:16, 17:24};
    colors = [hsv(8)*0.8; hsv(8)*0.8; hsv(8)*0.8];

    for c=1:size(colors,1)
        psthOpts.lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
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
    cSpeed = data.handSpeed;
    cSpeed(cSpeed>1000) = nan;
    tmp = triggeredAvg(cSpeed, psthOpts.trialEvents(data.trlGain(useTrials)==0.5), timeWindow);
    speedProfile_low = nanmean(tmp)';
    
    tmp = triggeredAvg(cSpeed, psthOpts.trialEvents(data.trlGain(useTrials)==2.0), timeWindow);
    speedProfile_high = nanmean(tmp)';
    
    %%
    %for each array...
    chanSets = {1:96, 97:192};
    arrayCodes = {'M1','PMd'};
    for arrayIdx=1:2

        smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,chanSets{arrayIdx}), 5);  
        margNames = {'Dir', 'Gain', 'CI', 'Dir x Gain'};

        out = apply_dPCA_simple( smoothData, psthOpts.trialEvents, ...
            [data.targCodes(useTrials), data.trlGain(useTrials)], timeWindow, 0.010, margNames );
        close(gcf);

        nDir = length(unique(data.targCodes(useTrials)));
        nGain = length(unique(data.trlGain(useTrials)));

        lineArgs = cell(nDir, nGain);
        lStyles = {':','--','-'};
        dirColors = jet(nDir)*0.8;
        for dirIdx=1:nDir
            for gainIdx=1:nGain
                lineArgs{dirIdx, gainIdx} = {'Color',dirColors(dirIdx,:),'LineWidth',2,'LineStyle',lStyles{gainIdx}};
            end
        end

        yAxesFinal = twoFactor_dPCA_plot( out, 0.01*(timeWindow(1):timeWindow(2)), lineArgs, margNames, 'zoom', [speedProfile_high, speedProfile_low] );
        saveas(gcf, [saveDir 'comp_' num2str(compIdx) '_' dirGroupNames{dirGroupIdx} '_2fac.png'],'png');

    end %array
    
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
