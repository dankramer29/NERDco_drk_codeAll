function [ format, formatLen ] = packTaskDetails( taskName, versionID, varargin )
%TASKDETAILS Puts together a format packet listing the taskName, versionID,
% and an alternating list of state names and numbers (basic state machine
% details)
%#codegen


MAX_TASK_NAME_LENGTH = 50;
MAX_STATE_NAME_LENGTH = 50;

assert(mod(nargin,2) == 0, 'TaskDetails requires an even number of inputs!!');

%format = uint8(zeros(1, (MAX_TASK_NAME_LENGTH + 4) + (length(varargin))*(MAX_STATE_NAME_LENGTH + 4)/2));
format = uint8(zeros(1,1400));
formatLen = uint16((MAX_TASK_NAME_LENGTH + 4) + (length(varargin))*(MAX_STATE_NAME_LENGTH + 4)/2);

format(1 : length(taskName)) = uint8(taskName);
format(MAX_TASK_NAME_LENGTH+1:MAX_TASK_NAME_LENGTH+4) = typecast(versionID, 'uint8');

formatIdx = (MAX_TASK_NAME_LENGTH+4);
for i = 1:2:(length(varargin)-1)
    format(formatIdx+ (1:length(varargin{i}))) = uint8(varargin{i});
    formatIdx = formatIdx + MAX_STATE_NAME_LENGTH;
    format(formatIdx+(1:4)) = typecast(uint32(varargin{i+1}), 'uint8');
    formatIdx = formatIdx + 4;
end



