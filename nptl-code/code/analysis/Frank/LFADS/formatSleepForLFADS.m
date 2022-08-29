%convert .ns5 sleep files to an LFADS data matrix
[ codePath, dataPath ] = getFRWPaths( );

addpath(genpath([codePath '/code/analysis/Frank']));
arrayNames = {'lateral','medial'};
dataDir = [dataPath filesep 'Sleep' filesep];

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
    txEvents = getTXFromNS5_chunk( fileName, thresholds, 1:96, 180 );
    save([dataDir 'txEvents_' nsFiles{f,1}(1:(end-4)) '.mat'],'txEvents');
end

%%
%convert spike times into binned spike count matrices for LFADS