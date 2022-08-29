function addVectorFieldDialog()


global modelConstants

filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
[selection, ok] = listdlg('PromptString', 'Select a filter to use as base:', 'ListString', {filterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if(ok)
    clear model;
    filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];
    load(filename);
    modelOptions = options;
    clear options;
else
    return
end


originalFilter = filterFiles(selection).name(1);
prompt.outputFilterStartNum = char(originalFilter+1);
prompt.vectorFieldMultiplier = num2str(50);

promptfields = fieldnames(prompt);
response=inputdlg(promptfields,'Filter options', 1, struct2cell(prompt));

if isempty(response)
    disp('filter build canceled')
    return
end

for nn=1:length(response)
    options.(promptfields{nn}) = str2num(response{nn});
end

filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
filterNum = options.outputFilterStartNum;


%% iterate over multipliers and add vector fields
for nm = 1:length(options.vectorFieldMultiplier)
    multiplier = options.vectorFieldMultiplier(nm);
    model=createPositionVectorField(model, multiplier);
    modelOptions.vectorFieldMultiplier = multiplier;

    fn = sprintf('%g-model%s-with%gvectorMultiplier', filterNum, originalFilter,multiplier);
    disp(['saving filter : ' fn]);
    save([filterOutDir fn],'model','modelOptions');
    filterNum = filterNum+1;
end