xNeuralSim_Init;


modelStep = 0.0005;

ch=96;
sigLen = 15;
sampFreq = 30000;
spikeAmplitude = 400;

totalMatTime = 30; % seconds

t = []; lfp = []; lfpAmpScale = []; t_total = 0; scaleTolerance = [];

longSignal = zeros(ch,round(30*sampFreq));

for sampleSteps = 1:round(30/modelStep)
noise = int16(normrnd(0,noiseScaleFactor,[ch sigLen]));

velPacket = [-.5 -.5 0 .5]';


velPacket(4) = velPacket(4) - .5; % rescale the click

cursorMap = unitMap'-repmat([velPacket]',[ch 1]);

rho=sqrt(cursorMap(:,1).^2+cursorMap(:,2).^2 + cursorMap(:,3).^2+cursorMap(:,4).^2)-.6;

% Xa=(cursorMap(:,1))./(cursorMap(:,2)+10^-10);

% ArcTan can be computed via a Taylor Approximation (for speed)
% theta=Xa-1/3*Xa.^3+1/5*Xa.^5-1/7*Xa.^7+1/9*Xa.^9+1/11*Xa.^11;

% CosTheta=1-1/2*theta.^2+1/24*theta.^4-1/120*theta.^6;
% CosTheta = zeros(size(rho));
SpikeRateSec = (100 * (rho)); %.*(CosTheta+1);
lfpAmpMod = 5 + 45 * max(rho,0); %.*(CosTheta+1);
lfpAmpScaleBase = 50;

% persistent t lfp lfpAmpScale scaleTolerance;

if isempty(scaleTolerance)
    scaleTolerance = 1;
end

ch=96;
sigLen = 15;
sampFreq = 30000;

velPacket(4) = velPacket(4) - .5; % rescale the click

cursorMap = unitMap'-repmat([velPacket]',[ch 1]);

rho=sqrt(cursorMap(:,1).^2+cursorMap(:,2).^2 + cursorMap(:,3).^2+cursorMap(:,4).^2)-.6;

% Xa=(cursorMap(:,1))./(cursorMap(:,2)+10^-10);

% ArcTan can be computed via a Taylor Approximation (for speed)
% theta=Xa-1/3*Xa.^3+1/5*Xa.^5-1/7*Xa.^7+1/9*Xa.^9+1/11*Xa.^11;

% CosTheta=1-1/2*theta.^2+1/24*theta.^4-1/120*theta.^6;
% CosTheta = zeros(size(rho));

randTolerance = .1;


SpikeRateSec = (20 * (rho)); %.*(CosTheta+1);
SpikeRateSec = SpikeRateSec * scaleTolerance;
lfpAmpMod = 5 + 45 * max(rho,0); %.*(CosTheta+1);
lfpAmpMod = lfpAmpMod * scaleTolerance;
lfpAmpScaleBase = 50;


% Spikes

spikeProb = repmat(SpikeRateSec * sigLen / sampFreq,[1 sigLen]);

probMatrix = (rand(96,sigLen) > (1-spikeProb));

spikes = zeros(size(probMatrix));

spikeCounter = sum(probMatrix,2);

totalNumSpikes = sum(spikeCounter);

spikes(probMatrix) =  -80;



fbands=[5 10 20 40 80 160 320];
% fbands=[5];

% sigLen=samples;


maxLen=sigLen*400; % must enforce maxLen as 2N multiple of sigLen

% t = []; lfp = [];
if isempty(t)
    t=0;
    lfp=zeros(ch,maxLen,length(fbands));
    lfpAmpScale = lfpAmpScaleBase*ones(ch,1).* (lfpAmpMod);
    for f=1:length(fbands)
        lfp(:,1:maxLen,f)=((1/f*(sin(2*pi*(1/sampFreq)*((fbands(f)))*repmat([1:maxLen],[ch 1 1])+repmat(rand(ch,1)*2*pi,[1 maxLen 1])))));
    end
end


data = int16((mean(lfp(:,t+1:t+sigLen,:) .* repmat(lfpAmpScale,[1 sigLen length(fbands)]),3)));

% Prep for next iteration

t=t+sigLen;
%a=round(mod(t+1,slen/plen)*plen);

if t + sigLen == maxLen/2
    lfpAmpScale = lfpAmpScaleBase*ones(ch,1) .* (lfpAmpMod);
end

if t + sigLen == maxLen
    t=0;
    lfpAmpScale = lfpAmpScaleBase*ones(ch,1) .* (lfpAmpMod);
    scaleTolerance = rand(1) * randTolerance * 2 + (1-randTolerance);
end


% Collect outputs

sampleData = data+noise+int16(spikes);
numSamples = int32(sigLen);

spikeCounts = int32(spikeCounter);
numSpikes = totalNumSpikes;
spikeRates = [SpikeRateSec; zeros(ch*2,1)];

% to=t;

end

cd('C:\SimData\')
save simulatedReference longSignal