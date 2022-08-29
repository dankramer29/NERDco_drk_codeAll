function [discreteData, continuousData, taskDetails] = spitMergedDirectory(dirName0, baseOutDir, baseBlockNum)

assert(exist(dirName0, 'dir') ~= 0, ['Cant find directory ' dirName0]);
dirName = [dirName0 '/'];

%% get discrete format packet files
htext = 'discrete-format-';
dffs = getFiles(dirName, htext);
dfNums = getNums(dffs, htext);
for nn = 1:length(dffs)
    splitMergedFile([dirName dffs(nn).name], htext, [], [], baseOutDir, baseBlockNum);
end

%% get continuous format packet files
htext = 'continuous-format-';
cffs = getFiles(dirName, htext);
cfNums = getNums(cffs, htext);
for nn = 1:length(cffs)
    splitMergedFile([dirName cffs(nn).name], htext, [], [], baseOutDir, baseBlockNum);
%     tmp = parseDataFile([dirName cffs(nn).name], htext);
%     cdformat{nn} = [tmp];
%     clear tmp;
end

%% get all task details packet files
htext = 'task-details-';
tdfs = getFiles(dirName, htext);
tdNums = getNums(tdfs, htext);

if length(tdfs)
    %% parse all the task details packets
    %emptyPacket = makeEmptyPacket(ddformat{1}(1));
    for nn = 1:length(tdfs)
        splitMergedFile([dirName tdfs(nn).name], htext, [], [], baseOutDir, baseBlockNum);
%         tmp=parseDataFile([dirName tdfs(nn).name], htext);
%         taskDetails{nn} = [tmp];
    end
%     taskDetails = [taskDetails{:}];
% else
%     taskDetails = [];
end

%% get all data packet files
htext = 'discrete-data-';
ddfs = getFiles(dirName, htext);
ddNums = getNums(ddfs, htext);

if length(ddfs)
    %% parse all the discrete data packets
%     emptyPacket = makeEmptyPacket(ddformat{1}(1));
    for nn = 1:length(ddfs)
        splitMergedFile([dirName ddfs(nn).name], htext, [],[], baseOutDir, baseBlockNum);
%         tmp=parseDataFile([dirName ddfs(nn).name], htext, ddformat{1}(1), emptyPacket);
%         discreteData{nn} = [tmp];
    end
%     discreteData = [discreteData{:}];
% else
%     discreteData = [];
end

%% get all the continous data files
htext = 'continuous-data-';
cdfs = getFiles(dirName, htext);
cdNums = getNums(cdfs, htext);

if length(cdfs)
    %% parse all the continuous data packets
    %emptyPacket = makeEmptyPacket(cdformat{1}(1));
    for nn = 1:length(cdfs)
        splitMergedFile([dirName cdfs(nn).name], htext, [],[], baseOutDir, baseBlockNum);
%         tmp=parseDataFile([dirName cdfs(nn).name], htext, cdformat{1}(1), emptyPacket);
%         continuousData{nn} = [tmp];
    end
%     continuousData = [continuousData{:}];
% else
%     continuousData = [];
end


function files = getFiles(dirName, template)
files = dir([dirName template '*.dat']);

function nums = getNums(filenames, heading)
nums = arrayfun(@(x) sscanf(x.name, [heading '%d.dat']), filenames);

