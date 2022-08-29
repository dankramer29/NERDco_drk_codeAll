%%
%quickly load and check results
datasetName = 't5.2017.10.23-phonemes';

%The pre_LFADS folder contains the input files for LFADS, the post_LFADS
%folder contains the results of each LFADS run
lfadsPreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName filesep];
lfadsPostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName filesep];

%unParams contains descriptions of what parameters were used for each run.
%Here I varied only the number of inferred inputs (from 0 to 4, with 3
%repetitions each).
load([lfadsPreDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');

%also load your original data for comparison
originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.23-phonemes_5ae60c61a42dca423cd4ab54034528cc.mat';
originalDat = load(originalDataPath);

for r=3:size(runTable,1)

    plotDir = ['/net/home/fwillett/Data/Derived/Speech_LFADS_analysis/LFADS_run_' num2str(r)];
    mkdir(plotDir);
    
    %these model_runs files are the output of LFADS and are in hdf5 format
    datasetNumStr = num2str(r);
    fileTrain = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_train_posterior_sample_and_average'];
    fileValid = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    fileMat = [lfadsPreDir 'matlabDataset.mat'];
    
    resultTrain = hdf5load(fileTrain);
    resultValid = hdf5load(fileValid);
    matInput = load(fileMat);
    
    %output_dist_params are the smoothed rates given by LFADS
    smoothRates = zeros(size(matInput.all_data));
    smoothRates(:,:,matInput.trainIdx) = resultTrain.output_dist_params;
    smoothRates(:,:,matInput.validIdx) = resultValid.output_dist_params;
    
    %the rest of the code makes PSTHs and applies demixed PCA to compare
    %the LFADS smoothed rates to the raw data
    smoothRatesExp = [];
    originalRatesExp = [];
    for t=1:size(smoothRates,3)
        smoothRatesExp = [smoothRatesExp; smoothRates(:,:,t)'];
        originalRatesExp = [originalRatesExp; matInput.all_data(:,:,t)'];
    end
    startIdx = 100:250:size(smoothRatesExp,1);
    startIdx_rt = (1:250:size(smoothRatesExp,1)) + round(originalDat.datInfo.reactionTime'/10);
    originalRatesExp = double(originalRatesExp);
    
    [labelKey,~,labelIdx] = unique(originalDat.datInfo.label);
    
    psthOpts = makePSTHOpts();
    psthOpts.gaussSmoothWidth = 3;
    psthOpts.neuralData = {originalRatesExp, smoothRatesExp};
    psthOpts.timeWindow = [-80, 100];
    psthOpts.trialEvents = startIdx_rt;
    psthOpts.trialConditions = labelIdx;
    
    psthOpts.conditionGrouping = {1:length(labelKey)};
    
    colors = hsv(length(labelKey))*0.8;
    for c=1:size(colors,1)
        psthOpts.lineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
    end
    
    psthOpts.plotsPerPage = 10;
    psthOpts.plotDir = plotDir;
    featLabels = cell(size(smoothRatesExp,2),1);
    for f=1:size(smoothRatesExp,2)
        featLabels{f} = ['Chan' num2str(f)];
    end
    psthOpts.featLabels = featLabels;
    psthOpts.prefix = 'Raw_vs_LFADS';
    psthOpts.subtractConMean = false;
    psthOpts.timeStep = 10/1000;
    pOut = makePSTH_simple(psthOpts);
    
    smoothData = gaussSmooth_fast(originalRatesExp, 3);
    dPCA_all = apply_dPCA_simple( smoothData, startIdx_rt, psthOpts.trialConditions, ...
        [-80 100], 0.02, {'Condition-dependent', 'Condition-independent'} );    
    
    dPCA_all_lfads = apply_dPCA_simple( smoothRatesExp, startIdx_rt, psthOpts.trialConditions, ...
        [-80 100], 0.02, {'Condition-dependent', 'Condition-independent'} );    
    
    save([plotDir filesep 'dPCA_data.mat'],'dPCA_all_lfads','dPCA_all','pOut');
    
    timeWindow = [-80, 100];
    margNamesShort = {'CD','CI'};

    oneFactor_dPCA_plot( dPCA_all, (timeWindow(1):timeWindow(2))*(10/1000), psthOpts.lineArgs, margNamesShort, 'sameAxes');
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[plotDir filesep 'dPCA_raw.png'],'png');
    saveas(gcf,[plotDir filesep 'dPCA_raw.svg'],'svg');
                
    oneFactor_dPCA_plot( dPCA_all_lfads, (timeWindow(1):timeWindow(2))*(10/1000), psthOpts.lineArgs, margNamesShort, 'sameAxes');
    set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    saveas(gcf,[plotDir filesep 'dPCA_lfads.png'],'png');
    saveas(gcf,[plotDir filesep 'dPCA_lfads.svg'],'svg');
    
    close all;
    
    %look at single-trial activity for a given condition, LFADS smoothed
    %rates vs. raw rates, in a dimension picked by dPCA
    concatData_lfads = triggeredAvg(smoothRatesExp * dPCA_all.W(:,2), startIdx_rt, [-80 100]);
    concatData_raw = triggeredAvg(originalRatesExp * dPCA_all.W(:,2), startIdx_rt, [-80 100]);
    
    plotTrl = labelIdx==1;
    avg_lfads = mean(concatData_lfads(plotTrl,:));
    avg_raw = mean(concatData_raw(plotTrl,:));
    
    figure
    hold on
    plot(concatData_lfads(plotTrl,:)');
    plot(avg_lfads,'k','LineWidth',3);
    
    figure
    hold on
    plot(concatData_raw(plotTrl,:)');
    plot(avg_raw,'k','LineWidth',3);
end


%%
%spectrogram + PCA
datasetName = 't5.2017.10.23-caterpillar';

%The pre_LFADS folder contains the input files for LFADS, the post_LFADS
%folder contains the results of each LFADS run
lfadsPreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName filesep];
lfadsPostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName filesep];

%unParams contains descriptions of what parameters were used for each run.
%Here I varied only the number of inferred inputs (from 0 to 4, with 3
%repetitions each).
load([lfadsPreDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');

%also load your original data for comparison
originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.23-caterpillar_b450ebf04ef105cc4d99d2de1ad31a5e.mat';
originalDat = load(originalDataPath);

oRates = zeros(size(originalDat.datTensor,1)*250,175);
currentIdx = 1:250;
for t=1:size(originalDat.datTensor,1)
    oRates(currentIdx,:) = squeeze(originalDat.datTensor(t,:,:))';
    currentIdx = currentIdx + 250;
end

nSnippets = size(originalDat.audioMatrix,1);
allAudio = zeros(75000*nSnippets,1);
currentIdx = 1:75000;
for t=1:size(originalDat.audioMatrix,1)
    allAudio(currentIdx) = originalDat.audioMatrix(t,1:75000);
    currentIdx = currentIdx + 75000;
end
[SR,freq,times] = spectrogram(allAudio,3000,2700,[],30000);
SR = zscore(abs(SR)');

for r=3:size(runTable,1)
    plotDir = ['/net/home/fwillett/Data/Derived/Speech_LFADS_analysis/LFADS_run_' num2str(r)];
    mkdir(plotDir);
    
    %these model_runs files are the output of LFADS and are in hdf5 format
    datasetNumStr = num2str(r);
    fileTrain = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_train_posterior_sample_and_average'];
    fileValid = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    fileMat = [lfadsPreDir 'matlabDataset.mat'];
    
    resultTrain = hdf5load(fileTrain);
    resultValid = hdf5load(fileValid);
    matInput = load(fileMat);
    
    %output_dist_params are the smoothed rates given by LFADS
    smoothRates = zeros(size(matInput.all_data));
    smoothRates(:,:,matInput.trainIdx) = resultTrain.output_dist_params;
    smoothRates(:,:,matInput.validIdx) = resultValid.output_dist_params;
    
    %convert into non-overlapping time series
    allRates = zeros(50*size(smoothRates,3), size(smoothRates,1));
    currentIdx = 1:50;
    for t=1:size(smoothRates,3)
        allRates(currentIdx,:) = squeeze(smoothRates(:,1:50,t))';
        currentIdx = currentIdx + 50;
    end
    allRates(1:4,:) = [];
    allRates((end-4):end,:) = [];
    
    score_dpc = oRates * dPCA_all.W(:,1:2);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allRates);
    smoothORates = gaussSmooth_fast(oRates, 2.5);
    
    figure
    imagesc(SR',[-3 3]);
    set(gca,'YDir','normal');
    ylim([0 500]);
    hold on;
    filt_dpc = gaussSmooth_fast(score_dpc,2.5);
    filt_dpc = (zscore(filt_dpc)+3)*83;
    plot(filt_dpc,'LineWidth',2);
    
    figure
    ax1=subplot(2,1,1);
    imagesc(SR',[-3 3]);
    set(gca,'YDir','normal');
    ylim([0 500]);
    
    ax2=subplot(2,1,2);
    imagesc(zscore(smoothORates)',[-3 3])
    
    linkaxes([ax1, ax2], 'x');
    
    filt_dpc = (zscore(score_dpc)+3)*83;
    filt_dpc = gaussSmooth_fast(filt_dpc,2.5);
    plot(filt_dpc,'LineWidth',2);
end

%%
%spectrogram + PCA
datasetName = 't5.2017.10.23-caterpillar-overlap';

%The pre_LFADS folder contains the input files for LFADS, the post_LFADS
%folder contains the results of each LFADS run
lfadsPreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName filesep];
lfadsPostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName filesep];

%unParams contains descriptions of what parameters were used for each run.
%Here I varied only the number of inferred inputs (from 0 to 4, with 3
%repetitions each).
load([lfadsPreDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');

%also load your original data for comparison
originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.23-caterpillar_6d87e2b2dea9d0fd01a4dab770229c1b.mat';
originalDat = load(originalDataPath);

oRates = zeros(443*50,175);
currentIdx = 1:50;
for t=1:443
    oRates(currentIdx,:) = squeeze(originalDat.datTensor(t,:,1:50))';
    currentIdx = currentIdx + 50;
end

nSnippets = size(originalDat.audioMatrix,1);
allAudio = zeros(15000*nSnippets,1);
currentIdx = 1:15000;
for t=1:size(originalDat.audioMatrix,1)
    allAudio(currentIdx) = originalDat.audioMatrix(t,1:15000);
    currentIdx = currentIdx + 15000;
end
[SR,freq,times] = spectrogram(allAudio,3000,2700,[],30000);
SR = zscore(abs(SR)');

for r=3:size(runTable,1)
    plotDir = ['/net/home/fwillett/Data/Derived/Speech_LFADS_analysis/LFADS_run_' num2str(r)];
    mkdir(plotDir);
    
    %these model_runs files are the output of LFADS and are in hdf5 format
    datasetNumStr = num2str(r);
    fileTrain = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_train_posterior_sample_and_average'];
    fileValid = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_valid_posterior_sample_and_average'];
    fileMat = [lfadsPreDir 'matlabDataset.mat'];
    
    resultTrain = hdf5load(fileTrain);
    resultValid = hdf5load(fileValid);
    matInput = load(fileMat);
    
    %output_dist_params are the smoothed rates given by LFADS
    smoothRates = zeros(size(matInput.all_data));
    smoothRates(:,:,matInput.trainIdx) = resultTrain.output_dist_params;
    smoothRates(:,:,matInput.validIdx) = resultValid.output_dist_params;
    
    %convert into non-overlapping time series
    allRates = zeros(50*size(smoothRates,3), size(smoothRates,1));
    currentIdx = 1:50;
    for t=1:size(smoothRates,3)
        allRates(currentIdx,:) = squeeze(smoothRates(:,1:50,t))';
        currentIdx = currentIdx + 50;
    end
    allRates(1:4,:) = [];
    allRates((end-4):end,:) = [];
    
    [~,topChan] = sort(pOut.dimSNR(:,1),'descend');
    
    figure
    ax1 = subplot(3,1,1);
    imagesc(SR',[-3 3]);
    set(gca,'YDir','normal');
    ylim([0 500]);
    
    ax2 = subplot(3,1,2);
    imagesc(zscore(allRates(:,topChan(1:30)))',[-3 3]);
        
    ax3 = subplot(3,1,3);
    imagesc(zscore(oRates(:,topChan(1:30)))',[-3 3]);
    
    linkaxes([ax1, ax2, ax3],'x');
    
    score_dpc = oRates * dPCA_all.W(:,1:2);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(allRates);
    smoothORates = gaussSmooth_fast(oRates, 2.5);
    
    figure
    imagesc(SR',[-3 3]);
    set(gca,'YDir','normal');
    ylim([0 500]);
    hold on;
    filt_dpc = gaussSmooth_fast(score_dpc,2.5);
    filt_dpc = (zscore(filt_dpc)+3)*83;
    plot(filt_dpc,'LineWidth',2);
    
    figure
    ax1=subplot(2,1,1);
    imagesc(SR',[-3 3]);
    set(gca,'YDir','normal');
    ylim([0 500]);
    
    ax2=subplot(2,1,2);
    imagesc(zscore(smoothORates)',[-3 3])
    
    linkaxes([ax1, ax2], 'x');
    
    filt_dpc = (zscore(score_dpc)+3)*83;
    filt_dpc = gaussSmooth_fast(filt_dpc,2.5);
    plot(filt_dpc,'LineWidth',2);
end