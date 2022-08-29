%%
files = {'t7.2013.08.23 Whole body cued movts, new cable (TOUCH)'};
rootDir = '/Users/frankwillett/Data/BG Datasets/movementSweepDatasets';
saveDir = [rootDir filesep 'processedDatasets'];
outDirRoot = '/Users/frankwillett/Data/Derived/movementSweepBrown/';

paths = getFRWPaths();
addpath(genpath(paths.codePath));
    
%%
for fIdx = 1:size(files,1)
    load([saveDir filesep files{fIdx} '.mat']);
    blockList = unique(dataset.blockIdx);
    
    bothRasters = cell(2,1);
    bothUnitLists = cell(2,1);
    
    for arrayIdx=1:2
        %Load sorted data from plexon and the rollover .mat file.
        sortData = importdata([paths.dataPath filesep 'Derived' filesep 'sortedUnits' filesep files{fIdx,1} filesep 'array' num2str(arrayIdx) '.txt']);
        rollovers = load([paths.dataPath filesep 'Derived' filesep 'sortedUnits' filesep files{fIdx,1} filesep 'rollover_array' num2str(arrayIdx) '.mat']);
        rollovers = rollovers.rollovers;
        rollovers = [0, rollovers, inf];
        
        %The following alignment code proceeds one unit at a time within each block. 
        %For each spike fired, we search for the 1 ms bin in the R struct with an NSP clock time that most
        %closely matches that spike time. We then record a spike as having
        %occurred in that bin.
        unitList = unique(sortData(:,1:2),'rows');
        allRasters = cell(length(blockList),1);
        clockFields = {'nsp1Clock', 'nsp2Clock'};
        
        for blockIdx = 1:length(blockList)
            disp(['Array ' num2str(arrayIdx) ' - block ' num2str(blockList(blockIdx))]);
            blockLoop = find(dataset.blockIdx==blockList(blockIdx));
            
            clockTime = dataset.(clockFields{arrayIdx});
            clockTime = double(clockTime(blockLoop,1))*30000;
    
            sortRaster = zeros(length(blockLoop),size(unitList,1));
            for unitIdx=1:size(unitList,1)
                allTimes = sortData(:,1)==unitList(unitIdx,1) & sortData(:,2)==unitList(unitIdx,2);
                allTimes = sortData(allTimes,3)*30000;
                allTimes = allTimes(allTimes>=rollovers(blockIdx) & allTimes<rollovers(blockIdx+1));
                allTimes = double(allTimes - rollovers(blockIdx));
                
                minResult = zeros(length(allTimes),2);
                for spikeIdx=1:length(allTimes)
                    [minResult(spikeIdx,1), minResult(spikeIdx,2)] = min(abs(clockTime-allTimes(spikeIdx)));
                    if minResult(spikeIdx,1) <= 1000
                        sortRaster(minResult(spikeIdx,2),unitIdx) = sortRaster(minResult(spikeIdx,2),unitIdx) + 1;
                    end
                end
            end
            
            allRasters{blockIdx} = sortRaster;
        end
        
        fullRaster = vertcat(allRasters{:});
        bothRasters{arrayIdx} = fullRaster;
        bothUnitLists{arrayIdx} = unitList;
    end
    
    save([paths.dataPath filesep 'Derived' filesep 'sortedUnits' filesep files{fIdx,1} filesep 'alignedRaster.mat'],...
        'bothRasters','bothUnitLists');
end

