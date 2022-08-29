function R = addSpikeRaster(R, thresholds)
%
% R = addSpikeRaster(R, thresholds)
%
% thresholds is an Nx1 that represents each channel's threshold level

	% LOCKOUT NOT USED
	% LOCKOUT = 1; % how many ms after a given spike to not allow a subsequent spike

	rawSpikeBand = [R.minAcausSpikeBand]; % some NxT array, N is number of channels, T is time in ms

	numChannels = size(rawSpikeBand, 1);

	if numel(thresholds) ~= numChannels
		error('addSpikeRaster:invalidThresholds', 'Incorrect size for thresholds vector');
	end

	spikeThresholds = bsxfun(@lt, rawSpikeBand, thresholds);

	%[numChannels, totalTime] = size(spikeThresholds);

	%
	% this code for enforcing the lockout is not used
	%for i = 1 : numChannels
	%
	%	possibleSpikeI = find( spikeThresholds(i, :) ); 
	%	for j = 1 : numel(possibleSpikeI)
	%
	%		if possibleSpikeI(j) + LOCKOUT > totalTime % index bounding
	%			stopPos = totalTime;
	%		else
	%			stopPos = LOCKOUT;
	%		end
	%
	%		if any( spikeThresholds(i, possibleSpikeI(j) + [1 : stopPos]) )
	%			spikeThresholds(i, possibleSpikeI(j) + [1 : stopPos]) = 0;
	%		end
	%
	%	end
	%end

	R = addRFieldMS(R, 'spikeRaster', spikeThresholds);

end
