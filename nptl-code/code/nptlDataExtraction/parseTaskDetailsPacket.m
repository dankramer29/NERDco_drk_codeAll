function td = parseTaskDetailsPacket(bytes)
MAX_TASK_NAME_LENGTH = 50;
VERSIONID_LENGTH = 4;
MAX_STATE_NAME_LENGTH = 50;

BASE_SIZE = MAX_TASK_NAME_LENGTH + 4;
STATE_INFO_SIZE = MAX_STATE_NAME_LENGTH + 4;

assert(logical(mod(length(bytes)-BASE_SIZE, STATE_INFO_SIZE) == 0), 'Invalid size for TaskDetails packet');

td.taskName = getStringFromBytes(bytes(1:MAX_TASK_NAME_LENGTH));
td.versionId = typecast(bytes(MAX_TASK_NAME_LENGTH+(1:VERSIONID_LENGTH)),'single');
idx = MAX_TASK_NAME_LENGTH+VERSIONID_LENGTH;

numStates = ((length(bytes)-BASE_SIZE)/STATE_INFO_SIZE);
for nn = 1:numStates
    stateName = getStringFromBytes(bytes(idx+(1:MAX_STATE_NAME_LENGTH)));
    idx = idx + MAX_STATE_NAME_LENGTH;
    tmp = bytes(idx+(1:4));
    stateCode = typecast(tmp, 'uint32');
    idx = idx+4;
    td.states(nn).name = stateName;
    td.states(nn).id = stateCode;
end
