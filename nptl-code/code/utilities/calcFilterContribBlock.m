function contrib = calcFilterContribBlock(R, filter, bW)
% contrib = calcFilterContribBlock(R, filter)
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

binNeural = bin([R.spikeRaster], bW, 'sum');

mnNeural = bsxfun(@times, bsxfun(@minus, binNeural, initialMeans(1:192)), invSoftNorms(1:192)); % mean subtracted normalized neural

% extract contribution per channel from steady state

decoderContrib = sqrt( sum( K(3:4, 1:192).^2) )';

contrib = bsxfun(@times, abs(mnNeural), decoderContrib);

numBins = size(contrib, 2);
for i = 1 : numBins

	contrib(:, i) = contrib(:, i) / sum(contrib(:, i));
end

end
