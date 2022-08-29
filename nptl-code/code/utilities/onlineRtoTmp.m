function [R, td] = onlineRtoTmp(blockDir)

stream = parseDataDirectory(blockDir);
taskParseCommand = ['R = ' stream.taskDetails.taskName '_streamParser(stream);'];
td = stream.taskDetails;

if blockDir(end) == '/'
    [partDir, partBlockDir] = fileparts(blockDir(1:end - 1));
else
    [partDir, partBlockDir] = fileparts(blockDir);
end

%try
    eval(taskParseCommand);
%catch err
%   error(['Could not run task parsing code for this block: ' taskParseCommand]);
%end

save(sprintf('/tmp/R_%02i.mat', str2num(partBlockDir)), 'R');