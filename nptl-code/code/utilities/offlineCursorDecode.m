function x = offlineCursorDecode(R, model, bw)

A = model.A;
C = model.C;
K = model.K;

if isfield(model, 'initialMeans')
	initialMeans = model.initialMeans;
end
    

% hack, only works for T7
R = addRSpikeRasterT7(R);
global modelConstants
if ~strcmp(modelConstants.rig,'t7')
    warning('offlineCursorDecode:16 - this should only run with T7?');
end

binNeural = bin([R.spikeRaster], bw, 'sum');

if isfield(model,'invSoftNormVals')
    invSoftNorms = model.invSoftNormVals;
else
    invSoftNorms = ones([size(binNeural,1) 1]);
end

%if exist('initialMeans', 'var')
%	neural = bsxfun(@times, bsxfun(@minus, binNeural, initialMeans(1:192)), invSoftNorms(1:192));
%else
	neural = bsxfun(@times, binNeural, invSoftNorms(1:192));
%end

numBins = size(neural, 2);

x = zeros(5, numBins);

% main decode loop
for i = 2 : numBins

	x(3:4, i) = A(3:4, 3:4) * x(3:4, i - 1);

	x(:, i) = x(:, i) + K(:, 1:192) * (neural(:, i) - C(1:192, :)*x(:, i));

end
