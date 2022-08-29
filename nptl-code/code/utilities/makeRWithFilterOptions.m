function R = makeRWithFilterOptions(block,filter);
% MAKERWITHFILTEROPTIONS    
% 
% R = makeRWithFilterOptions(Rdir,filter);


    opts.gaussSD = filter.options.gaussSmoothHalfWidth;
    opts.thresh = filter.model.thresholds;
    opts.useHLFP = filter.options.useHLFP;
    opts.useHalfGauss = true;
    opts.normalizeKernelPeak = false;
    R = onlineR(block, opts);
