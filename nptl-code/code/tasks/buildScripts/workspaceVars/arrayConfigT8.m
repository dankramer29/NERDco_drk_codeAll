function arrayConfig = arrayConfigT8(whichConfig)

%% array order - default is order 1 (lateral is primary array)
if ~exist('whichConfig','var')
    whichConfig = 1;
end

global modelConstants

switch whichConfig
    case 1
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T8_LATERAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T8_MEDIAL;
        arrayConfig.numArrays = 0;
        modelConstants.arrayNevDirs = {'_Lateral/','_Medial/'};
    case 2
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T8_MEDIAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T8_LATERAL;
        arrayConfig.numArrays = 0;
        modelConstants.arrayNevDirs = {'_Medial/','_Lateral/'};
    case 3
        arrayConfig.array1 = 0;
        arrayConfig.array2 = 0;
        arrayConfig.numArrays = 0;
        modelConstants.arrayNevDirs = {'_Medial/','_Lateral/'};
end
