nDataPoints = 8000;
resultsDir = '/Users/frankwillett/Data/CaseDerived/';
mkdir([resultsDir filesep 'ReFIT sim']);

%%
pwX = [         0
    0.0909
    0.1818
    0.2727
    0.3636
    0.4545
    0.5455
    0.6364
    0.7273
    0.8182
    0.9091
    1.0000
    1.01];
pwY = [       0
    0.3999
    0.6842
    0.7434
    0.8041
    0.8646
    0.9088
    0.9455
    0.9668
    0.9913
    1.0101
    0.9754
    0.9754];

opts = makeBciSimOptions();
opts.trlCon.gen.tmOpts.targList = bsxfun(@plus, [0   54.5000
         0   26.5000
   14.0000   40.5000
  -14.0000   40.5000
    9.8995   50.3995
    9.8995   30.6005
   -9.8995   50.3995
   -9.8995   30.6005], -[0 40.5]);
opts.trlCon.gen.tmOpts.targRad = 3.56;
opts.trlCon.gen.tmOpts.returnToCenter = 0;

opts.nReaches = 50;
opts.mRule.type = opts.mRule.type_piecewisePointModel;
opts.mRule.piecewisePointModel.distCoef = pwY;
opts.mRule.piecewisePointModel.distEdges = pwX';
opts.mRule.piecewisePointModel.distRange =  [0 14];
opts.mRule.piecewisePointModel.speedRange =  [0 1];
opts.mRule.piecewisePointModel.speedEdges =  [0 1];
opts.mRule.piecewisePointModel.speedCoef =  [0 0]';
opts.mRule.piecewisePointModel.modelOpts.targetDeadzone = false;
opts.mRule.predictiveStopLookAhead=0;

nChan = 192;
opts.effector.nControlDims = 2;
opts.effector.nKinDims = 2;
opts.effector.nStateDims = 4 + nChan;
opts.effector.defaultState = [0 0 0 0 zeros(1,nChan);];
opts.effector.state = [0 0 0 0 zeros(1,nChan)];
opts.trlCon.gen.tmOpts.initialEffectorState = [0 0 0 0 zeros(1,nChan)];
opts.effector.getKinematicPositionFcn = @getEffectorPos;

opts.filt.ln.B = 1;
opts.filt.ln.A = [1,0];

assumptionNames = {'True\newlineModel','FBC\newlineModel','Position\newlineError','Unit\newlineVector','ReFIT','Decoded\newlineVelocity'};
alphaVal = 0.92;
betaVal = 14;
nReps = 20;

targRads = linspace(1,4,5);
allOfflineError = cell(2, length(targRads), length(assumptionNames), nReps);
abKalman = cell(2, 2, nReps);
ttt = cell(2, 2, nReps);
optSweeps = cell(2, 2, nReps);

for n=1:nReps
    disp(['N=' num2str(n) ' / ' num2str(nReps)]);
    
    %lower = more noisy; 0.25 = noisy, 0.5 = clean
    indStd = 7./random('exp',0.5,nChan,1);
    E = randn(nChan,2);
    E_ol = E + randn(nChan,2)*0.75;
    
    %%
    %generate OL dataset
    theta = linspace(0,2*pi,9)';
    theta = theta(1:8);

    targList =  [cos(theta), sin(theta)];
    movTime = 1;
    olXY = [];
    olTargXY = [];
    olVelXY = [];
    movCommand_ol = [];

    for s=1:size(targList,1)
        tAxis = linspace(0,movTime,round(movTime*50));
        minJerk = [targList(s,1)*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5)
            targList(s,2)*(10*(tAxis/movTime).^3-15*(tAxis/movTime).^4+6*(tAxis/movTime).^5)]';

        olXY = [olXY; minJerk];
        olTargXY = [olTargXY; repmat(targList(s,:), length(minJerk), 1)];
        olVelXY = [olVelXY; [0 0; diff(minJerk)*50]];

        targDist = matVecMag(bsxfun(@plus, minJerk, -targList(s,:)),2);
        targDir = bsxfun(@times, repmat(targList(s,:), length(minJerk), 1)-minJerk, 1./targDist);
        targDir(end,:)=0;
        movCommand_ol = [movCommand_ol; bsxfun(@times, targDir, interp1(pwX, pwY, targDist))];
    end

    
    %%
%     movCommand_ol = randn(500,2);
%     comMag = matVecMag(movCommand_ol,2);
%     tooBig = comMag>1;
%     movCommand_ol(tooBig,:) = bsxfun(@times, movCommand_ol(tooBig,:), 1./comMag(tooBig));

    simNoise = bsxfun(@times, randn(size(movCommand_ol,1),nChan), indStd');
    simAct_ol = (E_ol * movCommand_ol')' + simNoise;

    initDecoder = buildLinFilts(movCommand_ol, simAct_ol, 'inverseLinear');
    initDecoder = [0 0; initDecoder];
    
    for normVectors = 1:2
        for stateMat = 1:2
            disp([' State Mat ' num2str(stateMat)]);
            abKalman{normVectors, stateMat, n} = zeros(length(targRads), length(assumptionNames), 10, 2);
            ttt{normVectors, stateMat, n} = zeros(length(targRads), length(assumptionNames), 11, 3);
            optSweeps{normVectors, stateMat, n} = cell(length(targRads), length(assumptionNames));

            for radIdx = 4:length(targRads)
                disp(['  R=' num2str(radIdx) ' / ' num2str(length(targRads))]);
                opts.trlCon.gen.tmOpts.targRad = targRads(radIdx);
                for methodIdx = 1:length(assumptionNames)
                    disp(['   M=' num2str(methodIdx) ' / ' num2str(length(assumptionNames))]);

                    decoder = initDecoder;
                    alpha = alphaVal;
                    beta = betaVal;
                    opts.effector.stepForwardFcnFM = @(state, controlSignal)integrateForward_withoutNeurons( E, indStd, controlSignal, state, 0.02, ...
                        alpha, beta );
                    opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_2( E, indStd, controlSignal, state, 0.02, decoder, ...
                        alpha, beta, [0 0] );
                    opts.noise.noiseSeries = zeros(10000,2);

                    res = bciSim(opts);
                    [ttt{stateMat, n}(radIdx, methodIdx, 1, 1), ~, ttt{stateMat, n}(radIdx, methodIdx, 1, 2:3)] = normfit(res.ttt);

                    for reCalIdx=1:10
                        disp(['    RC=' num2str(reCalIdx) ' / 10']);

                        %trial segmentation
                        reachesNoRT = [res.reachEpochs(:,1)+10, res.reachEpochs(:,2)];
                        for nReach = 1:size(reachesNoRT,1)
                            tmp = length(expandEpochIdx(reachesNoRT(1:nReach,:)));
                            if tmp>nDataPoints
                                break;
                            end
                        end
                        rIdxTrain = expandEpochIdx(reachesNoRT(1:nReach,:)); %train only on 10000 samples

                        %simulated neural activity
                        simAct = res.effectorState(:,5:end);
                        decCVec = simAct * decoder(2:end,:);

                        trainVec = cell(6,1);
                        trainVec{1} = res.movCommand*14;

                        fitOpts = makeCartesianCVecModelOpts();
                        fitOpts.pos = double(res.pos);
                        fitOpts.vel = double(res.effectorState(:,3:4))/50;
                        fitOpts.targPos = double(res.targPos);
                        fitOpts.cVec = decCVec;
                        fitOpts.targRad = zeros(size(res.pos,1),1)+opts.trlCon.gen.tmOpts.targRad;
                        fitOpts.modelName = 'pointModel';
                        fitOpts.modelOpts.noVel = false;
                        fitOpts.returnNoiseModel = false;
                        fitOpts.reachEpochsToFit = reachesNoRT(1:nReach,:);
                        fitOpts.filtAlpha = alpha;
                        fitOpts.filtBeta = beta/50;
                        fitOpts.fbDelayAndBackStep = [0.200 0;];
                        fitOpts.timeStep = 0.02;
                        modelOut = fitCartesianCVecModel( fitOpts );
                        trainVec{2} = modelOut.bestControlModelCVec*14;

                        trainVec{3} = res.targPos - res.pos;
                        trainVec{4} = 14*bsxfun(@times, trainVec{3}, 1./matVecMag(trainVec{3},2));

                        speed = matVecMag(res.effectorState(:,3:4),2);
                        reFIT = bsxfun(@times, trainVec{3}, 1./matVecMag(trainVec{3},2));
                        reFIT = bsxfun(@times, reFIT, speed);
                        reFIT(res.inTarget,:) = 0;
                        trainVec{5} = reFIT;
                        trainVec{6} = res.effectorState(:,3:4);

                        if normVectors==1
                            for normIdx=1:length(trainVec)
                                trainVec{normIdx} = trainVec{normIdx}/mean(matVecMag(trainVec{normIdx}(rIdxTrain,:),2));
                            end
                        end

                        if stateMat==1
                            A = eye(2)*0.9929;
                            Q = eye(2)*0.04;
                        else
                            A = buildLinFilts(trainVec{methodIdx}(rIdxTrain(2:end),:), trainVec{methodIdx}(rIdxTrain(1:(end-1)),:), 'standard');
                            Q = cov(trainVec{methodIdx}(rIdxTrain(2:end),:)-trainVec{methodIdx}(rIdxTrain(1:(end-1)),:)*A);
                        end

                        C = buildLinFilts(simAct(rIdxTrain,:), trainVec{methodIdx}(rIdxTrain,:), 'standard');
                        R = cov(simAct(rIdxTrain,:)-trainVec{methodIdx}(rIdxTrain,:)*C);
                        sys = ss(A,[zeros(2) eye(2)],C',[],0.02);
                        try
                            [k,L,P,M,Z] = kalman(sys,Q,R,[]);
                        catch
                            break;
                        end
                        decVectors = simAct*M';
                        tmp = (eye(2)-M*C')*A;
                        alpha = mean(diag(tmp));

                        abKalman{normVectors, stateMat, n}(radIdx, methodIdx, reCalIdx, 1) = alpha;
                        decVectors = decVectors / (1-alpha);

                        [normFactor, farFieldStd] = normalizeCommandVectors( res.pos, res.targPos, ...
                            decVectors, reachesNoRT(1:nReach,:), [11.2 14] ); 
                        beta = 1/normFactor;
                        abKalman{normVectors, stateMat, n}(radIdx, methodIdx, reCalIdx, 2) = beta;
                        
                        decoder = normFactor*(M')/(1-alpha);
                        decoder = [0 0; decoder];
                        
                        if stateMat==2 && reCalIdx==1
                            %offline reconstruction vs. online ttt
                            if normVectors==1
                                betaSweep = linspace(2,40,30)/14;
                            else
                                betaSweep = linspace(2,40,30);
                            end
                            alphaSweep = linspace(0.8,0.98,30);
                            
                            offlineError = zeros(length(betaSweep),length(alphaSweep));
                            for a=1:length(alphaSweep)
                                for b=1:length(betaSweep)
                                    offlineRecon = zeros(size(trainVec{1},1),2);
                                    currentVel = [0 0];
                                    for t=1:size(trainVec{1},1)
                                        currentVel = alphaSweep(a)*currentVel + (1-alphaSweep(a))*betaSweep(b)*(res.effectorState(t,5:end)*decoder(2:end,:));
                                        offlineRecon(t,:) = currentVel;
                                    end
                                    offlineError(b,a) = mean(sum((trainVec{5}(rIdxTrain,:)-offlineRecon(rIdxTrain,:)).^2,2));
                                end
                            end
                            [~,minIdx] = min(offlineError(:));
                            [i,j] = ind2sub([30 30],minIdx);
                            allOfflineError{normVectors, radIdx, methodIdx, n} = offlineError;
                        end
                        
                        if normVectors==1
                            beta = beta*betaVal;
                        end
                        opts.effector.stepForwardFcnFM = @(state, controlSignal)integrateForward_withoutNeurons( E, indStd, controlSignal, state, 0.02, ...
                            alpha, beta );
                        opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_2( E, indStd, controlSignal, state, 0.02, decoder, ...
                            alpha, beta, [0 0] );
                        opts.noise.noiseSeries = zeros(10000,2);

                        res = bciSim(opts);
                        ttt{normVectors, stateMat, n}(radIdx, methodIdx, reCalIdx+1) = mean(res.ttt);
                        disp(abKalman{normVectors, stateMat, n}(radIdx, methodIdx, reCalIdx, 2));
                        disp(ttt{normVectors, stateMat, n}(radIdx, methodIdx, reCalIdx+1));

                        %find the optimal ttt
                        if reCalIdx==1
                            
                            %use bciSimFast approximation
                            fitOpts = makeCartesianCVecModelOpts();
                            fitOpts.pos = double(res.pos);
                            fitOpts.vel = double(res.effectorState(:,3:4))/50;
                            fitOpts.targPos = double(res.targPos);
                            fitOpts.cVec = res.effectorState(:,5:end) * decoder(2:end,:);
                            fitOpts.targRad = zeros(size(res.pos,1),1)+opts.trlCon.gen.tmOpts.targRad;
                            fitOpts.modelName = 'pointModel';
                            fitOpts.modelOpts.noVel = false;
                            fitOpts.returnNoiseModel = false;
                            fitOpts.reachEpochsToFit = [res.reachEpochs(:,1)+10, res.reachEpochs(:,2)];
                            fitOpts.filtAlpha = alpha;
                            fitOpts.filtBeta = beta/50;
                            fitOpts.fbDelayAndBackStep = [0.200 0;];
                            fitOpts.timeStep = 0.02;
                            modelOut = fitCartesianCVecModel( fitOpts );
                            
                            simOpts = makeFastBciSimOptions( );
                            simOpts.trial.dwellTime = 1;
                            simOpts.control.fTargX = pwX' * 14;
                            simOpts.control.fTargY = pwY';
                            simOpts.noiseMatrix = randn(100000,2)*std(modelOut.noiseTimeSeries(:));
                            
                            gameOpts = makeBciSimFastGameOpts( );
                            gameOpts.targList = [14 0];
                            gameOpts.targRad = opts.trlCon.gen.tmOpts.targRad;
                            gameOpts.returnToCenter = false;
                            gameOpts.nReaches = 500;
                            
                            fOpts.rapidRepeat = true;
                            fOpts.returnTraj = false;
                            fOpts.rapidFitts = false;

                            simOpts.plant.alpha = alpha;
                            simOpts.plant.beta = beta;
                            
                            out = bciSimFast(gameOpts, simOpts, fOpts);
                            mean(out.ttt)
                            
                            betaSweep = linspace(2,40,30);
                            alphaSweep = linspace(0.8,0.98,30);
                            optTTT = zeros(length(betaSweep),length(alphaSweep));
                            for b=1:length(betaSweep)
                                %disp(b);
                                for a=1:length(alphaSweep)
                                    simOpts.plant.alpha = alphaSweep(a);
                                    simOpts.plant.beta = betaSweep(b);
                                    out = bciSimFast(gameOpts, simOpts, fOpts);
                                    optTTT(b,a) = mean(out.ttt);
                                end
                            end
                            [~,minIdx] = min(optTTT(:));
                            [i,j] = ind2sub([30 30],minIdx);

                            optSweeps{normVectors, stateMat, n}{radIdx, methodIdx} = optTTT;
                        end
                        
                    end %calibration attempt
                end %method
            end %target radius
        end %state mat
    end %norm vectors
end %nRep

save([resultsDir filesep 'ReFIT sim' filesep 'ieeeSim_v2.mat']);
close all;
    
%%
load([resultsDir filesep 'ReFIT sim' filesep 'jneRevision.mat']);

%%
optAB = zeros(length(targRads),2);
for r=1:length(targRads)
    tmp = squeeze(optSweeps{2,2,1}{r,1});
    
    smoothTmp = tmp;
    [X,Y]=meshgrid(-3:3,-3:3);
    stencil = [X(:), Y(:)];
    for rowIdx=1:size(tmp,1)
        for colIdx=1:size(tmp,2)
            smoothIdx = bsxfun(@plus, stencil, [rowIdx, colIdx]);
            badIdx = any(smoothIdx(:,1)<1 | smoothIdx(:,1)>size(tmp,1) | ...
                smoothIdx(:,2)<1 | smoothIdx(:,2)>size(tmp,2),2);
            smoothIdx(badIdx,:)=[];
            
            tmpInd = sub2ind(size(tmp), smoothIdx(:,1), smoothIdx(:,2));
            smoothTmp(rowIdx, colIdx) = mean(tmp(tmpInd));
        end
    end
    
    [~,minIdx] = min(smoothTmp(:));
    [i,j]=ind2sub([30 30],minIdx);
    optAB(r,:) = [alphaSweep(j), betaSweep(i)];
end

%%
figure('Position',[159         626        1281         354]);
subplot(1,3,1);
hold on
for m=2:6
    tmp = squeeze(abKalman{2,2,1}(:,m,2,:));
    plot(targRads, tmp(:,2), '-o', 'LineWidth', 1);
end
plot(targRads, optAB(:,2), '-k', 'LineWidth', 2)
set(gca,'FontSize',14);
xlabel('Target Radius');
ylabel('Gain \beta (cm/s)');

subplot(1,3,2);
hold on
for m=2:6
    tmp = squeeze(abKalman{2,2,1}(:,m,2,:));
    plot(targRads, tmp(:,1), '-o', 'LineWidth', 1);
end
plot(targRads, optAB(:,1), '-k', 'LineWidth', 2);
set(gca,'FontSize',14);
xlabel('Target Radius');
ylabel('Smooting \alpha');

subplot(1,3,3);
hold on
for m=2:6
    tmp = squeeze(ttt{2,2,1}(:,m,3));
    plot(targRads, tmp, '-o', 'LineWidth', 1);
end
tmpOptTTT = zeros(length(targRads),1);
for r=1:length(targRads)
    tmp = squeeze(optSweeps{2,2,1}{r,1});
    tmpOptTTT(r) = min(tmp(:));
end
plot(targRads, tmpOptTTT, '-k', 'LineWidth', 2);

legend({'PLM','PE/OFC','UnitVec','ReFIT','RawVel','Optimal'});
set(gca,'FontSize',14);
xlabel('Target Radius');
ylabel('Movement Time (s)');
ylim([0 10]);

exportPNGFigure(gcf, [resultsDir filesep 'ReFIT sim' filesep 'ieee1_v2']);

%%
plotRad = 2;
tmp = squeeze(optSweeps{2,2,1}{plotRad,5});
[~,minIdx] = min(tmp(:));
[i,j] = ind2sub([30 30],minIdx);
optBeta = betaSweep(i);
optAlpha = alphaSweep(j);
optTTT = tmpOptTTT(plotRad);
    
figure('Position',[159         626        1281         354]);
subplot(1,3,1);
hold on
for m=2:6
    tmp = squeeze(abKalman{2,2,1}(plotRad,m,1:(end-1),2));
    plot(1:length(tmp), tmp, '-o', 'LineWidth', 1);
end
plot(get(gca,'XLim'),[optBeta optBeta],'-k','LineWidth',2);
xlabel('Calibration Iteration');
ylabel('Gain \beta (cm/s)');
set(gca,'FontSize',14);

subplot(1,3,2);
hold on
for m=2:6
    tmp = squeeze(abKalman{2,2,1}(plotRad,m,1:(end-1),1));
    plot(1:length(tmp), tmp, '-o', 'LineWidth', 1);
end
plot(get(gca,'XLim'),[optAlpha optAlpha],'-k','LineWidth',2);
xlabel('Calibration Iteration');
ylabel('Smooting (\alpha)');
set(gca,'FontSize',14);

subplot(1,3,3);
hold on
for m=2:6
    tmp = squeeze(ttt{2,2,1}(plotRad,m,2:(end-2),1));
    plot(1:length(tmp), tmp, '-o', 'LineWidth', 1);
end
plot(get(gca,'XLim'),[optTTT optTTT],'-k','LineWidth',2);
legend({'PLM','PE/OFC','UnitVec','ReFIT','RawVel'});
xlabel('Calibration Iteration');
ylabel('Movement Time (s)');
set(gca,'FontSize',14);

exportPNGFigure(gcf, [resultsDir filesep 'ReFIT sim' filesep 'ieee2']);
%%
figure
subplot(1,2,1);
hold on
tmpOpt = zeros(length(targRads),1);
for r=1:length(targRads)
    tmp = squeeze(optSweeps{1,1,1}{r,5});
    [~,minIdx] = min(tmp(:));
    [i,j] = ind2sub([30 30],minIdx);
    tmpOpt(r) = betaSweep(i);
end
plot(targRads, tmpOpt, '-k');

subplot(1,2,2);
hold on
tmpOpt = zeros(length(targRads),1);
for r=1:length(targRads)
    tmp = squeeze(allOfflineError{1,r,5,1});
    [~,minIdx] = min(tmp(:));
    [i,j] = ind2sub([30 30],minIdx);
    tmpOpt(r) = alphaSweep(i);
end
plot(targRads, tmpOpt, '-k');
