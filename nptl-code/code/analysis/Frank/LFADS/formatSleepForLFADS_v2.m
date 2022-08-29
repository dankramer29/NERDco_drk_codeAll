%convert .ns5 sleep files to an LFADS data matrix
paths = getFRWPaths( );

addpath(genpath([paths.codePath '/code/analysis/Frank']));
arrayNames = {'lateral','medial'};
dataDir = [paths.dataPath filesep 'Sleep' filesep];

%%
%get thresholds from each array that we can consistently apply across all
%.ns5 files from an array
thresh_nsFiles = {'NSP_LATERAL_2016_1122_124313(7)007.ns5',...
    'NSP_MEDIAL_2016_1122_124313(7)007.ns5'};
for f=1:length(thresh_nsFiles)
    fileName = [dataDir thresh_nsFiles{f}];
    thresholds = getThresholdsFromNS5( fileName, -3.5, 1:96, 180 );
    save([dataDir 'thresh_' arrayNames{f} '.mat'],'thresholds');
end

%%
%get spike times from the ns5 files
nsFiles = {'NSP_LATERAL_2016_1122_124313(7)007.ns5','lateral';
    'NSP_LATERAL_2016_1122_134014(18)018.ns5','lateral';
    'NSP_MEDIAL_2016_1122_124313(7)007.ns5','medial';
    'NSP_MEDIAL_2016_1122_134014(18)018.ns5','medial'};

for f=1:size(nsFiles,1)
    load([dataDir 'thresh_' nsFiles{f,2} '.mat'],'thresholds');
    
    fileName = [dataDir nsFiles{f,1}];
    txEvents = getTXFromNS5_chunk( fileName, thresholds, 1:96, 360 );
    save([dataDir 'txEvents_' nsFiles{f,1}(1:(end-4)) '.mat'],'txEvents');
end

%%
%convert spike times into binned spike count matrices for LFADS
nsFiles = {'NSP_LATERAL_2016_1122_124313(7)007.ns5','lateral';
    'NSP_LATERAL_2016_1122_134014(18)018.ns5','lateral';
    'NSP_MEDIAL_2016_1122_124313(7)007.ns5','medial';
    'NSP_MEDIAL_2016_1122_134014(18)018.ns5','medial'};
binMS = 10;
binnedData = cell(size(nsFiles,1),1);

for f=1:size(nsFiles,1)
    load([dataDir 'txEvents_' nsFiles{f,1}(1:(end-4)) '.mat'],'txEvents');
    
    allEvents = horzcat(txEvents{:});
    endTime = max(allEvents);
    
    nBins = ceil(endTime*(1000/binMS));
    binEdges = (0:nBins)*(binMS/1000);
    binnedData{f} = zeros(nBins,96);
    binTimes{f} = (0:(nBins-1))*binMS;
    
    for c=1:length(txEvents)
        binnedData{f}(:,c) = histcounts(txEvents{c}, binEdges);
    end
end

idx1 = min([length(binnedData{1}), length(binnedData{3})]);
idx2 = min([length(binnedData{2}), length(binnedData{4})]);

concatArray = cell(2,1);
concatArray{1} = [binnedData{1}(1:idx1,:), binnedData{3}(1:idx1,:)];
concatArray{2} = [binnedData{2}(1:idx2,:), binnedData{4}(1:idx2,:)];

nBins = 100;
trlMat = cell(length(concatArray),1);
for conIdx = 1:length(concatArray)
    binIdx = 1:nBins;
    nTrl = floor(length(concatArray{conIdx})/length(binIdx));
    trlMat{conIdx} = zeros(nTrl,length(binIdx),192);

    for t=1:nTrl
        trlMat{conIdx}(t,:,:) = concatArray{conIdx}(binIdx,:);
        binIdx = binIdx + length(binIdx);
    end
end

allTrl = cat(1, trlMat{1}, trlMat{2});
trlCode = zeros(size(allTrl,1),1);
trlCode(1:size(trlMat{1},1)) = 1;
trlCode((size(trlMat{1},1)+1):end) = 2;

excludeTheseChannels = unique([1:14 16:18 20 22:24 26 28 33:36 43 44 ...
                56 65:71 75:79 100 101 106 107 112 120 122 126 129 131 139 158 166 175 176 181 ...
                21 31 32 39 40 41 42 45 46 49 50 51 52 54 59 61 62 63 64 80 82 83 85 86 89 90 93 94 95]);
allTrl = permute(allTrl, [3 2 1]);
allTrl(excludeTheseChannels,:,:) = [];
%%
%do LFADS
datasetName = 'sleep_2016_1122_exChan';
lfadsPreDir = [paths.dataPath filesep 'Derived' filesep 'pre_LFADS'];
binnedCubeToLFADS( [lfadsPreDir filesep datasetName filesep], datasetName, allTrl, 0.8, binMS  );

%bash scripts    
remotePreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName];
remotePostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName];
lfadsPyDir = '/net/home/fwillett/models/lfads/';
scriptDir = [paths.dataPath '/Derived/pre_LFADS/' datasetName '/'];

availableGPU = [0 1 2 3 5 6 7 8];
mode = 'pairedSampleAndAverage';
displayNum = 7;

%try random values uniformly within a hyperbox of specified
%limits
defaultOpts = lfadsMakeOptsSimple();
defaultOpts.learning_rate_stop = 1e-04;
defaultOpts.gen_dim = 128;
defaultOpts.keep_prob = 0.98;
defaultOpts.l2_con_scale = 250;
defaultOpts.l2_gen_scale = 250;

paramVec = repmat(defaultOpts,5,1);
for p=1:length(paramVec)
    paramVec(p).co_dim = (p-1);
end

datasetVec = repmat({datasetName},5,1);

lfadsMakeBatchScripts( scriptDir, remotePreDir, remotePostDir, lfadsPyDir, ...
    datasetVec, paramVec, availableGPU, displayNum, mode );

save([scriptDir 'runParams.mat'],'paramVec','datasetVec');

%%
%collect result
datasetName = 'sleep_2016_1122_1arr';
remotePreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName];
remotePostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName];
lfadsCollectResultsSimple([remotePreDir filesep], [remotePostDir filesep]);










  