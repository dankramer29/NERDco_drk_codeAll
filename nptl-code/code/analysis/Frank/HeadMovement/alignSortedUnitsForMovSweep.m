%%
files = {'t5.2018.10.22',[5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]};

%%
for fIdx = 1:size(files,1)
    blockList = files{fIdx,2};
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep files{fIdx,1} filesep];

    %This function call just makes an R struct out of each block and then concatenates
    %them.
    R = getSTanfordBG_RStruct( sessionPath, blockList, [], 4.5 );
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
        allRasters = cell(length(files{fIdx,2}),1);
        for blockIdx = 1:length(files{fIdx,2})
            disp(['Array ' num2str(arrayIdx) ' - block ' num2str(files{fIdx,2}(blockIdx))]);
            blockTrl = find([R.blockNum]==files{fIdx,2}(blockIdx));
            
            sr = [R(blockTrl).spikeRaster]';
            clockTime = [R(blockTrl).firstCerebusTime]';
            clockTime = double(clockTime(:,1));
    
            sortRaster = false(size(sr,1),size(unitList,1));
            for unitIdx=1:size(unitList,1)
                allTimes = sortData(:,1)==unitList(unitIdx,1) & sortData(:,2)==unitList(unitIdx,2);
                allTimes = sortData(allTimes,3)*30000;
                allTimes = allTimes(allTimes>=rollovers(blockIdx) & allTimes<rollovers(blockIdx+1));
                allTimes = double(allTimes - rollovers(blockIdx));
                
                minResult = zeros(length(allTimes),2);
                for spikeIdx=1:length(allTimes)
                    [minResult(spikeIdx,1), minResult(spikeIdx,2)] = min(abs(clockTime-allTimes(spikeIdx)));
                    if minResult(spikeIdx,1) <= 50
                        sortRaster(minResult(spikeIdx,2),unitIdx) = true;
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

