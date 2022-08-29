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
    dataset = dat.dataset;
    dataset.trialEpochs(dataset.trialEpochs>length(dataset.cursorPos)) = length(dataset.cursorPos);
    
    remIdx = [];
    for b=1:length(dataset.blockList)
        if dataset.decodingClick(b)
            trlIdx = find(dataset.blockNums(dataset.trialEpochs(:,1))==dataset.blockList(b));
            remIdx = [remIdx; trlIdx];
        end
    end
    
    dataset.trialEpochs(remIdx,:) = [];
    dataset.instructedDelays(remIdx,:) = [];
    dataset.intertrialPeriods(remIdx,:) = [];
    dataset.isSuccessful(remIdx) = [];
    
    if length(dataset.isSuccessful)<100
        continue;
    end
    
    %%
    dist = matVecMag(dataset.targetPos - dataset.cursorPos, 2);
    maxDist = prctile(dist(dataset.trialEpochs(:,1)),95);
    
    in.outlierRemoveForCIS = false;
    in.cursorPos = dataset.cursorPos;
    in.targetPos = dataset.targetPos;
    in.reachEpochs = dataset.trialEpochs;
    in.reachEpochs_fit = dataset.trialEpochs;
    in.features = double(dataset.TX);
    in.maxDist = maxDist;
    in.plot = false;
    in.gameType = 'fittsImmediate';
    
    %get reaction time
    in = fit4DimModel_RNN( in );

    %%
    sessionName = sessionList(s).name(1:(end-4));
    out = prepareXValRNNData(in, maxDist, sessionName, [paths.dataPath '/Derived/rnnDecoding_2dDatasets_v2']);
    
    mkdir([outDir filesep 'trainingMeta']);
    save([outDir filesep 'trainingMeta' filesep sessionName '.mat'],'out');
end %session


%%
%todo: workspace size normalization, redo posErrForFit to take into account
%delays / intertrial pauses and reflect desired RNN target, test limited RNN runs on T5 vs. control decoders to get pipeline in place
