function [stateEstimate, Ztot, Dout] = decodeDstruct(D, decoder, opts)
% DECODEDSTRUCT
%
% [stateEstimate, Ztot, Dout] = decodeDstruct(D, decoder)

Ztot = [D.Z];
numStates = decoder.numStates;
stateEstimate = zeros(size(Ztot,2),numStates);
trans = decoder.trans;
emisMean = decoder.emisMean;
emisCovar = decoder.emisCovar;
emisCovarInv = decoder.emisCovarInv;
emisCovarDet = decoder.emisCovarDet;
numDims = decoder.numDimensionsToUse; %SNF
currStateEstimate = zeros(DecoderConstants.MAX_DISCRETE_STATES,1);
currStateEstimate(1) = 1;
t=0;
Dout = D;

opts.foo = false;
opts = setDefault(opts, 'resetEachTrial', false, false);

%% iterate over trials
for nD = 1:length(D)
    if opts.resetEachTrial
        currStateEstimate = zeros(size(currStateEstimate));
        currStateEstimate(1) = 1;
    end
    %% iterate over timesteps
    for nt = 1:size(D(nD).Z,2)
        prevStateEstimate = currStateEstimate;
        %% first project the neural data
        % Zt = Z(t,:);
        % Zn = Zt(:) .* normFactors(:);
        % Zms = Zn - pcaMeans(:);
        % Zp1 = projector' * Zms;
        
         Zp = D(nD).Z(:,nt); %SNF: Zp needs to exclude non-included channels/PCs
       % Zp = D(nD).Z(1:numDims,nt); %SNF: Zp needs to exclude non-included channels/PCs
        % X = [Dtrain.Z]' ;
        % X(:, 17:end) = [];
        Px = zeros(DecoderConstants.MAX_DISCRETE_STATES,1);
        switch decoder.discreteDecoderType
            case DecoderConstants.DISCRETE_DECODER_TYPE_HMMPCA
                for s = 1:numStates
                    emisMeanCur = squeeze(emisMean(s,:))';
                    emisCovarCur = squeeze(emisCovar(s,:,:));
                    emisCovarCurDet = emisCovarDet(s);
                    emisCovarCurInv = squeeze(emisCovarInv(s,:,:));
                    
                    % gaussian pdf
                    % Px(s) = (1/(det(emisCovarCur))^(0.5))* ...
                    %         exp(-0.5*(Zp(:) - emisMeanCur(:))' * inv(emisCovarCur) * (Zp(:)-emisMeanCur(:)));
                    % lPx(s) = log(1/(det(emisCovarCur))^(0.5))+ ...
                    %          (-0.5*(Zp(:) - emisMeanCur(:))' * inv(emisCovarCur) * (Zp(:)-emisMeanCur(:)));
                    neuralDistance = Zp(:) - emisMeanCur(:);
                    Px(s) = (1/(emisCovarCurDet)^(0.5)) * ...
                        exp(-0.5*(neuralDistance)' * emisCovarCurInv * (neuralDistance));
                end
            case DecoderConstants.DISCRETE_DECODER_TYPE_HMMLDA
                %L=[ones(size(observ,2),1) observ(find(osum),:)']*y';
                %P = exp(L) ./ repmat(sum(exp(L),2),[1 numStates]);
                %this needs to only use the num channels used
                L=[];
                for s = 1:numStates
                    emisMeanCur = squeeze(emisMean(s,:))';
                    p=[emisMeanCur(1) decoder.projector(:,s)']; %SNF
                   % p=[emisMeanCur(1) decoder.projector(1:numDims,s)'];
                    L(s) = [1;Zp(:)]'*p';
                end
                Px(1:numStates) = exp(L) ./ repmat(sum(exp(L),2),[1 numStates]);
            otherwise
                error('decodeDstruct: don''t know this discreteDecoderType');
        end
        
        currStateEstimate = trans * prevStateEstimate .*Px(:);
        currStateEstimate = currStateEstimate ./ sum(currStateEstimate);
        %currStateEstimate = Px;
        t = t+1;
        stateEstimate(t,1:numStates) = currStateEstimate(1:numStates);
        Dout(nD).Px(:,nt) = Px;
        Dout(nD).stateEstimate(1:numStates,nt) = currStateEstimate(1:numStates)';
        if any(isnan(currStateEstimate(1:numStates)))
            disp('decoding error - getting NAN values...')
            keyboard
        end
    end
end