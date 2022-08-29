addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/submodules/nptlDataExtraction'));

dataDir = '/Users/frankwillett/Data/t5/';
lfadsPreDir = '/Users/frankwillett/Data/pre_LFADS/';
lfadsPostDir = '/Users/frankwillett/Data/post_LFADS/';
datasets = {'t5.2017.04.03',[4 5 6 11 12 13]; %5D
    't5.2017.03.22',[4 5 6 11 12 13]; %3D
    't5.2017.04.12',[5 6 7 12 13 14]; %4D
    };

%%
for d=1:length(datasets)
    %%
    sessionPath = [dataDir datasets{d,1} filesep];
    flDir = [sessionPath 'Data' filesep 'FileLogger' filesep];
    cd(sessionPath);
    
    %load all blocks
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
        
    R = [];
    for b=1:length(datasets{d,2})
        tmp = onlineR(loadStream([flDir num2str(datasets{d,2}(b)) '/'], datasets{d,2}(b)));
        R = [R, tmp];
    end
    
    %load LFADS data
    datasetNameDash = strrep(datasets{d},'.','-');
    fileTrain = [lfadsPostDir datasetNameDash filesep 'model_runs_h5_train_posterior_sample_and_average'];
    fileValid = [lfadsPostDir datasetNameDash filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    fileInput = [lfadsPreDir datasetNameDash filesep datasetNameDash '.h5'];

    resultTrain = hdf5load(fileTrain);
    resultValid = hdf5load(fileValid);
    resultInput = hdf5load(fileInput);

    matData = load([lfadsPreDir datasetNameDash filesep 'matlabDataset.mat']);
    
    %%
    lfads_rates = zeros(size(matData.all_data));
    lfads_rates(:,:,matData.trainIdx) = resultTrain.output_dist_params;
    lfads_rates(:,:,matData.validIdx) = resultValid.output_dist_params;
    
    tmp = lfads_rates(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(tmp);
    
    %%
    %just axes targets
    [targList, ~, targCodes] = unique(matData.targPos, 'rows');
    targToFind = [1 0 0 0 0;
        -1 0 0 0 0;
        0 1 0 0 0;
        0 -1 0 0 0;
        0 0 1 0 0;
        0 0 -1 0 0;
        0 0 0 1 0;
        0 0 0 -1 0;
        0 0 0 0 1;
        0 0 0 0 -1;]*0.1;
    conCodes = zeros(size(targToFind,1), 1);
    for t=1:size(targToFind,1)
        tmp = sum(abs(bsxfun(@plus, targList, -targToFind(t,:))),2);
        [~,minIdx] = min(tmp);
        conCodes(t) = minIdx;
    end
    
    finalTrlIdx = [];
    finalCodes = [];
    for c=1:length(conCodes)
        trlIdx = find(targCodes==conCodes(c));
        finalTrlIdx = [finalTrlIdx; trlIdx];
        finalCodes = [finalCodes; repmat(c,length(trlIdx),1)];
    end
    
    %%
    %blurred average
    [targList, ~, targCodes] = unique(matData.targPos, 'rows');
    targToFind = [1 0 0 0 0;
        -1 0 0 0 0;
        0 1 0 0 0;
        0 -1 0 0 0;
        0 0 1 0 0;
        0 0 -1 0 0;
        0 0 0 1 0;
        0 0 0 -1 0;
        0 0 0 0 1;
        0 0 0 0 -1;]*0.1;
    isOuter = ~all(matData.targPos==0,2);

    finalTrlIdx = [];
    finalCodes = [];
    for c=1:size(targToFind,1)
        [~,activeDim] = max(abs(targToFind(c,:)));
        trlIdx = find(sign(targToFind(c,activeDim)) == sign(matData.targPos(:,activeDim)) & isOuter);
        
        finalTrlIdx = [finalTrlIdx; trlIdx];
        finalCodes = [finalCodes; repmat(c,length(trlIdx),1)];
    end

    %%
    %dPCA to LFADS
    unrollRates = lfads_rates(:,:,finalTrlIdx);
    unrollRates = unrollRates(:,:)';
    unrollStartIdx = 1:200:length(unrollRates);
    
    dPCA_out_lfads = apply_dPCA_simple( unrollRates, unrollStartIdx, ...
        finalCodes, [0 199], 0.01, {'Condition-dependent', 'Condition-independent'} );

    colors = hsv(10)*0.8;
    newLineArgs = cell(size(colors,1),1);
    for c=1:size(colors,1)
        newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
    end
    margNamesShort = {'Dir','CI'};
    oneFactor_dPCA_plot( dPCA_out_lfads, [0 199], newLineArgs, margNamesShort, 'zoomedAxes' );  
    
    %%
    %dPCA to raw data
    unrollRates = matData.all_data(:,:,finalTrlIdx);
    unrollRates = gaussSmooth_fast(unrollRates(:,:)', 3);
    unrollStartIdx = 1:200:length(unrollRates);
    
    dPCA_out_raw = apply_dPCA_simple( unrollRates, unrollStartIdx, ...
        finalCodes, [0 199], 0.01, {'Condition-dependent', 'Condition-independent'} );

    colors = hsv(10)*0.8;
    newLineArgs = cell(size(colors,1),1);
    for c=1:size(colors,1)
        newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
    end
    margNamesShort = {'Dir','CI'};
    oneFactor_dPCA_plot( dPCA_out_raw, [0 199], newLineArgs, margNamesShort, 'zoomedAxes' );  

    %%
    %single trial 
    dPCA_SCORE  = unroll_lfads * dPCA_out_lfads.W;
    dPCA_SCORE = bsxfun(@plus, dPCA_SCORE, -mean(dPCA_SCORE));
    dPCA_SCORE = reshape(dPCA_SCORE', [20, size(matData.all_data,2), size(matData.all_data,3)]);
    dPCA_CI = dPCA_SCORE(dPCA_out_lfads.whichMarg==2,:,:);
    dPCA_CD = dPCA_SCORE(dPCA_out_lfads.whichMarg==1,:,:);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED_raw] = pca(unroll_lfads);
    SCORE = reshape(SCORE', size(matData.all_data));
    
    trlIdx = finalTrlIdx;
    
    %%
    figure
    for t=1:length(trlIdx)
        subtightplot(5,5,t);
        hold on
        plot(dPCA_CI(:,:,trlIdx(t))','LineWidth',2);
    end
    
    figure
    for t=1:length(trlIdx)
        subtightplot(5,5,t);
        hold on
        imagesc(dPCA_CI(:,:,trlIdx(t)));
        axis tight;
    end
    
    %%
    figure
    for t=1:length(trlIdx)
        subtightplot(5,5,t);
        hold on
        plot(dPCA_CD(1:5,:,trlIdx(t))','LineWidth',2);
    end
    
    figure
    for t=1:length(trlIdx)
        subtightplot(5,5,t);
        hold on
        imagesc(dPCA_CD(1:5,:,trlIdx(t)));
        axis tight;
    end
    
    %%
    figure
    hold on
    for t=1:length(trlIdx)
        tmp = squeeze(SCORE(1:10,:,trlIdx(t)));
        neuralSpeed = matVecMag(diff(tmp'),2);
        plot(neuralSpeed,'LineWidth',2);
    end
    
    figure
    hold on
    for t=1:length(trlIdx)
        tmp = squeeze(SCORE(1:10,:,trlIdx(t)));
        neuralMod = matVecMag(tmp',2);
        plot(neuralMod,'LineWidth',2);
    end
    
    figure
    hold on
    for t=1:length(trlIdx)
        neuralState = squeeze(SCORE(1:10,:,trlIdx(t)))';
        neuralVel = diff(neuralState);
        neuralVel = bsxfun(@times, neuralVel, 1./matVecMag(neuralVel,2));
        neuralState = bsxfun(@times, neuralState, 1./matVecMag(neuralState,2));
        
        for t=1:199
            neuralAngle(t) = subspace(neuralState(t,:)', neuralVel(t,:)');
        end
        plot(neuralAngle,'LineWidth',2);
    end
    
    
    linSysR2 = zeros(10,2);
    binIdx = 1:20;
    for b=1:10
        tmp = SCORE(1:10,binIdx,:);
        
        binIdx = binIdx+20;
    end
    
    %%
    %get CI dimension and apply on single trial
    CI_dim = find(dPCA_out_lfads.whichMarg==2);
    CI_dim = CI_dim(1);
    
    figure
    hold on
    for t=1:10
        ci = dPCA_out_lfads.W(:,CI_dim)' * lfads_rates(:,:,t); 
        plot(ci,'LineWidth',2);
    end
    
    CI_dim = find(dPCA_out_raw.whichMarg==2);
    CI_dim = CI_dim(1);
    
    figure
    hold on
    for t=1:10
        ci = gaussSmooth_fast((dPCA_out_raw.W(:,CI_dim)' * matData.all_data(:,:,t))', 3);
        plot(ci,'LineWidth',2);
    end
    
    %%
    %get CI dimension and apply on single trial
    Cd_dim = find(dPCA_out_lfads.whichMarg==1);
    Cd_dim = Cd_dim(2);
    
    figure
    hold on
    for t=1:10
        ci = dPCA_out_lfads.W(:,Cd_dim)' * lfads_rates(:,:,t); 
        plot(ci,'LineWidth',2);
    end
    
    Cd_dim = find(dPCA_out_raw.whichMarg==1);
    Cd_dim = Cd_dim(2);
    
    figure
    hold on
    for t=1:10
        ci = gaussSmooth_fast((dPCA_out_raw.W(:,Cd_dim)' * matData.all_data(:,:,t))', 3);
        plot(ci,'LineWidth',2);
    end
    
    %%
    posErr = zeros(5,size(matData.all_data,2),size(matData.all_data,3));
    for t=1:length(R)
        loopIdx = 1:10:2000;
        fullPos = R(t).cursorPosition';
        if loopIdx(end)>length(fullPos)
            fullPos = [fullPos; R(t+1).cursorPosition'];
        end
        
        cursorPos = fullPos(loopIdx,:);
        posErr(:,:,t) = bsxfun(@plus, matData.targPos(t,:), -cursorPos)';
    end
    
    unroll_posErr = posErr(:,:)';
    unroll_lfads = lfads_rates(:,:)';
    unroll_raw = matData.all_data(:,:)';
    trlEpochs = [(1:200:length(unroll_posErr))', (200:200:length(unroll_posErr))'];
    useIdx = expandEpochIdx([trlEpochs(:,1)+40, trlEpochs(:,2)]);
    
    coef_lfads = buildLinFilts(unroll_posErr(useIdx,:), [ones(length(useIdx),1), unroll_lfads(useIdx,:)], 'standard');
    coef_raw = buildLinFilts(unroll_posErr(useIdx,:), [ones(length(useIdx),1), unroll_raw(useIdx,:)], 'standard');
    
    pred_lfads = [ones(size(unroll_lfads,1),1), unroll_lfads]*coef_lfads;
    pred_raw = [ones(size(unroll_raw,1),1), unroll_raw]*coef_raw;
    
    figure
    hold on
    plot(unroll_posErr(:,1),'LineWidth',2);
    plot(pred_lfads(:,1),'LineWidth',2);
    plot(gaussSmooth_fast(pred_raw(:,1),3),'LineWidth',2);
    
    %%
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(unroll_lfads);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED_raw] = pca(gaussSmooth_fast(unroll_raw,6));
    
    figure
    plot(0:15, [0; cumsum(EXPLAINED(1:15))],'-o','LineWidth',2);
    
    figure
    plot(0:15, [0; cumsum(EXPLAINED_raw(1:15))],'-o','LineWidth',2);
    
    %%
    figure; 
    subplot(2,1,1);
    imagesc(resultTrain.output_dist_params(:,:,301));
    
    subplot(2,1,2);
    imagesc(resultInput.train_data(:,:,301));
    
    %%
    figure; 
    subplot(2,1,1);
    imagesc(lfads_rates(:,:,1));
    
    subplot(2,1,2);
    imagesc(matData.all_data(:,:,1));
    
    %%
    figure; 
    subplot(2,1,1);
    imagesc(matData.all_data(:,:,matData.trainIdx(1)));
    
    subplot(2,1,2);
    imagesc(resultInput.train_data(:,:,1));
end
