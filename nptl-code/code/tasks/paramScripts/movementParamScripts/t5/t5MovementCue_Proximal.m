%% movement cue parameters file
% this file sets the order of movement presentation and random delay
% periods.
%
% This particular script is used for the proximal (elbow/shoulder)-related set of the cued
% movement task.

% number of total repetitions
repsPerBlock = 5;

% delay period randomization params
expRandMu = 2000;
expRandMin = 2300;
expRandMax = 2600;
expRandBinSize = 100;

whichMovementsTmp = uint8([...
    movementTypes.ELBOWFLEX, ...
    movementTypes.SHOULDER_INTERNAL_ROT, ...
    movementTypes.SHOULDER_EXTERNAL_ROT, ...
    movementTypes.SHOULDABDUCT, ...
]);

whichMovements = zeros([1 50],'uint8');
whichMovements(1:numel(whichMovementsTmp))=whichMovementsTmp;

% how many movement sets in one shuffled order
cyclesPerRandomBlock= uint16(1);
movementInds = whichMovements(whichMovements>0);
numMovements = numel(movementInds);

% the model params will be assigned to these variables
movementOrder = zeros([1 movementConstants.MAX_CUED_MOVEMENTS+0],'uint8');
delayOrder = zeros([1 movementConstants.MAX_CUED_MOVEMENTS+0],'uint16');

if mod(double(repsPerBlock), double(cyclesPerRandomBlock)) ~= 0
    error('need to run an even number of cycles');
end

% randomly seed the random number generator
rng('shuffle');

%% calculate the movement presentation order
for nrep = 1:(double(repsPerBlock) / double(cyclesPerRandomBlock))
    movementsPerRandSet = (double(numMovements) * double(cyclesPerRandomBlock));
    offset = (nrep-1)*movementsPerRandSet;
    thisBlockMovementInds = uint8(mod(randperm(movementsPerRandSet)-1, double(numMovements))+1);
    movementOrder(offset+(1:movementsPerRandSet)) = movementInds(thisBlockMovementInds);
end

%% calculate the random relays
for nn = 1:numel(delayOrder)
    thisTrialDelay = uint16(0);
    while double(thisTrialDelay) < expRandMin || double(thisTrialDelay) > expRandMax
        thisTrialDelay = uint16(expRandMu * -log(rand([1 1])));
    end
    thisTrialDelay = uint16(round(double(thisTrialDelay) / double(expRandBinSize))*expRandBinSize);
    delayOrder(nn) = thisTrialDelay;
end


%setModelParam('delayPeriodDuration', 2000)
setModelParam('movementDuration', 2000);
setModelParam('holdDuration', 1500);
setModelParam('returnDuration', 4000);
setModelParam('restDuration', 2000);
setModelParam('repsPerBlock', repsPerBlock);
setModelParam('whichMovements', whichMovements);
setModelParam('movementOrder', movementOrder);
setModelParam('delayOrder', delayOrder);
setModelParam('playSpokenCues', false);

%%
unpauseOnAny();