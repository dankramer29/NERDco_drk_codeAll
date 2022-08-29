function replaceKinematicsDialog()


global modelConstants

filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
[selection, ok] = listdlg('PromptString', 'Select a filter to use as base:', 'ListString', {filterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;
    filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];
    load(filename);
    baseModel =model;
    if ~exist('options','var')
        options=[];
    end
    modelOptions = options;
    clear options;
else
    return
end

originalFilter = filterFiles(selection).name;

kinematicFilterFiles = dir([modelConstants.sessionRoot modelConstants.filterComponentsDir '*.mat']);
[selection, ok] = listdlg('PromptString', 'Select a state model to use:', 'ListString', {kinematicFilterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);


if(ok)
    clear model;
    filename = [modelConstants.sessionRoot modelConstants.filterComponentsDir kinematicFilterFiles(selection).name];
    model=load(filename);
    kinematicModel = model;
    clear options;
else
    return
end

if kinematicModel.dtMS ~= baseModel.dtMS
    fprintf(1, 'dt doesn''t match in filters! Base is %ims and Kinematic is %ims\n', baseModel.dtMS, kinematicModel.dtMS);
    return;
end
    
    

baseModel.A = kinematicModel.A;
baseModel.W = kinematicModel.W;
model =calcSteadyStateKalmanGain(baseModel);


prompt.outputFilterName = originalFilter(1:end-4);

promptfields = fieldnames(prompt);
response=inputdlg(promptfields,'Filter options', [1 75], struct2cell(prompt));

if isempty(response)
    disp('filter build canceled')
    return
end
% 
% for nn=1:length(response)
%     options.(promptfields{nn}) = str2num(response{nn});
% end

filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
filterName = response{1};


fn = sprintf('%s-newKin.mat', filterName);
disp(['saving filter : ' fn]);
save([filterOutDir fn],'model','modelOptions');