function  parseDataFile(fn, fileType, dFormat, emptyPacket, baseOutDir, baseBlockNum)
fd = fopen(fn,'r');
fileData1 = fread(fd, 'uint8=>uint8');
fclose(fd);

dataLen = typecast(fileData1(8+(1:2)), 'uint16'); % Size is data length + header info
packetLen = dataLen+10;

fileData = reshape(fileData1, packetLen, []);

ids = typecast(reshape(fileData(1:8, :), 1, []), 'uint64');
% find the start points of each block
startPackets = find(ids == min(ids));
disp(sprintf('Found %g blocks', length(startPackets)));

% add on a dummy boundary id at the end
startPackets(end+1) = length(ids)+1;
for nn = 1:length(startPackets)-1
   blockLength(nn) = (startPackets(nn+1)-startPackets(nn)) * double(packetLen);
end

%% now write these new files out
if ~isdir(baseOutDir)
    mkdir(baseOutDir)
end

%get the end of the filename
slashInd = max([strfind(fn,'/') 0 ]);
trailingName = fn(slashInd+1:end);
for nn = 1:length(blockLength)
    outDir = [baseOutDir num2str(baseBlockNum+nn-1) '/'];
    if ~isdir(outDir)
        mkdir(outDir)
    end
    outFile = [outDir trailingName];
    startByte = max([cumsum(double(blockLength(1:nn-1))) 0]);
    outData = fileData1(startByte+(1:double(blockLength(nn))));
    fout=fopen(outFile,'w');
    fwrite(fout,outData);
    fclose(fout);
end

% assert(all(diff(typecast(reshape(fileData(1:8, :), 1, []), 'uint64')) == 1), ['Non-sequential Packet Numbers for ' fileType]);
% assert(all(typecast(reshape(fileData(9:10, :), 1, []), 'uint16') == dataLen), ['Packet Size change in ' fileType]);

% dataIdx = 10 + (1:dataLen);
% 
% switch lower(fileType)
%     case 'discrete-format-'
%         parsed = parseFormatPacket(fileData(dataIdx, 1));
%     case 'continuous-format-'
%         parsed = parseFormatPacket(fileData(dataIdx, 1));
%     case 'task-details-'
%         parsed = parseTaskDetailsPacket(fileData(dataIdx, 1));
%     case 'discrete-data-'
%         assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
%         parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);       
%     case 'continuous-data-'
%         assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');        
%         parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
%     otherwise
%         assert(false, ['Dont know how to handle this fileType: ' fileType]);
% end
% 
% packets = parsed;

