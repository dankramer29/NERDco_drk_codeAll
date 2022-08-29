global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

filterFiles = dir([modelConstants.sessionRoot modelConstants.discreteFilterDir '*.mat']);
filterNames = cell(numel(filterFiles, 1), 1);
for i = 1 : numel(filterFiles)
    filterNames{i} = filterFiles(i).name(1:end-4);
end
[selection, ok] = listdlg('PromptString', 'Select a DISCRETE filter file:', 'ListString', filterNames, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;

    loadedModel = load(fullfile(modelConstants.sessionRoot,modelConstants.discreteFilterDir, filterFiles(selection).name));
    loadedModel.discretemodel.filterName = zeros([100 1],'uint8');
    tmp = length(filterFiles(selection).name);
    loadedModel.discretemodel.filterName(1:min(tmp,100)) = uint8(filterFiles(selection).name(1:min(tmp,100)));
    setDiscreteDecoderModel(loadedModel.discretemodel);    
end
