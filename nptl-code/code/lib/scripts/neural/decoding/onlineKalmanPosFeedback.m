function dout = onlineKalmanPosFeedback(M, din)

%% time-dependent params
xkIn = din.x0;
neural = din.Yk;

%% model params
decoderType = M.decoderType;
K = M.K;
C = M.C;
Cfeedback = M.Cfeedback;
A = M.A;

switch decoderType
  case DecoderConstants.DECODER_TYPE_VFBNORMSSKF
    invSoftNormVals = M.invSoftNormVals;
  case DecoderConstants.DECODER_TYPE_PCAVFBSSKF
    invSoftNormVals = M.invSoftNormVals;
    projector = M.projector;
    pcaMeans = M.pcaMeans;
end

%% static decoding manipulations
scaleXk = ones(size(xkIn));
gainK = ones(size(xkIn));
offsetXk = zeros(size(xkIn));
if isfield(din,'decoderD')
    scaleXk = din.decoderD.scaleXk;
    gainK = din.decoderD.gainK;
    offsetXk = din.decoderD.offsetXk;
end


% Position has already been updated by the task, just need the prior on
% velocity to be updated
xk = xkIn./scaleXk;
xk(3:4) = A(3:4, 3:4)*xk(3:4);

switch decoderType
  case DecoderConstants.DECODER_TYPE_VFBSSKF
    xk = xk + gainK.*(K*(neural(:)-Cfeedback*xk - C*xk));

  case DecoderConstants.DECODER_TYPE_VFBNORMSSKF
    neural(:) = neural(:) .* invSoftNormVals;
    xk = xk + gainK.*(K*(neural(:)-Cfeedback*xk - C*xk));

  case DecoderConstants.DECODER_TYPE_PCAVFBSSKF
    if (any(invSoftNormVals))
        neural(:) = neural(:) .* invSoftNormVals;
    end
    neural(:) = neural(:) - pcaMeans;
    projN = projector' * neural(:);
    xk = xk + gainK.*(K*(projN-Cfeedback*xk - C*xk));
end

xk = xk + offsetXk;

xk = scaleXk.*xk;

dout.xk = xk;