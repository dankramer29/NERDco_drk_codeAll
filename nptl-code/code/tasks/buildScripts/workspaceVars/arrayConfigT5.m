function arrayConfig = arrayConfigT5(whichConfig)

%% array order - default is order 1 (lateral is primary array)
if ~exist('whichConfig','var')
    whichConfig = 1;
end

global modelConstants

switch whichConfig
    case 1 % I LOVE LAMP
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T5_LATERAL; %ANTERIOR
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T5_MEDIAL; %POSTERIOR
        arrayConfig.numArrays = 2;
        modelConstants.arrayNevDirs = {'_Lateral/','_Medial/'};
    case 2
        arrayConfig.array1 = rigHardwareConstants.ARRAY_T5_MEDIAL;
        arrayConfig.array2 = rigHardwareConstants.ARRAY_T5_LATERIAL;
        arrayConfig.numArrays = 2;
        modelConstants.arrayNevDirs = {'_Medial/','_Lateral/'};
end
