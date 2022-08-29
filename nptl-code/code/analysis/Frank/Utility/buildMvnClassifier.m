function model = buildMvnClassifier(feat, featGroup, type)
    %works like Matlab's classify function to build a multivariate normal,
    %generative classifier model that assumes the features are generated by mvn
    %distributions, one for each class. applyMvnGenerativeClassifier then
    %uses Bayesian logic, assuming equal priors, to compute the likelihood
    %of each feature vector coming from each of the distributions,
    %selecting the most likely one
    
    %feat is an MxN feature matrix, where each row is a feature vector
    %featGroup is an Mx1 grouping vector, where each entry indicates the
    %class of the corresponding feature vector
    %type can be "linear" or "quadratic"
    
    % grp2idx sorts a numeric grouping var ascending, and a string grouping
    % var by order of first occurrence
    nModels = size(featGroup,2);
    for m=1:nModels
        [gIndex, ~, classNames] = grp2idx(featGroup(:,m));
        nGroups = max(gIndex);
        nanIdx = find(isnan(gIndex) | any(isnan(feat),2));
        if ~isempty(nanIdx)
            feat(nanIdx,:) = [];
            gIndex(nanIdx) = [];
        end
        gSize = hist(gIndex,1:nGroups);

        %compute mean of groups
        nDim = size(feat,2);
        nObs = size(feat,1);
        gMeans = NaN(nGroups, nDim);
        for k = 1:nGroups
            gMeans(k,:) = mean(feat(gIndex==k,:),1);
        end

        model(m).type = type;
        model(m).gMeans = gMeans;
        model(m).logDetSigma = zeros(nGroups,1,class(feat));
        model(m).R = zeros(nDim,nDim,nGroups,class(feat));
        model(m).classNames = classNames;
        switch type
            case 'linear'
                % Pooled estimate of the covariance for our mvn distributions.  Do not do pivoting, so that A can be
                % computed without unpermuting.  Instead use SVD to find rank of R.
                [Q,R] = qr(feat - gMeans(gIndex,:), 0);
                R = R / sqrt(nObs - nGroups); % SigmaHat = R'*R
                
                s = svd(R);
                if any(s <= max(nObs,nDim) * eps(max(s)))
                    error(message('stats:classify:BadLinearVar'));
                end
                logDetSigma = 2*sum(log(s)); % avoid over/underflow

                model(m).logDetSigma(:) = logDetSigma;
                for k=1:nGroups
                    model(m).R(:,:,k) = R;
                end
            case 'quadratic'
                for k = 1:nGroups
                    % Stratified estimate of covariance.  Do not do pivoting, so that A
                    % can be computed without unpermuting.  Instead use SVD to find rank
                    % of R.
                    [Q,Rk] = qr(bsxfun(@minus,feat(gIndex==k,:),gMeans(k,:)), 0);
                    Rk = Rk / sqrt(gSize(k) - 1); % SigmaHat = R'*R
                    s = svd(Rk);
                    if any(s <= max(gSize(k),nDim) * eps(max(s)))
                        error(message('stats:classify:BadQuadVar'));
                    end
                    model(m).logDetSigma(k) = 2*sum(log(s)); % avoid over/underflow
                    model(m).R(:,:,k) = Rk;
                end
        end
    end
end