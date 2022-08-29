function funOut = rnnDecoders_magOnly(in)

    %%
    trlLen = in.reachEpochs(:,2) - in.reachEpochs(:,1) + 1;
    tooLong = trlLen>450;
    in.reachEpochs(tooLong,:) = [];
    
    nFolds = 6;
    in.modelType = 'FMP';
    C = cvpartition(size(in.reachEpochs,1),'KFold',nFolds);
    posErr = in.targetPos - in.cursorPos;
    
    popModelOut = cell(nFolds,1);
    
    for n=1:nFolds
        disp([' -- Fold ' num2str(n)]);
        inFold = in;
        inFold.reachEpochs = in.reachEpochs(C.training(n),:);
        foldModel = fitPhasicAndFB_6(inFold);
        out = applyPhasicAndFB(inFold, foldModel);
        popModelOut{n} = out.popResponse;
        
        %standard magnitude decoder
        rEpochs = [inFold.reachEpochs(:,1)+10, inFold.reachEpochs(:,2)];
        rIdx = expandEpochIdx(rEpochs);
        alpha = linspace(0.8,0.98,10);
        err = zeros(length(alpha),1);
        dec = cell(length(alpha),1);
        for a=1:length(alpha)
            dec{a} = buildMagDec( inFold.reachEpochs, posErr/inFold.maxDist, alpha(a), out.popResponse(:,1:2), out.popResponse(:,3) );
            decVec = applyMagDec( dec{a}, alpha(a), out.popResponse(:,1:2), out.popResponse(:,3) );
            err(a) = getFTargErr( decVec(rIdx,:), posErr(rIdx,:), inFold.maxDist );
        end
        [~,minIdx] = min(err);
        
        testEpochs = in.reachEpochs(C.training(n),:);
        testIdx = expandEpochIdx([testEpochs(:,1)+10, testEpochs(:,2)]);
        decVecFinal = applyMagDec( dec{minIdx}, alpha(minIdx), out.popResponse(:,1:2), out.popResponse(:,3) );
        xValOutLin{1}(testIdx,:) = decVecFinal(testIdx,:);
        
        %linear decoder with exponential smoothing
        for a=1:length(alpha)
            decPop = filter(1-alpha(a),[1, -alpha(a)], out.popResponse(:,1:2));
            err(a) = getFTargErr( decPop(rIdx,:), posErr(rIdx,:), inFold.maxDist );
        end
        [~,minIdx] = min(err);
        
        decVecFinal = filter(1-alpha(minIdx),[1, -alpha(minIdx)], out.popResponse(:,1:2));
        xValOutLin{2}(testIdx,:) = decVecFinal(testIdx,:);
    end

    allIdx = expandEpochIdx([in.reachEpochs(:,1)+10, in.reachEpochs(:,2)]);
    nearIdx = intersect(allIdx, find(matVecMag(posErr,2)<in.maxDist*0.25));
    farIdx = setdiff(allIdx, nearIdx);
    
    mae = zeros(2,1);
    speedRatio = zeros(2,1);
    for d=1:2
        mae(d) = nanmean(abs(getAngularError(posErr(allIdx,:), xValOutLin{d}(allIdx,:))))*(180/pi);
        speed = matVecMag(xValOutLin{d},2);
        speedRatio(d) = mean(speed(nearIdx))/mean(speed(farIdx));
    end
    
    %%
    nBinsPerChunk = 510;
    
    popIdx = {[1 2 3 4],[1 2 4],[1 2 3],[1 2]};
    xValOut = cell(length(popIdx),1);
    for p=1:length(popIdx)
        xValOut{p} = zeros(size(in.kin.posErrForFit,1),1);
    end
    
    paths = getFRWPaths();
    hfTmpPath = [paths.dataPath filesep 'Derived' filesep 'hfDataTmp'];
    pythonScriptPath = [paths.codePath filesep 'code' filesep 'analysis' filesep 'Frank' filesep 'BackpropSim'];
    
    mkdir(hfTmpPath);
    magTarget = matVecMag(in.kin.posErrForFit,2);
    magTarget = repmat(magTarget, 1, 2);
    
    for n=1:nFolds
        disp(['Fold: ' num2str(n)]);  
        trainIdx = find(C.training(n));
        testIdx = find(C.test(n));
        
        innerTrainIdx = trainIdx(1:(4*floor(length(trainIdx)/5)));
        innerTestIdx = setdiff(trainIdx, innerTrainIdx);

        for p=1:length(popIdx)
            [inputs, targets, globalIdx] = formatInput(in.reachEpochs, innerTrainIdx, nBinsPerChunk, popModelOut{n}, magTarget, popIdx{p});
            [inputsVal, targetsVal, globalIdxVal] = formatInput(in.reachEpochs, innerTestIdx, nBinsPerChunk, popModelOut{n}, magTarget, popIdx{p});
            [inputsFinal, targetsFinal, globalIdxFinal] = formatInput(in.reachEpochs, testIdx, nBinsPerChunk, popModelOut{n}, magTarget, popIdx{p});

            save([hfTmpPath filesep 'rnnData.mat'],'inputs','targets','inputsVal','targetsVal','inputsFinal','targetsFinal');
            tic;
            setenv('PATH','/Users/frankwillett/google-cloud-sdk/bin:/Users/frankwillett/anaconda/bin:/Library/Frameworks/Python.framework/Versions/3.6/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin')
            system(['python ' pythonScriptPath filesep 'rnn4Comp.py']);
            toc;
            tmp = load([hfTmpPath filesep 'rnnResults.mat']);
            
            out = permute(tmp.outputsFinal,[2 1 3]);
            out = reshape(out, size(out,1)*size(out,2), 2);
            targ = permute(targetsFinal,[2 1 3]);
            targ = reshape(targ, size(targ,1)*size(targ,2), 2);
            goodIdx = find(all(~isnan(targ),2));
            
            xValOut{p}(globalIdxFinal,:) = out(goodIdx,1);
            disp(diag(corr(out(goodIdx,1), targ(goodIdx,1))));
        end
    end
    
    funOut.xValOut = xValOut;
    funOut.xValOutLin = xValOutLin;
    funOut.in = in;
end

function [input, target, globalIdx] = formatInput(reachEpochs, trlIdx, nBinsPerChunk, popResponse, targetVals, popIdx)
    input = zeros(length(trlIdx),nBinsPerChunk,length(popIdx));
    target = nan(length(trlIdx),nBinsPerChunk,size(targetVals,2));
    globalIdx = [];
    for t=1:length(trlIdx)
        loopIdx = reachEpochs(trlIdx(t),1):reachEpochs(trlIdx(t),2);
        allIdx = (reachEpochs(trlIdx(t),1)-nBinsPerChunk+length(loopIdx)):reachEpochs(trlIdx(t),2);
        input(t,:,:) = popResponse(allIdx,popIdx);
        target(t,(end-length(loopIdx)+1):end,:) = targetVals(loopIdx,:);

        globalIdx = [globalIdx; loopIdx'];
    end
end