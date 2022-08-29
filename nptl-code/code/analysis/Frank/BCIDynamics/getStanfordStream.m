function [ streams ] = getStanfordStream( sessionPath, blockNums )

    %load all blocks
    paths = getFRWPaths();
    addpath(genpath([paths.codePath '/code/analysis/Frank']));
    addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

    flDir = [sessionPath 'Data' filesep 'FileLogger' filesep];
    streams = cell(length(blockNums),1);
    for b=1:length(blockNums)
        streams{b} = parseDataDirectoryBlock([flDir num2str(blockNums(b)) '/'], blockNums(b));
    end
end

