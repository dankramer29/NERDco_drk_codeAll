function [ modelOut ] = fitPiecewiseModel( opts )
    
    rIdx = expandEpochIdx(opts.reachEpochsToFit);
    opts.offsetConvention = 1;
    
    %concatenate velocity and position together as a state vector
    posIdx = 1:size(opts.pos,2);
    velIdx = (size(opts.pos,2)+1):(2*size(opts.pos,2));
    effectorStates = [opts.pos, opts.vel];

    %start by using purely delayed states as an initial guess for the internal model estimates
    delayedStates = [zeros(opts.feedbackDelaySteps+opts.offsetConvention,size(effectorStates,2)); effectorStates(1:(end-opts.feedbackDelaySteps),:)];
    internalStates = delayedStates;
    
    %iteratively fit control strategy model and update internal model
    %estimates
    nIterations = 4;

    for n=1:nIterations
        %fit piecewise model
        [model, predVals] = fitPW( opts.decoded_u(rIdx,:), internalStates(rIdx,posIdx), internalStates(rIdx,velIdx), opts.targPos(rIdx,:), opts.modelOpts);
           
        %update internal model estimates
        cVecPredicted = zeros(size(opts.decoded_u));
        cVecPredicted(rIdx,:) = predVals;
        internalStates = getInternalModelState(effectorStates, opts.feedbackDelaySteps, opts.filtAlpha, opts.filtBeta, opts.timeStep, ...
            cVecPredicted, opts.offsetConvention );
    end
    
    maxLags = ceil(0.400 / opts.timeStep);
    arModel = fitARNoiseModel( opts.decoded_u - cVecPredicted, opts.reachEpochsToFit, maxLags );
    modelOut.noiseModel = arModel;
    modelOut.controlModel = model;
    modelOut.internalModelEstimates = internalStates;
    modelOut.modeledControlVector = cVecPredicted;
    
    %make struct for simulating movements with this model
    simOpts = makeBciSimOptions( );
    simOpts.loopTime = opts.timeStep;
    simOpts.plant.alpha = opts.filtAlpha;
    simOpts.plant.beta = opts.filtBeta;
    simOpts.plant.nDim = size(opts.decoded_u,2);
    simOpts.forwardModel.delaySteps = opts.feedbackDelaySteps;
    simOpts.forwardModel.forwardSteps = opts.feedbackDelaySteps;
    simOpts.control.fTargX = modelOut.controlModel.fTargX;
    simOpts.control.fTargY = modelOut.controlModel.fTargY;
    simOpts.control.fVelX = modelOut.controlModel.fVelX;
    simOpts.control.fVelY = modelOut.controlModel.fVelY;
    simOpts.control.rtSteps = opts.feedbackDelaySteps;
    simOpts.noiseMatrix = generateNoiseFromModel( 100000, modelOut.noiseModel );
    modelOut.simOpts = simOpts;
end

function [ idx ] = expandEpochIdx( epochs )
    idx = [];
    for e=1:size(epochs,1)
        idx = [idx, epochs(e,1):epochs(e,2)];
    end
end
