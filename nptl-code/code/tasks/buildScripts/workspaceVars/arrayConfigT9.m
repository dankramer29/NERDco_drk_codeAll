function arrayConfig = arrayConfigT9(whichConfig)

%% array order - default is order 1 (lateral is primary array)
if ~exist('whichConfig','var')
    whichConfig = 1;
end

global modelConstants

switch whichConfig
    case 1
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T9_LATERAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T9_MEDIAL;
        arrayConfig.numArrays = 2;
        modelConstants.arrayNevDirs = {'_Lateral/','_Medial/'};
    case 2
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T9_MEDIAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T9_LATERAL;
        arrayConfig.numArrays = 2;
        modelConstants.arrayNevDirs = {'_Medial/','_Lateral/'};
end
