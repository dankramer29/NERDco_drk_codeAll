function out = apply_mPCA_general( features, eventIdx, trialCodes, timeWindow, timeStep, opts  )
    %%
    %features: N x M matrix of M features and N time steps
    %eventIdx: T x 1 vector of time step indices where each trial begins
    %trialCodes: T x 1 (single factor) or T x 2 (two factor) matrix of
    %   codes defining what condition each trial belongs to
    %timeWindow: 1 x 2 vector defining the time window (e.g. [-50 100] for
    %   1 second before and 2 seconds after the event index (assuming 0.02
    %   second time step)
    %timeStep: scalar defining  the length of time step (0.02 seconds in our case)
    
    %opts fields: 
    %margNames
    %margGroupings
    %nCompsPerMarg
    %makePlots
    %nFolds
    %readoutMode
    
    %the following subfunction formats the feature data into a data tensor (neurons x condition1 x condition2 x ... x time) that is required for dPCA
    time = (timeWindow(1):timeWindow(2))*timeStep;
    nFactors = size(trialCodes,2);
    
    [featureVals, featureAverages, trialNum, maxRep] = computeFeatureMatrices(features, trialCodes, eventIdx, timeWindow, time, nFactors);
    
    %%    
    ifSimultaneousRecording = 1;
    
    Xnoise = bsxfun(@minus, featureVals, featureAverages);
    Xnoise = Xnoise(:,:);
    Xnoise = Xnoise(:, ~isnan(Xnoise(1,:)));
    SSnoise = Xnoise*Xnoise';
    Cnoise = SSnoise/size(Xnoise,2);
    
    pca_result = pca_perMarg_general(featureAverages, opts.nCompsPerMarg, 'combinedParams', opts.margGroupings);
    
    Cnoise_obsWeighted = dpca_getNoiseCovariance(featureAverages, ...
        featureVals, trialNum, 'simultaneous', ifSimultaneousRecording);
    [readouts, readoutCov, readoutZ, readoutCov_unc] = mpca_readouts(pca_result, Cnoise, Cnoise_obsWeighted, featureAverages, opts.readoutMode);
    
    explVar = mpca_explainedVariance_frw(featureAverages, pca_result.W, pca_result.V, pca_result.whichMarg, ...
        'combinedParams', opts.margGroupings, ...
        'numOfTrials', trialNum, 'Cnoise', Cnoise_obsWeighted);
        
    out.featureAverages = featureAverages;
    out.featureVals = featureVals;
    out.readouts = readouts;
    out.readoutCov = readoutCov;
    out.readoutCov_unc = readoutCov_unc;
    out.sepScore = readoutCov_unc./readoutCov;
    out.readoutZ = readoutZ;
    
    X = features(:,:);
    X = bsxfun(@minus, X, nanmean(X,2));
    XfullCen = reshape(X, size(features));
    out.readoutZ_unroll = XfullCen * readouts;
 
    out.explVar = explVar;
    
    out.W = pca_result.W;
    out.Z = pca_result.Z;
    out.whichMarg = pca_result.whichMarg;
    out.Xmargs = pca_result.Xmargs;
    out.varOrder = pca_result.varOrder;
    
    out.componentVarNumber = zeros(size(pca_result.varOrder));
    out.componentVarNumber(pca_result.varOrder) = 1:length(pca_result.varOrder);
    
    %%
    %cross-validate readouts to generate CIs
    disp('Readout X-Val Folds: ');
    allReadouts = cell(opts.nFolds,1);

    %train readouts for each fold
    cxInds = crossvalind('Kfold',length(trialCodes),opts.nFolds);
    
    for foldIdx=1:opts.nFolds
        disp([num2str(foldIdx) ' / ' num2str(opts.nFolds)]);
        
        trainIdx = find(cxInds~=foldIdx);
        [featureVals_leaveOut, featureAverages_leaveOut, trialNum_leaveOut] = ...
            computeFeatureMatrices(features, trialCodes(trainIdx,:), eventIdx(trainIdx), timeWindow, time, nFactors);

        Xnoise = bsxfun(@minus, featureVals_leaveOut, featureAverages_leaveOut);
        Xnoise = Xnoise(:,:);
        Xnoise = Xnoise(:, ~isnan(Xnoise(1,:)));
        SSnoise = Xnoise*Xnoise';
        Cnoise_leaveOut = SSnoise/size(Xnoise,2);
        
        Cnoise_obsWeighted_leaveOut = dpca_getNoiseCovariance(featureAverages_leaveOut, ...
            featureVals_leaveOut, trialNum, 'simultaneous', ifSimultaneousRecording);
        
        pca_result_leaveOut = pca_perMarg_general(featureAverages_leaveOut, opts.nCompsPerMarg, 'combinedParams', opts.margGroupings);
        readouts_leaveOut = mpca_readouts(pca_result_leaveOut, Cnoise_leaveOut, Cnoise_obsWeighted_leaveOut, featureAverages_leaveOut, opts.readoutMode);
                
        allReadouts{foldIdx} = readouts_leaveOut;
    end
    
    %find the sign that most aligns each dimension to the dimensions of the first
    %leave-one-out result
    if strcmp(opts.alignMode,'reflection')
        for x=1:length(allReadouts)
            dotProduct = sum(allReadouts{x}.*readouts);
            allReadouts{x} = allReadouts{x} .* sign(dotProduct);
        end
    elseif strcmp(opts.alignMode,'rotation')
        for x=1:length(allReadouts)
            [D, rotatedReadout, TRANSFORM] = procrustes(readouts, allReadouts{x}, 'Scaling', false);
            allReadouts{x} = rotatedReadout;
        end
    elseif ~strcmp(opts.alignMode,'none')
        error('Wrong opts.alignMode');
    end

    %compute Z by trial
    nDim = size(allReadouts{1},2);
    nTrials = length(allReadouts);
    nSteps = length(time);

    Z_trialOrder = nan(nTrials,nDim,nSteps);
    for dimIdx=1:nDim
        concatDat = nan(nTrials,nSteps);
        for foldIdx=1:opts.nFolds
            testIdx = find(cxInds==foldIdx);
            
            for trlIdx=1:length(testIdx)
                loopIdx = ((eventIdx(testIdx(trlIdx))+timeWindow(1)):(eventIdx(testIdx(trlIdx))+timeWindow(2)));
                if loopIdx(end)>size(features,1)
                    continue;
                end
                concatDat(testIdx(trlIdx),:) = features(loopIdx,:) * allReadouts{foldIdx}(:,dimIdx);
            end    
        end

        Z_trialOrder(1:size(concatDat,1),dimIdx,:) = concatDat;
    end

    Z_unroll = nan(size(features,1), size(Z_trialOrder,2));
    for t=1:length(eventIdx)
        loopIdx = ((eventIdx(t)+timeWindow(1)):(eventIdx(t)+timeWindow(2)));
        if loopIdx(end)>size(features,1)
            continue;
        end
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

        CI = zeros(2, size(tmp,2));
        for t=1:size(tmp,2)
            inTmp = tmp(:,t);
            inTmp(isnan(inTmp))=[];
            [~,~,CI(:,t)] = normfit(inTmp);
        end
        
        eval(['dimCI' idxOp '=CI'';']);
    end
    
    out.readout_xval.CIs = dimCI;
    out.readout_xval.Z = ZAvg;
    out.readout_xval.ZTrial = ZTrial;
    out.readout_xval.whichMarg = pca_result.whichMarg;
    out.readout_xval.Z_unroll = Z_unroll;
    
    %%
    %resample marginalizations to generate CIs
    disp('Marginalization Resampling: ');
    
    ref_W = pca_result.W;    
    codeList = unique(trialCodes, 'rows');
    if isfield(opts,'nResamples')
        nResamples = opts.nResamples; %200;
    else
        nResamples = 200;
    end
    allResampledZ = cell(nResamples,1);
    
    for n=1:nResamples
        disp([num2str(n) ' / ' num2str(nResamples)]);
        
        resampleIdx = [];
        for codeIdx=1:size(codeList,1)
            trlIdx = find(all(trialCodes==codeList(codeIdx,:),2));
            tmp = randi(length(trlIdx),length(trlIdx),1);
            resampleIdx = [resampleIdx; trlIdx(tmp)];
        end
        
        [featureVals_resample, featureAverages_resample] = computeFeatureMatrices(features, trialCodes(resampleIdx,:), eventIdx(resampleIdx), ...
            timeWindow, time, nFactors);
 
        pca_result_resample = pca_perMarg_general(featureAverages_resample, opts.nCompsPerMarg, 'combinedParams', opts.margGroupings);
                
        if strcmp(opts.alignMode, 'reflection')
            dotProduct = sum(pca_result_resample.W.*ref_W);
            alignedZ = pca_result_resample.Z.*sign(dotProduct)';
        elseif strcmp(opts.alignMode,'rotation')
            alignedZ = realignZ(ref_W, pca_result_resample.W, pca_result_resample.Z, pca_result_resample.Xmargs, ...
                size(featureAverages), opts);
        elseif strcmp(opts.alignMode,'none')
            alignedZ = pca_result_resample.Z;
        else
            error('Wrong opts.alignMode');
        end
        
        allResampledZ{n} = alignedZ;
    end

    %compute CIs for Z
    ZResamples = cat(ndims(alignedZ)+1,allResampledZ{:});
    
    sz = size(pca_result.Z);
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

        tmp = eval(['squeeze(ZResamples' idxOp ')'';']);
        
        CI = zeros(2, size(tmp,2));
        for t=1:size(tmp,2)
            inTmp = tmp(:,t);
            inTmp(isnan(inTmp))=[];
            [~,~,CI(:,t)] = normfit(inTmp);
        end

        CI = prctile(tmp,[2.5 97.5]);
        eval(['dimCI' idxOp '=CI'';']);
    end
    
    out.margResample.CIs = dimCI;
    out.margResample.Z = pca_result.Z;
    out.margResample.whichMarg = pca_result.whichMarg;
    out.margResample.explVar = explVar;
    out.margResample.sepScore = out.sepScore;
    out.margResample.componentVarNumber = out.componentVarNumber;
    
    %%
    %if a plot is requested, plot results
    if opts.makePlots
        margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;
        Z = pca_result.Z;

        if nFactors==2 && size(Z,3)<=4
            colors = jet(size(Z,2))*0.8;
            ciColors = [];

            ls = {':','-','--','-.'};
            lineArgs = cell(size(Z,2), size(Z,3));
            for x=1:size(Z,2)
                for y=1:size(Z,3)
                    lineArgs{x,y} = {'Color',colors(x,:),'LineStyle',ls{y},'LineWidth',2};
                    ciColors = [ciColors; colors(x,:)];
                end
            end
        else
            sz = size(Z);
            if length(sz(2:(end-1)))==1
                lineArgs = cell(sz(2),1);
            else
                lineArgs = cell(sz(2:(end-1)));
            end
            
            colors = jet(numel(lineArgs))*0.8;
            ciColors = colors;
            
            for x=1:numel(lineArgs)
                lineArgs{x} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
            end
        end
        
        timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
        
        layoutInfo.nPerMarg = 5;
        layoutInfo.fPos = [136   510   867   552];
        layoutInfo.gap = [0.03 0.01];
        layoutInfo.marg_h = [0.07 0.02];
        layoutInfo.marg_w = [0.15 0.07];
        layoutInfo.colorFactor = 1;
        layoutInfo.textLoc = [0.025, 0.85];
        layoutInfo.plotLayout = 'horizontal';
        layoutInfo.verticalBars = [0];
        plotTitles = opts.margNames;
        
        %for each marginalization, define plot styles
        lineArgsPerMarg = cell(length(opts.margNames),1);
        nFactors = ndims(Z)-1;
        conShape = size(Z);
        conShape = conShape(2:end);
        for margIdx=1:length(opts.margNames)
            allFactors = unique(horzcat(opts.margGroupings{margIdx}{:}));
            allFactors = setdiff(allFactors, nFactors);
            lineArgsPerMarg{margIdx} = makeLineArgs(conShape(allFactors));
        end
        
        [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( out.margResample, timeAxis, lineArgs, ...
            plotTitles, 'sameAxesGlobal', [], [], out.margResample.CIs, lineArgsPerMarg, opts.margGroupings, opts.plotCI, layoutInfo );

        out.margPlot.layoutInfo = layoutInfo;
        out.margPlot.timeAxis = timeAxis;
        out.margPlot.lineArgsPerMarg = lineArgsPerMarg;
        out.margPlot.lineArgs = lineArgs;
        out.margPlot.plotTitles = plotTitles;
        out.margPlot.ciColors = ciColors;
        
        [yAxesFinal, allHandles, allYAxes] = general_mPCA_plot( out.readout_xval, timeAxis, lineArgs, ...
            plotTitles, 'sameAxesGlobal', [], [], out.readout_xval.CIs, ciColors, opts.plotCI, layoutInfo );

        in.whichMarg = out.whichMarg(out.varOrder);
        in.explVar = out.explVar;
        in.explVar.margVar = in.explVar.margVar(:,out.varOrder);
        try
            componentVarPlot_mpca( in, opts.margNames );
        end

        componentAnglePlot_mpca( out.W(:,out.varOrder) );
    end
end

function alignedZ = realignZ(ref_W, new_W, originalZ, Xmargs, size_X, opts)
    alignedZ = originalZ;
    axIdx = 1:opts.nCompsPerMarg;
    for setIdx=1:length(opts.margGroupings)
        [D, rotAx, TRANSFORM] = procrustes(ref_W(:,axIdx), new_W(:,axIdx), 'Scaling', false);

        indexOp = ['(currentIdx'];
        for dimIdx=1:(length(size_X)-1)
            indexOp = [indexOp, ',:'];
        end
        indexOp = [indexOp,')'];

        for compIdx=1:opts.nCompsPerMarg
            currentIdx = axIdx(compIdx);
            tmp = reshape(rotAx(:,compIdx)'*Xmargs{setIdx}, size_X(2:end));
            eval(['alignedZ' indexOp ' = tmp;']);
        end

        axIdx = axIdx + opts.nCompsPerMarg;
    end
end

function lineArgs = makeLineArgs(conShape)
    nFactors = length(conShape);
    if isempty(conShape)
        lineArgs = {{'Color',lines(1),'LineStyle','-','LineWidth',2}};
    elseif nFactors==2 && conShape(2)<=4
        colors = jet(conShape(1))*0.8;

        ls = {':','-','--','-.'};
        lineArgs = cell(conShape(1), conShape(2));
        for x=1:conShape(1)
            for y=1:conShape(2)
                lineArgs{x,y} = {'Color',colors(x,:),'LineStyle',ls{y},'LineWidth',2};
            end
        end
    else
        if nFactors==1
            lineArgs = cell(conShape,1);
        else
            lineArgs = cell(conShape);
        end

        colors = jet(numel(lineArgs))*0.8;
        for x=1:numel(lineArgs)
            lineArgs{x} = {'Color',colors(x,:),'LineStyle','-','LineWidth',2};
        end
    end
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
