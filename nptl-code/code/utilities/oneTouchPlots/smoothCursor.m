function cursorPosSmooth = smoothCursor(input)
% cursorPosSmooth = smoothCursor(input)
%
%	input is a struct
%		cursorPos
%		updateRate
%		prevCursorPos (optional)
%		filterWidthMult (optional) (multiple of update rate)
%
% returns the smoothed cursor trace

	localizeFields(input);
	checkForVars({'cursorPos' 'updateRate'});

	blinkOutValue = [70 1278.5 -219]; % this is the value set by system when marker is not seen

	if exist('prevCursorPos', 'var')
		prevCursor = true;
	else
		prevCursor = false;
	end

	if prevCursor
		startOfCurData = size(prevCursorPos, 2) + 1;
		cursorPos = [prevCursorPos cursorPos];
	end

	if ~exist('filterWidthMult', 'var')
		filterWidthMult = 3;	% default filter width 3 times update rate
	end

	numPoints = size(cursorPos, 2);

	% find all times of blinkOuts (ms)
	blinkOutTimes = find(cursorPos(2,:) > 1000 );
	numBlinkOuts = numel(blinkOutTimes);

	if numBlinkOuts 

		i = 1; % first found blink out time
		if blinkOutTimes(1) == 1 % handle case of starting with blinkOut
			cursorPos(:, i) = [0 0 0]; % HACK: initialize to center
			i = 2;
		end

		j = 0;

		while i < numBlinkOuts && j ~= numBlinkOuts

			startTime = blinkOutTimes(i) - 1;

			for j = i + 1 : numBlinkOuts

				nextContigTime = blinkOutTimes(j - 1) + 1;
				if nextContigTime ~= blinkOutTimes(j)
					stopTime = nextContigTime;
					i = j; % set i to the start of the next blinkOut block
					break; % contiguous block found, break out of j loop
				elseif j == numBlinkOuts
					stopTime = blinkOutTimes(j) + 1;
					break;
				end

			end

			if blinkOutTimes(i) == 1 % blink out at beginning
				% back-propgate zero-order hold of first known good position
				cursorPos(:, 1 : stopTime) = repmat(cursorPos(:, stopTime), 1, stopTime);

			elseif blinkOutTimes(j) == numPoints % blink out at end
				% zero-order hold last known good position
				cursorPos(:, startTime : end) = repmat(cursorPos(:, startTime), 1, numPoints - startTime + 1);
	
			else	% blinkOut in middle of trial
				% interpolate over last good position before and first good position after blinkOut
				cursorPos(1, startTime : stopTime) = linspace(cursorPos(1, startTime), cursorPos(1, stopTime), stopTime - startTime + 1);
				cursorPos(2, startTime : stopTime) = linspace(cursorPos(2, startTime), cursorPos(2, stopTime), stopTime - startTime + 1);
				cursorPos(3, startTime : stopTime) = linspace(cursorPos(3, startTime), cursorPos(3, stopTime), stopTime - startTime + 1);
			end

		end % end while loop

	end


	filterWidth = (floor(updateRate) + 1)*filterWidthMult;
	filterWin = ones(filterWidth, 1)/filterWidth;
	filterHalf = floor(filterWidth/2);
	% smooth
	cursorPosSmoothX = smooth(cursorPos(1,:), filterWidth, 'loess');
	cursorPosSmoothY = smooth(cursorPos(2,:), filterWidth, 'loess');
	cursorPosSmoothZ = smooth(cursorPos(3,:), filterWidth, 'loess');
	
%{	
	% offset to align to leading edge
	cursorPosSmoothX(1 : end - filterHalf) = cursorPosSmoothX(filterHalf + 1 : end);
	cursorPosSmoothX(end - filterHalf + 1 : end) = repmat(cursorPosSmoothX(end - filterHalf), 1, filterHalf);
	cursorPosSmoothY(1 : end - filterHalf) = cursorPosSmoothY(filterHalf + 1 : end);
	cursorPosSmoothY(end - filterHalf + 1 : end) = repmat(cursorPosSmoothY(end - filterHalf), 1, filterHalf);
	cursorPosSmoothZ(1 : end - filterHalf) = cursorPosSmoothZ(filterHalf + 1 : end);
	cursorPosSmoothZ(end - filterHalf + 1 : end) = repmat(cursorPosSmoothZ(end - filterHalf), 1, filterHalf);
%}
	
	
	% assign
	cursorPosSmooth = zeros(3, numel(cursorPosSmoothX));
	cursorPosSmooth(1,:) = cursorPosSmoothX;
	cursorPosSmooth(2,:) = cursorPosSmoothY;
	cursorPosSmooth(3,:) = cursorPosSmoothZ;

	% truncate previous data
	if prevCursor
		cursorPosSmooth = cursorPosSmooth(:, floor(startOfCurData - filterWidth/10) : floor(end - filterWidth/10));
	end
	

end
