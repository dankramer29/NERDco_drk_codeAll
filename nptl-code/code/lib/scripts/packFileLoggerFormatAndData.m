function fileLoggerFormatAndData = packFileLoggerFormatAndData(filename, taskName, versionID, varargin)
%codegen
%PACKDATAANDFORMAT takes an even number of arguments, alternating between
% field name and variable

MAX_TASK_NAME_LENGTH = 50;
VERSIONID_LENGTH = 4;
MAX_VAR_NAME_LENGTH = 30; 
FORMAT_LENGTH = MAX_VAR_NAME_LENGTH + 1 + 8; % +1 for typeID, +8 for dimensions
len = 0;

assert(mod(numel(varargin),2) == 0, 'PackDataAndFormat requires an even number of inputs!!');
assert(length(filename) < 12, 'Filelogger filenames must be less than 12 characters!!');

%format = uint8(zeros(1, (MAX_TASK_NAME_LENGTH + VERSIONID_LENGTH) + FORMAT_LENGTH * (nargin/2-1)));
format = uint8(zeros(1,1400));
formatLen = uint16((MAX_TASK_NAME_LENGTH + VERSIONID_LENGTH) + FORMAT_LENGTH * (nargin/2-1));

% add the taskName and versionId
format(1 : length(taskName)) = uint8(taskName);

VID = typecast(uint32(versionID),'uint8');
format(MAX_TASK_NAME_LENGTH+(1:4)) = VID(1:4);

for i = 1:2:length(varargin)
    
    [typeCode,typeLen]=getTypeCode(varargin{i+1});

    varName = uint8(zeros(1, MAX_VAR_NAME_LENGTH));
    varName(1:length(varargin{i})) = uint8(varargin{i});
    
    varDim = typecast(int32(size(varargin{i+1})), 'uint8');
    
    formatIdx = (i-1)/2*FORMAT_LENGTH + MAX_TASK_NAME_LENGTH + VERSIONID_LENGTH;    
    format(formatIdx + 1 : formatIdx + length(varName)) = varName;
    format(formatIdx+length(varName)+1) = typeCode;    
    format(formatIdx+length(varName)+2:formatIdx+length(varName)+1+length(varDim)) = varDim;
    
    byteLen = typeLen * numel(varargin{i+1});
            
    len = len + byteLen;
end

% Now initialize output accordingly
%data = coder.nullcopy(uint8(zeros(1, len)));
data = uint8(zeros(1,1400));
dataLen = uint16(len);

% Now copy the data
idx = 0;
for i = 1:2:length(varargin)
    if((ischar(varargin{i+1})) || islogical(varargin{i+1}))
            tmp1 = uint8(varargin{i+1});
            tmp = reshape(tmp1, 1, []);
    else
        tmp = typecast(reshape(varargin{i+1}, 1, []), 'uint8');
    end
    data(idx+1:idx+length(tmp)) = tmp;
    idx = idx + length(tmp);
end

baseFileNameLen = length(filename);
dataFileName = uint8(zeros(1,20));
dataFileName(1:baseFileNameLen) = uint8(filename);
dataFileName(baseFileNameLen+1:baseFileNameLen+5) = uint8('-data');

formatFileName = uint8(zeros(1,20));
formatFileName(1:baseFileNameLen) = uint8(filename);
formatFileName(baseFileNameLen+1:baseFileNameLen+7) = uint8('-format');

fileLoggerData.data = data;
fileLoggerData.dataLen = dataLen;
fileLoggerData.fileName = dataFileName;
fileLoggerData.send = false;

fileLoggerFormat.format = format;
fileLoggerFormat.formatLen = formatLen;
fileLoggerFormat.fileName = formatFileName;

fileLoggerFormatAndData.format = fileLoggerFormat;
fileLoggerFormatAndData.data = fileLoggerData;
