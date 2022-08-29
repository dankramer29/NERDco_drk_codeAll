global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
[selection, ok] = listdlg('PromptString', 'Select a KINEMATICS filter file:', 'ListString', {filterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;
    filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];
    load(filename);
    if ~exist('model','var')
        error(['couldnt find a model in that file: ' filename]);
    end
    model.filterName = uint8(filterFiles(selection).name);
    if(length(model.filterName) < 100)
        model.filterName(end+1:100) = uint8(0);
    else
        model.filterName = model.filterName(1:100);
    end
    fprintf('Setting decoder %s\n', char( model.filterName ) )
    setDecoderModel(model);
    
end
