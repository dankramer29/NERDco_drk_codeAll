function data = getAllFormat(dirName, heading, parseHeading)
if ~exist('parseHeading','var'), parseHeading = heading; end
data = {};
dffs = getFilesFromTemplate(dirName, heading);
dfNums = getNumsFromTemplate(dffs, heading);
for nn = 1:length(dffs)
    tmp = parseDataFile([dirName dffs(nn).name], parseHeading);
    data{nn} = [tmp];
end
