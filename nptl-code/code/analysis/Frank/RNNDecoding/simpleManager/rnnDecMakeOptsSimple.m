function [ opts ] = rnnDecMakeOptsSimple( )
    %default options strcut for all rnn decoder options
    opts.datasets = {};
    opts.datasetDir = '';
    opts.outputDir = '';
    opts.loadDir = '';
    
    opts.nModelDatasets = 1;
    opts.nInputsPerModelDataset = 2;
    opts.preInitDatasetNum = 0;
    opts.datasetIdxForDecoding = 0;
    opts.mode = 'train';
    
    opts.batchSize = 32;
    opts.nTargetDim = 2;
    opts.nSteps = 510;
    opts.doPlot = 0;
    
    opts.nLayers = 1;
    opts.nDecInputFactors = 10;
    opts.L2Reg = 50;
    opts.rnnType = 'RNN'; %RNN, GRU, LSTM
    opts.learnRateStart = 0.01;
    opts.nEpochs = 2000;
    opts.initWeightScale = 1.0;
    opts.nDecUnits = 50;
    opts.useInputProj = 1; %0 or 1
    opts.keepProbIn = 1;
    opts.keepProbLayer = 1;
end

