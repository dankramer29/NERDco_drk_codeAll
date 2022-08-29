function [ model ] = createPositionVectorField( model, multiplier )


model.C(:,1:2) = model.C(:,3:4)*multiplier;

model = calcSteadyStateKalmanGain(model);