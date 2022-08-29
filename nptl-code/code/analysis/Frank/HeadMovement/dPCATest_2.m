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
nTrials = 10;
currentIdx = 1;

for c=1:nCon
    for t=1:nTrials
        allLF = [allLF; latentFactors(:,c), latentFactors_ci(:,c)];
        factorCodes = [factorCodes; c];
        eventIdx = [eventIdx; currentIdx+100];
        currentIdx = currentIdx + length(tuningProfile);
    end
end

neuralActivity = cell(length(tuningCoef),2);
for t=1:length(tuningCoef)
    neuralActivity{t,1} = allLF * tuningCoef{t}';
    neuralActivity{t,2} = neuralActivity{t,1} + 2*randn(size(neuralActivity{t,1}));
end

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
end

%%
nData = 20;
u1 = randn(nData,100);
u2 = randn(nData,100)+1;
[BETA,SIGMA,RESID,VARPARAM]=mvregress([ones(nData*2,1),[-ones(nData,1); ones(nData,1)]],[u1; u2],'algorithm','cwls');

%%
nData = 2;
nDim = 2;
allDimSamples = cell(nDim,1);

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

figure;
hist(effMag,200);

%%
nRuns = 10000;
nData = 18;
nDim = 100;
runEst = zeros(nRuns,2);

for runIdx=1:nRuns
    u1 = 2*randn(nData,nDim);
    u2 = 2*randn(nData,nDim)+1.0;

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
nboot = 1000;
%bootfun = @(d1,d2)(norm(mean(d1)-mean(d2)));
bootfun = @(d1,d2)(cvMeanDiffMagnitude_unbiased( d1, d2 ));
d1 = randn(10,100);
d2 = randn(10,100)+1;

[sampleEstimate, projPoints1, projPoints2] = bootfun(d1,d2);
[CI,bstat] = bootci(nboot,{bootfun,d1,d2},'type','bca');

[ diffNorm, rawProjPoints_1, rawProjPoints_2 ] = ;

%%
v1 = [1,1]; 
v2 = [1,-1];
v1_c = v1-mean(v1);
v2_c = v2-mean(v2);

figure; 
plot([0,v1(1)],[0,v1(2)],'-o'); 
hold on; 
plot([0,v2(1)],[0,v2(2)],'-ro'); 
axis equal;

figure; 
plot([0,v1_c(1)],[0,v1_c(2)],'-o'); 
hold on; 
plot([0,v2_c(1)],[0,v2_c(2)],'-ro'); 
axis equal;