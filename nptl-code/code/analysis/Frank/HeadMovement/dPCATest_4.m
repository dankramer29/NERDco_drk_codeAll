%%
%one dimensional tuning with two effectors & different subspace alignments
xAxis = linspace(-2,2,200);
tuningProfile = normpdf(xAxis,0,1)';
tuningProfile = tuningProfile - min(tuningProfile);
tuningProfile = [zeros(100,1); tuningProfile; zeros(100,1)];

nCon = 6;
conditionTuning = linspace(-1,1,nCon);

latentFactors = zeros(length(tuningProfile),nCon);
for t=1:nCon
    latentFactors(:,t) = tuningProfile * conditionTuning(t);
end

latentFactors_ci = zeros(length(tuningProfile),nCon);
for t=1:nCon
    latentFactors_ci(:,t) = tuningProfile * 1;
end

nCell = 100;
tuningCoef = cell(1,1);
tuningCoef{1} = randn(nCell,2);

allLF = [];
factorCodes = [];
eventIdx = [];
nTrials = 3;
currentIdx = 1;

for c=1:nCon
    for t=1:nTrials
        allLF = [allLF; latentFactors(:,c), latentFactors_ci(:,c)];
        factorCodes = [factorCodes; c];
        eventIdx = [eventIdx; currentIdx+100];
        currentIdx = currentIdx + length(tuningProfile);
    end
end

nReps = 20;
noiseFactors = [0.5,1.0,2.0,4.0,8.0];
sizeMeasures = zeros(length(noiseFactors),nReps,3);

for noiseIdx=1:length(noiseFactors)
    for repIdx=1:nReps
        disp(repIdx);

        neuralActivity = cell(length(tuningCoef),2);
        for t=1:length(tuningCoef)
            neuralActivity{t,1} = allLF * tuningCoef{t}';
            neuralActivity{t,2} = neuralActivity{t,1} + noiseFactors(noiseIdx)*randn(size(neuralActivity{t,1}));
        end

        smoothActivity = gaussSmooth_fast(neuralActivity{t,2}, 3.0);
        dPCA_out = apply_dPCA_simple( smoothActivity, eventIdx, ...
            factorCodes, [-100,300], 0.010, {'CI','CD'}, 10);
        close(gcf);

        cdIdx = find(dPCA_out.whichMarg==1);
        sizeMeasures(noiseIdx,repIdx,1) = (dPCA_out.Z(cdIdx(1),end,201)-dPCA_out.Z(cdIdx(1),1,201))/2;

        cdIdx = find(dPCA_out.pca_result.whichMarg==1);
        sizeMeasures(noiseIdx,repIdx,2) = (dPCA_out.pca_result.Z(cdIdx(1),end,201)-dPCA_out.pca_result.Z(cdIdx(1),1,201))/2;
 
        cdIdx = find(dPCA_out.whichMarg==1);
        sizeMeasures(noiseIdx,repIdx,3) = (1/norm(dPCA_out.W(:,cdIdx(1))))*(dPCA_out.Z(cdIdx(1),end,201)-dPCA_out.Z(cdIdx(1),1,201))/2;
        
        %cross-validated pca
%         for x=1:nTrials
%             testIdx = x:nTrials:length(eventIdx);
%             trainIdx = setdiff(1:length(eventIdx),testIdx);
%             
%             concatDatTrain = triggeredAvg( smoothActivity, eventIdx(trainIdx), [-100,300] );
%             concatDatTest = triggeredAvg( smoothActivity, eventIdx(testIdx), [-100,300] );
%             
%             marginalizedTrain = concatDatTrain - nanmean(concatDatTrain(:));
%             marginalizedTrain = marginalizedTrain - nanmean(marginalizedTrain,1);
%             marginalizedTrain = permute(marginalizedTrain,[3 1 2]);
%             marginalizedTrain = marginalizedTrain(:,:)';
%             [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(marginalizedTrain); 
%             
%             marginalizedTest = concatDatTest - nanmean(concatDatTest(:));
%             marginalizedTest = marginalizedTest - nanmean(marginalizedTest,1);
%             
%             pca_out = apply_dPCA_PCAOnly( smoothActivity, eventIdx, ...
%                 factorCodes, [-100,300], 0.010, {'CI','CD'}, 20 );
%         end
        
%         dPCA_out_cval = apply_dPCA_simple( smoothActivity, eventIdx, ...
%             factorCodes, [-100,300], 0.010, {'CI','CD'}, 20, 'xval');
%         close(gcf);
%         
%         cdIdx = find(dPCA_out_cval.cval.whichMarg==1);
%         sizeMeasures(noiseIdx,repIdx,3) = (dPCA_out_cval.cval.Z(cdIdx(1),end,201)-dPCA_out_cval.cval.Z(cdIdx(1),1,201))/2;
    end
end

meanSize = squeeze(mean(abs(sizeMeasures),2));
trueSize = norm(tuningCoef{1}(:,1))*max(tuningProfile);

figure;
hold on;
plot(noiseFactors, meanSize, '-o');
plot(get(gca,'XLim'),[trueSize, trueSize],'--k');
legend({'dPCA','PCA','dPCA Norm Correction'});

dPCA_out = cell(length(tuningCoef),1);
for t=1:length(tuningCoef)
    smoothActivity = gaussSmooth_fast(neuralActivity{t,2}, 3.0);
    dPCA_out{t} = apply_dPCA_simple( smoothActivity, eventIdx, ...
        factorCodes, [-100,300], 0.010, {'CI','CD'}, 20, 'xval' );
         
    singleColors = jet(nCon)*0.8;
    lineArgs_single = cell(nCon,1);
    for x=1:nCon
        lineArgs_single{x} = {'Color',singleColors(x,:),'LineWidth',2,'LineStyle','-'};
    end

    labels = {'CI','CD'};
    layoutInfo.nPerMarg = 1;
    layoutInfo.fPos = [49   846   776   213];
    layoutInfo.gap = [0.03 0.01];
    layoutInfo.marg_h = [0.07 0.02];
    layoutInfo.marg_w = [0.30 0.10];
    layoutInfo.colorFactor = 2;
    layoutInfo.textLoc = [0.7,0.2];
    layoutInfo.plotLayout = 'horizontal';
    layoutInfo.verticalBars = [0,1.5];

    timeWindow = [-100,300];
    timeAxis = (timeWindow(1):timeWindow(2))*0.01;
    [yAxesFinal, allHandles, axFromSingle] = general_dPCA_plot( dPCA_out{t}.cval, timeAxis, lineArgs_single, ...
        labels, 'sameAxes', [], [-6,6], dPCA_out{t}.cval.dimCI, singleColors );
    
    %%
    %straight PCA of the mean
    [yAxesFinal, allHandles, axFromSingle] = general_dPCA_plot( dPCA_out{t}.pca_result, timeAxis, lineArgs_single, ...
        labels, 'sameAxes', [], [-6,6], [] );
    
    %%
    %unbiased estimators
    unbiasedMeanScores_cd = zeros(10,6,401);
    unbiasedMeanScores_ci = zeros(10,6,401);
    
    for x=1:length(eventIdx)
        trainIdx = setdiff(1:length(eventIdx),x);
        testIdx = x;
        
        %fit PCA of the means on the trainIdx, fit mean on the testIdx, then combine
        
    end
    
end

%%
nData = 20;
u1 = randn(nData,100);
u2 = randn(nData,100)+1;
[BETA,SIGMA,RESID,VARPARAM]=mvregress([ones(nData*2,1),[-ones(nData,1); ones(nData,1)]],[u1; u2],'algorithm','cwls');

%%
nGrandRuns = 100;
grandErr = zeros(nGrandRuns,1);
for grandRunIdx=1:nGrandRuns
    disp(grandRunIdx);
    
    nData = 2;
    nDim = 100;
    allDimSamples = cell(nDim,1);
    trueMeanDist = sqrt(nDim)/2;
    
    for dimIdx=1:nDim
        u1 = randn(nData,1);
        u2 = randn(nData,1)+1;

        X = [ones(nData*2,1),[-ones(nData,1); ones(nData,1)]];
        Y = [u1; u2];

        beta_hat = (X'*X)\X'*Y;

        u_0 = zeros(2,1);
        del_0 = zeros(2,2);
        a_0 = 0;
        b_0 = 0;

        del_n = X'*X + del_0;
        inv_del_n = inv(del_n);
        u_n = (del_n)\(X'*X*beta_hat + del_0*u_0);
        a_n = a_0 + length(Y)/2;
        b_n = b_0 + (1/2)*(Y'*Y + u_0'*del_0*u_0 - u_n'*del_n*u_n);

        nSamples = 1000;
        jointSamples = zeros(nSamples,length(beta_hat)+1);
        for n=1:nSamples
            %first sample variance
            sigInv = gamrnd(a_n,1./b_n);
            sig_sample = 1/sigInv;

            %then sample beta
            beta_sample = mvnrnd(u_n, sig_sample*inv_del_n); 

            jointSamples(n,:) = [sig_sample, beta_sample];
        end

        allDimSamples{dimIdx} = jointSamples;
    end

    %get distribution of effect size magnitude
    allEffVec = horzcat(allDimSamples{:});
    allEffVec = allEffVec(:,3:3:end);

    effMag = sqrt(sum(allEffVec.^2,2));

    grandErr(grandRunIdx,1) = norm(mean(effMag)-trueMeanDist);
end

%%
nRuns = 1000;
nData = 2;
nDim = 100;
runEst = zeros(nRuns,2);

for runIdx=1:nRuns
    u1 = randn(nData,nDim);
    u2 = randn(nData,nDim)+1.0;

    X = [ones(nData*2,1),[-ones(nData,1); ones(nData,1)]];
    Y = [u1; u2];

    squareEst = zeros(nData,1);
    for x=1:nData
        trainIdx = setdiff(1:nData, x)';
        allTrainIdx = [trainIdx; trainIdx+nData];

        leaveOutIdx = [x; x+nData];

        beta_train = (X(allTrainIdx,:)'*X(allTrainIdx,:))\X(allTrainIdx,:)'*Y(allTrainIdx,:);
        beta_leavOut = (X(leaveOutIdx,:)'*X(leaveOutIdx,:))\X(leaveOutIdx,:)'*Y(leaveOutIdx,:);

        squareEst(x) = beta_train(2,:)*beta_leavOut(2,:)';
    end
    
    runEst(runIdx,1) = mean(squareEst);
    
    beta_all = (X'*X)\X'*Y;
    runEst(runIdx,2) = beta_all(2,:)*beta_all(2,:)';
end

figure
plot(runEst,'o');

figure; 
plot(sign(runEst).*sqrt(abs(runEst)),'o');

v = 100;
sigma = 1;

u_1 = sigma*sqrt(pi/2)*laguerreL(1/2,-(v^2)/(2*sigma^2));

%%
nGrandRuns = 10;
grandErr = zeros(nGrandRuns,2);
grandErr_square = zeros(nGrandRuns,2);
grandStats = cell(nGrandRuns,1);
trueDists = zeros(nGrandRuns,2);

for grandRunIdx=1:nGrandRuns
    disp(grandRunIdx);
    
    nData = 2;
    nDim = 100;
    allDimSamples = cell(nDim,1);
    
    u_0 = zeros(2,1);
    del_0 = [10.0 0; 0 10.0];
    inv_del_0 = inv(del_0);
    v_0 = 1;
    s_0 = 1;
    
    a_0 = v_0/2;
    b_0 = (1/2)*v_0*(s_0^2);
    
    gStats_allDim = zeros(3,nDim);
    for dimIdx=1:nDim        
        grandSigInv = gamrnd(a_0,1./b_0);
        grandSig = sqrt(1./grandSigInv);
        
        tmp = mvnrnd(u_0, grandSig.^2*inv_del_0);
        grandMean = tmp(1);
        grandMeanDiff = tmp(2);
        
        gStats_allDim(:,dimIdx) = [grandSig, grandMean, grandMeanDiff];
    end
    
    gStats_allDim(1,:) = 1;
    gStats_allDim(2,:) = 0;
    gStats_allDim(3,:) = 0.5;

    grandStats{grandRunIdx} = gStats_allDim;
    
    trueMeanDist = sqrt(sum(gStats_allDim(3,:).^2));
    trueDists(grandRunIdx,1) = trueMeanDist;
    
    trueMeanDistSquare = sum(gStats_allDim(3,:).^2);
    trueDists(grandRunIdx,2) = trueMeanDistSquare;
    
    u1 = randn(nData,nDim).*repmat(gStats_allDim(1,:),nData,1)+gStats_allDim(2,:)-gStats_allDim(3,:);
    u2 = randn(nData,nDim).*repmat(gStats_allDim(1,:),nData,1)+gStats_allDim(2,:)+gStats_allDim(3,:);
        
    for dimIdx=1:nDim
        X = [ones(nData*2,1),[-ones(nData,1); ones(nData,1)]];
        Y = [u1(:,dimIdx); u2(:,dimIdx)];

        beta_hat = (X'*X)\X'*Y;

        del_n = X'*X + del_0;
        inv_del_n = inv(del_n);
        u_n = (del_n)\(X'*X*beta_hat + del_0*u_0);
        a_n = a_0 + length(Y)/2;
        b_n = b_0 + (1/2)*(Y'*Y + u_0'*del_0*u_0 - u_n'*del_n*u_n);

        nSamples = 1000;
        jointSamples = zeros(nSamples,length(beta_hat)+1);
        for n=1:nSamples
            %first sample variance
            sigInv = gamrnd(a_n,1./b_n);
            sig_sample = sqrt(1/sigInv);

            %then sample beta
            beta_sample = mvnrnd(u_n, sig_sample^2*inv_del_n); 

            jointSamples(n,:) = [sig_sample, beta_sample];
        end

        allDimSamples{dimIdx} = jointSamples;
    end

    %get distribution of effect size magnitude
    allEffVec = horzcat(allDimSamples{:});
    allEffVec = allEffVec(:,3:3:end);

    effMag = sqrt(sum(allEffVec.^2,2));
    grandErr(grandRunIdx,1) = mean(effMag)-trueMeanDist;
    grandErr_square(grandRunIdx,1) = mean(sum(allEffVec.^2,2))-trueMeanDistSquare;
    
    %estimate with unbiased estimator
    X = [ones(nData*2,1),[-ones(nData,1); ones(nData,1)]];
    Y = [u1; u2];

    squareEst = zeros(nData,1);
    for x=1:nData
        trainIdx = setdiff(1:nData, x)';
        allTrainIdx = [trainIdx; trainIdx+nData];

        leaveOutIdx = [x; x+nData];

        beta_train = (X(allTrainIdx,:)'*X(allTrainIdx,:))\X(allTrainIdx,:)'*Y(allTrainIdx,:);
        beta_leavOut = (X(leaveOutIdx,:)'*X(leaveOutIdx,:))\X(leaveOutIdx,:)'*Y(leaveOutIdx,:);

        squareEst(x) = beta_train(2,:)*beta_leavOut(2,:)';
    end
    
    meanSquare = mean(squareEst);
    runEst = sign(meanSquare).*sqrt(abs(meanSquare));
    grandErr(grandRunIdx,2) = mean(runEst)-trueMeanDist;
    grandErr_square(grandRunIdx,2) = meanSquare-trueMeanDistSquare;
end