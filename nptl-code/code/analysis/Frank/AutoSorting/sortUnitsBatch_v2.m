paths = getFRWPaths( );

addpath(genpath([paths.codePath 'code/analysis/Frank/AutoSorting']));
saveDir = [paths.dataPath filesep 'sortedUnits'];

arrayNames = {'_Lateral','_Medial'};
sessionList = {'t5.2016.09.28',[4 6];
    't5.2016.09.28',[7 8 9 10];
    't5.2017.10.16',[2 3 5 6 8 9 12 13 16 17 18 19 20 21];};
tmpFilePath = [paths.dataPath filesep 'tmpSortingJunk'];

%%
for s=3:size(sessionList,1)
    sessionDir = getBGSessionPath(sessionList{s,1});
    sortSession(tmpFilePath, saveDir, sessionDir, sessionList{s,1}, sessionList{s,2}, arrayNames);
    packageSortResults(sessionList{s,1}, saveDir, arrayNames, sessionList{s,2});
end
