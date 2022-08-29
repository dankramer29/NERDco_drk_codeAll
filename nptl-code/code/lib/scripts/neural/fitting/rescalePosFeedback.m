function modelOut= rescalePosFeedback(modelIn, scaleFactor)

modelOut = modelIn;
modelOut.C(:,1:2) = modelOut.C(:,1:2)*scaleFactor;

modelOut = calcSteadyStateKalmanGain(modelOut);