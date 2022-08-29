function [discreteData, continuousData, taskDetails, neuralData, ...
    decoderDiscreteData, decoderContinuousData, system, meanTracking] = parseDataDirectory(dirName0, excludeFields)

if ~exist('excludeFields','var')
    excludeFields = {};
end

if ~exist('dirName0','dir')
    dirName0=strrep(dirName0,'\','/');
end

assert(exist(dirName0, 'dir') ~= 0, ['Cant find directory ' dirName0]);
dirName = [dirName0 '/'];

if any(strcmp(excludeFields,'discrete'))
    discreteData = [];
else
    %% get discrete format packet files
    htext = 'discrete-format-';
    ddformat=getAllFormat(dirName, htext);
    htext = 'discrete-data-';
    discreteData = getAllData(dirName,htext,ddformat{1}(1));
end

if any(strcmp(excludeFields,'continuous'))
    continuousData = [];
else
    %% get continuous format packet files
    htext = 'continuous-format-';
    cdformat = getAllFormat(dirName,htext);
    htext = 'continuous-data-';
    continuousData = getAllData(dirName,htext,cdformat{1}(1));
end

if any(strcmp(excludeFields,'system'))
    system = [];
else
    %% get all system data
    htext = 'system-format-';
    sdformat = getAllFormat(dirName,htext);
    system = [];
    if ~isempty(sdformat)
        htext = 'system-data-';
        system = getAllData(dirName,htext,sdformat{1}(1));
    end
end


if any(strcmp(excludeFields,'meanTracking'))
    meanTracking = [];
else
    %% get all meanTracking data
    htext = 'meanTracking-format-';
    sdformat = getAllFormat(dirName,htext);
    meanTracking =[];
    if ~isempty(sdformat)
        htext = 'meanTracking-data-';
        meanTracking = getAllData(dirName,htext,sdformat{1}(1));
    end
end

if any(strcmp(excludeFields,'neural'))
    neuralData = [];
else
    %% get neural format packet files
    % neural may have different extensions for each array
    htextAll = 'neural*-format-';
    ndffsAll = getFilesFromTemplate(dirName, htextAll);
    numndfs = 0;
    for nNeural = 1:numel(ndffsAll)
        % the beginning of the filename has to be 'neural' given above, we want
        % to know what's in between that and the first '-' char
        dashes = strfind(ndffsAll(nNeural).name, '-');
        thisNum = str2double(ndffsAll(nNeural).name(7:dashes(1)-1));
        % if this number is 0, the array was inactive. Skip it
        if thisNum ==0
            continue
        end
        numndfs = numndfs+1;
        % if this is empty, there is only one array (data from initial rig)
        if isempty(thisNum) || isnan(thisNum)
            headings{numndfs} = ndffsAll(nNeural).name(1:dashes(2));
            arrayData(numndfs).arrayID = rigHardwareConstants.ARRAY_T6;
            arrayData(numndfs).prefix = ndffsAll(nNeural).name(1:dashes(1)-1);
        elseif thisNum
            headings{numndfs} = ndffsAll(nNeural).name(1:dashes(2));
            arrayData(numndfs).arrayID = thisNum;
            arrayData(numndfs).prefix = ndffsAll(nNeural).name(1:dashes(1)-1);
        else
            error('parseDataDirectory: don''t understand this neural data');
        end
    end
    
    %% get neural data for all arrays
    parseHeading1 = 'neural-format-';
    parseHeading2 = 'neural-data-';
    allNeuralData = []; % all neural data, but unsorted (by array number)
    neuralData = [];% actual output of this function
    
    for nn = 1:numndfs
        ndformat{nn} = getAllFormat(dirName, headings{nn}, ...
            parseHeading1);
        % ndformat is now a cell array of cell arrays
        htext = strrep(headings{nn}, 'format', 'data');
        afields = fields(arrayData);
        for nf = 1:numel(afields)
            allNeuralData(nn).(afields{nf}) = arrayData(nn).(afields{nf});
        end
        allNeuralData(nn).data = getAllData(dirName, htext, ...
            ndformat{nn}{1}(1), parseHeading2);
    end
    
    %% now merge neural data across all arrays
    if isempty(allNeuralData)
        disp(sprintf('parseDataDirectory: warning: couldn''t find any neural data in this dir (%s). continuing on...', dirName0));
    else
        % sort the neural data by array number
        %[~,sortinds] = sort([allNeuralData.arrayID]);
        sortinds = arrayDataOrdering([allNeuralData.arrayID]);
        
        allNeuralData = allNeuralData(sortinds);
        % guard against slight differences in file lengths
        allClockInds = allNeuralData(1).data.clock;
        for nn = 2:numel(allNeuralData)
            allClockInds = intersect(allClockInds,allNeuralData(nn).data.clock);
        end
        
        nfields = fields(allNeuralData(1).data);
        %neuralData = allNeuralData(1).data;
        for nn = 1:numel(allNeuralData)
            [~, ~, keepinds] = intersect(allClockInds,allNeuralData(nn).data.clock);
            for nf = 1:numel(nfields)
                numdims = ndims(allNeuralData(nn).data.(nfields{nf}));
                if numdims == 2
                    selectedData = allNeuralData(nn).data.(nfields{nf})(keepinds,:);
                elseif numdims == 3
                    selectedData = allNeuralData(nn).data.(nfields{nf})(keepinds,:,:);
                else
                    error('parseDataDirectory: don''t know how to handle >3-D fields...?');
                end
                % we don't want redundant clock indices, so let's cut that out right here
                if isfield(neuralData, nfields{nf}) && ~strcmp(nfields{nf},'clock')
                    neuralData.(nfields{nf}) = cat(numdims, neuralData.(nfields{nf}), selectedData);
                else
                    neuralData.(nfields{nf}) = selectedData;
                end
            end
        end
    end
end

decoderDiscreteData = [];
if ~any(strcmp(excludeFields,'decoderD'))
    %% get decoder discrete
    htext = 'decoderD-format-';
    decdformat=getAllFormat(dirName, htext);
    if isempty(decdformat)
        disp('Can''t find decoder-discrete-format packets. old Rstruct?');
    else
        htext = 'decoderD-data-';
        decoderDiscreteData = getAllData(dirName,htext,decdformat{1}(1));
    end
end

decoderContinuousData = [];
if ~any(strcmp(excludeFields,'decoderC'))
    %% get decoder continuous
    htext = 'decoderC-format-';
    deccformat=getAllFormat(dirName, htext);
    if isempty(deccformat)
        disp('Can''t find decoder-continuous-format packets. old Rstruct?');
    else
        htext = 'decoderC-data-';
        decoderContinuousData = getAllData(dirName,htext,deccformat{1}(1));
    end
end

if any(strcmp(excludeFields,'taskDetails'))
    taskDetails = [];
else
    %% get all task details packet files
    htext = 'task-details-';
    tdfs = getFilesFromTemplate(dirName, htext);
    
    if ~isempty(tdfs) % not sure why this check is here, but preserved for legacy
        taskDetails=getAllFormat(dirName, htext);
        taskDetails = [taskDetails{:}];
    else
        fprintf('parseDataDirectory: warning!!! couldnt find a taskDetails packet for this block: \n  (%s)\n',dirName);
        fprintf('parseDataDirectory: that is odd! press any key to acknowledge.\n');
        pause
        taskDetails = [];
    end
end