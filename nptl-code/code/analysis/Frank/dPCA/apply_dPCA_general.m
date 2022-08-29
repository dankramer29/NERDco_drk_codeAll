function out = apply_dPCA_general( features, eventIdx, trialCodes, timeWindow, timeStep, opts  )
    %%
    %features: N x M matrix of M features and N time steps
    %eventIdx: T x 1 vector of time step indices where each trial begins
    %timeWindow: 1 x 2 vector defining the time window (e.g. [-50 100] for
    %   1 second before and 2 seconds after the event index (assuming 0.02
    %   second time step)
    %timeStep: scalar defining  the length of time step (0.02 seconds in our case)
    %trialCodes: T x 1 (single factor) or T x 2 (two factor) matrix of
    %   codes defining what condition each trial belongs to
    %margNames: 2 x 1 (single factor) or 4 x 1 (two factor) cell vector
    %   defining the names of each marginalization
    
    %opts fields: margNames, margGroupings, maxDim, CIMode, orthoMode,
    %useCNoise
    
    %the following subfunction formats the feature data into a data tensor (neurons x condition1 x condition2 x ... x time) that is required for dPCA
    time = (timeWindow(1):timeWindow(2))*timeStep;
    nFactors = size(trialCodes,2);
    [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(features, trialCodes, eventIdx, timeWindow, time, nFactors);
        
    margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

    % Time events of interest (e.g. stimulus onset/offset, cues etc.)
    % They are marked on the plots with vertical lines
    timeEvents = 0;
    
    %%    
    ifSimultaneousRecording = 1;
    
    Cnoise = dpca_getNoiseCovariance(featureAverages, ...
        featureVals, trialNum, 'simultaneous', ifSimultaneousRecording);
    
    if opts.useCNoise
        if strcmp(opts.orthoMode,'ortho') || any(isnan(trialNum(:)))
            %have to rewrite optimizeLambda to deal with missing conditions
            optimalLambda = 1e-4;
        else
            optimalLambda = dpca_optimizeLambda(featureAverages, featureVals, trialNum, ...
                'combinedParams', opts.margGroupings, ...
                'simultaneous', ifSimultaneousRecording, ...
                'numRep', 2, ...  % increase this number to ~10 for better accuracy
                'lambdas', 1e-05 * 1.5.^[0:25]);
            close(gcf);
        end
        Cnoise_forOpt = Cnoise;
    else
        optimalLambda = opts.optimalLambda;
        Cnoise_forOpt = zeros(size(Cnoise));
    end
    
    if strcmp(opts.orthoMode,'ortho')
        [W,V,whichMarg,XMarg] = dpca_ortho(featureAverages, opts.maxDim, ...
           'combinedParams', opts.margGroupings, ...
           'lambda', optimalLambda, ...
           'Cnoise', Cnoise_forOpt);
    else
        [W,V,whichMarg,XMarg] = dpca_frw(featureAverages, opts.maxDim, ...
            'combinedParams', opts.margGroupings, ...
            'lambda', optimalLambda, ...
            'Cnoise', Cnoise_forOpt);
    end

    out.XMarg = XMarg;
    explVar = dpca_explainedVariance_frw(featureAverages, W, V, ...
        'combinedParams', opts.margGroupings, ...
        'numOfTrials', trialNum, 'Cnoise', Cnoise);
    
    out.W = W;
    out.whichMarg = whichMarg;
    out.V = V;
    out.explVar = explVar;
    
    Z = dpca_plot_frw(featureAverages, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', opts.margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', time,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
    out.Z = Z;
    
    out.featureAverages = featureAverages;
    out.featureVals = featureVals;
    out.optimalLambda = optimalLambda;
    
    %%
    %If requested, compute confidence intervals according to the method
    %specified. Standard mode is faster and in my limited testing, yields
    %CIs almost identical to xval mode. However, xval mode is more conservative 
    %and can be used to try to conservatively verify an important result. 
    if strcmp(opts.CIMode,'none')
        out.dimCI = [];
        return;
        
    elseif strcmp(opts.CIMode,'standard')     
        %Standard mode computes confidence intervals assuming a normal
        %distribution without trying to protect against the fact that the
        %dPCs were not cross-validated (i.e. they are a function of the
        %data and may be biased towards finding a certain result).
        
        featureMeans = mean(featureAverages(:,:)');
        out.dimCI = dPCA_CI( out, features-featureMeans, eventIdx, trialCodes, timeWindow );
        
    elseif strcmp(opts.CIMode,'xval') 
        %Uses leave-one-out cross-validation to protect against the fact
        %that dPCA is a supervised method. Takes a small liberty in
        %aligning the signs of the dPCs to match each other. This method
        %can end up being very conservative in the case where two dPCs
        %explain almost the same amount of variance and correspond to the same marginilization, in which case they
        %will change dramatically from test set to test set and average out.  
        
        %center features to match standard dPCA
        featureMeans = mean(featureAverages(:,:)');
        features = features-featureMeans;
        
        allW = cell(length(trialCodes),1);
        allV = cell(length(trialCodes),1);
        allWhichMarg = cell(length(trialCodes),1);
        
        disp('X-Val Folds: ');
        for x=1:length(trialCodes)
            disp([num2str(x) ' / ' num2str(length(trialCodes))]);
            leaveOneOutIdx = setdiff(1:length(trialCodes),x);
            
            [featureVals_leaveOut, featureAverages_leaveOut, trialNum_leaveOut] = ...
                computeFeatureMatrices(features, trialCodes(leaveOneOutIdx,:), eventIdx(leaveOneOutIdx), timeWindow, time, nFactors);
            
            if ~opts.useCNoise
                Cnoise_forOpt = zeros(size(Cnoise));
            else
                Cnoise_forOpt = dpca_getNoiseCovariance(featureAverages_leaveOut, ...
                    featureVals_leaveOut, trialNum_leaveOut, 'simultaneous', ifSimultaneousRecording);
            end
            
            if strcmp(opts.orthoMode,'ortho')
                [W,V,whichMarg] = dpca_ortho(featureAverages_leaveOut, opts.maxDim, ...
                    'combinedParams', opts.margGroupings, ...
                    'lambda', optimalLambda, ...
                    'Cnoise', Cnoise_forOpt);                
            else
                [W,V,whichMarg] = dpca(featureAverages_leaveOut, opts.maxDim, ...
                    'combinedParams', opts.margGroupings, ...
                    'lambda', optimalLambda, ...
                    'Cnoise', Cnoise_forOpt);
            end
        
            allW{x} = W;
            allV{x} = V;
            allWhichMarg{x} = whichMarg;
        end
        
        %how many dimensions to keep per marginalization?
        nMarg = length(opts.margNames);
        nDimToKeep = zeros(nMarg,1);
        for n=1:nMarg
            tmpNDim = zeros(length(trialCodes),1);
            for x=1:length(trialCodes)
                tmpNDim(x) = length(find(allWhichMarg{x}==n));
            end
            nDimToKeep(n) = min(tmpNDim);
        end
        totalDimToKeep = sum(nDimToKeep);

        %sort dimensions by marginalization 
        resortW = allW;
        resortV = allV;
        resortWhichMarg = allWhichMarg;
        for x=1:length(allW)
            resortWhichMarg{x} = zeros(totalDimToKeep, 1);
            margIdx = 1:nDimToKeep(1);

            for n=1:nMarg
                axIdx = find(allWhichMarg{x}==n);
                axIdx = axIdx(1:nDimToKeep(n));

                resortWhichMarg{x}(margIdx) = n;
                resortW{x}(:,margIdx) = allW{x}(:,axIdx);
                resortV{x}(:,margIdx) = allV{x}(:,axIdx);
                
                if n<nMarg
                    margIdx = (margIdx(end)+1):(margIdx(end)+nDimToKeep(n+1));
                end
            end
            resortW{x}(:,(margIdx(end)+1):end) = [];
            resortV{x}(:,(margIdx(end)+1):end) = [];
        end

        %find the sign that most aligns each dimension to the dimensions of the first
        %leave-one-out result
        for x=1:length(resortW)
            dotProduct = sum(resortW{x}.*resortW{1});
            resortW{x} = resortW{x} .* sign(dotProduct);
            resortV{x} = resortV{x} .* sign(dotProduct);
        end
                
        %compute Z by trial for further cross-validated analyses outside of
        %this function
        nDim = size(resortW{1},2);
        nTrials = length(resortW);
        if nFactors==1
            nSteps = size(out.featureAverages,3);
        else
            nSteps = size(out.featureAverages,4);
        end
        
        Z_trialOrder = nan(nTrials,nDim,nSteps);
        for dimIdx=1:nDim
            concatDat = zeros(nTrials,nSteps);
            for x=1:nTrials
                loopIdx = ((eventIdx(x)+timeWindow(1)):(eventIdx(x)+timeWindow(2)))+1;
                if loopIdx(end)>size(features,1)
                    concatDat(x:end,:) = [];
                    break
                end
                concatDat(x,:) = features(loopIdx,:) * resortW{x}(:,dimIdx);
            end

            Z_trialOrder(1:size(concatDat,1),dimIdx,:) = concatDat;
        end
        
        Z_unroll = zeros(size(features,1), size(Z_trialOrder,2));
        for t=1:length(eventIdx)
            loopIdx = ((eventIdx(t)+timeWindow(1)):(eventIdx(t)+timeWindow(2)))+1;
            Z_unroll(loopIdx,:) = squeeze(Z_trialOrder(t,:,:))';
        end
        [ZTrial, ZAvg] = computeFeatureMatrices(Z_unroll, trialCodes, eventIdx, timeWindow, time, nFactors);
            
        %compute CIs for Z
        sz = size(ZAvg);
        sz_con = sz(1:(end-1));
        dimCI = zeros([sz, 2]);
        subIdx = cell(length(sz_con),1);
        
        for x = 1:prod(sz_con)
            [subIdx{:}] = ind2sub(sz_con,x);
            
            idxOp = '(';
            for t=1:length(sz_con)
                idxOp = [idxOp, num2str(subIdx{t}) ','];
            end
            idxOp = [idxOp, ':,:)'];
            
            tmp = eval(['squeeze(ZTrial' idxOp ')'';']);
            tmp(any(isnan(tmp),2),:) = [];
            
            [~,~,CI] = normfit(tmp);
            eval(['dimCI' idxOp '=CI'';']);
        end
       
        %compute variance explained on Z
        % centering
        Xfull = featureAverages;
        X = Xfull(:,:);
        Xfull = bsxfun(@minus, Xfull, nanmean(X,2));
        X = bsxfun(@minus, X, nanmean(X,2));

        % marginalizing
        Xmargs = dpca_marginalize(Xfull, 'combinedParams', opts.margGroupings, 'ifFlat', 'yes');

        %don't include missing conditions
        validColumns = find(all(~isnan(X)));
        XValid = X(:,validColumns);
        XmargsValid = Xmargs;
        for x=1:length(XmargsValid)
            XmargsValid{x} = XmargsValid{x}(:,validColumns);
        end

        % total variance
        explVar_cval.totalVar = nansum(nansum(XValid.^2));

        % total marginalized variance
        for i=1:length(XmargsValid)
            explVar_cval.totalMarginalizedVar(i) = nansum(XmargsValid{i}(:).^2);
        end

        % PCA explained variance
        [~,S,~] = svd(XValid', 'econ');
        S = diag(S);
        S = S(1:size(W,2));
        explVar_cval.cumulativePCA = cumsum(S.^2'/ explVar_cval.totalVar * 100);

        %for each component, compute its reconstruction
        compReconValid = cell(size(W,2),1);
        compReconMargs = cell(size(W,2),1);
        for i=1:size(W,2)
            X_Recon_trialOrder = nan(nTrials,size(features,2),nSteps);
            for x=1:nTrials
                tmp = squeeze(Z_trialOrder(x,i,:));
                tmp = tmp';
                
                X_Recon_trialOrder(x,:,:) = resortV{x}(:,i)*tmp;
            end

            recon_unroll = zeros(size(features,1), size(X_Recon_trialOrder,2));
            for t=1:length(eventIdx)
                loopIdx = ((eventIdx(t)+timeWindow(1)):(eventIdx(t)+timeWindow(2)))+1;
                recon_unroll(loopIdx,:) = squeeze(X_Recon_trialOrder(t,:,:))';
            end
            [reconTrial, reconAvg] = computeFeatureMatrices(recon_unroll, trialCodes, eventIdx, timeWindow, time, nFactors);
            reconAvgUnroll = reconAvg(:,:);
            compReconValid{i} = reconAvgUnroll(:,validColumns);
            
            %recompute reconstruction using only this component
            compReconMargs{i} = dpca_marginalize_frw(reconAvg, 'combinedParams', opts.margGroupings, 'ifFlat', 'yes');
            for x=1:length(compReconMargs{i})
                compReconMargs{i}{x} = compReconMargs{i}{x}(:,validColumns);
            end
            
            %component variance
            explVar_cval.componentVar(i) = 100 - sum(sum((XValid - compReconValid{i}).^2)) / explVar_cval.totalVar * 100;    
            for j=1:length(XmargsValid)
                ZZ = XmargsValid{j} - compReconMargs{i}{j};
                explVar_cval.margVar(j,i) = (explVar_cval.totalMarginalizedVar(j) - sum(ZZ(:).^2)) / explVar_cval.totalVar * 100;    
            end
        end
        
        %resort according to component variance
        [explVar_cval.componentVar, varOrder] = sort(explVar_cval.componentVar,'descend');
        explVar_cval.margVar = explVar_cval.margVar(:,varOrder);
        
        % dPCA cumulative explained variance        
        for i=1:size(W,2)        
            cumulativeRecon = sum(cat(3,compReconValid{varOrder(1:i)}),3);
            explVar_cval.cumulativeDPCA(i) = 100 - sum(sum((XValid - cumulativeRecon).^2)) / explVar_cval.totalVar * 100;    
        end
        
        %return results in a cval struct that can be passed to plotting functions
        %reorder every component by variance
        out.cval.explVar = explVar_cval;
        
        reorderOp = '(varOrder';
        for x=1:(ndims(ZAvg)-1)
            reorderOp = [reorderOp, ',:'];
        end
        reorderOp = [reorderOp,')'];
        
        reorderOp_more = '(varOrder';
        for x=1:(ndims(ZTrial)-1)
            reorderOp_more = [reorderOp_more, ',:'];
        end
        reorderOp_more = [reorderOp_more,')'];
        
        out.cval.Z = eval(['ZAvg' reorderOp]);
        out.cval.Z_singleTrial = eval(['ZTrial' reorderOp_more]);
        out.cval.dimCI = eval(['dimCI' reorderOp_more]);
        out.cval.whichMarg = resortWhichMarg{1}(varOrder);
        out.cval.Z_trialOrder = Z_trialOrder(:,varOrder,:);
        
        for x=1:length(resortW)
            resortW{x} = resortW{x}(:,varOrder);
            resortV{x} = resortV{x}(:,varOrder);
        end
        
        out.cval.resortW = resortW;
        out.cval.resortV = resortV;
    end
    
    featureMeans = mean(featureAverages(:,:)');
    out.featureMeansFromTrlAvg = featureMeans;
end

function [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(features, trialCodes, eventIdx, timeWindow, time, nFactors)

    N = size(features,2);   % number of features
    T = length(time);       % number of time steps in a trial
    
    [codeList,~,muxCodes] = unique(trialCodes, 'rows');
    maxRep = max(hist(muxCodes, max(muxCodes)));
    nCodes = size(codeList,1);
    nCons = zeros(nFactors, 1);
    for f=1:nFactors
        nCons(f) = length(unique(trialCodes(:,f)));
    end
    
    matrixSize_singleTrial = [N, nCons', T, maxRep];
    matrixSize_numTrials = [N, nCons'];
    
    featureVals = nan(matrixSize_singleTrial); 
    trialNum = nan(matrixSize_numTrials);

    for codeIdx = 1:nCodes
        trlIdx = find(muxCodes==codeIdx);
        indOp = '(:';
        for f=1:nFactors
            indOp = [indOp, ',' num2str(codeList(codeIdx,f))];
        end
        indOp = [indOp, ')'];
        eval(['trialNum' indOp ' = length(trlIdx);']);
        
        indOp_neural = '(:';
        for f=1:nFactors
            indOp_neural = [indOp_neural, ',' num2str(codeList(codeIdx,f))];
        end
        indOp_neural = [indOp_neural, ',:,e)'];
        
        for e = 1:length(trlIdx)
            loopIdx = (eventIdx(trlIdx(e))+timeWindow(1)):(eventIdx(trlIdx(e))+timeWindow(2));
            if loopIdx(end)>size(features,1) || loopIdx(1)<1
                eval(['trialNum' indOp ' = trialNum' indOp ' - 1;']);
                continue;
            end
            
            eval(['featureVals' indOp_neural ' = features(loopIdx,:)'';']);
        end
    end
    
    if ndims(featureVals)>3
        featureAverages = nanmean(featureVals, ndims(featureVals));
    else
        featureAverages = featureVals;
    end
end
