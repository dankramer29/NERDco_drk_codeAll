function [R, td, stream, smoothKernel] = onlineR_robustT6(stream, opts)
% saved from one in t6.2014.06.30 but removed an offending rmfield that
% caused it to error because that field didn't exist (.cerebusFrame)..
opts.foo = false;

if ~isfield(opts,'gaussSD')
    opts.gaussSD = 0;
end

if ~isfield(opts,'useHalfGauss')
    opts.useHalfGauss = false;
end


%% remove large fields that we don't need in the Rstruct
stream.neural = rmfield(stream.neural, 'LFP');

%% smooth if desired
if opts.gaussSD
    if ~isfield(opts,'thresh')
        error('onlineR: in order to smooth, must pass in threshold values in options struct');
    end
    disp(sprintf('smoothing neural data with %g ms gaussian, isHalf: %g, normalize: %g',opts.gaussSD, opts.useHalfGauss, ...
                 opts.normalizeKernelPeak));
    [stream.neural smoothKernel] = smoothStream(stream.neural, opts.thresh, opts.gaussSD, opts.useHalfGauss, ...
                                                opts.normalizeKernelPeak);

else
    smoothKernel=1;
end



R = parseStream(stream);
td = stream.taskDetails;
