function T = binTrial(inputStruct, opts)
%
% T = binTrial(inputStruct)
%
% inputStruct contains:
%	R - single struct only
%	modelInput
%	prevR (optional)
%
% returns the binned T struct for a particular single trial (R)

% input error checking

opts.foo = false;
if ~isfield(opts, 'displayOn')
    opts.displayOn = true;
end

localizeFields(inputStruct);
checkForVars({'R' 'modelInput'});

if isempty(R)
	error('decode:processBin:binTrial', 'ERROR: no trial found in R struct');
end

if numel(R) > 1
	error('decode:processBin:binTrial', 'multiple trials found in input R');
end

if isempty(modelInput)
	error('decode:processBin:binTrial', 'ERROR: no modelinput parameters passed');
end

localizeFields(modelInput);
checkForVars({'dt'});

localizeFields(R);
checkForVars({'trialLength' 'cursorPosition' 'spikeRaster'});

if size(cursorPosition, 1) <3
    cursorPosition(3,:) = 0;
end


if exist('prevR', 'var')
	prevRData = true;
else
	prevRData = false;
end

%{
if ~exist('neuralDT', 'var')
	neuralDT = dt;
end
%}


%%%%%%%%%
% raw processing (ms level)
%%%

% build raw neural matrix (ms resolution)
if exist('spikeRaster2', 'var') && any(any(spikeRaster2))
	twoArrays = true;
else
	twoArrays = false;
end

if twoArrays
	neuralMS = vertcat(full(spikeRaster), full(spikeRaster2));
else
	neuralMS = full(spikeRaster);
end

% Squeeze out channels that have no spikes
neuralMS(chanNull,:) = [];

% option to add ones to a potentially sparse matrix
% neuralMS = neuralMS + 1;

% smooth & build kinematic space (ms resolution)
if opts.displayOn, fprintf('s.'); end
if prevRData
	smoothCursorPosMS = smoothCursor( struct( 'cursorPos', cursorPosition, 'prevCursorPos', prevR.cursorPos, 'updateRate', findCursorUpdateRate(R)) );
else
	smoothCursorPosMS = smoothCursor( struct( 'cursorPos', cursorPosition, 'updateRate', findCursorUpdateRate(R)) );
end
if opts.displayOn, fprintf('.  '); end

% gaussian smooth the neural data
if exist('neuralGaussian', 'var')

if opts.displayOn, 	fprintf('g.'); end

	if prevRData
		if twoArrays
			prevNeuralMS = vertcat(full(prevR.spikeRaster), full(prevR.spikeRaster2));
		else
			prevNeuralMS = full(prevR.spikeRaster);
		end
	end
	
	numChannels = size(neuralMS, 1);
	gFilter = genGaussKernel(neuralGaussian);
	if prevRData
		for i = 1 : numChannels
			neuralOut(i, :) = filter(gFilter, 1, [prevNeuralMS(i, :) neuralMS(i,:)] );
		end
		neuralMS = neuralOut(:, size(prevNeuralMS, 2) + 1 : end);
	else
		for i = 1 : numChannels
			neuralMS(i, :) = filter(gFilter, 1, neuralMS(i, :));
		end
	end

if opts.displayOn, 	fprintf('.  '); end

end

%%%
% end raw processing (ms level)
%%%%%%%%%


%%%%%%%%%
% binning
%%%

if opts.displayOn, fprintf('b.'); end

if exist('reachStartTime', 'var')
	timeStartStr = regexprep(reachStartTime, 'ttO', 'timeTargetOn');
	timeStart = eval( timeStartStr );
else
	timeStart = timeTargetOn;
end

if exist('reachEndTime', 'var')
	timeEndStr = regexprep(reachEndTime, 'tFA|timeFirstAcquire', 'timeFirstTargetAcquire');
	timeEndStr = regexprep(timeEndStr, 'tLA|timeLastAcquire', 'timeLastTargetAcquire');
	timeEndStr = regexprep(timeEndStr, 'end', 'size(cursorPos, 2)');

	timeEnd = eval( timeEndStr );
else
	timeEnd = timeTargetOn + trialLength;
end

%{
if dt < neuralDT
	timeStart = timeStart + neuralDT - dt;
else
	neuralDT = dt;
end
%}

% build non-overlapping bins
numBins = floor( (timeEnd - timeStart) / dt);
if numBins < 0
    numBins = 0;
end


for i = 1 : numBins

    binStart = timeStart + (i-1) * dt;
    binEnd   = binStart + dt - 1;
    %	neuralBinStart = binEnd - neuralDT + 1;
    smoothCursorPosBin(:, i) = smoothCursorPosMS(:, binEnd);
    smoothCursorVelBin(:, i) = (smoothCursorPosMS(:, binEnd) - smoothCursorPosMS(:, binStart)) / dt;
    neuralBin(:, i) = sum(neuralMS(:, binStart : binEnd ), 2);
    %	neuralBin(:, i) = sum(neuralMS(:, neuralBinStart : binEnd ), 2);

    %{  old implementation
    smoothCursorPosBin(:, i) = smoothCursorPosMS(:, timeStart + i * dt - 1);
    smoothCursorVelBin(:, i) = (smoothCursorPosMS(:, timeStart + i * dt - 1) - smoothCursorPosMS(:, timeStart + (i-1) * dt))/dt;
    neuralBin(:, i) = sum(neuralMS(:, timeStart + (i - 1)*dt : timeStart + i * dt - 1), 2);
    %}

end

if opts.displayOn, fprintf('.  '); end


% cursorGoal correction (2D)
if exist('cursorGoal', 'var')

    if opts.displayOn, 	fprintf('cg.'); end

    targetPos = startTrialParams.posTarget;
    for i = 1 : numBins

        % find direction to target for given bin
        targetDir = targetPos(1:2) - smoothCursorPosBin(1:2, i);
        targetDirN = targetDir ./ norm(targetDir);

        % find velocity magnitude of current bin
        binSpeed = norm(smoothCursorVelBin((1:2), i));
        % project assumed intended direction onto speed 
        rotatedVel = binSpeed * targetDirN;

        smoothCursorVelBin(1:2, i) = rotatedVel;

    end

    if opts.displayOn, 	fprintf('.  '); end


end


% zero correction
if exist('zeroCorrection', 'var')

    if opts.displayOn, 	fprintf('z.'); end

    %{
    if dt < neuralDT
        zeroTimeStart = timeLastTargetAcquire + neuralDT - dt;
    else
        zeroTimeStart = timeLastTargetAcquire;
    end
    %}

    zeroTimeStart = timeLastTargetAcquire;
    additionalBins = floor( (timeTargetHeld - zeroTimeStart) / dt);
    targetPos = startTrialParams.posTarget;

    for i = 1 : additionalBins

        binStart = zeroTimeStart + (i-1) * dt;
        binEnd   = binStart + dt - 1;
        %		neuralBinStart = binEnd - neuralDT + 1;

        smoothCursorPosBin(:, numBins + i) = targetPos;	% hold target constant
        smoothCursorVelBin(:, numBins + i) = [0 0 0];
        neuralBin(:, numBins + i) = sum(neuralMS(:, binStart : binEnd), 2);
        %		neuralBin(:, numBins + i) = sum(neuralMS(:, neuralBinStart : binEnd), 2);
    end

    numBins = numBins + additionalBins;

    if opts.displayOn, 	fprintf('.  '); end
end

% take neural differences as input signal
if exist('neuralDiff', 'var')

    if opts.displayOn, 	fprintf('nd.'); end

    neuralBin = diff(neuralBin')';
    smoothCursorPosBin = smoothCursorPosBin(:, 2:end);
    smoothCursorVelBin = smoothCursorVelBin(:, 2:end);

    if opts.displayOn, 	fprintf('.  '); end
end



% assign all variables to T
T = [];
T.modelInput = modelInput;
% T.neuralMS = neuralMS;	% too big
% T.smoothCursorPosMS = smoothCursorPosMS;	% also too big
T.smoothCursorPosBin = smoothCursorPosBin;
T.smoothCursorVelBin = smoothCursorVelBin;
T.neuralBin = neuralBin;
T.trialNum = trialNum;
T.R = R;
