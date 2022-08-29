function [D, R] = decodeBlockWithDiscreteFilter(blockOrBlockNumber, loadedModel)
% function [D, R] decodeBlockWithDiscreteFilter(blockNumber, loadedModel)

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

% was an Rstruct passed in? if not, create it
if ~isstruct(blockOrBlockNumber)
    if ~isnumeric(blockOrBlockNumber), error('pass in an Rstruct or block number'); end
    R = onlineR(parseDataDirectoryBlock(fullfile(...
            modelConstants.sessionRoot, modelConstants.filelogging.outputDirectory,...
            num2str(blockOrBlockNumber))));
else
    R=blockOrBlockNumber;
end

if isfield(R(1).decoderD, 'discreteFilterName') && ...
        ~isempty(R(1).decoderD.discreteFilterName)
    disp(sprintf('Filter used online: %s', R(1).decoderD.discreteFilterName));
end

% if no model was passed in, prompt for one
if ~exist('loadedModel','var')
    filterFiles = dir([modelConstants.sessionRoot modelConstants.discreteFilterDir '*.mat']);
    filterNames = cell(numel(filterFiles, 1), 1);

    disp('Select a filter file: ');
    for i = 1 : numel(filterFiles)
        filterNames{i} = filterFiles(i).name(1:end-4);
        disp(sprintf('%i: %s', i, filterNames{i}));
    end

    reply = input('Which filter: ', 's');

    if ~isempty(reply)
        clear model;
        selection = str2double(reply);

        tmp = load(fullfile(modelConstants.sessionRoot,modelConstants.discreteFilterDir, filterFiles(selection).name));
        loadedModel = tmp.discretemodel;
    else
        error('huh? choose a model');
    end
end

% create a discrete decode-specific Dstruct
D = onlineDfromR(R,[], loadedModel, loadedModel.options);

% get the offline projected data
offlineProjectedData=[D.Z];
offlineClock=[D.clock];

% get the online projected data
dc = [R.decoderC];
onlineClock = [dc.clock];
onlineProjectedData = [dc.discreteZ];

% offline decode
[se, Ztot, Dout] = decodeDstruct(D, loadedModel);

figure();
plot(offlineClock, offlineProjectedData(1,:),'rx-');
hold on
plot(onlineClock, onlineProjectedData(1,:), 'bo-');
title('Offline (red) vs. Online projected neural data');

figure()
plot(offlineClock, se(:,2), 'rx-');
hold on
tmp = [dc.discreteStateLikelihoods];
plot(onlineClock, tmp(2,:), 'bo-');
title('Offline (red) vs. Online click likelihoods');




keyboard
