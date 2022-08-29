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

originalFilterName = filterFiles(selection).name;

resp = inputdlg('Select channels to mask off');
if isempty(resp)
    disp('aborting!'); return
end

channels = str2num(resp{1});
fprintf('wiping out channels %s\n', num2str(channels));

fldir = [modelConstants.sessionRoot modelConstants.filterDir];

for nc =1:numel(channels)
    model.C(channels(nc),3:5)=0;
    model.Q(channels(nc),channels(nc))=1e11;
end

model = calcSteadyStateKalmanGain(model);



%% GUI to choose savename
global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end


originalFilterName = originalFilterName(1:end-4);

% replace the original filter number
numbInds = strfind(originalFilterName,'-');
originalFilterName = originalFilterName(numbInds(1):end);
newFilterNum = sprintf('%03g',CURRENT_FILTER_NUMBER);
newFilterName = [newFilterNum originalFilterName];
fn = sprintf('%s-channelsMasked.mat', newFilterName);
disp(['saving filter : ' fn]);
filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
save([filterOutDir fn],'model','modelOptions');