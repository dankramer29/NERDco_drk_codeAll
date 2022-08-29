function stream2R(rID)

[runID runIDtrim] = parseRunID(rID);

inDir1 = fullfile(runID(1:2),runID);

inDir = ['/net/derivative/stream/' inDir1];

blockFiles = dir([inDir '/*.mat']);
fnames = {blockFiles.name};

isBlock = cellfun(@(x) ~isempty(str2num(x(1:end-4))), fnames);
blockNames = fnames(isBlock);
blockNums = cellfun(@(x) str2num(x(1:end-4)), blockNames);

outDir = ['/net/derivative/R/' inDir1 '/'];

if ~exist(outDir)
    mkdir(outDir);
end


for nb = 1:length(blockNames)
    disp(blockNames{nb})
    block = load([inDir '/' blockNames{nb}]);
    clear R
    blockSkipped = false;
    %% edited by chethan 20130912 - somehow completely empty blocks are getting through, cut them out.
    try
        taskParseCommand = ['R = ' block.taskDetails.taskName '_streamParser(block);'];
        eval(taskParseCommand);
    catch
        %[a,b] = lasterr
        a=lasterror
        disp(['skipping ' blockNames{nb} ', perhaps it is an aborted block?']);
        blockSkipped = true;
    end

    
    if ~blockSkipped
		RName = fullfile(outDir, ['R_' sprintf('%03i', blockNums(nb))] );
        disp(sprintf('outputting block %03i to %s', blockNums(nb), outDir));
        splitSave(RName, R);
        system( sprintf('chmod -R g+w %s', RName ) ); % fix its permissions so others can overwrite if calling same funciton SDS Nov 2 2016
    end
end
