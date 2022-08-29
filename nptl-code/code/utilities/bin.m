function binX = bin(X, binWidth, binType)
% binX = bin(X, binWidth, binType)
%
% assumes X is formatted NxT
%
% binType can be: 'sum', 'mean', 'first', 'last'

    if ~regexp(binType, 'sum|mean|first|last')
        error('bin:binType', 'Wrong binType entered');
    end

    [dims numSamples] = size(X);
    numBins = floor(numSamples/binWidth);
    binX = zeros(dims, numBins);

    for i = 1 : numBins

        binStart = (i - 1)*binWidth + 1;
        binStop  = i*binWidth;

        switch binType
            case 'sum'
                binX(:, i) = nansum( X(:, binStart : binStop), 2);
            case 'mean'
                binX(:, i) = nanmean( X(:, binStart : binStop), 2);
            case 'first'
                binX(:, i) = X(:, binStart);
            case 'last'
                binX(:, i) = X(:, binStop);
        end

    end

end
