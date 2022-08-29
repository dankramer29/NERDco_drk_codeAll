%% movement cue parameters file
% this file sets the order of movement presentation and random delay
% periods

% delay period randomization params
expRandMu = 2000;
expRandMin = 1900;
expRandMax = 2500;
expRandBinSize = 100;

whichMovements = uint8([0 1 1 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 ]);

% how many movement sets in one shuffled order
cyclesPerRandomBlock= uint16(2);
movementInds = find(whichMovements);
numMovements = numel(movementInds);
% number of total repetitions
repsPerBlock = 10;

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
setModelParam('movementDuration', 1500);
setModelParam('holdDuration', 1500);
setModelParam('returnDuration', 1500);
setModelParam('restDuration', 1500);
setModelParam('repsPerBlock', repsPerBlock);
setModelParam('whichMovements', whichMovements);
setModelParam('movementOrder', movementOrder);
setModelParam('delayOrder', delayOrder);
