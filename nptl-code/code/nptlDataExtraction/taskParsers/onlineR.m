function [R, td, stream, smoothKernel] = onlineR(stream, opts)

opts.foo = false;

if ~isfield(opts,'gaussSD')
    opts.gaussSD = 0;
end

if ~isfield(opts,'useHalfGauss')
    opts.useHalfGauss = false;
end

%% remove large fields that we don't need in the Rstruct
% CP - 20161019 - default behavior had been to cut out LFP.
%   changing that behavior
if ~isfield(opts,'removeNeuralFields')
    opts.removeNeuralFields = {'cerebusFrame'};
end


for nn = 1:numel(opts.removeNeuralFields)
    if isfield(stream.neural,opts.removeNeuralFields{nn})
        stream.neural = rmfield(stream.neural, opts.removeNeuralFields{nn});
    end
end

%% smooth if desired
if opts.gaussSD
    if ~isfield(opts,'neuralChannels')
        opts.neuralChannels = 1:size(squeeze(stream.neural.minAcausSpikeBand),2);
    end
    
    if ~isfield(opts,'neuralChannelsHLFP')
        opts.neuralChannelsHLFP = 1:size(squeeze(stream.neural.HLFP),2);
    end

    if ~isfield(opts,'thresh')
        error('onlineR: in order to smooth, must pass in threshold values in options struct');
    end
    disp(sprintf('smoothing neural data with %g ms gaussian, isHalf: %g, normalize: %g',opts.gaussSD, opts.useHalfGauss, ...
                 opts.normalizeKernelPeak));
    [stream.neural, smoothKernel] = smoothStream(stream.neural, opts.thresh, opts.gaussSD, opts.useHalfGauss, ...
                                                opts.normalizeKernelPeak, opts.neuralChannels, opts.neuralChannelsHLFP);
else
    smoothKernel=1;
end


if isfield(opts, 'useRTI') && opts.useRTI
    R = linux_streamParser(stream); %BJ: for RTI (esp for testing), just use 
    %the linux_streamParser for now, no matter what the effector (creates 1 
    %giant R trial with decoded velocities, ignoring positions since they 
    %might be incorrect; relabelDataUsingRTI parses it into sub-trials after 
    %deducing intended targets, relative cursor positions, etc. at a later
    %step. Eventually, might want to wrap relabelDataUsingRTI into its own
    %streamParser and call parseStream same way?  
else 
    R = parseStream(stream);  %as before, use whichever parser is correct for effector. 
end

td = stream.taskDetails;
