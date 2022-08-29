%%
%TODO: add delay to the linear filter
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = [paths.dataPath '/Derived/rnnDecoding_monk'];
outDir = [paths.dataPath '/Derived/rnnDecoding_monk/'];

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
    load([dataDir filesep sessionList(s).name]);

    %%
    alpha = [0.6:0.02:0.94];
    lagSteps = 0:10;
    xValOut_ridge = zeros(size(data.cursorPos,1),2);
    xValOut_lin = zeros(size(data.cursorPos,1),2);
    
    nFolds = 6;
    fold_R = zeros(nFolds,2);
    fold_angErr = zeros(nFolds,2);
    fold_magR = zeros(nFolds,2);
    fold_mse = zeros(nFolds,2);
    foldIdx = cell(nFolds,2);
    allDec = cell(nFolds,2);
    for n=1:nFolds
        disp(['Fold ' num2str(n)]);
        
        trainIdx = find(C.training(n));
        testIdx = find(C.test(n));
        rIdxTrain = expandEpochIdx(reachEpochs(trainIdx,:));
        rIdxTest = expandEpochIdx(reachEpochs(testIdx,:));
        
        %linear first order
        dec_lf = buildLFDecoder( reachEpochs(trainIdx,:), alpha, lagSteps, data.spikes, data.handVel(:,1:2) );
        
        tmpDecFinal = applyLFDecoder( dec_lf, data.spikes );
        xValOut_lin(rIdxTest,:) = tmpDecFinal(rIdxTest,:);
        
        %Weiner filter
        dec_wf = buildWFDecoder( data.spikes, data.handVel(:,1:2), rIdxTrain );
        tmpDecFinal = applyWFDecoder( dec_wf, data.spikes, rIdxTest );
        xValOut_ridge(rIdxTest,:) = tmpDecFinal;
    
        targetValues = data.handVel(:,1:2);
        evalIdx = 2;
        
        fold_R(n,1) = mean(diag(corr(xValOut_ridge(rIdxTest,evalIdx), targetValues(rIdxTest,evalIdx))));
        fold_R(n,2) = mean(diag(corr(xValOut_lin(rIdxTest,evalIdx), targetValues(rIdxTest,evalIdx))));
        
        fold_angErr(n,1) = (180/pi)*nanmean(abs(getAngularError(xValOut_ridge(rIdxTest,:), targetValues(rIdxTest,:))));
        fold_angErr(n,2) = (180/pi)*mean(abs(getAngularError(xValOut_lin(rIdxTest,:), targetValues(rIdxTest,:))));
        
        fold_magR(n,1) = mean(diag(corr(matVecMag(xValOut_ridge(rIdxTest,:),2), ...
            matVecMag(targetValues(rIdxTest,:),2))));
        fold_magR(n,2) = mean(diag(corr(matVecMag(xValOut_lin(rIdxTest,:),2), ...
            matVecMag(targetValues(rIdxTest,:),2))));
        
        fold_mse(n,1) = mean(mean((xValOut_ridge(rIdxTest,:) - targetValues(rIdxTest,:)).^2));
        fold_mse(n,2) = mean(mean((xValOut_lin(rIdxTest,:) - targetValues(rIdxTest,:)).^2));
        
        allDec{n,1} = dec_lf;
        allDec{n,2} = dec_wf;
    end
    
    coefIdx = (1:50)+1;
    allFilt = [];
    for n=1:192
        allFilt = [allFilt; allDec{1,2}.curW(2,coefIdx)];
        coefIdx = coefIdx + 50;
    end
    figure;
    imagesc(allFilt);
    
    mkdir([outDir filesep 'controlDecoders']);
    save([outDir filesep 'controlDecoders' filesep sessionList(s).name],'fold_R','fold_angErr','fold_magR','fold_mse',...
        'xValOut_ridge','xValOut_lin','foldIdx','allDec');
end %session


%%
%todo: workspace size normalization, redo posErrForFit to take into account
%delays / intertrial pauses and reflect desired RNN target, test limited RNN runs on T5 vs. control decoders to get pipeline in place
