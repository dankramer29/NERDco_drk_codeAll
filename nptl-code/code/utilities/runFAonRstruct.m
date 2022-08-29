function out = runFAonRstruct(R, faopts)
% RUNFAONRSTRUCT    
% 
% out = runFAonRstruct(R, faopts)
% faopts: 
% required
%   faopts.useChannels
%   faopts.thresholds
% optional
%   faopts.outputDir % needed if global modelConstants.factorAnalysisDir is undefined
%   faopts.blockNums % use if mC.factorAnalysisDir is being used
%   faopts.FArunIdx % otherwise mC.FArunIdx is used
%   faopts.kernSD % defaults to 80
%   faopts.binWidth % defaults to 20


if ~isfield(faopts,'FArunIdx')
    global modelConstants
    if ~isfield(modelConstants,'FArunIdx')
        modelConstants.FArunIdx = 1;
    else
        modelConstants.FArunIdx = modelConstants.FArunIdx + 1;
    end
    faopts.FArunIdx = modelConstants.FArunIdx;
end
FArunIdx = faopts.FArunIdx;

kernSD = 60;
if isfield(faopts,'kernSD')
    kernSD = faopts.kernSD;
end

binWidth = 20;
if isfield(faopts,'binWidth')
    binWidth = faopts.binWidth;
end


method = 'fa';

xDim = 6;
if isfield(faopts,'xDim')
    xDim = faopts.xDim;
end

%%sometimes we use this to process stream structs instead
if numel(size([R.minAcausSpikeBand])) > 2
    R.minAcausSpikeBand = squeeze(R.minAcausSpikeBand)';
end

if isfield(faopts,'outputDir')
    outputDir = faopts.outputDir;
elseif isfield(faopts,'blockNums')
    blocksStr = num2str(faopts.blockNums,'%g_');
    blocksStr = blocksStr(1:end-1);
    outputDir = sprintf('%s%s',modelConstants.factorAnalysisDir, blocksStr);
    fprintf(1,'runFAonRstruct: using output directory %s\n', outputDir);
else
    error('runFAonRstruct: must specify an output directory');
end

useChannels = faopts.useChannels;
thresholds = faopts.thresholds;

if ~isdir(outputDir),mkdir(outputDir); end

%% setup data for FA
for nn = 1:length(R)
    R(nn).trialId = nn;
    dat(nn).trialId = nn;
    for ic = 1:numel(useChannels)
        ch=useChannels(ic);
        thresh = thresholds(ch);
        dat(nn).spikes(ic,:) = single(R(nn).minAcausSpikeBand(ch,:)<thresh);
    end
    %% add HLFP?
    %hblock = sqrt(abs(single(R(nn).HLFP(1:96,:))))/sqrt(500);
    %dat(nn).spikes(numel(useChannels)+(1:96),:) = hblock;
end

%% eliminate channels that have no spikes - code is very touchy-feely.
sumSpikes = sum([dat.spikes]');
keep = logical(sumSpikes);
useChannels = useChannels(keep);
for nn = 1:length(dat)
    dat(nn).spikes = dat(nn).spikes(keep,:);
end

%% eliminate any duplicate units 
% just look for units that have /exactly/ the same number of spikes over the entire Rstr
tmpx = [dat.spikes];
[~,i] = unique(sum(tmpx,2));
if length(i) < size(tmpx,1)
    for nn = 1:length(dat)
        dat(nn).spikes = dat(nn).spikes(i,:);
    end
end
clear a i tmpx


% run smooth+fa
result = neuralTraj(FArunIdx, dat, 'method', method, 'xDim', xDim, 'outputDir',outputDir, 'binWidth', binWidth ,'kernSDList',[kernSD]);
% Orthonormalize neural trajectories
[~, seqTrain] = postprocess(result, 'kernSD', kernSD);
[~,sorted]=sort([seqTrain.trialId],'ascend');


%% sort the trials
seqTrain = seqTrain(sorted);

out.R = R;
out.seqTrain = seqTrain;
out.binWidth = result.binWidth;