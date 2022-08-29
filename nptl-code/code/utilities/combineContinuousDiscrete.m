function model = combineContinuousDiscrete(continuousmodel, discretemodel)
% COMBINECONTINUOUSDISCRETE    
% 
% model = combineContinuousDiscrete(continuousmodel, discretemodel)
%
    
    model = continuousmodel;
    model.discrete = discretemodel;
