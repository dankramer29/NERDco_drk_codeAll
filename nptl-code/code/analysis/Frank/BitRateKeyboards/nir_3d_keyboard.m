%%
%paths and data specification (fits the simulator model based on the block
%given)
datasetPath = '/Users/frankwillett/Data/BG Datasets/';
datasetName = 't5.2017.03.22';
blockNum = 17;
kbPath = '/Users/frankwillett/Downloads/keyboards_coord.mat';

%%
%load a single block of 3D BCI data
stream = parseDataDirectoryBlock([datasetPath datasetName filesep 'Data' filesep 'FileLogger' filesep num2str(blockNum) filesep], blockNum);
R = onlineR(stream);
load([datasetPath datasetName filesep 'Data' filesep 'Filters' filesep R(end).decoderD.filterName '.mat']);

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

[ alpha, beta, D] = reparamKalman( K, A, H, posErr(rIdxNoRT,:), centeredSpike(rIdxNoRT,:), farDistInterval);
beta = beta * R(2).gain(2);

%normalized neural push
decoded_u = centeredSpike * D;

%convert alpha from 15 ms to 20 ms
sys = dss(alpha, 1-alpha, 1, 0, 1, 0.015);
sys_c = d2c(sys);
sys_20 = c2d(sys_c, 0.02);
alpha = sys_20.A;

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

opts.modelOpts.noVel = true;
opts.modelOpts.nKnots = 12;
opts.modelOpts.noNegativeFTarg = true;

opts.filtAlpha = alpha;
opts.filtBeta = beta;

opts.reachEpochsToFit = [rEpochs(:,1)+10, rEpochs(:,2)];
opts.feedbackDelaySteps = 10;
opts.timeStep = 0.02;
opts.fitNoiseModel = true;
opts.fitSDN = true;

disp('Fitting Model');
modelOut = fitPiecewiseModel( opts );
disp(['Noise STD: ' num2str(sqrt(diag(modelOut.noiseModel.covNoise))',2)]);

%it is a large extrapolation to use the control policy fit on T5 on the 1D
%keyboard which has a bunch of very small targets. Thus I am helping it out
%a little bit by increasing the size of the neural push near the target,
%otherwise performance would be worse. This makes the assumption that T5
%would learn to push harder near the target, likely the case if the gain is
%low and he gets practice on the small targets.
modelOut.controlModel.fTargY(1:3) = max(0.5, modelOut.controlModel.fTargY(1:3));

%%
%set up task parameters for a sanity check radial simulation
startPos = zeros(1,nDim);
modelOut.simOpts.plant.bCoef = smoothCoef;
modelOut.simOpts.trial.dwellTime = 0.5;
modelOut.simOpts.trial.maxTrialTime = 10;
modelOut.simOpts.plant.alpha = 0.92;
modelOut.simOpts.plant.nDim = nDim;
modelOut.simOpts.trial.targRad =  R(2).startTrialParams.targetDiameter/2;

nTrials = 640;
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

%%
%simulate data under conditions in which the model was fit to verify that
%trajectories look similar
modelOut.simOpts.plant.beta = beta;
modelOut.simOpts.plant.alpha = alpha;
out = simBatch( modelOut.simOpts, testTargs, startPos );

figure
hold on;
for t=1:60
    loopIdx = out.reachEpochs(t,1):out.reachEpochs(t,2);
    plot3(out.pos(loopIdx,1), out.pos(loopIdx,2), out.pos(loopIdx,3),'b');
end
axis equal;
title('Simlulated Trajectories');

figure
hold on;
for t=1:60
    cp = R(t).cursorPosition';
    plot3(cp(:,1),cp(:,2),cp(:,3),'b');
end
axis equal;
title('Real Trajectories');

disp(['Simulated Mean Movement Time: ' num2str(mean(out.movTime)) ' (s)']);
disp(['Actual Mean Movement Time: ' num2str(mean([R.trialLength])/1000.0) ' (s)']);

%%
%simulate bit rates for different keyboards
kb = load(kbPath);
kbCell = cell(3,1);
kbCell{1} = (kb.X_1D(:,2)-mean(kb.X_1D(:,2)))/360;
kbCell{2} = (kb.X_2D(:,1:2)-mean(kb.X_2D(:,1:2)))/50;
kbCell{3} = (kb.X_3D(:,1:3)-mean(kb.X_3D(:,1:3)))/34;

betaValues = logspace(log10(0.01), log10(0.6), 30);
alpha = 0.92; %set the smoothing to this value instead of sweeping
dwellTimeValues = 4:4:150;
allBitRates = zeros(3,length(betaValues),length(dwellTimeValues));

disp('Starting (keyboard / gain / dwell time) sweep');

%sweep over gain values
for b=1:length(betaValues)
    disp(['Gain value ' num2str(b) '/' num2str(length(betaValues)) ' ...']);
    for kbIdx=1:3
        %--simulate point-to-point movements all over the keyboard 
        newModel = modelOut;
        newModel.simOpts.plant.nDim = kbIdx;
        newModel.simOpts.noiseMatrix = newModel.simOpts.noiseMatrix(:,1:kbIdx);
        newModel.simOpts.plant.beta = betaValues(b);
        newModel.simOpts.plant.alpha = alpha;
        newModel.simOpts.trial.dwellTime = 22.0;
        newModel.simOpts.trial.maxTrialTime = 20.0;
             
        nTargs = 600;
        targetPos = zeros(nTargs, kbIdx);
        startPos = zeros(nTargs, kbIdx);
        targetIdx = zeros(nTargs,1);
        for targIdx=1:nTargs
            startTargIdx = randi(length(kbCell{kbIdx}),1,1);
            endTargIdx = randi(length(kbCell{kbIdx}),1,1);
            
            targetPos(targIdx,:) = kbCell{kbIdx}(endTargIdx,:);
            startPos(targIdx,:) = kbCell{kbIdx}(startTargIdx,:);
            targetIdx(targIdx) = endTargIdx;
        end

        out = simBatch( newModel.simOpts, targetPos, startPos );
        
        %for each time step, find the closest target
        closestTargetIdx = zeros(length(out.pos),1);
        for t=1:length(out.pos)
            targDist = matVecMag(out.pos(t,:) - kbCell{kbIdx},2);
            [~,closestTargetIdx(t)] = min(targDist);
        end
        
        %--estimate bit rate as a function of dwell time
        for dwellIdx=1:length(dwellTimeValues)
            dTime = dwellTimeValues(dwellIdx);
            trialResults = zeros(nTargs,2);
            
            %estimate success/failure and trial time for each trial
            for trlIdx=1:nTargs
                loopIdx = out.reachEpochs(trlIdx,1):out.reachEpochs(trlIdx,2);
                dwellCounter = 0;
                trialDone = false;
                dwellCounterVec = zeros(length(loopIdx),1);
                for lp=2:length(loopIdx)
                    lpIdx = loopIdx(lp);
                    if closestTargetIdx(lpIdx)==closestTargetIdx(lpIdx-1) && lp>10 %RT delay
                        dwellCounter = dwellCounter + 1;
                    else
                        dwellCounter = 0;
                    end
                    dwellCounterVec(lp) = dwellCounter;
                    
                    if dwellCounter>=dTime
                        %target acquired
                        if closestTargetIdx(lpIdx)==targetIdx(trlIdx)
                            %success
                            trialResults(trlIdx,1) = 1;
                        else
                            %failure
                            trialResults(trlIdx,1) = 0;
                        end
                        trialResults(trlIdx,2) = lp;
                        trialDone = true;
                        break;
                    end
                end
                if ~trialDone
                    trialResults(trlIdx,:) = [0, length(loopIdx)];
                end %time step
            end %trials
            
            %compute achieved bit rate
            N = length(kbCell{kbIdx});
            totalTime = sum(trialResults(:,2))/50;
            allBitRates(kbIdx,b,dwellIdx) = log2(N-1)*max(sum(trialResults(:,1))-sum(~trialResults(:,1)),0)/totalTime;
        end %dwell time
    end %keyboard
end %beta

for kbIdx=1:3
    figure
    imagesc(dwellTimeValues/50, betaValues, squeeze(allBitRates(kbIdx,:,:)));
    colorbar;
    title(['Achieved Bitrates for Keyboard ' num2str(kbIdx)]);
    xlabel('Dwell Time');
    ylabel('Gain');
end
