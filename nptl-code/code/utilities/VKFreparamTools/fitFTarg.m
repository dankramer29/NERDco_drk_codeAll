function fTarg = fitFTarg(posErr, decVectors, maxDist, nKnots)
    
    targDist = sqrt(sum(posErr.^2,2));
    goodIdx = targDist<=maxDist;
    nDim = size(posErr, 2);
    
    distNorm = targDist/maxDist;
    distEdges = prctile(distNorm(goodIdx),linspace(0,100,nKnots));
    distEdges = unique(distEdges);
    nKnots = length(distEdges);
    distExp = cpwlDesignMatrix( distEdges, distNorm );

    %expand weights features into vectors
    toTargVec = bsxfun(@times, posErr, 1./targDist);
    toTargVec(isnan(toTargVec))=0;
    toTargVec(isinf(toTargVec))=0;
    
    distVec = [];
    for t=1:nKnots
        distVec = [distVec, bsxfun(@times, toTargVec, distExp(:,t))];
    end
    goodIdx = ~all(distVec==0,2) & goodIdx;
    goodIdxStack = repmat(goodIdx, nDim, 1);
        
    %stack dimensions
    distVecStack = [];
    for n=1:nDim
        distVecStack = [distVecStack; distVec(:,n:nDim:end)];
    end
    response = decVectors(:); %stack columns
    
    coefFinal = distVecStack(goodIdxStack,:) \ response(goodIdxStack,:);
    distEdges = distEdges*maxDist;
    fTarg = [distEdges', coefFinal];
end