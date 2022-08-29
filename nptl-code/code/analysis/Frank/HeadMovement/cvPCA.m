function [ cvScore ] = cvPCA( X, mode, nComp )
    if nargin<3
        nComp = [];
    end
    
    allCoeff = cell(size(X,1),1);
    allMU = cell(size(X,1),1);

    for obsIdx=1:size(X,1)
        trainIdx = [1:(obsIdx-1), (obsIdx+1):size(X,1)];
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(X(trainIdx,:));
        
        allCoeff{obsIdx} = COEFF;
        allMU{obsIdx} = MU;
    end
    
    [fullCoeff, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(X);
    if ismepty(nComp)
        nComp = size(fullCoeff,2);
    end
    
    if strcmp(mode,'reflection')
        for obsIdx=1:size(X,1)
            signs = sign(sum(allCoeff{obsIdx}.*fullCoeff));
            allCoeff{obsIdx} = allCoeff{obsIdx} .* signs;
        end       
    elseif strcmp(mode,'rotation')
        for obsIdx=1:size(X,1)
            [D, Z, TRANSFORM] = procrustes(fullCoeff(:,1:nComp), allCoeff{obsIdx}(:,1:nComp), 'Scaling', false);
            allCoeff{obsIdx} = allCoeff{obsIdx} * TRANSFORM.T;
        end       
    end
    
    cvScore = zeros(size(X,1), size(COEFF,2));
    for obsIdx=1:size(X,1)
        obs = X(obsIdx,:) - allMU{obsIdx};
        cvScore(obsIdx,:) = obs * allCoeff{obsIdx};
    end
end

