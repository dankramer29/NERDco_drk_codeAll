%%
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = [paths.dataPath '/Derived/2dDatasets'];
outDir = [paths.dataPath '/Derived/rnnDecoding_2dDatasets_v2/'];

%%
sessionList = dir([dataDir filesep '*.mat']);
remIdx = [];
for s=1:length(sessionList)
    if strfind(sessionList(s).name,'features')
        remIdx = [remIdx, s];
    end
end
sessionList(remIdx) = [];

for s = 1:length(sessionList)

    disp(sessionList(s).name);
    
    %%
    %load dataset
    tmp = load([dataDir filesep sessionList(s).name]);
    dat = tmp.dataset;
    dat.trialEpochs(dat.trialEpochs>length(dat.cursorPos)) = length(dat.cursorPos);
    
    remIdx = [];
    for b=1:length(dat.blockList)
        if dat.decodingClick(b)
            trlIdx = find(dat.blockNums(dat.trialEpochs(:,1))==dat.blockList(b));
            remIdx = [remIdx; trlIdx];
        end
    end
    
    dat.trialEpochs(remIdx,:) = [];
    dat.instructedDelays(remIdx,:) = [];
    dat.intertrialPeriods(remIdx,:) = [];
    dat.isSuccessful(remIdx) = [];
    
    if length(dat.isSuccessful)<100
        continue;
    end

    %%
    sessionName = sessionList(s).name(1:(end-4));
    tm = load([outDir filesep 'trainingMeta' filesep sessionName '.mat'],'out');
    %tm.out.in.kin.targDist = tm.out.in.kin.targDist / tm.out.in.maxDist;
    
    %%
    csWeight = linspace(0,1,20);
    alpha = [0.6:0.02:0.94];
    xValOut = zeros(size(dat.cursorPos,1),2);
    xValOut_lin = zeros(size(dat.cursorPos,1),2);
    
    nFolds = 6;
    fold_R = zeros(nFolds,2);
    fold_angErr = zeros(nFolds,2);
    fold_magR = zeros(nFolds,2);
    fold_mse = zeros(nFolds,2);
    foldIdx = cell(nFolds,2);
    for n=1:nFolds
        disp(['Fold ' num2str(n)]);
        
        trainIdx = find(tm.out.C.training(n));
        testIdx = find(tm.out.C.test(n));
        rIdxTest = expandEpochIdx(tm.out.in.reachEpochs(testIdx,:));
        rIdxTrain = expandEpochIdx(tm.out.in.reachEpochs(trainIdx,:));
        foldIdx{n,1} = rIdxTrain;
        foldIdx{n,2} = rIdxTest;
        
        %first fit 4-component model
        inFold = tm.out.in;
        inFold.reachEpochs = inFold.reachEpochs(tm.out.C.training(n),:);
        inFold.reachEpochs_fit = inFold.reachEpochs_fit(tm.out.C.training(n),:);
        foldModel = fitPhasicAndFB_6(inFold);
        out = applyPhasicAndFB(inFold, foldModel);
        
        %sweep to find best parameters for magnitude decoder
        dec = buildMagDec_rnn( inFold.reachEpochs, tm.out.in.kin.posErrForFit, out.popResponse(:,1:2), out.popResponse(:,3), alpha, csWeight );

        %apply to test set
        tmpDecFinal = applyMagDec_rnn( dec, out.popResponse(:,1:2), out.popResponse(:,3) );
        xValOut(rIdxTest,:) = tmpDecFinal(rIdxTest,:);
        
        %simple linear decoder
        dec = buildMagDec_rnn( inFold.reachEpochs, tm.out.in.kin.posErrForFit, out.popResponse(:,1:2), out.popResponse(:,3), alpha, 0 );

        %apply to test set
        tmpDecFinal = applyMagDec_rnn( dec, out.popResponse(:,1:2), out.popResponse(:,3) );
        xValOut_lin(rIdxTest,:) = tmpDecFinal(rIdxTest,:);
        
        fold_R(n,1) = mean(diag(corr(xValOut(rIdxTest,:), tm.out.in.kin.posErrForFit(rIdxTest,:))));
        fold_R(n,2) = mean(diag(corr(xValOut_lin(rIdxTest,:), tm.out.in.kin.posErrForFit(rIdxTest,:))));
        
        fold_angErr(n,1) = (180/pi)*nanmean(abs(getAngularError(xValOut(rIdxTest,:), tm.out.in.kin.posErrForFit(rIdxTest,:))));
        fold_angErr(n,2) = (180/pi)*mean(abs(getAngularError(xValOut_lin(rIdxTest,:), tm.out.in.kin.posErrForFit(rIdxTest,:))));
        
        fold_magR(n,1) = mean(diag(corr(matVecMag(xValOut(rIdxTest,:),2), ...
            matVecMag(tm.out.in.kin.posErrForFit(rIdxTest,:),2))));
        fold_magR(n,2) = mean(diag(corr(matVecMag(xValOut_lin(rIdxTest,:),2), ...
            matVecMag(tm.out.in.kin.posErrForFit(rIdxTest,:),2))));
        
        fold_mse(n,1) = mean(mean((xValOut(rIdxTest,:) - tm.out.in.kin.posErrForFit(rIdxTest,:)).^2));
        fold_mse(n,2) = mean(mean((xValOut_lin(rIdxTest,:) - tm.out.in.kin.posErrForFit(rIdxTest,:)).^2));
    end
    
    %fit full model
    fullModel = fitPhasicAndFB_6(tm.out.in);
    fullModel_out = applyPhasicAndFB(tm.out.in, fullModel);
        
    mkdir([outDir filesep 'controlDecoders']);
    save([outDir filesep 'controlDecoders' filesep sessionName '.mat'],'fold_R','fold_angErr','fold_magR','fold_mse',...
        'xValOut','xValOut_lin','foldIdx','fullModel','fullModel_out');
end %session


%%
%todo: workspace size normalization, redo posErrForFit to take into account
%delays / intertrial pauses and reflect desired RNN target, test limited RNN runs on T5 vs. control decoders to get pipeline in place
