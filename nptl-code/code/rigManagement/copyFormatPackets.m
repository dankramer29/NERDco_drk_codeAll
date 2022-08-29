function copyFormatPackets(blockFrom, blockTo)

global modelConstants

if ~exist('blockFrom', 'var') || ~exist('blockTo', 'var')
    fprintf('Error: incorrect parameters. Usage: copyFormatPackets(<blockFrom>, <blockTo>)\n');
end

if ~isnumeric(blockFrom) || ~isnumeric(blockTo) || ~(blockFrom >= 0) || ~(blockTo >= 0)
    fprintf('Error: paramter incorrect, use positive integer\n');
end

blockFrom = uint16(blockFrom);
blockTo = uint16(blockTo);

file_logger_path = fullfile(modelConstants.sessionRoot, modelConstants.dataDir, 'FileLogger');

block_from_data = parseDataDirectoryBlock(fullfile(file_logger_path, num2str(blockFrom)));
task_type_from = block_from_data.taskDetails.taskName;


r = input(sprintf('Copying format packets from block %i to block %i.\nThis is a %s task block.\nIs this correct? [y/n]\n', blockFrom, blockTo, task_type_from), 's');

if ~strcmp(r, 'y')
    fprintf('Exiting\n');
    return;
end


src_path = fullfile(file_logger_path, num2str(blockFrom));
dst_path = fullfile(file_logger_path, num2str(blockTo));

copyfile(sprintf('%s/*-format-*.dat', src_path), dst_path);
copyfile(sprintf('%s/task-details-*.dat', src_path), dst_path);

logBlockData(blockTo);