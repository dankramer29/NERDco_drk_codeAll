function out = getBaselinesFromBlock(block)
%% function out = getBaselinesFromBlock(block)
%%   takes a block and parses the 'meanTracking' data to find the mean-tracked values

if ischar(block)
    fprintf('assuming this is a directory containing the block\n');
    dirName = block;
    % enforce a trailing slash
    if dirName(end) ~= '/'
        dirName(end+1) = '/';
    end
    fprintf('getting baselines from %s\n', dirName);

    %% get all meanTracking data
    htext = 'meanTracking-format-';
    sdformat = getAllFormat(dirName,htext);
    meanTracking =[];
    if ~isempty(sdformat)
        htext = 'meanTracking-data-';
        meanTracking = getAllData(dirName,htext,sdformat{1}(1));
    end

    %% get all continuous data
    htext = 'continuous-format-';
    sdformat = getAllFormat(dirName,htext);
    continuous =[];
    if ~isempty(sdformat)
        htext = 'continuous-data-';
        continuous = getAllData(dirName,htext,sdformat{1}(1));
    end


    if isempty(meanTracking)
        error('getBaselinesFromBlock: couldnt load these mean tracking numbers');
    end
elseif isstruct(block)
    meanTracking = block.meanTracking;
    continuous =block.continuous;
else
    error('getBaselinesFromBlock: dont know how to process this...?');
end


%% we only want values from when the clock was running
maxUnpaused =  max(continuous.clock(~continuous.pause));

maxReset = max(meanTracking.clock(meanTracking.continuousResetToInitial | meanTracking.continuousResetToCurrent));
%% if this wasn't a means-tracking block...
if isempty(maxReset)
    maxReset = meanTracking.clock(1);
end

cIndFields = {'contMean1Ind','contMean2Ind'};
dIndFields = {'discMean1Ind','discMean2Ind'};
cValFields = {'contMean1Val','contMean2Val'};
dValFields = {'discMean1Val','discMean2Val'};


for nn = 1:numel(cIndFields)

    %% only keep values that were less than the "maxUnpaused" time
    maxKeep = find(meanTracking.clock<maxUnpaused,1,'last');
    minKeep = find(meanTracking.clock>maxReset,1,'first');

    % get all the continuous meantracking indices and values
    allCInds = meanTracking.(cIndFields{nn})(minKeep:maxKeep,:);
    allCVals = meanTracking.(cValFields{nn})(minKeep:maxKeep,:);

    % get all the discrete meantracking indices and values
    allDInds = meanTracking.(dIndFields{nn})(minKeep:maxKeep,:);
    allDVals = meanTracking.(dValFields{nn})(minKeep:maxKeep,:);

    % place these into a cell array for each channel
    x = unique(allCInds);
    x = x(x>0);
    for ic = 1:length(x)
        nc=x(ic);
        allCValsCh{nc} = allCVals(allCInds == nc);
    end
    x = unique(allDInds);
    x = x(x>0);
    for ic = 1:length(x)
        nc=x(ic);
        allDValsCh{nc} = allDVals(allDInds == nc);
    end
end

minlen = min(cellfun(@length,allCValsCh));
for ic = 1:numel(allCValsCh)
    allcvals(ic,:) = allCValsCh{ic}(1:minlen);
end

minlen = min(cellfun(@length,allDValsCh));
for ic = 1:numel(allDValsCh)
    alldvals(ic,:) = allDValsCh{ic}(1:minlen);
end


out.continuous = allcvals;
out.discrete = alldvals;