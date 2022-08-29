function adaptFilterBaselines()

%% GUI to choose filter to use

global modelConstants

filterDir = [modelConstants.sessionRoot modelConstants.filterDir];
filterFiles = dir([filterDir '*.mat']);
if isempty(filterFiles)
    fprintf('No filters to adapt to.\n');
    return;
end
[selection, ok] = listdlg('PromptString', 'Select a filter to adapt:', 'ListString', {filterFiles.name}, ...
    'SelectionMode', 'Single', 'ListSize', [400 300]);

if ~ok
    disp('adaptBaselinesDialog: Canceled');
    return
end

filename = [filterDir filterFiles(selection).name];
filter=load(filename);
if filter.model.decoderType ~= DecoderConstants.DECODER_TYPE_VFBNORMSSKF
    disp(filter.model.decoderType);
    error('adaptBaselinesDialog: dont know how to adapt this type of filter...?');
end

originalFilterName = filterFiles(selection).name;


%% GUI to choose which block to use to adapt
try
    ok = 1;
    selection = showBlocksDialog;
    usegui = true;
    if isempty(selection)
        ok = 0;
    end
catch
    usegui = false;
    fldir = dir([modelConstants.sessionRoot modelConstants.filelogging.outputDirectory]);
    names = {fldir.name};
    keep = ~strcmp(names,'.') & ~strcmp(names,'..');
    fldir = fldir(keep);
    
    [selection, ok] = listdlg('PromptString', 'Select a block:', 'ListString', {fldir.name}, ...
        'SelectionMode', 'Single', 'ListSize', [400 300]);
end
if ~ok
    disp('adaptBaselinesDialog: Canceled');
    return
end

if usegui
    blockNumStr = num2str(selection);
else
    blockNumStr = fldir(selection).name;
end
Rdir = [modelConstants.sessionRoot modelConstants.filelogging.outputDirectory blockNumStr];

baselines = getBaselinesFromBlock(Rdir);
badapt = convertBaselinesToFilterBaselines(baselines.continuous, filter.model);
%% kill the unused channels
unusedCh = ~filter.model.C(:,5);
badapt(unusedCh,:) = 0;
%% take the most recent values
newBase = badapt(:, end);

%% modify filter
filter.model.C(:,5) = newBase;

%% set meansTrackingInitial
filter.model.meansTrackingInitial = double(filter.model.C(:,5)) / double(filter.model.dtMS);
filter.model.meansTrackingInitial = filter.model.meansTrackingInitial(:);
% adjust for any normalization
if isfield(filter.model,'invSoftNormVals')
    isnvDefined = find(filter.model.invSoftNormVals);
    filter.model.meansTrackingInitial(isnvDefined) = filter.model.meansTrackingInitial(isnvDefined) ./ double(filter.model.invSoftNormVals(isnvDefined));
end
1

%% GUI to choose savename
global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
end

%% make a new filter name
% trim off .mat
originalFilterName=originalFilterName(1:end-4);
% if this has been adapted previously, trim off that part of the name
sfind = strfind(originalFilterName,'-adaptedBl');
if ~isempty(sfind)
    originalFilterName=originalFilterName(1:sfind(1)-1);
end

% replace the original filter number
numbInds = strfind(originalFilterName,'-');
originalFilterName = originalFilterName(numbInds(1):end);
newFilterNum = sprintf('%03g',CURRENT_FILTER_NUMBER);
newFilterName = [newFilterNum originalFilterName '-adaptedBl-' blockNumStr];

prompt.outputFilterName = newFilterName;
promptfields = fieldnames(prompt);
response=inputdlg(promptfields,'New filter name', [1 75], struct2cell(prompt));

if isempty(response)
    disp('canceled, aborting...')
else
    save([filterDir newFilterName '.mat'], '-struct', 'filter');
end
