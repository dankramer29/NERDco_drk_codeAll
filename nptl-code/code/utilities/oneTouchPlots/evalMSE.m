function MSE = evalMSE(estX, trueX);
    
% EVALMSE evaluates the MSE between two vectors.
%   MSE = EVALMSE(ESTX, TRUEX) accepts two vectors, estX and trueX, which
%   denote the estimated values and the true values respectively (but this
%   really doesn't matter) and calculates the mean square error of the
%   estimator.
%
%   Copyright (c) by Jonathan C. Kao
    

    % Input checks
    assert(nargin == 2, 'You did not provide correct inputs.');
    assert(isvector(estX) && isvector(trueX), 'The inputs are not vectors');
    assert(length(estX) == length(trueX), 'The vectors are not of the same size');
    
    % MSE calculation
    MSE = sum(sum((estX - trueX).^2))/length(trueX);

end