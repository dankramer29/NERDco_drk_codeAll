function data  = getAllData(dirName, heading, pformat, parseHeading)
if ~exist('parseHeading','var'), parseHeading = heading; end
data = {};
ndfs = getFilesFromTemplate(dirName, heading);
ndNums = getNumsFromTemplate(ndfs, heading);
if ~isempty(ndfs)
    %% parse all the continuous data packets
    emptyPacket = makeEmptyPacket(pformat);
    for nn = 1:length(ndfs)
        fileName = [dirName ndfs(nn).name];
        tmp=parseDataFile(fileName, parseHeading, pformat, emptyPacket);
        data{nn} = [tmp];
    end
    data= [data{:}];
else
    data = [];
end
