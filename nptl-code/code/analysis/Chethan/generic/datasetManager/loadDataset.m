function loadDataset()

%% define save locations
global CACHEDIR
if isempty(CACHEDIR)
    CACHEDIR = '/net/cache/chethan/datasets/';
end
infodir = [CACHEDIR 'info/'];
datadir = [CACHEDIR 'data/'];

%% get the available datasets

chosenFile = [];
fileNames = cell(1,1);;
dF = figure;

set(dF, 'menuBar', 'none');
dfpos = get(dF,'position');
dfpos(3:4) = [700 400];
set(dF, 'position', dfpos);

%set(dF, 'position', [200 50 900 500]);

% filter list box
uiFLB = uicontrol(  'parent', dF, ...
                    'style', 'listbox', ...
                    'units', 'normalized', ...
                    'position', [0.05 0.1 0.45 0.85], ...
                    'callback', @setChosenFile);
% properties list box
uiPLB = uicontrol(  'parent', dF, ...
                    'style', 'text', ...
                    'units', 'normalized', ...
                    'position', [0.55 0.1 0.4 0.85], ...
                    'callback', @setChosenFile);
loadedInfo = [];
refreshFiles();
chosenFile = 1;
updateDisplayedInfo();

uiButtonPanel = uipanel(    'parent', dF, ...
                            'units', 'normalized', ...
                            'position', [0.3 0.01 0.4 0.08]);

uiLoadB = uicontrol( 'parent', uiButtonPanel, ...
                     'style', 'pushbutton', ...
                     'units', 'normalized', ...
                     'position', [0.02 0.02 0.55 0.9], ...
                     'string', 'Load Data', ...
                     'callback', @loadChosenFile);

uiDeleteB = uicontrol( 'parent', uiButtonPanel, ...
                       'style', 'pushbutton', ...
                       'string', 'Delete', ...
                       'units', 'normalized', ...
                       'position',  [0.6 0.02 0.35 0.9], ...
                       'callback', @deleteChosenFile);           

function refreshFiles()
    % list the directory
    ds = dir([infodir '*.mat']);
    allFileNames = cell(numel(ds, 1), 1);
    for i = 1 : numel(ds)
        allFileNames{i} = ds(i).name(1:end-4);
        allInfo(i) = loadvar([infodir allFileNames{i}],'info');
        datasetNames{i} = allInfo(i).title;
    end

    loadedInfo = allInfo;
    fileNames = allFileNames;
    % set it in the UI
    set(uiFLB, 'string', datasetNames);
end

function updateDisplayedInfo()
    thisInfo = loadedInfo(chosenFile);
    f = fields(thisInfo);
    str = '';
    for nf = 1:length(f)
        str = strcat(str,sprintf('\n\n%s:',f{nf}));
        if iscell(thisInfo.(f{nf}))
            %% e.g. variable names
            for nel = 1:numel(thisInfo.(f{nf}))
                str = strcat(str,sprintf('  %s\n',char(thisInfo.(f{nf}){nel})));
            end
        elseif all(size(thisInfo.(f{nf}))>1)
            %% multi-line strings
            for nel = 1:size(thisInfo.(f{nf}),1)
                str = strcat(str,sprintf('  %s\n',char(thisInfo.(f{nf})(nel,:))));
            end
        else
            str = strcat(str,sprintf('  %s\n',char(thisInfo.(f{nf}))));
        end
    end
    set(uiPLB, 'string', str);
    set(uiPLB, 'HorizontalAlignment', 'left');
end

function setChosenFile(hObj, event)
    chosenFile = get(hObj,'value');
    updateDisplayedInfo();
end

function loadChosenFile(hObj, event)
    disp(['loading ' datadir fileNames{chosenFile}]);
    tic;
    t = loadvar([datadir fileNames{chosenFile}],'d2');
    t = hlp_deserialize(t);
    toc;
    f = fields(t);
    for nn = 1:length(f)
        assignin('base',f{nn},t.(f{nn}));
    end
end

function deleteChosenFile(hObj, event)
    if (strcmp(questdlg('Delete this file?'), 'Yes'))
        disp(['deleting ' infodir fileNames{chosenFile}]);
        disp(['deleting ' datadir fileNames{chosenFile}]);
        delete([infodir fileNames{chosenFile} '.mat']);
        delete([datadir fileNames{chosenFile} '.mat']);
        refreshFiles();
    end
end

end