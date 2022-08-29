function [ concatOut ] = minDistAndDimBootFun( varargin )
    %for use with bootci
    %computes minimum distance metrics and scree plot metrics
    nClass = length(varargin);
    avgRates = zeros(nClass, size(varargin{1},2));
    for t=1:nClass
        avgRates(t,:) = mean(varargin{t});
    end
    
    distanceMatrix = zeros(size(avgRates,1));
    for d1=1:size(avgRates,1)
        for d2=1:size(avgRates,1)
            distanceMatrix(d1,d2) = norm(avgRates(d1,:)-avgRates(d2,:));
            %distanceMatrix(d1,d2) = lessBiasedDistance( varargin{d1}, varargin{d2} );
        end
    end
    
    minDist = zeros(nClass,1);
    for t=1:nClass
        distMatRow = distanceMatrix(t,:);
        distMatRow(t) = [];
        minDist(t) = min(distMatRow);
    end
    
    avgMinDist = mean(minDist);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgRates);

    concatOut = [avgMinDist, minDist', cumsum(EXPLAINED(1:10)')];
end

function S = softmin(data, alpha)
    S = sum(exp(alpha*data).*data)/sum(exp(alpha*data));
end

