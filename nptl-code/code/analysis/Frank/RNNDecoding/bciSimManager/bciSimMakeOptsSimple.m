function [ opts ] = bciSimMakeOptsSimple( )
    opts.targSeqFile = '';
    opts.outputDir = '';
    
    opts.nCursorDim = 2;
    opts.nOutputFactors = 2;
    opts.nDecUnits = 50;
    opts.nControllerUnits = 50;
    opts.dt = 0.02;
    opts.batchSize = 32;
    opts.nSteps = 250;
    opts.nDelaySteps = 10;
    opts.learnRateStart = 0.01;
    opts.nTrainIterations = 10000;
    opts.doPlot = 0;
end

