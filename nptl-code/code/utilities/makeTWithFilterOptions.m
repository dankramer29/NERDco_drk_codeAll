function [T, thresholds, Toptions] = makeTWithFilterOptions(R,filter,kinematicVar)
% MAKETWITHFILTEROPTIONS    
% 
% [T, thresholds] = makeTWithFilterOptions(R,filter,kinematicVar)


options = filter.options;
Toptions.useAcaus = options.useAcaus;
if isfield(Toptions,'useSqrt')
    Toptions.useSqrt = options.useSqrt;
else
    Toptions.useSqrt = false;
end
Toptions.tSkip = options.tSkip;
Toptions.useDwell = options.useDwell;
Toptions.delayMotor = options.delayMotor;
Toptions.dt = options.binSize;
Toptions.hLFPDivisor = options.hLFPDivisor;
Toptions.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth;
%Toptions.kinematicVar = options.kinematics;
%Toptions.neuralOnsetAlignment = options.neuralOnsetAlignment;
%Toptions.isThresh = options.useFixedThresholds;
%Toptions.excludeLiftoffs = true;
if ~exist('kinematicVar','var')
    Toptions.kinematicVar = 'mouse';
else
    Toptions.kinematicVar = kinematicVar;
end

Toptions.neuralOnsetAlignment = false;
Toptions.isThresh = true;
Toptions.excludeLiftoffs = false;

Toptions.rmsMultOrThresh = filter.model.thresholds;
Toptions.eliminateFailures = false;

Toptions.normalizeRadialVelocities = options.normalizeRadialVelocities;

[T,thresholds] = onlineTfromR(R, Toptions);

