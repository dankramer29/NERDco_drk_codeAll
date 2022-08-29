function z=getFiringRates(R,dt,options)

    options.foo = false;
    if ~isfield(options,'lfpfield')
        options.lfpfield = 'HLFP';
    end

    if ~isfield(options,'hLFPDivisor')
        options.hLFPDivisor = single(DecoderConstants.HLFP_DIVISOR+0);
    end
    
    allData = [R.(options.lfpfield)];

    sumspikes = cumsum((allData.^2)');

    z = diff(sumspikes(1:dt:end,:))'/options.hLFPDivisor;
