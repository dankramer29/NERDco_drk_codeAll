function saveDataset(data)

if ~exist('data','var')
    error('saveDataset - must pass in struct containing data to be saved');
end

global CACHEDIR
if isempty(CACHEDIR)
    CACHEDIR = '/net/cache/chethan/datasets/';
end

if ~isdir(CACHEDIR)
    disp(['Making cachedir: ' CACHEDIR]);
    mkdir(CACHEDIR)
end
infodir = [CACHEDIR 'info/'];
datadir = [CACHEDIR 'data/'];


if ~isdir(infodir)
    disp(['Making dir: ' infodir]);
    mkdir(infodir)
end
if ~isdir(datadir)
    disp(['Making dir: ' datadir]);
    mkdir(datadir)
end

%% options that are prompted
prompt.title = '';
prompt.group = '';
prompt.notes = '';
prompt.date = datestr(now,'YYYY-mm-DD_HH-MM-SS');

promptfields = fieldnames(prompt);
response=inputdlg(promptfields,'Filter options', [1 1 4 1], struct2cell(prompt));

dumvar = 0;

if ~isempty(response)
    info = struct;
    for nn = 1:length(promptfields)
        info.(promptfields{nn}) = response{nn};
    end
    info.variables = fieldnames(data);
    infofnout = [infodir info.date];
    datafnout = [datadir info.date];
    savefast(infofnout, 'info');
    d2=hlp_serialize(data);
    disp(['saving ' datafnout]);
    tic; 
    savefast(datafnout, 'd2');
    toc;
end