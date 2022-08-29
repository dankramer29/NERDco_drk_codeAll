%% movement cue parameters file
% this file sets the order of movement presentation and random delay
% periods.

% number of total repetitions
repsPerBlock = 3;

% delay period randomization params
expRandMu = 3500;
expRandMin = 3000;
expRandMax = 4000;
expRandBinSize = 20;

whichMovementsTmp = uint8([...
    movementTypes.BI_LEFT_NO, ...
    movementTypes.BI_RIGHT_NO, ...
    movementTypes.BI_UP_NO, ...
    movementTypes.BI_DOWN_NO, ...
    movementTypes.BI_NO_LEFT, ...
    movementTypes.BI_NO_RIGHT, ...
    movementTypes.BI_NO_UP, ...
    movementTypes.BI_NO_DOWN, ...
    movementTypes.BI_LEFT_LEFT, ...
    movementTypes.BI_LEFT_RIGHT, ...
    movementTypes.BI_LEFT_UP, ...
    movementTypes.BI_LEFT_DOWN, ...
    movementTypes.BI_RIGHT_LEFT, ...
    movementTypes.BI_RIGHT_RIGHT, ...
    movementTypes.BI_RIGHT_UP, ...
    movementTypes.BI_RIGHT_DOWN, ...
    movementTypes.BI_UP_LEFT, ...
    movementTypes.BI_UP_RIGHT, ...
    movementTypes.BI_UP_UP, ...
    movementTypes.BI_UP_DOWN, ...
    movementTypes.BI_DOWN_LEFT, ...
    movementTypes.BI_DOWN_RIGHT, ...
    movementTypes.BI_DOWN_UP, ...
    movementTypes.BI_DOWN_DOWN, ...
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
setModelParam('outputType', uint16(cursorConstants.OUTPUT_TYPE_CURSOR))  %PTB graphics

setModelParam('movementDuration', 1500);
setModelParam('holdDuration', 0);
setModelParam('returnDuration', 1500);
setModelParam('restDuration', 0);
setModelParam('repsPerBlock', repsPerBlock);
setModelParam('whichMovements', whichMovements);
setModelParam('movementOrder', movementOrder);
setModelParam('delayOrder', delayOrder);
setModelParam('playSpokenCues', false);
setModelParam('textOverlayID', uint16(3));

%%
unpauseOnAny();