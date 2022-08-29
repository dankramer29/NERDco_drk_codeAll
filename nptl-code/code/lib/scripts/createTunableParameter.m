function parameter = createTunableParameter(value, dataType)
% Returns a Simulink parameter set as specified
parameter = Simulink.Parameter;
parameter.Value = value;
parameter.DataType = dataType;
parameter.CoderInfo.StorageClass = 'ExportedGlobal'; % makes it tunable and accessible by xPC, Chethan thinks