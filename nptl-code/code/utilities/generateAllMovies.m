function generateAllMovies(rID, blocks)


[runID runIDtrim] = parseRunID(rID);

inDir1 = fullfile(runID(1:2),runID);

inDir = ['/net/derivative/R/' inDir1];
outDir = ['/net/www/vid/otp/' rID '/'];

% get all the Rstructs in that dir
blockFiles = dir([inDir '/R*']);


if defined('blocks')
    %% filter out to just the blocks requested
    blockNums = arrayfun(@(x) sscanf(x.name,'R_%d'), blockFiles);
    [~,b2keep,~] = intersect(blockNums,blocks);
    blockFiles = blockFiles(b2keep);
end


for nR = 1:numel(blockFiles)
    R=splitLoad(sprintf('%s/%s',inDir,blockFiles(nR).name));
    movieFromR(R, outDir);
end

