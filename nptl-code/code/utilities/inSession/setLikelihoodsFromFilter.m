function setLikelihoodsFromFilter()
global modelConstants

filterFiles = dir([modelConstants.sessionRoot modelConstants.discreteFilterDir '*.mat']);
filterNames = cell(numel(filterFiles, 1), 1);
for i = 1 : numel(filterFiles)
    filterNames{i} = filterFiles(i).name(1:end-4);
end
[selection, ok] = listdlg('PromptString', 'Select a filter file:', 'ListString', filterNames, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;

    loadedModel = load(fullfile(modelConstants.sessionRoot,modelConstants.discreteFilterDir, filterFiles(selection).name));
    modelConstants.sessionParams.hmmLikelihoods = loadedModel.likelihoods;
    disp('Likelihoods set');
else
    disp('Aborted')
end
