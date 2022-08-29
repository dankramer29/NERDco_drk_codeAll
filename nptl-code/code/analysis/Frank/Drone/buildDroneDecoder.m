%%
%load data & bin
stream = parseDataDirectoryBlock('/Users/frankwillett/Downloads/100/', 100);

targetPos = stream.continuous.robotPosition(:,1:4);
dronePos = stream.continuous.robotPosition(:,7:10);

rms = channelRMS(stream.neural);
thresh = -3.5*rms;

minSpikeBand = squeeze(stream.neural.minAcausSpikeBand(:,1,:));
minSpikeBand = minSpikeBand(stream.continuous.clock(1):end,:);
spikeRaster = bsxfun(@lt, minSpikeBand, thresh);

binSize = 15;
binTargetPos = binTimeSeries( targetPos, binSize, @median );
binDronePos = binTimeSeries( dronePos, binSize, @mean );
binSpikeRaster = binTimeSeries( spikeRaster, binSize, @sum );

%%
%ignore the first bins of each trial
targChangeIdx = find(any(diff(binTargetPos)~=0,2));
rtTime = 500;
rtSteps = round(rtTime/binSize);

rtIdx = [];
for t=1:length(targChangeIdx)
    rtIdx = [rtIdx, targChangeIdx(t):(targChangeIdx(t)+rtSteps)];
end

binTargetPos(rtIdx,:) = [];
binDronePos(rtIdx,:) = [];
binSpikeRaster(rtIdx,:) = [];

%%
%make a linear decoder
cVector = binTargetPos - binDronePos;

encodingMatrix = [ones(size(cVector,1),1), cVector]\binSpikeRaster;
encodingNoise = [ones(size(cVector,1),1), cVector]*encodingMatrix - binSpikeRaster;
encodingNoiseCov = cov(encodingNoise);

neuralMeans = encodingMatrix(1,:);
encodingMatrix = encodingMatrix(2:end,:);

filts = (encodingMatrix/encodingNoiseCov*encodingMatrix')\(encodingMatrix/encodingNoiseCov);
filts = filts';
        
%%
%normalize the gain based on far-target outputs
decVectors = (binSpikeRaster - neuralMeans)*filts;

targDist = sqrt(sum(cVector.^2,2));
unitErr = bsxfun(@times, cVector, 1./targDist);
projDec = sum(unitErr.*decVectors,2);

farDistInterval = [0.8, 10];
farIdx = (targDist > farDistInterval(1)) & (targDist < farDistInterval(2));
normFactor = 1/mean(projDec(farIdx));

filts = filts * normFactor;

%%
%put into decoder params
decoderParams.linFiltDecoder = zeros(384, 20);
decoderParams.linFiltDecoder(1:192, 2:2:8) = filt;
decoderParams.linFiltAlpha = 0.96;
decoderParams.linFiltNeuralMeans = zeros(384,1);
decoderParams.linFiltNeuralMeans(1:192) = neuralMeans;

%%
%the decoder will operate as follows
prev_xk = zeros(20,1);
centeredSpikes = [binSpikeRaster(1,:), zeros(1,192)] - decoderParams.linFiltNeuralMeans';
newDecode = centeredSpikes * decoderParams.linFiltDecoder;
new_xk = decoderParams.linFiltAlpha*prev_xk + (1-decoderParams.linFiltAlpha)*newDecode';
