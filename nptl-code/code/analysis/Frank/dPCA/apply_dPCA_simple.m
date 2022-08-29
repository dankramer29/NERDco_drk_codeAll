function out = apply_dPCA_simple( features, eventIdx, trialCodes, timeWindow, timeStep, margNames, ...
    maxDim, CIMode, orthoMode, margGroupings, useCNoise )
    %%
    %features: N x M matrix of M features and N time steps
    %eventIdx: T x 1 vector of time step indices where each trial begins
    %timeWindow: 1 x 2 vector defining the time window (e.g. [-50 100] for
    %   1 second before and 2 seconds after the event index (assuming 0.02
    %   second time step)
    %timeStep: scalar defining the length of time step (0.02 seconds in our case)
    %trialCodes: T x 1 (single factor) or T x 2 (two factor) matrix of
    %   codes defining what condition each trial belongs to
    %margNames: 2 x 1 (single factor) or 4 x 1 (two factor) cell vector
    %   defining the names of each marginalization
    
    if nargin<7
        maxDim = 20;
    end
    if nargin<8
        CIMode = 'none';
    end
    if nargin<9
        orthoMode = 'standard_dpca';
    end
    if nargin<10
        margGroupings = [];
    end
    if nargin<11
        useCNoise = true;
    end
    
    nFactors = size(trialCodes,2);
    if nFactors > 2
        error('Cant do more than 2 factors with this function.');
    end
        
    %the following subfunction formats the feature data into a 4 (single
    %factor) or 5 (two factor) matrix that is required for the dPCA
    %functions
    time = (timeWindow(1):timeWindow(2))*timeStep;
    [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(features, trialCodes, eventIdx, timeWindow, time, nFactors);
    
    % parameter groupings
    % 1 - factor1
    % 2 - factor2
    % 3 - time
    % [1 3] - factor1/time interaction
    % [2 3] - factor2/time interaction
    % [1 2] - factor1/factor2 interaction
    % [1 2 3] - rest
    % Here we group stimulus with stimulus/time interaction etc.

    if nFactors==1
        combinedParams = {{1, [1 2]}, {2}};
        if isempty(margNames)
            margNames = {'Condition-dependent', 'Condition-independent'};
        end
    else
        combinedParams = {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}};
        if isempty(margNames)
            margNames = {'Factor 1', 'Factor 2', 'Condition-independent', 'Factor Interaction'};
        end
    end
    %combinedParams = {{1, [1 3], [1 2], [1 2 3]}, {2, [2 3]}, {3}};
    %margNames = {'M, M x L', 'L', 'Condition-independent'};
    if ~isempty(margGroupings)
        combinedParams = margGroupings;
    end
    
    margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

    % Time events of interest (e.g. stimulus onset/offset, cues etc.)
    % They are marked on the plots with vertical lines
    timeEvents = 0;
    
    %%
    if strcmp(orthoMode,'ortho')
        dpcaFun = @dpca_ortho;
    elseif strcmp(orthoMode,'marg')
        dpcaFun = @dpca_marg;
%         if nFactors==2
%             featureAverages = featureAverages - nanmean(nanmean(featureAverages,2),3);
%             featureVals = featureVals - nanmean(nanmean(nanmean(featureVals,2),3),5);
%         else
%             featureAverages = featureAverages - nanmean(featureAverages,2);
%             featureVals = featureVals - nanmean(nanmean(featureVals,2),4);
%         end
    else
        dpcaFun = @dpca;
    end
    
    %%
    %Calls the dPCA functions from the 2016 paper. See the paper for
    %notation.
    tmp = version('-release');
    tmp = str2num(tmp(1:4));
    if tmp>2015
        try
            pca_result = pca_perMarg(featureAverages, 'combinedParams', combinedParams);
            pca_result.featureAverages = featureAverages;
            
            featureMeans = mean(featureAverages(:,:)');
            featureAverages_ms = featureAverages-featureMeans';
            
            if nFactors==2
                for c1=1:size(pca_result.Z,2)
                    for c2=1:size(pca_result.Z,3)
                        pca_result.Z(:,c1,c2,:) = (squeeze(featureAverages_ms(:,c1,c2,:))'*pca_result.W)';
                    end
                end
            else
                for c1=1:size(pca_result.Z,2)
                    pca_result.Z(:,c1,:) = (squeeze(featureAverages_ms(:,c1,:))'*pca_result.W)';
                end
            end
            
            out.pca_result = pca_result;
        end
    end
    
    ifSimultaneousRecording = 1;
    if any(trialNum(:)==1)
        [W,V,whichMarg] = dpca(featureAverages, maxDim, ...
            'combinedParams', combinedParams);
        
        explVar = dpca_explainedVariance(featureAverages, W, V, ...
            'combinedParams', combinedParams, ...
            'numOfTrials', trialNum);
        
        optimalLambda = 0;
    else
        if strcmp(orthoMode,'ortho') || strcmp(orthoMode,'marg')
            optimalLambda = 0;
        else
            optimalLambda = dpca_optimizeLambda(featureAverages, featureVals, trialNum, ...
                'combinedParams', combinedParams, ...
                'simultaneous', ifSimultaneousRecording, ...
                'numRep', 2, ...  % increase this number to ~10 for better accuracy
                'lambdas', 1e-05 * 1.5.^[0:25]);
            close(gcf);
        end
        %optimalLambda = 0;
        
        Cnoise = dpca_getNoiseCovariance(featureAverages, ...
            featureVals, trialNum, 'simultaneous', ifSimultaneousRecording);
        
        if ~useCNoise
            Cnoise_forOpt = zeros(size(Cnoise));
        else
            Cnoise_forOpt = Cnoise;
        end
        
        [W,V,whichMarg] = dpcaFun(featureAverages, maxDim, ...
           'combinedParams', combinedParams, ...
           'lambda', optimalLambda, ...
           'Cnoise', Cnoise_forOpt);
        
        explVar = dpca_explainedVariance(featureAverages, W, V, ...
            'combinedParams', combinedParams, ...
            'numOfTrials', trialNum, 'Cnoise', Cnoise);
    end
    
    out.W = W;
    out.whichMarg = whichMarg;
    out.V = V;
    out.explVar = explVar;
    
    Z = dpca_plot(featureAverages, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
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
    if strcmp(CIMode,'none')
        out.dimCI = [];
        return;
        
    elseif strcmp(CIMode,'standard')     
        %Standard mode computes confidence intervals assuming a normal
        %distribution without trying to protect against the fact that the
        %dPCs were not cross-validated (i.e. they are a function of the
        %data and may be biased towards finding a certain result).
        
        featureMeans = mean(featureAverages(:,:)');
        out.dimCI = dPCA_CI( out, features-featureMeans, eventIdx, trialCodes, timeWindow );
        
    elseif strcmp(CIMode,'xval') 
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
        allWhichMarg = cell(length(trialCodes),1);
        
        disp('X-Val Folds: ');
        for x=1:length(trialCodes)
            disp([num2str(x) ' / ' num2str(length(trialCodes))]);
            leaveOneOutIdx = setdiff(1:length(trialCodes),x);
            
            [featureVals_leaveOut, featureAverages_leaveOut, trialNum_leaveOut] = ...
                computeFeatureMatrices(features, trialCodes(leaveOneOutIdx,:), eventIdx(leaveOneOutIdx), timeWindow, time, nFactors);
            
            if ~useCNoise
                Cnoise_forOpt = zeros(size(Cnoise));
            else
                Cnoise_forOpt = dpca_getNoiseCovariance(featureAverages_leaveOut, ...
                    featureVals_leaveOut, trialNum_leaveOut, 'simultaneous', ifSimultaneousRecording);
            end
            
            [W,V,whichMarg] = dpcaFun(featureAverages_leaveOut, maxDim, ...
                'combinedParams', combinedParams, ...
                'lambda', optimalLambda, ...
                'Cnoise', Cnoise_forOpt);                
        
            allW{x} = W;
            allWhichMarg{x} = whichMarg;
        end
        
        %how many dimensions to keep per marginalization?
        nMarg = length(margNames);
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
        resortWhichMarg = allWhichMarg;
        for x=1:length(allW)
            resortWhichMarg{x} = zeros(totalDimToKeep, 1);
            margIdx = 1:nDimToKeep(1);

            for n=1:nMarg
                axIdx = find(allWhichMarg{x}==n);
                axIdx = axIdx(1:nDimToKeep(n));

                resortWhichMarg{x}(margIdx) = n;
                resortW{x}(:,margIdx) = allW{x}(:,axIdx);
                
                if n<nMarg
                    margIdx = (margIdx(end)+1):(margIdx(end)+nDimToKeep(n+1));
                end
            end
            resortW{x}(:,(margIdx(end)+1):end) = [];
        end

        %find the sign that most aligns each dimension to the dimensions of the first
        %leave-one-out result
        for x=1:length(resortW)
            dotProduct = sum(resortW{x}.*resortW{1});
            resortW{x} = resortW{x} .* sign(dotProduct);
        end

        %re-align explained variance to match the new dimension sorting
        resortComponentVar = zeros(totalDimToKeep, 1);
        margIdx = 1:nDimToKeep(1);

        for n=1:nMarg
            axIdx = find(out.whichMarg==n);
            axIdx = axIdx(1:nDimToKeep(n));
            resortComponentVar(margIdx) = out.explVar.componentVar(axIdx);

            if n<nMarg
                margIdx = (margIdx(end)+1):(margIdx(end)+nDimToKeep(n+1));
            end
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

        %compute Z and confidence intervals for Z using the single trial
        %data
        if nFactors==1
            codeList = unique(trialCodes);
            Z = zeros(nDim,size(out.featureAverages,2),size(out.featureAverages,3));
            Z_singleTrial = nan(maxRep,nDim,size(out.featureAverages,2),size(out.featureAverages,3));
            dimCI = zeros(nDim,size(out.featureAverages,2),size(out.featureAverages,3),2);

            for dimIdx=1:nDim
                for conIdx=1:size(out.featureAverages,2)
                    innerTrlIdx = find(trialCodes==codeList(conIdx));
                    concatDat = zeros(length(innerTrlIdx),nSteps);
                    for x=1:length(innerTrlIdx)
                        loopIdx = ((eventIdx(innerTrlIdx(x))+timeWindow(1)):(eventIdx(innerTrlIdx(x))+timeWindow(2)))+1;
                        if loopIdx(end)>size(features,1)
                            concatDat(x:end,:) = [];
                            break
                        end
                        concatDat(x,:) = features(loopIdx,:) * resortW{innerTrlIdx(x)}(:,dimIdx);
                    end

                    [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                    dimCI(dimIdx,conIdx,:,:) = MUCI';
                    Z(dimIdx,conIdx,:) = MUHAT;
                    Z_singleTrial(1:size(concatDat,1),dimIdx,conIdx,:) = concatDat;
                end
            end
        elseif nFactors==2
            code1List = unique(trialCodes(:,1));
            code2List = unique(trialCodes(:,2));
            
            Z = zeros(nDim,size(out.featureAverages,2),size(out.featureAverages,3),size(out.featureAverages,4));
            Z_singleTrial = nan(maxRep,nDim,size(out.featureAverages,2),size(out.featureAverages,3),size(out.featureAverages,4));
            dimCI = zeros(nDim,size(out.featureAverages,2),size(out.featureAverages,3),size(out.featureAverages,4),2);
            for dimIdx=1:nDim
                for conIdx_1=1:size(out.featureAverages,2)
                    for conIdx_2=1:size(out.featureAverages,3)
                        innerTrlIdx = find(trialCodes(:,1)==code1List(conIdx_1) & trialCodes(:,2)==code2List(conIdx_2));
                        concatDat = zeros(length(innerTrlIdx),nSteps);
                        for x=1:length(innerTrlIdx)
                            loopIdx = ((eventIdx(innerTrlIdx(x))+timeWindow(1)):(eventIdx(innerTrlIdx(x))+timeWindow(2)))+1;
                            if loopIdx(end)>size(features,1)
                                concatDat(x:end,:) = [];
                                break
                            end
                            concatDat(x,:) = features(loopIdx,:) * resortW{innerTrlIdx(x)}(:,dimIdx);
                        end

                        [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                        dimCI(dimIdx,conIdx_1,conIdx_2,:,:)=MUCI';
                        Z(dimIdx,conIdx_1,conIdx_2,:) = MUHAT;
                        Z_singleTrial(1:size(concatDat,1),dimIdx,conIdx_1,conIdx_2,:) = concatDat;
                    end
                end
            end
        end
        
        %return results in a cval struct that can be passed to plotting functions
        out.cval.Z = Z;
        out.cval.Z_singleTrial = Z_singleTrial;
        out.cval.dimCI = dimCI;
        out.cval.explVar.componentVar = resortComponentVar;
        out.cval.whichMarg = resortWhichMarg{1};
        out.cval.Z_trialOrder = Z_trialOrder;
        out.cval.resortW = resortW;
        
        %also compute standard CIs, for comparison
        out.dimCI = dPCA_CI( out, features, eventIdx, trialCodes, timeWindow );
    end
    
    featureMeans = mean(featureAverages(:,:)');
    out.featureMeansFromTrlAvg = featureMeans;
end

function [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(features, trialCodes, eventIdx, timeWindow, time, nFactors)
    %get maximum number of trials for any condition
    if nFactors==1
        maxRep = max(hist(trialCodes));
    else
        [~,~,muxCodes] = unique(trialCodes, 'rows');
        maxRep = max(hist(muxCodes));
    end
    
    if nFactors==1
        codeList = unique(trialCodes);
        nCodes = length(codeList);
        
        N = size(features,2);   % number of features
        T = length(time);       % number of time steps in a trial
        S = nCodes;             % number of stimuli 
        E = maxRep;             % maximal number of trial repetitions

        trialNum = zeros(N, S);
        featureVals = nan(N, S, T, E);
        
        for s = 1:nCodes
            trlIdx = find(trialCodes(:,1)==codeList(s));
            trialNum(:,s) = length(trlIdx);
            for e = 1:length(trlIdx)
                loopIdx = (eventIdx(trlIdx(e))+timeWindow(1)):(eventIdx(trlIdx(e))+timeWindow(2));
                if loopIdx(end)>size(features,1) || loopIdx(1)<1
                    trialNum(:,s) = trialNum(:,s) - 1;
                    continue;
                end
                featureVals(:,s,:,e) = features(loopIdx,:)';
            end
        end
    elseif nFactors==2
        code1List = unique(trialCodes(:,1));
        code2List = unique(trialCodes(:,2));
        nCodes1 = length(code1List);
        nCodes2 = length(code2List);
        
        N = size(features,2); % number of neurons
        T = length(time);     % number of time points
        S = nCodes1;          % number of stimuli for factor 1
        D = nCodes2;          % number of stimuli for factor 2
        E = maxRep;           % maximal number of trial repetitions

        trialNum = zeros(N, S, D);
        featureVals = nan(N, S, D, T, E);
        for s = 1:S
            for d = 1:D
                trlIdx = find(trialCodes(:,1)==code1List(s) & trialCodes(:,2)==code2List(d));
                trialNum(:,s,d) = length(trlIdx);
                for e = 1:length(trlIdx)
                    loopIdx = (eventIdx(trlIdx(e))+timeWindow(1)):(eventIdx(trlIdx(e))+timeWindow(2));
                    if loopIdx(end)>size(features,1) || loopIdx(1)<1
                        trialNum(:,s) = trialNum(:,s) - 1;
                        continue;
                    end
                    featureVals(:,s,d,:,e) = features(loopIdx,:)';
                end
            end
        end
    end
    
    if ndims(featureVals)>3
        featureAverages = nanmean(featureVals, ndims(featureVals));
    else
        featureAverages = featureVals;
    end
end
