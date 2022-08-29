function [ filts, featureMeans ] = buildLinFilts( Y, X, type, alphaMultiplier, filtWeights )
    %BUILDLINFILTS builds linear filters using a form of linear regression,
    %building a filter that can predict Y when given X as input;
    
    %X and Y are NxF matrices, where N = number of observations, F = number
    %of features
    
    %alphaMultiplier should be used when doing ridge regression, as it
    %specifies the amount of regularization to apply (start with values in
    %the range of 1 to 10, but test a variety of values)
    
    %filtWeights should be given when using weighted regression, and is a
    %vector of weights, one for each observation
    
    %type specifies the type of regression to use
    featureMeans = [];
    
    if strcmp(type,'standard')==1
        %standard least squares regression
        filts = X\Y;
        
    elseif strcmp(type,'weight')==1
        %weighted linear regression using filtWeights, which specifies a
        %weight for each observation; the greater the weight, the more
        %importance given to that observation when fitting the model
        W = spdiags(filtWeights,0,length(filtWeights),length(filtWeights));
        filts = (W*X)\(W*Y);
        
    elseif strcmp(type,'weight_plus_ridge')==1
        %do weighted regression and ridge regression; alphaMultiplier
        %controls how much regularization to apply when doing the ridge
        %regression
        
        %compute the ridge regression parameter
        prodA = X'*X;
        lam_max = max(eig(prodA));
        alpha = alphaMultiplier * lam_max/(size(X,1));
        
        %add pseudo-observations to implement ridge regression
        X = [X; sqrt(alpha)*eye(size(X,2))];
        Y = [Y; zeros(size(X,2),size(Y,2))]; 
        
        %now do weighted regression
        filtWeights = [filtWeights; ones(size(X,2),1)];
        W = spdiags(filtWeights,0,length(filtWeights),length(filtWeights));
        filts = (W*X)\(W*Y);
        
    elseif strcmp(type,'ridge')==1
        %do a ridge regression with alphaMultiplier controlling how much
        %regularization to apply
        
        prodA = X'*X;
        lam_max = max(eig(prodA));
        alpha = alphaMultiplier * lam_max/(size(X,1));
        filts = (prodA + alpha * eye(size(X,2)))\(X'*Y);

    elseif strcmp(type,'inverseLinear')==1
        %assume features in X are a linear function of what we are trying
        %to predict, Y; then invert this optimally
        encodingMatrix = buildLinFilts(X, Y, 'standard');
        encodingNoise = Y * encodingMatrix - X;
        encodingNoise = cov(encodingNoise);

        filts = (encodingMatrix/encodingNoise*encodingMatrix')\(encodingMatrix/encodingNoise);
        filts = filts';
    elseif strcmp(type,'inverseLinearMeanSubtract')==1
        %assume features in X are a linear function of what we are trying
        %to predict, Y; then invert this optimally
        encodingMatrix = buildLinFilts(X, [ones(size(Y,1),1), Y], 'standard');
        encodingNoise = [ones(size(Y,1),1), Y] * encodingMatrix - X;
        encodingNoise = cov(encodingNoise);

        filts = (encodingMatrix(2:end,:)/encodingNoise*encodingMatrix(2:end,:)')\(encodingMatrix(2:end,:)/encodingNoise);
        filts = filts';
        featureMeans = encodingMatrix(1,:);
    elseif strcmp(type,'inverseLinearReg')==1
        %assume features in X are a linear function of what we are trying
        %to predict, Y; then invert this optimally
        encodingMatrix = buildLinFilts(X, Y, 'standard');
        tmp = Y * encodingMatrix - X;
        encodingNoise = zeros(size(tmp,2));
        diagCov = diag(cov(tmp));
        for n=1:size(tmp,2)
            encodingNoise(n,n) = diagCov(n);
        end

        filts = (encodingMatrix/encodingNoise*encodingMatrix')\(encodingMatrix/encodingNoise);
        filts = filts';
    elseif strcmp(type,'PVA')==1
        %assume features in X are a linear function of what we are trying
        %to predict, Y; then invert this optimally
        encodingMatrix = buildLinFilts(X, Y, 'standard');
        filts = encodingMatrix';
        %modDepth = matVecMag(encodingMatrix,2);
        %normEncMatrix = bsxfun(@times, encodingMatrix, 1./modDepth);
    else
        error('Type must be either standard, weight, ridge, weight_plus_ridge, or inverseLinear');
    end
end

%Y = Xbeta + Q

