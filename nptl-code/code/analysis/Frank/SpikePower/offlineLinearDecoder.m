dataDir = '/Users/frankwillett/Data/Derived/2dDatasets/';
files = dir([dataDir '*_features.mat']);
allPerf = zeros(length(files),13);

for f=1:length(files)
    disp(files(f).name);
    
    features = load([dataDir files(f).name]);
    features.sp = gaussSmooth_fast(features.sp, 3);
    for t=1:size(features.tx,3)
        features.tx(:,:,t) = gaussSmooth_fast(squeeze(features.tx(:,:,t)), 3);
    end
    
    dat = load([dataDir files(f).name(1:(end-13)) '.mat']);
    
    for b=1:length(dat.dataset.blockList)
        blockIdx = find(dat.dataset.blockNums==dat.dataset.blockList(b));
        features.sp(blockIdx,:) = bsxfun(@plus, features.sp(blockIdx,:), -mean(features.sp(blockIdx,:)));
        for t=1:size(features.tx,3)
            features.tx(blockIdx,:,t) = bsxfun(@plus, features.tx(blockIdx,:,t), -mean(squeeze(features.tx(blockIdx,:,t))));
        end
    end
    
    rIdx = expandEpochIdx([dat.dataset.trialEpochs(:,1)+8, dat.dataset.trialEpochs(:,2)]);
    rIdx(rIdx>length(dat.dataset.cursorPos))=[];
    nThresh = size(features.tx,3);
    nChan = size(features.tx,2);
    
    posErr = dat.dataset.targetPos - dat.dataset.cursorPos;
    
    decoderFun = @(decoder, predictors)(applyFODecoder(decoder, predictors));
    testFun = @(x,y)(corr(x,y));
    topN = 140;
    
    %TX only, single threshold
    for t=1:nThresh
        predictors = squeeze(features.tx(:,:,t));        
        trainFun = @(predictors,response)(buildFODecoder(predictors, response, false, nChan, 1, true, false, topN));

        [ perf, decoder, predVals ] = crossVal( predictors(rIdx,:), posErr(rIdx,:), ...
            trainFun, testFun, decoderFun, 10);
        allPerf(f,t) = mean(diag(corr(predVals, posErr(rIdx,:))));
    end
    
    %TX optimized
    predictors = zeros(length(dat.dataset.cursorPos),nChan*nThresh);
    chanIdx = 1:nThresh;
    for n=1:nChan
        predictors(:,chanIdx) = squeeze(features.tx(:,n,:));
        chanIdx = chanIdx + nThresh;
    end

    trainFun = @(predictors,response)(buildFODecoder(predictors, response, true, nChan, nThresh, true, false, topN));
    [ perf, decoder, predVals ] = crossVal( predictors(rIdx,:), posErr(rIdx,:), ...
        trainFun, testFun, decoderFun, 10);
    allPerf(f,6) = mean(diag(corr(predVals, posErr(rIdx,:))));
    
    %SP only
    predictors = features.sp;
    trainFun = @(predictors,response)(buildFODecoder(predictors, response, false, nChan, 1, false, true, topN));
    [ perf, decoder, predVals ] = crossVal( predictors(rIdx,:), posErr(rIdx,:), ...
        trainFun, testFun, decoderFun, 10);
    allPerf(f,7) = mean(diag(corr(predVals, posErr(rIdx,:))));
    
    %SP + TX only, single threshold
    for t=1:nThresh
        predictors = [squeeze(features.tx(:,:,t)), features.sp];
        trainFun = @(predictors,response)(buildFODecoder(predictors, response, false, nChan, 1, true, true, topN));
        [ perf, decoder, predVals ] = crossVal( predictors(rIdx,:), posErr(rIdx,:), ...
            trainFun, testFun, decoderFun, 10);
        allPerf(f,7+t) = mean(diag(corr(predVals, posErr(rIdx,:))));
    end
    
    %SP + TX optimized
    predictors = zeros(length(dat.dataset.cursorPos),nChan*nThresh);
    chanIdx = 1:nThresh;
    for n=1:nChan
        predictors(:,chanIdx) = squeeze(features.tx(:,n,:));
        chanIdx = chanIdx + nThresh;
    end
    predictors = [predictors, features.sp];

    trainFun = @(predictors,response)(buildFODecoder(predictors, response, true, nChan, nThresh, true, true, topN));
    [ perf, decoder, predVals ] = crossVal( predictors(rIdx,:), posErr(rIdx,:), ...
        trainFun, testFun, decoderFun, 10);
    allPerf(f,end) = mean(diag(corr(predVals, posErr(rIdx,:))));
end