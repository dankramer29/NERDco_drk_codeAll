function setDiscreteDecoderModel(discretemodel)
% function assumes that model.filterName exists

if ~isfield(discretemodel, 'filterName')
    fprintf('Error: filterName is not a valid field');
    return;
end
setModelParam('discreteFilterName', discretemodel.filterName);

fprintf('loading discrete model parameters from %s\n', discretemodel.filterName );



% CP/PN - 2016-10-04 - these are params that were cut
%   we are just going to use the continuous model parameters rather than
%   having a separate set for discrete
%   we need to check that the loaded continuous model params are
%   appropriate for this model

paramsToVerify = {'thresholds','hLFPDivisor','dtMS'};
for nn = 1:numel(paramsToVerify)
    loadedp = getModelParam(paramsToVerify{nn});
    thismodelp = discretemodel.(paramsToVerify{nn});
    if loadedp(:) ~= thismodelp(:)
        warning(sprintf('this param doesn''t match the loaded param: %s', paramsToVerify{nn}));
    end
end
% also need to verify smoothing kernel, which needs padding
thismodelp = zeros([uint16(DecoderConstants.MAX_KERNEL_LENGTH) 1]);
klen = min(length(thismodelp),length(discretemodel.smoothingKernel));
thismodelp(1:klen) = discretemodel.smoothingKernel(1:klen);
loadedp = getModelParam('smoothingKernel');
if loadedp(:) ~= thismodelp(:)
    warning(sprintf('this param doesn''t match the loaded param: %s', 'smoothingKerel'));
end

%   CP: cutting means tracking
% arrayDependent = {'discreteInvSoftNormVals', 'meansTrackingInitial','discreteProjector'};
% arrayDependent = {'discreteThresholds'};
% discretemodel.discreteThresholds = discretemodel.thresholds;
% if isfield(discretemodel, 'smoothingKernel')
%     sk = zeros([uint16(DecoderConstants.MAX_KERNEL_LENGTH) 1]);
%     klen = min(length(sk),length(discretemodel.smoothingKernel));
%     sk(1:klen) = discretemodel.smoothingKernel(1:klen);
%     setModelParam('discreteSmoothingKernel', sk);
% end
%setModelParam('discreteHLFPDivisor', discretemodel.hLFPDivisor);
%setModelParam('discreteDtMS',discretemodel.dtMS);
if isfield(discretemodel, 'hLFPTransform')
    %setModelParam('discreteHLFPTransform', discretemodel.hLFPTransform);
    error('hlfp transform is no longer used');
end



%% these params are now dependent on # arrays being used
discretemodel.discreteInvSoftNormVals = discretemodel.invSoftNormVals;
discretemodel.discreteProjector = discretemodel.projector;

arrayDependent = {'discreteInvSoftNormVals', 'discreteProjector'};
relevantIdx = [1 1 1 1]; % some params are NumChannels x M, others are M x NumChannels
nspks =  0+(DecoderConstants.NUM_CHANNELS_PER_ARRAY);
nspksfilt =  0+(DecoderConstants.NUM_CHANNELS_PER_ARRAY);

for na = 1:numel(arrayDependent)
    if ~isfield(discretemodel,arrayDependent{na});
        continue;
    end
    tmpP = getModelParam(arrayDependent{na});
    %tmpP = zeros(size(tmp));
    modelP = discretemodel.(arrayDependent{na});
    
    % transpose if needed
    if relevantIdx(na) == 2
        tmpP=tmpP'; modelP=modelP';
    end
    
    if size(modelP,1) == size(tmpP,1)
        tmpP = modelP;
    elseif size(modelP,1) > nspks
        tmpP(1:nspks,:) = modelP(1:nspks,:);
        tmpP((1:nspks)+nspks*2,:) = modelP((1:nspks)+nspks,:);
    else
        tmpP(1:size(modelP,2),:) = modelP;
    end
    
    % transpose back if needed
    if relevantIdx(na) == 2
        tmpP=tmpP';
    end
    setModelParam(arrayDependent{na},tmpP);
end

setModelParam('discretePcaMeans',discretemodel.pcaMeans);

% load HMM params
setModelParam('hmmNumStates',discretemodel.numStates);
setModelParam('hmmTrans',discretemodel.trans);
setModelParam('hmmEmisMean',discretemodel.emisMean);
setModelParam('hmmEmisCovarDet',discretemodel.emisCovarDet);
setModelParam('hmmEmisCovarInv',discretemodel.emisCovarInv);
setModelParam('hmmStateModel',discretemodel.stateModel);
%% hmm click likelihood threshold should be set using parameter scripts

    try
        setModelParam('discreteEnable',true);
    catch
        disp('setDecoderModel: couldn''t set discreteEnable');
    end
    

end