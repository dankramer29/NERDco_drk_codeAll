function contrib = calcFilterContriErrorbBlock(R, filter, bW)
% contrib = calcFilterContribErrorBlock(R, filter)
%
%

% bW = filter.options.binSize;

invSoftNorms = filter.model.invSoftNormVals;
K = filter.model.K;
if isfield(filter.model, 'meansTrackingInitial')
	initialMeans = filter.model.meansTrackingInitial;
else
	initialMeans = zeros(192, 1);
end

% loop through R
b = 1;
numTrials = numel(R);
nC = size(R(1).spikeRaster, 1);
for i = 1 : numTrials

	targetPos = R(i).posTarget;

	cursorPosStart = bin(R(i).cursorPosition, bW, 'first');
	toTarget = bsxfun(@minus, targetPos, cursorPosStart);

	binNeural = bin(R(i).spikeRaster, bW, 'sum');
	mnNeural = bsxfun(@times, bsxfun(@minus, binNeural, initialMeans(1:192)), invSoftNorms(1:192)); % mean subtracted normalized neural

	numBins = size(binNeural, 2);
	for j = 1 : numBins

		curTarget = toTarget(:, j);
		curTarget = curTarget ./ norm(curTarget);

		for k = 1 : nC

			channelPush = mnNeural(k, j) .* K(3:4, k);
			inDir = dot(channelPush, curTarget);
			outDir = dot(channelPush, [-curTarget(2) curTarget(1)]);
			contrib(k, b) = abs(outDir) - inDir;

		end

		b = b + 1;

	end

end
