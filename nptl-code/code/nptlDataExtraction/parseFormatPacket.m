function taskDataFormat = parseFormatPacket(formatBytes)

  MAX_TASK_NAME_LENGTH = 50;
  MAX_VAR_NAME_LENGTH = 30;
  FORMAT_LENGTH = MAX_VAR_NAME_LENGTH + 1 + 8; % +1 for typeID, +8 for dimensions
  VERSIONID_LENGTH = 4;

  %% first get the task name and versionId
  taskDataFormat.taskName = getStringFromBytes(formatBytes(1:MAX_TASK_NAME_LENGTH));
  taskDataFormat.versionId = typecast(formatBytes(MAX_TASK_NAME_LENGTH+(1:VERSIONID_LENGTH)),'uint32');

  %% now get the variables
%  numVars = (length(formatBytes)-MAX_TASK_NAME_LENGTH-VERSIONID_LENGTH)/FORMAT_LENGTH;
  varStart = MAX_TASK_NAME_LENGTH+VERSIONID_LENGTH+1;
  numVars = max(find(formatBytes(varStart:FORMAT_LENGTH:end)));
  assert(mod(numVars, 1) == 0, 'non-integer number of variables in format packet');
  
  idx = MAX_TASK_NAME_LENGTH+VERSIONID_LENGTH;
  for nVar = 1:numVars
    varName = getStringFromBytes(formatBytes(idx+(1:MAX_VAR_NAME_LENGTH)));
    idx = idx + MAX_VAR_NAME_LENGTH;
    varTypeCode = formatBytes(idx+1);
    idx = idx+1;
    tmp = formatBytes(idx+(1:4));
    dim1 = typecast(tmp,'uint32');
    tmp = formatBytes(idx+(5:8));
    dim2 = typecast(tmp,'uint32');
    idx = idx+8;

    taskDataFormat.vars(nVar).name = varName;
    [taskDataFormat.vars(nVar).className, ...
      taskDataFormat.vars(nVar).typeLen] = getClassName(varTypeCode);
    taskDataFormat.vars(nVar).size = [dim1 dim2];
    taskDataFormat.vars(nVar).datalen = dim1 * dim2 * taskDataFormat.vars(nVar).typeLen;
  end

end
