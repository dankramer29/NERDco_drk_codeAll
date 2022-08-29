%% movement cue parameters file
% number of total repetitions
repsPerBlock = 4;

% delay period randomization params about 3min per 1repPerBlock
expRandMu = 2500;
expRandMin = 2000;
expRandMax = 3000;
expRandBinSize = 20;

whichMovementsTmp = uint16([...
    movementTypes.LETTER_CAT, ...
    movementTypes.LETTER_BAT, ...
    movementTypes.LETTER_TOM, ...
    movementTypes.LETTER_MAT, ...
    ]);

whichMovements = zeros([1 200],'uint16');
whichMovements(1:numel(whichMovementsTmp))=whichMovementsTmp;

% how many movement sets in one shuffled order
cyclesPerRandomBlock= uint16(1);
movementInds = whichMovements(whichMovements>0);
numMovements = numel(movementInds);

% the model params will be assigned to these variables
movementOrder = zeros([1 movementConstants.MAX_CUED_MOVEMENTS+0],'uint16');
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
    thisBlockMovementInds = uint16(mod(randperm(movementsPerRandSet)-1, double(numMovements))+1);
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

setModelParam('movementDuration', 3000);
setModelParam('holdDuration', 0);
setModelParam('returnDuration', 0);
setModelParam('restDuration', 0);
setModelParam('repsPerBlock', repsPerBlock);
setModelParam('whichMovements', whichMovements);
setModelParam('movementOrder', movementOrder);
setModelParam('delayOrder', delayOrder);
setModelParam('playSpokenCues', false);

%%
unpauseOnAny();