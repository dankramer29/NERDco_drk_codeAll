addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));
resultsDir = '/Users/frankwillett/Data/CaseDerived/';
mkdir([resultsDir filesep 'Offline Demo']);

%%
opts = makeBciSimOptions();
opts.trlCon.gen.tmOpts.targList = bsxfun(@plus, [0   54.5000
         0   26.5000
   14.0000   40.5000
  -14.0000   40.5000
    9.8995   50.3995
    9.8995   30.6005
   -9.8995   50.3995
   -9.8995   30.6005], -[0 40.5]);
opts.trlCon.gen.tmOpts.targRad = 1; %1 and 4
opts.trlCon.gen.tmOpts.returnToCenter = 0;

opts.nReaches = 400;
opts.mRule.type = opts.mRule.type_piecewisePointModel;
opts.mRule.piecewisePointModel.distCoef = [0 1]';
opts.mRule.piecewisePointModel.distEdges = [0 16];
opts.mRule.piecewisePointModel.distRange =  [0 1];
opts.mRule.piecewisePointModel.speedRange =  [0 1];
opts.mRule.piecewisePointModel.speedEdges =  [0 1];
opts.mRule.piecewisePointModel.speedCoef =  [0 0]';
opts.mRule.piecewisePointModel.modelOpts.targetDeadzone = false;
opts.mRule.predictiveStopLookAhead=0;
opts.mRule.feedbackDelay = 0;
opts.mRule.initialDelay = 0;

nChan = 40;
opts.effector.nControlDims = 2;
opts.effector.nKinDims = 2;
opts.effector.nStateDims = 4 + nChan;
opts.effector.defaultState = [0 0 0 0 zeros(1,nChan);];
opts.effector.state = [0 0 0 0 zeros(1,nChan)];
opts.trlCon.gen.tmOpts.initialEffectorState = [0 0 0 0 zeros(1,nChan)];
opts.effector.getKinematicPositionFcn = @getEffectorPos;

opts.filt.ln.B = 1;
opts.filt.ln.A = [1,0];

%%
%generate OL dataset
targList =  opts.trlCon.gen.tmOpts.targList;
movTime = 0.750;
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
    movCommand_ol = [movCommand_ol; (repmat(targList(s,:), length(minJerk), 1) - minJerk)/16];
end

nRep = 10;
olXY = repmat(olXY, nRep, 1);
olTargXY = repmat(olTargXY, nRep, 1);
olVelXY = repmat(olVelXY, nRep, 1);
movCommand_ol = repmat(movCommand_ol, nRep, 1);

%%
%lower = more noisy; 0.25 = noisy, 0.5 = clean
indStd = zeros(40,1)+2;
theta = linspace(0, 2*pi, nChan+1);
theta = theta(1:(end-1));
E = zeros(nChan,3);
for n=1:nChan
    E(n,2:3) = [cos(theta(n)), sin(theta(n))];
end

simNoise = bsxfun(@times, randn(size(movCommand_ol,1),nChan), indStd');
simAct_ol = (E * [ones(size(movCommand_ol,1),1) movCommand_ol]')' + simNoise;

decoder_ol = buildTopNDecoderKalman(simAct_ol, olVelXY, size(simAct_ol,2), 'FitA');
decVals = applyKalman( decoder_ol, simAct_ol );

opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_kalman( E, indStd, controlSignal, state, 0.02, decoder_ol );
opts.noise.noiseSeries = zeros(10000,2);

opts.nReaches = 40;
res_ol = bciSim(opts);  
visSim( opts, res_ol, false, true );

olAlpha = mean(diag(decoder_ol.inertiaMatrix));
[~,rawVals] = applyKalman( decoder_ol, res_ol.effectorState(:,5:end) );
[normFactor, farFieldStd] = normalizeCommandVectors( res_ol.pos, res_ol.targPos, ...
    rawVals/(1-olAlpha), res_ol.reachEpochs, [11.2 14] ); 
olBeta = 1/normFactor;

%%
%refit
simAct = res_ol.effectorState(:,5:end);

targDir = bsxfun(@times, res_ol.targPos - res_ol.pos, 1./matVecMag(res_ol.targPos - res_ol.pos,2));
refitVel = bsxfun(@times, targDir, matVecMag(res_ol.effectorState(:,3:4),2));
refitVel(res_ol.inTarget,:) = 0;
trainIdx = 1:(1*size(movCommand_ol,1));

decoder_cl = buildTopNDecoderKalman(simAct(trainIdx,:), refitVel(trainIdx,:), size(simAct,2), 'FitA');  
opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_kalman( E, indStd, controlSignal, state, 0.02, decoder_cl );

opts.nReaches = 40;
res_cl = bciSim(opts);  
visSim( opts, res_cl, false, true );

%%
%offline reconstruction surface
clAlpha = mean(diag(decoder_cl.inertiaMatrix));
[~,rawVals_refit] = applyKalman( decoder_cl, res_ol.effectorState(:,5:end) );
[normFactor, farFieldStd] = normalizeCommandVectors( res_ol.pos, res_ol.targPos, ...
    rawVals_refit/(1-clAlpha), res_ol.reachEpochs, [11.2 14] ); 
clBeta = (1/normFactor);

%normVec = normFactor*rawVals_refit(trainIdx,:)/(1-clAlpha);

%generate fake data from the Kalman model
nVals = 1e5;
fakeVel = zeros(nVals,2);
fakeAct = zeros(nVals,40);
for t=2:nVals
    fakeVel(t,:) = decoder_cl.A * fakeVel(t-1,:)' + mvnrnd([0 0], decoder_cl.Q)';
    fakeAct(t,:) = fakeVel(t,:)*decoder_cl.C + mvnrnd(zeros(1,40), decoder_cl.R);
end
normVec = fakeAct*decoder_cl.matrix(decoder_cl.usedFeatures,:);
normVec = normFactor*normVec/(1-clAlpha);

alphaVals = fliplr(1-logspace(log10(0.01),log10(0.50),10));
betaVals = logspace(log10(2), log10(120), 10);
offlineError = zeros(length(alphaVals), length(betaVals));
for a=1:length(alphaVals)
    for b=1:length(betaVals)
        smoothVals = zeros(size(normVec));
        for t=2:length(normVec)
            smoothVals(t,:) = smoothVals(t-1,:)*alphaVals(a) + (1-alphaVals(a))*betaVals(b)*normVec(t,:);
        end
        offlineError(a,b) = sqrt(mean(sum((smoothVals-fakeVel).^2,2)));
    end
end

bLabels = cell(length(betaVals),1);
for b=1:length(bLabels)
    bLabels{b} = num2str(betaVals(b)/14,2);
end

aLabels = cell(length(alphaVals),1);
for b=1:length(aLabels)
    aLabels{b} = num2str(alphaVals(b),2);
end

%%
%continue refitting
resLast = res_cl;
nRep = 5;
repAB = zeros(nRep,2);
for n=1:nRep
    simAct = resLast.effectorState(:,5:end);

    targDir = bsxfun(@times, resLast.targPos - resLast.pos, 1./matVecMag(resLast.targPos - resLast.pos,2));
    refitVel = bsxfun(@times, targDir, matVecMag(resLast.effectorState(:,3:4),2));
    refitVel(resLast.inTarget,:) = 0;
    trainIdx = 1:(1*size(movCommand_ol,1));

    dec_last = buildTopNDecoderKalman(simAct(trainIdx,:), refitVel(trainIdx,:), size(simAct,2), 'FitA');  
    repAB(n,1) = mean(diag(dec_last.inertiaMatrix));
    [~,rawVals_refit] = applyKalman( dec_last, resLast.effectorState(:,5:end) );
    [normFactor, farFieldStd] = normalizeCommandVectors( resLast.pos, resLast.targPos, ...
        rawVals_refit/(1-clAlpha), resLast.reachEpochs, [11.2 14] ); 
    repAB(n,2) = (1/normFactor);
    
    opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_kalman( E, indStd, controlSignal, state, 0.02, dec_last );
    opts.nReaches = 40;
    resLast = bciSim(opts);  
    visSim( opts, resLast, false, true );
end

%%
%optimal
movTimes = zeros(length(alphaVals),length(betaVals));
for a=1:length(alphaVals)
    disp(num2str(a));
    for b=1:length(betaVals)
        disp(['  ' num2str(b)]);
        
        newDec = decoder_cl;
        newDec.inertiaMatrix(1,1) = alphaVals(a);
        newDec.inertiaMatrix(2,2) = alphaVals(a);
        newDec.matrix = newDec.matrix*(1-alphaVals(a))/(1-clAlpha);
        newDec.matrix = newDec.matrix*betaVals(b)/clBeta;
        
        opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_kalman( E, indStd, controlSignal, state, 0.02, newDec );
        tmp = bciSim(opts);  
        movTimes(a,b) = mean(tmp.ttt);
    end
end

[minTime,minIdx] = min(movTimes(:));
[alphaIdx, betaIdx] = ind2sub(size(movTimes), minIdx);

olBeta_i = interp1(betaVals, 1:length(betaVals), olBeta);
olAlpha_i = interp1(alphaVals, 1:length(alphaVals), olAlpha);
clBeta_i = interp1(betaVals, 1:length(betaVals), clBeta);
clAlpha_i = interp1(alphaVals, 1:length(alphaVals), clAlpha); 

figure('Position',[624   571   570   407]);
hold on
imagesc(movTimes,[min(movTimes(:)) max(movTimes(:))]); 

plot(olBeta_i, olAlpha_i, 'ko', 'LineWidth', 2, 'MarkerSize', 10);
%plot(clBeta_i, clAlpha_i, 'ro', 'LineWidth', 2, 'MarkerSize', 10);
for n=1:nRep
    clBeta_i = [clBeta_i; interp1(betaVals, 1:length(betaVals), repAB(n,2))];
    clAlpha_i = [clAlpha_i; interp1(alphaVals, 1:length(alphaVals), repAB(n,1))];
end
plot(clBeta_i, clAlpha_i, '-ro', 'LineWidth', 2, 'MarkerSize', 6);

plot(betaIdx, alphaIdx, 'wx', 'LineWidth', 2, 'MarkerSize', 10);

xlim([1 length(betaVals)]);
ylim([1 length(alphaVals)]);
colormap(parula);
set(gca,'YDir','normal');
set(gca,'XTick',1:3:length(betaVals),'XTickLabel',bLabels(1:3:end));
set(gca,'YTick',1:3:length(alphaVals),'YTickLabel',aLabels(1:3:end));
xlabel('Beta (TD/s)');
ylabel('Alpha');
title('Average Movement Time (s)');
colorbar;
set(gca,'FontSize',14);
exportPNGFigure(gcf, [resultsDir filesep 'ReFIT sim' filesep 'largeTargExample surface 2']);

%%
figure('Position',[624   571   570   407]);
hold on
imagesc(offlineError,[min(offlineError(:)) 40]); 
xlim([1 length(betaVals)]);
ylim([1 length(alphaVals)]);
colormap(parula);
set(gca,'YDir','normal');
set(gca,'XTick',1:3:length(betaVals),'XTickLabel',bLabels(1:3:end));
set(gca,'YTick',1:3:length(alphaVals),'YTickLabel',aLabels(1:3:end));
xlabel('Beta (TD/s)');
ylabel('Alpha');
title('Reconstruction Error (RMSE)');
colorbar;
set(gca,'FontSize',14);
plot(olBeta_i, olAlpha_i, 'ko', 'LineWidth', 2, 'MarkerSize', 10);
plot(clBeta_i, clAlpha_i, '-ro', 'LineWidth', 2, 'MarkerSize', 6);
plot(betaIdx, alphaIdx, 'wx', 'LineWidth', 2, 'MarkerSize', 10);
exportPNGFigure(gcf, [resultsDir filesep 'ReFIT sim' filesep 'largeTargExample offlineSurface']);

%%
newDec = decoder_cl;
newDec.inertiaMatrix(1,1) = alphaVals(alphaIdx);
newDec.inertiaMatrix(2,2) = alphaVals(alphaIdx);
newDec.matrix = newDec.matrix*(1-alphaVals(alphaIdx))/(1-clAlpha);
newDec.matrix = newDec.matrix*betaVals(betaIdx)/clBeta;

opts.effector.stepForwardFcn = @(state, controlSignal)integrateForward_withNeurons_kalman( E, indStd, controlSignal, state, 0.02, newDec );
res_opt = bciSim(opts);  
        
figure('Position',[624         659        1085         319]);
subplot(1,3,1);
plotColoredTrajectories2D( res_ol.pos, res_ol.targNumByEpoch, res_ol.reachEpochs(1:opts.nReaches,:), 0, unique(res_ol.targPos,'rows'), mean(res_ol.targRad), true );
xlim([-18 18]);
ylim([-18 18]);
axis off;
title(['First Block (' num2str(mean(res_ol.ttt),3) 's)']);

subplot(1,3,2);
plotColoredTrajectories2D( res_cl.pos, res_cl.targNumByEpoch, res_cl.reachEpochs(1:opts.nReaches,:), 0, unique(res_cl.targPos,'rows'), mean(res_cl.targRad), true );
xlim([-18 18]);
ylim([-18 18]);
axis off;
title(['After ReFIT Recalibration (' num2str(mean(res_cl.ttt),3) 's)']);

subplot(1,3,3);
plotColoredTrajectories2D( res_opt.pos, res_opt.targNumByEpoch, res_opt.reachEpochs(1:opts.nReaches,:), 0, unique(res_opt.targPos,'rows'), mean(res_opt.targRad), true );
xlim([-18 18]);
ylim([-18 18]);
axis off;
title(['Optimal Parameters (' num2str(minTime,3) 's)']);

exportPNGFigure(gcf, [resultsDir filesep 'ReFIT sim' filesep 'smallTargExample traj 2']);
    
%%
save([resultsDir filesep 'ReFIT sim' filesep 'smallTargExampleData']);

    