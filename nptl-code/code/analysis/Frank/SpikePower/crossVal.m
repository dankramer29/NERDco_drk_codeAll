function [ perf, decoder, predVals, respVals, allTestIdx] = crossVal( predictors, response, trainFun, testFun, decoderFun, nFolds, decoderWeights)
    %An abstracted cross validation routing that can work for any decoder
    %and any evaluation function

    %predictors is a matrix specifying the features for the training data

    %response is a matrix specifying the variables to be decoded

    %trainFun is a function taking predictors and response as input, and
    %returing a decoder variable as output

    %decoderFun is a function taking a decoder variable and predictors as
    %input, and returning the predictions as output

    %testFun is a function taking the predictions and response as input,
    %and returning some measure of decoding accuracy as output

    %nFolds specifies how many folds of cross-validation to use (10 is a
    %common value)

    %decoderWeights is a vector of real values with a value for each
    %observation, it can be used to specify weights for a weighted
    %regression; if decoderWeights is given as an input, it will be passed
    %to trainFun as the third argument

    %we ignore the remainder observations if the number of observations in the training set
    %is not divisible by nFolds

    nObs = size(predictors,1);
    obsPerBlock = floor(nObs/nFolds);
    lastObs = obsPerBlock * nFolds;
    testIdx = 1:obsPerBlock;
    perf = cell(nFolds,1);
    decoder = cell(nFolds,1);
    predVals = zeros(nObs,size(response,2));
    respVals = predVals;  % Added by ABA on 02/09/2014 to return responses as part of the output

    if nargin<7
        decoderWeights = [];
    end

    allTestIdx = [];
    for b=1:nFolds
        disp(['Fold ' num2str(b) ' of ' num2str(nFolds)]);
        allTestIdx = [allTestIdx; [testIdx', repmat(b,length(testIdx),1)]];

        %train decoder
        trainIdx = setdiff(1:lastObs, testIdx);

        if isempty(decoderWeights)
            decoder{b} = trainFun(predictors(trainIdx,:), response(trainIdx,:));
        else
            decoder{b} = trainFun(predictors(trainIdx,:), response(trainIdx,:), decoderWeights(trainIdx));
        end

        %test decoder and store performance results
        predictions = decoderFun(decoder{b}, predictors(testIdx,:));
        predVals(testIdx,:) = predictions;
        respVals(testIdx,:) = response(testIdx,:); 

        perf{b} = testFun(predictions, response(testIdx,:));

        %go to the next block
        testIdx = testIdx + obsPerBlock;
    end
end

