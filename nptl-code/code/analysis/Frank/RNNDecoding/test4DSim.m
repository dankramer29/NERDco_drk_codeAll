%%
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = [paths.dataPath '/Derived/2dDatasets'];
outDir = [paths.dataPath '/Derived/rnnDecoding_2dDatasets_v2/'];

%%
sessionList = dir([dataDir filesep '*.mat']);
remIdx = [];
for s=1:length(sessionList)
    if strfind(sessionList(s).name,'features')
        remIdx = [remIdx, s];
    end
end
sessionList(remIdx) = [];

for s = 1:length(sessionList)

    disp(sessionList(s).name);
    
    %%
    %load dataset
    dat = load([dataDir filesep sessionList(s).name]);
    feat = load([dataDir filesep sessionList(s).name(1:(end-4)) '_features.mat']);
    
    dataset = dat.dataset;
    dataset.trialEpochs(dataset.trialEpochs>length(dataset.cursorPos)) = length(dataset.cursorPos);
    
    remIdx = [];
    for b=1:length(dataset.blockList)
         trlIdx = find(dataset.blockNums(dataset.trialEpochs(:,1))==dataset.blockList(b));
        if dataset.decodingClick(b)
            remIdx = [remIdx; trlIdx];
        end
        remIdx = [remIdx; trlIdx(1:2)];
    end
    
    dataset.trialEpochs(remIdx,:) = [];
    dataset.instructedDelays(remIdx,:) = [];
    dataset.intertrialPeriods(remIdx,:) = [];
    if ~isempty(dataset.isSuccessful)
        dataset.isSuccessful(remIdx) = [];
    end
    
    if length(dataset.isSuccessful)<100
        continue;
    end
    
    cFeat = [feat.sp, squeeze(feat.tx(:,:,2))];
    
    %%
    dist = matVecMag(dataset.targetPos - dataset.cursorPos, 2);
    maxDist = prctile(dist(dataset.trialEpochs(:,1)),95);
    
    in.outlierRemoveForCIS = false;
    in.cursorPos = dataset.cursorPos;
    in.targetPos = dataset.targetPos;
    in.reachEpochs = dataset.trialEpochs;
    in.reachEpochs_fit = dataset.trialEpochs;
    in.features = double(cFeat);
    in.maxDist = maxDist;
    in.plot = false;
    in.gameType = 'fittsImmediate';
    
    %get reaction time
    in = fit4DimModel_RNN( in );

    %%
    in.modelType = 'FMP';
    fullModel = fitPhasicAndFB_6(in);
    
    cFeatures = cFeat - fullModel.featureMeans;
    rawSignals = cFeatures * fullModel.filts;
    
    reachIdx_cVec = expandEpochIdx([in.reachEpochs(:,1)+in.rtSteps, in.reachEpochs(:,2)]);
    
    mn = mean(fullModel.modelVectors(reachIdx_cVec,2:5));
    sd = std(fullModel.modelVectors(reachIdx_cVec,2:5));
    noise = fullModel.modelVectors(reachIdx_cVec,2:5) - (rawSignals(reachIdx_cVec,:).*sd + mn);
    
    [ arModel ] = fitARNoiseModel( noise, [1 size(noise,1)], 2 );
   
    simOpts.noise = generateNoiseFromModel( 100000, arModel );
    
    figure; 
    hold on;
    plot(rawSignals(reachIdx_cVec,3).*sd(3) + mn(3)); 
    plot(fullModel.modelVectors(reachIdx_cVec,4));
    plot(noise(:,3));

    %%
    reachIdx_cVec = expandEpochIdx([in.reachEpochs(:,1)+in.rtSteps, in.reachEpochs(:,2)]);
        
    figure
    hold on; 
    plot(rawSignals(reachIdx_cVec,3));
    plot(fullModel.zModelVectors(reachIdx_cVec,3),'LineWidth',2);
    
    
    nAct = fullModel.modelVectors*fullModel.expCoef;
    Q = sqrt(diag(cov(nAct(reachIdx,:) - dataset.TX(reachIdx,:))));
    
    simAct = nAct + randn(size(nAct)).*Q';
    cSim = simAct - fullModel.featureMeans;
    rawSignalsSim = cSim * fullModel.filts;
    
    lambda = nAct/50;
    lambda(lambda<0) =0;
    alpha = 0.25;
    simAct_poiss = zeros(size(lambda));
    for x=2:size(simAct_poiss)
        newLambda = lambda(x,:)*(1-alpha) + simAct_poiss(x-1,:)*alpha;
        
        newLambda(newLambda<0.1)=0.1;
        
        p = 0.85;
        r = newLambda / ((1-p)/p);
        
        simAct_poiss(x,:) = nbinrnd(r, p);
        %simAct_poiss(x,:) = poissrnd(newLambda);
    end
    
    simAct_poiss = simAct_poiss*50;
    cSim = simAct_poiss - fullModel.featureMeans;
    rawSignalsSim_p = cSim * fullModel.filts;
    
    [ arModel_sim ] = fitARNoiseModel( fullModel.zModelVectors - rawSignalsSim(reachIdx,:), [1 size(noise,1)], 5 );
    [ arModel_sim_poiss ] = fitARNoiseModel( fullModel.zModelVectors - rawSignalsSim_p(reachIdx,:), [1 size(noise,1)], 5 );
    
    mn = mean(fullModel.modelVectors);
    sd = std(fullModel.modelVectors);
    zmod = (fullModel.modelVectors-mn)./sd;
    
    reachIdx_cVec = expandEpochIdx([in.reachEpochs(:,1)+in.rtSteps, in.reachEpochs(:,2)]);
    targDist = matVecMag(in.targetPos - in.cursorPos,2);
    maxDist = prctile(targDist(in.reachEpochs(:,1)), 90)*0.95;
    fTargModel = fitFTarg(in.kin.posErrForFit(reachIdx_cVec,:), zmod(reachIdx_cVec,2:3), maxDist, 10, true);
    
    %%
    figure;
    hold on;
    plot(rawSignals(reachIdx,:));
    plot(fullModel.zModelVectors,'LineWidth',2);
    
    opts.pos = dataset.cursorPos;
    opts.vel = double(dataset.decVel)*1000*2000;
    opts.targPos = dataset.targetPos;
    opts.decoded_u = rawSignals(:,1:2)/2;

    opts.modelOpts.noVel = false;
    opts.modelOpts.nKnots = 12;
    opts.modelOpts.noNegativeFTarg = true;

    opts.filtAlpha = 0.90;
    opts.filtBeta = 200;

    opts.reachEpochsToFit = in.reachEpochs;
    opts.feedbackDelaySteps = 8;
    opts.timeStep = 0.02;
    opts.fitNoiseModel = true;
    opts.fitSDN = true;

    [ modelOut ] = fitPiecewiseModel( opts );
    
    %%
    inForRT = in;
    if isfield(in,'isOuter')
        inForRT.reachEpochs = inForRT.reachEpochs(in.isOuter,:);
        inForRT.reachEpochs_fit = inForRT.reachEpochs_fit(in.isOuter,:);
    end

    possibleRT = 0:25;
    meanR2 = zeros(length(possibleRT),1);
    for rtIdx = 1:length(possibleRT)
        disp(possibleRT(rtIdx));
        inForRT.rtSteps = possibleRT(rtIdx);

        [inForRT.kin.posErrForFit, inForRT.kin.unitVec, inForRT.kin.targDist, inForRT.kin.timePostGo] = prepKinForModel( inForRT );
        inForRT.modelType = 'FMP';

        fullModel = fitPhasicAndFB_6(inForRT);
        [~,sortIdx] = sort(fullModel.R2Vals,'descend');
        meanR2(rtIdx) = mean(fullModel.R2Vals(sortIdx(1:96)));
    end

    [~,maxIdx] = max(meanR2);
    in.rtSteps = possibleRT(maxIdx);
    [in.kin.posErrForFit, in.kin.unitVec, in.kin.targDist, in.kin.timePostGo] = prepKinForModel( in );

    %%
    sessionName = sessionList(s).name(1:(end-4));
    out = prepareXValRNNData(in, maxDist, sessionName, [paths.dataPath '/Derived/rnnDecoding_2dDatasets_v2']);
    
    mkdir([outDir filesep 'trainingMeta']);
    save([outDir filesep 'trainingMeta' filesep sessionName '.mat'],'out');
end %session


%%
%todo: workspace size normalization, redo posErrForFit to take into account
%delays / intertrial pauses and reflect desired RNN target, test limited RNN runs on T5 vs. control decoders to get pipeline in place
