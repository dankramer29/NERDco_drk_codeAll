function setDecoderModel(model)
% function assumes that model.filterName exists

    if ~isfield(model, 'filterName')
        fprintf('Error: filterName is not a valid field');
        return;
    end
    previousInputType = getModelParam('inputType');
    setModelParam('inputType',uint16(cursorConstants.INPUT_TYPE_NONE));
    previousInitialInput = getModelParam('initialInput');
    setModelParam('initialInput',uint16(cursorConstants.INPUT_TYPE_NONE));
    
    setModelParam('filterName', model.filterName);
    setModelParam('dtMS', uint16(model.dtMS));
    
    setModelParam('A', model.A);
    
    %% these params are now dependent on # arrays being used
%     arrayDependent = {'C','Cfeedback','K','thresholds','invSoftNormVals', 'meansTrackingInitial'};
%     relevantIdx = [1 1 2 1 1 1]; % some params are NumChannels x M, others are M x NumChannels
    arrayDependent = {'C','K','thresholds','invSoftNormVals', 'meansTrackingInitial'};
    relevantIdx = [1 2 1 1 1]; % some params are NumChannels x M, others are M x NumChannels

    nspks =  0+(DecoderConstants.NUM_CHANNELS_PER_ARRAY);
    nspksfilt =  0+(DecoderConstants.NUM_CHANNELS_PER_ARRAY);
    
    for na = 1:numel(arrayDependent)
        if ~isfield(model,arrayDependent{na});
            continue;
        end
        tmpP = getModelParam(arrayDependent{na});
        %tmpP = zeros(size(tmp));
        modelP = model.(arrayDependent{na});
        
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
    
    
    %setModelParam('C', model.C);
    %setModelParam('K', model.K);
    %setModelParam('thresholds', model.thresholds);
    %if isfield(model,'invSoftNormVals');
    %    setModelParam('invSoftNormVals', model.invSoftNormVals);
    %end
    
    
    if isfield(model, 'transform')
        setModelParam('transform', model.transform);
    end
    if isfield(model, 'useFiltered')
        setModelParam('useFiltered', model.useFiltered);
    end
    if isfield(model, 'useAcaus')
        setModelParam('useAcaus', model.useAcaus);
    end

    if isfield(model, 'decoderType')
        setModelParam('decoderType', uint16(model.decoderType));
    end
    if isfield(model, 'hLFPTransform')
        setModelParam('hLFPTransform', model.hLFPTransform);
    end
    if isfield(model, 'smoothingKernel')
        klength = min(length(model.smoothingKernel),200);
        sk = zeros(size(getModelParam('smoothingKernel')));
        sk(1:klength) = model.smoothingKernel(1:klength);
        setModelParam('smoothingKernel', sk);
    end
    setModelParam('hLFPDivisor', model.hLFPDivisor);
    try
        setModelParam('continuousEnable',true);
    catch
        disp('couldn''t set continuousEnable');
    end
    
    %% add velocity bias correction if it exists
    if isfield(model,'velBias')
        tmp = getModelParam('offsetXk');
        tmp(3) = model.velBias(1);
        tmp(4) = model.velBias(2);
        setModelParam('offsetXk',tmp);
        clear tmp;
    end
    
    %% no reason for discrete models to be defined here.
    if isfield(model,'discrete')
        disp('warning: there is a discrete model defined, but that should be loaded separately... skipping. press any key to acknowledge');
        pause;
    end

    pause(0.5);
    setModelParam('initialInput',previousInitialInput);
    setModelParam('inputType',previousInputType);
    
end