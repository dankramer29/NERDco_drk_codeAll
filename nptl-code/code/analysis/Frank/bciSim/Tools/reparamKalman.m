function [ alpha, beta, D ] = reparamKalman( K, A, H, posErr, featureVectors, farDistInterval)
    %convert from VKF matrices to (alpha, beta, D) parameterization in Willett
    %et al., 2017

    %uses a dataset of position errors, feature vectors, and a specification of
    %far field distance in order to normalize the decoding matrix

    aMat = (eye(length(A))-K*H)*A;
    alphaInd = diag(aMat);
    alpha = mean(alphaInd);

    decVectors = (featureVectors*K')/(1-alpha);
    normFactor = normalizeDecoder(posErr, decVectors, farDistInterval);
    beta = 1/normFactor;
    D = K'*normFactor/(1-alpha);
end

