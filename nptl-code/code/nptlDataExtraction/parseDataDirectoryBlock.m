function block = parseDataDirectoryBlock(dirname, excludeFields)

% can pass in the directory number instead of a string
if isnumeric(dirname)
	dirname = sprintf('Data/FileLogger/%i/', dirname);
end

if ~exist('excludeFields','var')
    excludeFields = {};
end
[block.discrete,block.continuous,block.taskDetails,block.neural,block.decoderD, block.decoderC, ...
    block.system, block.meanTracking] = ...
    parseDataDirectory(dirname, excludeFields);

if isempty(block)
    disp('parseDataDirectoryBlock: warning - failing to parse this directory...')
end