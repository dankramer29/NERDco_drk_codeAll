function sortorder = arrayDataOrdering(arrayNums)
% function sortorder = arrayDataOrdering(arrayNums)
% this function is just to set the array order of the datastream 

orders = [];

%% for T7, lateral array comes first, then medial
orders(rigHardwareConstants.ARRAY_T7_LATERAL) = 1;
orders(rigHardwareConstants.ARRAY_T7_MEDIAL) = 2;

%% for T6, only 1 array
orders(rigHardwareConstants.ARRAY_T6) = 1;

%% for T9, lateral array comes first, then medial
orders(rigHardwareConstants.ARRAY_T9_LATERAL) = 1;
orders(rigHardwareConstants.ARRAY_T9_MEDIAL) = 2;

%% for T5, lateral array comes first, then medial
orders(rigHardwareConstants.ARRAY_T5_LATERAL) = 1;
orders(rigHardwareConstants.ARRAY_T5_MEDIAL) = 2;


sortorder = orders(arrayNums);
