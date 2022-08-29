function [binnedl, clickSource] = loadFilterHMMQuantiles()

global modelConstants;
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
    
    fprintf('suggested quantiles (for threshold):\n  q0.90-> %0.3f, q0.91-> %0.3f, q0.92-> %0.3f,\n  q0.93-> %0.3f, q0.94-> %0.3f, q0.95-> %0.3f\n',...
            quantile(loadedModel.likelihoods,[0.9 0.91 0.92 0.93 0.94 0.95]));

    
else
    disp('model load canceled');
end

end
