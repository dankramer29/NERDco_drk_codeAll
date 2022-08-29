function out = apply_dPCA_PCAOnly( features, eventIdx, trialCodes, timeWindow, timeStep, margNames, maxDim, CIMode )
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
    margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

    % Time events of interest (e.g. stimulus onset/offset, cues etc.)
    % They are marked on the plots with vertical lines
    timeEvents = 0;
    
    %%
    %Calls the dPCA functions from the 2016 paper. See the paper for
    %notation.
    tmp = version('-release');
    tmp = str2num(tmp(1:4));
    pca_result = pca_perMarg(featureAverages, 'combinedParams', combinedParams);
    pca_result.featureAverages = featureAverages;
    out.pca_result = pca_result;
    
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
