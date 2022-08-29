R = load('/Users/frankwillett/Data/Monk/BCIvsArm/R_2017-10-04_1.mat');

%%
%compile simulator if not compiled
if (ispc && ~exist('simBci.mexw64','file')) || (isunix && ~exist('simBci.mexa64','file'))
    codeDir = which('simBci.c');
    codeDir = codeDir(1:(end-8));
    currentDir = pwd;

    cd(codeDir);
    mex simBci.c simulator.c pwl_interp_1d.c
    cd(currentDir);
end

%%
%format data

%downsample to 20 ms bins, threshold the spike activity
allSpike = [R.minAcausSpikeBand]';
allSpike = bsxfun(@lt, allSpike, model.thresholds);

nBins = floor(size(allSpike,1)/20);
allSpike20 = zeros(nBins, size(allSpike,2));
binIdx = 1:20;
for n=1:nBins
    allSpike20(n,:) = sum(allSpike(binIdx,:));
    binIdx = binIdx + 20;
end
allSpike20 = double(allSpike20);

%downsample kinematic data
%nDim = length(R(1).posTarget);
nDim = length(find(std(R(1).decoderC.decoderXk(2:2:end,:)')~=0));

allKin = [R.xk]';
allPos = allKin(:,1:2:(nDim*2-1));
allVel = allKin(:,2:2:(nDim*2))*R(1).gain(1);
allTargPos = [R.currentTarget]';
trlNum = [];
for t=1:length(R)
    trlNum = [trlNum; zeros(length(R(t).holdTimer),1)+t];
end

allPos20 = double(allPos(20:20:end,:));
allVel20 = double(allVel(20:20:end,:))*1000;
allTarg20 = double(allTargPos(20:20:end,1:nDim));
trlNum20 = trlNum(20:20:end);

%summarize trial epochs
rEpochs = zeros(length(R),2);
for t=1:length(R)
    trlIdx = find(trlNum20==t);
    rEpochs(t,:) = [trlIdx(1), trlIdx(end)];
end
rIdxNoRT = expandEpochIdx([rEpochs(:,1)+10, rEpochs(:,2)]);

%far distance
posErr = allTarg20 - allPos20;
targDist = sqrt(sum(posErr.^2,2));
maxDist = prctile(targDist(rEpochs(:,1)+1),90);
farDistInterval = [0.7*maxDist, maxDist];

%     normSpike = zscore(allSpike20);
%     coef = buildLinFilts(posErr(rIdxNoRT,:), normSpike(rIdxNoRT,:), 'inverseLinear');
%     offlineDecode = normSpike * coef;
%     normFactor = normalizeDecoder(posErr(rIdxNoRT,:), offlineDecode(rIdxNoRT,:), farDistInterval);
%     offlineDecode = offlineDecode * normFactor;

%estimate Kalman parameters
centeredSpike = bsxfun(@plus, allSpike20, -mean(allSpike20));
centeredSpike = bsxfun(@times, centeredSpike, model.invSoftNormVals(1:192)');
K = double(model.K(2:2:(nDim*2),1:192));
A = zeros(nDim);
for n=1:nDim
    A(n,n) = double(model.A(n*2,n*2));
end
H = double(model.C(1:192,2:2:(nDim*2)));

%put into units of /s instead of /ms
K = K*1000*(15/20);
H = H/(1000*(15/20));

[ alpha, beta, D, alphaInd, betaInd ] = reparamKalman( K, A, H, posErr(rIdxNoRT,:), centeredSpike(rIdxNoRT,:), farDistInterval);
beta = beta * R(2).gain(2);

%normalized neural push
decoded_u = centeredSpike * D;

%convert alpha from 15 ms to 20 ms
sys = dss(alpha, 1-alpha, 1, 0, 1, 0.015);
sys_c = d2c(sys);
sys_20 = c2d(sys_c, 0.02);
alpha = sys_20.A;

%compute Willett 2017 Fitts paper SNR
%     allDec = [];
%     allTarg = [];
%     for t=1:size(rEpochs,1)
%         binIdx = (rEpochs(t,1)+10):(rEpochs(t,1)+25);
%         decVec = mean(decoded_u(binIdx,:));
%         toTargVec = mean(posErr(binIdx,:))/norm(mean(posErr(binIdx,:)));
% 
%         allDec = [allDec; decVec];
%         allTarg = [allTarg; toTargVec];
%     end
%     allDec = bsxfun(@plus, allDec, -mean(allDec));
% 
%     b = regress(allDec(:), allTarg(:));
%     noise = mean(std(allDec - allTarg*b));
%     SNR = b/noise;

%gaussian smoothing approximation
smoothCoef = [sum(model.smoothingKernel(1:20)), ...
    sum(model.smoothingKernel(21:40)), ...
    sum(model.smoothingKernel(41:end))];

%%
%fit model
opts.pos = allPos20;
opts.vel = allVel20;
opts.targPos = allTarg20;
opts.decoded_u = decoded_u;

opts.modelOpts.noVel = false;
opts.modelOpts.nKnots = 12;
opts.modelOpts.noNegativeFTarg = true;

opts.filtAlpha = alpha;
opts.filtBeta = beta;

opts.reachEpochsToFit = [rEpochs(:,1)+10, rEpochs(:,2)];
opts.feedbackDelaySteps = 10;
opts.timeStep = 0.02;

disp('Fitting Model');
modelOut = fitPiecewiseModel( opts );
disp(['Noise STD: ' num2str(sqrt(diag(modelOut.noiseModel.covNoise))',2)]);

%%
%set up task parameters
startPos = zeros(1,nDim);
modelOut.simOpts.plant.bCoef = smoothCoef;
modelOut.simOpts.trial.dwellTime = fOpts.dwellTime;
modelOut.simOpts.trial.maxTrialTime = 10;
modelOut.simOpts.plant.alpha = 0.92;

nTrials = 640;
if strcmp(fOpts.taskName,'Radial')
    nTargs = 3^nDim;
    targList = zeros(nTargs,nDim);
    for x=1:nTargs
        if nDim==2
            [targList(x,1), targList(x,2)] = ind2sub([3 3], x);
        elseif nDim==3
            [targList(x,1), targList(x,2), targList(x,3)] = ind2sub([3 3 3], x);
        elseif nDim==4
            [targList(x,1), targList(x,2), targList(x,3), targList(x,4)] = ind2sub([3 3 3 3], x);
        elseif nDim==5
            [targList(x,1), targList(x,2), targList(x,3), targList(x,4), targList(x,5)] = ind2sub([3 3 3 3 3], x);
        end
    end
    targList(targList==1)=-1;
    targList(targList==2)=0;
    targList(targList==3)=1;
    targList = 0.1*bsxfun(@times, targList, 1./sqrt(sum(targList.^2,2)));
    zeroIdx = find(all(isnan(targList),2));
    targList(zeroIdx,:) = [];

    altTargs = zeros(size(targList,1)*2,size(targList,2));
    altTargs(1:2:end,:) = targList;
    testTargs = repmat(altTargs, ceil(nTrials/size(altTargs,1)), 1);

    targRads = zeros(size(testTargs,1),1) + fOpts.radialDiameter/2;
else
    testTargs = (rand(nTrials,nDim)-0.5)*2*0.1;
    possibleRads = fOpts.fittsDiameters/2;
    %possibleRads = [0.0290    0.0345    0.0410    0.0488]/2;
    %possibleRads = [0.02 0.03 0.04 0.05]/2;
    rPrm = randperm(nTrials);
    targRads = zeros(nTrials,1);

    innerIdx = 1:(nTrials/length(possibleRads));
    for t=1:length(possibleRads)
        targRads(rPrm(innerIdx))=possibleRads(t);
        innerIdx = innerIdx + (nTrials/length(possibleRads));
    end
end

%%
%find best linear gain
betaValues = logspace(log10(0.02), log10(0.2), 50);
ttt = zeros(length(betaValues),1);

%     newModel = modelOut;
%     newModel.simOpts.plant.alpha = alpha;
%     newModel.simOpts.plant.beta = beta;
%     out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
%     
%     movTimes = rEpochs(:,2)-rEpochs(:,1);
%     movTimes = movTimes*0.02;
%     
%     disp(' ');
%     disp(['Actual movement time for block ' num2str(fOpts.blockToFit)]);
%     disp(mean(movTimes));
%     disp(['Simulated movement time for block ' num2str(fOpts.blockToFit)]);
%     disp(mean(out.movTime));

newModel = modelOut;
newModel.simOpts.control.fVelY(:) = 0;

disp('Sweeping for best linear gain');

for b=1:length(betaValues)
    newModel.simOpts.plant.beta = betaValues(b);
    out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
    ttt(b) = mean(out.movTime);
end

ttt = filtfilt(ones(3,1)/3,1,ttt);
[minTTT, minIdx] = min(ttt);
bestLinBeta = betaValues(minIdx);

figure
plot(betaValues,ttt,'-');
xlabel('Beta (m/s)');
ylabel('Mean Acquire Time (s)');
title('Linear Gain Sweep');
saveas(gcf,[sessionPath 'Analysis' filesep 'Model Optimization' filesep num2str(fOpts.blockToFit) ' linear gain sweep'],'png');

%%
%find best power function parameters
powValues = linspace(1,2.5,10);
betaValues = logspace(log10(0.02), log10(0.2), 25);
ttt = zeros(length(powValues), length(betaValues));
%fVelSlopes = linspace(0,-0.25,3);
%minSlopes = zeros(length(powValues), length(betaValues));

for p=1:length(powValues)
    disp(['Simulating power ' num2str(powValues(p))]);
    for b=1:length(betaValues)
        newModel.simOpts.plant.beta = 1;
        newModel.simOpts.plant.nonlinType = 3;
        newModel.simOpts.plant.fStaticX = linspace(0,2,100);
        newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticX.^powValues(p);
        newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticY * betaValues(b);

        out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
        ttt(p,b) = mean(out.movTime);
%             tmp = zeros(length(fVelSlopes),1);
%             for v=1:length(fVelSlopes)
%                 newModel.simOpts.control.fVelX = linspace(0,2,10);
%                 newModel.simOpts.control.fVelY = fVelSlopes(v)*linspace(0,2,10);
%                 out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
%                 tmp(v) = mean(out.movTime);
%             end
%             [~,minIdx] = min(tmp);
%             minSlopes(p,b) = fVelSlopes(minIdx);
%             ttt(p,b) = min(tmp);
    end
end

%smooth out some of the noise in movement time
ttt = filtfilt(ones(3,1)/3,1,ttt')';

%find best parameters
[minTime, bestIdx] = min(ttt(:));
[bestP, bestB] = ind2sub(size(ttt), bestIdx);
[~,best2Idx] = min(ttt(7,:));

%%
%validate with new noise time series
newModel = modelOut;
newModel.simOpts.noiseMatrix =  generateNoiseFromModel( 100000, modelOut.noiseModel );
newModel.simOpts.control.fVelY(:) = 0;
newModel.simOpts.plant.beta = bestLinBeta;

out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
linTTT = mean(out.movTime);

newModel.simOpts.plant.beta = 1;
newModel.simOpts.plant.nonlinType = 3;
newModel.simOpts.plant.fStaticX = linspace(0,2,100);
newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticX.^2;
newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticY*betaValues(best2Idx);

out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
squareTTT = mean(out.movTime);

newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticX.^powValues(bestP);
newModel.simOpts.plant.fStaticY = newModel.simOpts.plant.fStaticY * betaValues(bestB);
fStaticY_best2 = newModel.simOpts.plant.fStaticX.^2;

out = simBatch( newModel.simOpts, testTargs, startPos, targRads );
powTTT = mean(out.movTime);

%%
%plot best gains
lHandles = zeros(3,1);
figure
hold on
lHandles(1)=plot(newModel.simOpts.plant.fStaticX, newModel.simOpts.plant.fStaticY, '-', 'LineWidth', 2);
lHandles(2)=plot(newModel.simOpts.plant.fStaticX, newModel.simOpts.plant.fStaticX*bestLinBeta, '--k', 'LineWidth', 2);
lHandles(3)=plot(newModel.simOpts.plant.fStaticX, fStaticY_best2*betaValues(best2Idx), 'r-', 'LineWidth', 2);
title([num2str(100*(1-min(ttt(:))/min(ttt(1,:))),3) '% improvement (x^{' num2str(powValues(bestP)) '})']);
xlabel('Input Speed (Normalized Units /s)');
ylabel('Output Speed (Game Units /s)');
legend(lHandles, {'Optimal Power','Optimal Linear','Best x^2'},'Location','NorthWest');
axis tight;
xlim([0 1.2]);
saveas(gcf,[sessionPath 'Analysis' filesep 'Model Optimization' filesep num2str(fOpts.blockToFit) ' optimal gains'],'png');

%%
%print parameters to console
%convert alpha from 20 ms to 15 ms
simAlpha = newModel.simOpts.plant.alpha;
sys = dss(simAlpha, 1-simAlpha, 1, 0, 1, 0.020);
sys_c = d2c(sys);
sys_15 = c2d(sys_c, 0.015);
alpha_15 = sys_15.A;

disp(' ');

disp('Optimal Linear Parameters:');
disp(['Alpha = ' num2str(alpha_15,2)]);
disp(['Beta = ' num2str(bestLinBeta)]);
disp(['Estimated Mean Acquire Time (s) = ' num2str(linTTT)]);

disp(' ');

disp('Optimal Nonlinear Parameters:');
disp(['Alpha = ' num2str(alpha_15,2)]);
disp(['Beta = ' num2str(betaValues(bestB))]);
disp(['Crossover = ' num2str(betaValues(bestB)/1000)]);
disp(['Power = ' num2str(powValues(bestP))]);
disp(['Estimated Mean Acquire Time (s) = ' num2str(powTTT)]);

disp(' ');

disp('Best x^2 Parameters:');
disp(['Alpha = ' num2str(alpha_15,2)]);
disp(['Beta = ' num2str(betaValues(best2Idx))]);
disp(['Crossover = ' num2str(betaValues(best2Idx)/1000)]);
disp(['Power = ' num2str(2)]);
disp(['Estimated Mean Acquire Time (s) = ' num2str(squareTTT)]);


