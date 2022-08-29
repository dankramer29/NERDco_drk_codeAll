function packets = parseDataFile(fn, fileType, dFormat, emptyPacket)
fd = fopen(fn,'r');
fileData = fread(fd, 'uint8=>uint8');
fclose(fd);

dataLen = typecast(fileData(8+(1:2)), 'uint16'); % Size is data length + header info
packetLen = dataLen+10;
fileData = reshape(fileData, packetLen, []);


% assert(all(diff(typecast(reshape(fileData(1:8, :), 1, []), 'uint64')) == 1), ['Non-sequential Packet Numbers for ' fileType]);
%% edited by CP, 20130912. check for non-sequential packet numbers. if they exist,
%  instead of aborting, just get rid of packets after the last sequential
%  packet
pdiff = diff(typecast(reshape(fileData(1:8, :), 1, []), 'uint64'));
weirdos = find(pdiff<0);
if ~isempty(weirdos)
    lastIndex = min(weirdos);
    warning(sprintf('Non-sequential packet numbers. keeping packets 1-%g of %',lastIndex, size(fileData,2)));
    fileData = fileData(:,1:lastIndex);
end

% get the 'packetsize' for each packet
packetSizes = typecast(reshape(fileData(9:10, :), 1, []), ...
                       'uint16');
% CP: 2016-10-26 - we had a power outage, some of the data got set
% to zero. watching for that here:
if ~all(packetSizes == dataLen),
    disp(['parseDataFile: warning - packet Size change in ' fileType]);
    
    %change occurs at:
    changePoint = find(diff(double(packetSizes)), 1);
    
    % kill all the data after the changePoint
    % assume the last packet prior to changePoint is bad as well
    fileData = fileData(:, 1:changePoint-1);
end

dataIdx = 10 + (1:dataLen);

switch lower(fileType)
    case 'discrete-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'continuous-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'neural-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'decoderd-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'decoderc-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'system-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'meantracking-format-'
        parsed = parseFormatPacket(fileData(dataIdx, 1));
    case 'task-details-'
        parsed = parseTaskDetailsPacket(fileData(dataIdx, 1));
    case 'discrete-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);       
    case 'continuous-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    case 'neural-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    case 'decoderd-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    case 'decoderc-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    case 'system-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    case 'meantracking-data-'
        assert(logical(exist('dFormat','var')), 'Need to pass in a format to parse data files');
        parsed = parseDataPacketsFromFile(fileData(dataIdx, :), dFormat);
    otherwise
        assert(false, ['Dont know how to handle this fileType: ' fileType]);
end

packets = parsed;

