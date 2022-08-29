function arrayConfig = arrayConfigT7(whichConfig)

%% array order - default is order 1 (lateral is primary array)
if ~exist('whichConfig','var')
    whichConfig = 1;
end

switch whichConfig
    case 1
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T7_LATERAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T7_MEDIAL;
        arrayConfig.numArrays = 2;
    case 2
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T7_MEDIAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T7_LATERAL;
        arrayConfig.numArrays = 2;
end
