function [ model ] = scaleKalmanBinsize( model, binSizeOut, neuralBinIn, stateBinIn )

if ~exist('stateBinIn', 'var')
    stateBinIn = neuralBinIn;
end

if mod(neuralBinIn,binSizeOut) ~= 0
    error(sprintf('cant scale %g neural model down to %g',neuralBinIn,binSizeOut));
end

if mod(stateBinIn,binSizeOut) ~= 0
    error(sprintf('cant scale %g state model down to %g',stateBinIn,binSizeOut));
end


Atmp = model.A;
Atmp(1:2, 3:4) = Atmp(1:2, 3:4)/(stateBinIn/binSizeOut);
Atmp(3:4, 3:4) = Atmp(3:4, 3:4)^(1/(stateBinIn/binSizeOut));
model.A = Atmp;

model.W = model.W/(stateBinIn/binSizeOut);

model.Q = model.Q/(neuralBinIn/binSizeOut);
model.C = model.C/(neuralBinIn/binSizeOut);

%% recalculate steady state gain
model = calcSteadyStateKalmanGain(model);