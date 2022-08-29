function funOut = prepareXValRNNData(in, workspaceSize, datasetName, dataDir)

    %%
    nBinsPerChunk = 510; 
    trlLen = in.reachEpochs(:,2) - in.reachEpochs(:,1) + 1;
    tooLong = trlLen>450;
    in.reachEpochs(tooLong,:) = [];
    
    tooEarly = in.reachEpochs(:,2) < nBinsPerChunk;
    in.reachEpochs(tooEarly,:) = [];
    
    nFolds = 6;
    in.modelType = 'FMP';
    C = cvpartition(size(in.reachEpochs,1),'KFold',nFolds);
    popModelOut = cell(nFolds,1);
    
    for n=1:nFolds
        disp([' -- Fold ' num2str(n)]);
        inFold = in;
        inFold.reachEpochs = in.reachEpochs(C.training(n),:);
        foldModel = fitPhasicAndFB_6(inFold);
        out = applyPhasicAndFB(inFold, foldModel);
        popModelOut{n} = out.popResponse; 
    end
    
    %%
    in.kin.posErrForFit = in.kin.posErrForFit / workspaceSize;
    in.kin.targDist = in.kin.targDist / workspaceSize;

    popIdx = {[1 2 3 4],[1 2 3],[1 2]};
    inputNames = {'4comp_4','4comp_3','4comp_2','rawFeatures'};
    for inputType = 1:4
        for n=1:nFolds
            
            trainIdx = find(C.training(n));
            testIdx = find(C.test(n));

            innerTrainIdx = trainIdx(1:(4*floor(length(trainIdx)/5)));
            innerTestIdx = setdiff(trainIdx, innerTrainIdx);

            if inputType<=3
                inputFeatures = popModelOut{n}(:,popIdx{inputType});
            else
                inputFeatures = in.features;
            end
                        
            [inputs, targets, globalIdx] = formatInput(in.reachEpochs, innerTrainIdx, nBinsPerChunk, inputFeatures, in.kin.posErrForFit, 1:size(inputFeatures,2));
            [inputsVal, targetsVal, globalIdxVal] = formatInput(in.reachEpochs, innerTestIdx, nBinsPerChunk, inputFeatures, in.kin.posErrForFit, 1:size(inputFeatures,2));
            [inputsFinal, targetsFinal, globalIdxFinal] = formatInput(in.reachEpochs, testIdx, nBinsPerChunk, inputFeatures, in.kin.posErrForFit, 1:size(inputFeatures,2));

            errMask = zeros(size(inputs,1), size(inputs,2));
            errMask(:,101:end) = 1;
            
            errMaskVal = zeros(size(inputsVal,1), size(inputsVal,2));
            errMaskVal(:,101:end) = 1;
            
            errMaskFinal = zeros(size(inputsFinal,1), size(inputsFinal,2));
            errMaskFinal(:,101:end) = 1;
            
            saveDir = [dataDir filesep inputNames{inputType} filesep 'Fold' num2str(n)];
            mkdir(saveDir);
            save([saveDir filesep datasetName '.mat'],'inputs','targets','inputsVal','targetsVal','inputsFinal','targetsFinal',...
                'globalIdx','globalIdxVal','globalIdxFinal','errMask','errMaskVal','errMaskFinal');
        end
    end
    
    funOut.C = C;
    funOut.in = in;
    funOut.popIdx = popIdx;
    funOut.inputNames = inputNames;
end

function [input, target, globalIdx] = formatInput(reachEpochs, trlIdx, nBinsPerChunk, popResponse, posErr, popIdx)
    input = zeros(length(trlIdx),nBinsPerChunk,length(popIdx));
    target = zeros(length(trlIdx),nBinsPerChunk,2);
    globalIdx = [];
    for t=1:length(trlIdx)
        loopIdx = reachEpochs(trlIdx(t),1):reachEpochs(trlIdx(t),2);
        allIdx = (reachEpochs(trlIdx(t),1)-nBinsPerChunk+length(loopIdx)):reachEpochs(trlIdx(t),2);
        input(t,:,:) = popResponse(allIdx,popIdx);
        target(t,:,:) = posErr(allIdx,:);

        globalIdx = [globalIdx; loopIdx'];
    end
    
    input = single(input);
    target = single(target);
end