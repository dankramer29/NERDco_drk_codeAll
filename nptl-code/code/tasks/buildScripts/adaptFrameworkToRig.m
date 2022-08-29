function adaptFrameworkToRig(modelName)

if ~defined('modelName')
    modelName = 'framework';
end

global modelConstants
if isempty(modelConstants)
	modelConstants = modelDefinedConstants();
end

if ~bdIsLoaded(modelName)
    open_system(modelName)
end

targetBlock = ['acausalFiltering_' modelConstants.rig];

banks = 1:6;
for nn = 1:numel(banks)
    blocksToAdapt{nn} = ['filteringBank' num2str(banks(nn))];
    try
        set_param([modelName '/' blocksToAdapt{nn}],'ModelName',targetBlock)
    catch
    end
end
