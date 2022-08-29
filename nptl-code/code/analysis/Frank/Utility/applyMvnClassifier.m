function classOut = applyMvnClassifier(model, feat)
    %applyMvnClassifier uses the model output from buildMvnClassifier
    %and uses Bayesian logic, assuming equal priors, to compute the likelihood
    %of each feature vector coming from each of the mvn distributions; it then
    %selects the most likely distribution/class
    
    %feat is an MxN feature matrix where each row is a feature vector
    %model is the output from the buildMvnClassifier function
    %classOut is an Mx1 grouping vector which indicates the distribution to
    %which the corresponding feature vector is most likely to belong
    nModels = length(model);
    classOut = zeros(size(feat,1),nModels,class(model(1).classNames));
    for m=1:nModels
        nGroups = length(model(m).classNames);
        D = NaN(size(feat,1), nGroups);

        % MVN relative log posterior density, by group, for each sample
        for k = 1:nGroups
            A = bsxfun(@minus,feat,model(m).gMeans(k,:)) / model(m).R(:,:,k);
            D(:,k) = - .5*(sum(A .* A, 2) + model(m).logDetSigma(k));
        end

        %reformat in terms of original class labels
        [~,classIdx] = max(D, [], 2);
        classOut(:,m) = model(m).classNames(classIdx);
    end
end