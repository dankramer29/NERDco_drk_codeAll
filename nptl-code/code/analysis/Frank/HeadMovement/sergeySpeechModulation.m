%%
datasets = {
    't5.2018.12.12/R_t5.2018.12.12-words_noRaw.mat';
    't5.2018.12.17/R_t5.2018.12.17-words_noRaw.mat';
};
filterNames = {{''},{'t5.2018.12.17/001-blocks003-thresh-4.5-ch80-bin15ms-smooth25ms-delay60ms.mat',...
    't5.2018.12.17/002-blocks004-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat',...
    't5.2018.12.17/003-blocks004_006-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat',...
    't5.2018.12.17/005-blocks011_013-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat',...
    't5.2018.12.17/006-blocks013_016-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat',...
    't5.2018.12.17/004-blocks008_011-thresh-4.5-ch80-bin15ms-smooth25ms-delay0ms.mat'}};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    %load R struct, adjust start times, make spike rasters
    
    outDir = [paths.dataPath filesep 'Derived' filesep 'sergeySpeechModulation' filesep datasets{d,1}(1:13)];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1}];
    load(sessionPath);
    
    wordCues = {R.label};
    [wordList,~,wordCueNum] = unique(wordCues);
    
    %manually determined offsets for each word
    if d==1
        wordOffset = [0,0,130,280,280,0];
    elseif d==2
        wordOffset = [0,0,140,230,230,0];
    end
    
    for t=1:length(R)
        R(t).timeSpeechStart_last = R(t).timeSpeechStart(end);
        R(t).timeSpeechStart_corrected = R(t).timeSpeechStart(end)+wordOffset(wordCueNum(t));
        R(t).timeCueStart_last = R(t).timeSpeechStart(2);
        
        R(t).spikeRaster = R(t).minAcausSpikeBand1 < R(t).RMSarray1*(-4.5);
        R(t).spikeRaster2 = R(t).minAcausSpikeBand2 < R(t).RMSarray2*(-4.5);
        R(t).blockNum=R(t).blockNumber;
    end

    %%        
    %bin & format neural data 
    smoothWidth = 0;
    datFields = {};
    timeWindow = [-2000,2000];
    binMS = 10;
    
    alignFields = {'timeSpeechStart_corrected'};
    alignDat_acoustic_c = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    alignFields = {'timeSpeechStart_last'};
    alignDat_acoustic = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    alignFields = {'timeCueStart_last'};
    alignDat_cue = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    %acoustic spikes
    meanRate = mean(alignDat_acoustic.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat_acoustic.meanSubtractSpikes(:,tooLow) = [];
    alignDat_acoustic.zScoreSpikes(:,tooLow) = [];
    smoothSnippetMatrix_acoustic = gaussSmooth_fast(alignDat_acoustic.zScoreSpikes,3);
    smoothSpikes_acoustic = gaussSmooth_fast(alignDat_acoustic.meanSubtractSpikes*(1000/binMS),3);
    
    %acoustic corrected spikes
    meanRate = mean(alignDat_acoustic_c.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat_acoustic_c.meanSubtractSpikes(:,tooLow) = [];
    alignDat_acoustic_c.zScoreSpikes(:,tooLow) = [];
    smoothSnippetMatrix_acoustic_c = gaussSmooth_fast(alignDat_acoustic_c.zScoreSpikes,3);
    smoothSpikes_acoustic_c = gaussSmooth_fast(alignDat_acoustic_c.meanSubtractSpikes*(1000/binMS),3);
    
    %cue spikes
    meanRate = mean(alignDat_cue.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat_cue.meanSubtractSpikes(:,tooLow) = [];
    alignDat_cue.zScoreSpikes(:,tooLow) = [];
    smoothSnippetMatrix_cue = gaussSmooth_fast(alignDat_cue.zScoreSpikes,3);
    smoothSpikes_cue = gaussSmooth_fast(alignDat_cue.meanSubtractSpikes*(1000/binMS),3);
    
    %%
    %mPCA to all alignments
    margGroupings = {{1, [1 2]}, ...
        {2}};
    margNames = {'Word','Time'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'singleTrial';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;

    trlIdx = find(wordCueNum~=6);
    mPCA_cue = apply_mPCA_general( smoothSnippetMatrix_cue, alignDat_cue.eventIdx(trlIdx), ...
        wordCueNum(trlIdx), [-180,180], 0.010, opts_m);
    
    mPCA_acoustic = apply_mPCA_general( smoothSnippetMatrix_acoustic, alignDat_acoustic.eventIdx(trlIdx), ...
        wordCueNum(trlIdx), [-180,180], 0.010, opts_m);
    
    mPCA_acoustic_c = apply_mPCA_general( smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(trlIdx), ...
        wordCueNum(trlIdx), [-180,180], 0.010, opts_m);
    
    %%
    %save & plot mPCA
    save([outDir filesep 'mPCA'],'mPCA_acoustic_c');

    mp = mPCA_acoustic_c.margPlot;
    [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( mPCA_acoustic_c.margResample, mp.timeAxis, mp.lineArgs, ...
        mp.plotTitles, 'sameAxes', [], [-1, 2.2], mPCA_acoustic_c.margResample.CIs, mp.lineArgsPerMarg, opts_m.margGroupings, opts_m.plotCI, mp.layoutInfo );
    set(gcf,'Position',[136   510   325   552]);
    saveas(gcf,[outDir filesep 'mPCA_forceAxes.png'],'png');
    saveas(gcf,[outDir filesep 'mPCA_forceAxes.svg'],'svg');
    
    %%
    %compare to nothing
    movWindow = [-20, 20];
    baselineTrls = triggeredAvg(smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(wordCueNum==6), movWindow);
    
    trlIdx = find(wordCueNum~=6);
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( wordCueNum(trlIdx), smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(trlIdx), ...
        baselineTrls, movWindow, [], [], {1:5}, 'raw' );
    singleTrialBarPlot( {1:5}, rawProjPoints_marg, cVar_marg, wordList(1:5) );
    
    saveas(gcf,[outDir filesep 'bar_vsNothing.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsNothing.svg'],'svg');
    
    %%
    %compare to internal baseline
    movWindow = [-20 20];
    baselineWindow = [-120, -80];

    trlIdx = 1:length(wordCueNum);
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( wordCueNum(trlIdx), smoothSnippetMatrix_acoustic_c, ...
        alignDat_acoustic_c.eventIdx(trlIdx), movWindow, baselineWindow, {1:5}, 'raw' );
    singleTrialBarPlot( {1:5}, rawProjPoints_marg, cVar_marg, wordList(1:5) );

    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline.svg'],'svg');
    
    %%
    reducedSpikes = alignDat_acoustic_c.rawSpikes*100;
    %reducedSpikes = reducedSpikes(:,mean(reducedSpikes)>1);
    
    speakCon = [1 2 3 4 5];
    nUnits = size(reducedSpikes,2);
    modDepth = zeros(nUnits, length(speakCon));
    modDepthSquare = zeros(nUnits, length(speakCon));
    movWindow = [-20 20];
    baselineWindow = [-120, -80];
    
    for unitIdx=1:nUnits    
        for w=1:length(speakCon)
            concat_mov = triggeredAvg(reducedSpikes(:,unitIdx), alignDat_acoustic_c.eventIdx(wordCueNum==speakCon(w)), movWindow);
            concat_base = triggeredAvg(reducedSpikes(:,unitIdx), alignDat_acoustic_c.eventIdx(wordCueNum==speakCon(w)), baselineWindow);

            concat_mov = mean(concat_mov,2);
            conta_base = mean(concat_base,2);
            [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( concat_mov, concat_base );
            
            modDepth(unitIdx, w) = lessBiasedEstimate;
            modDepthSquare(unitIdx, w) = meanOfSquares;
        end
    end
    
    disp(mean(modDepth(:)));
    % 39 Hz, 20 Hz
    % 23
    
    figure
    hist(mean(modDepth,2));
    xlabel('Modulation (Hz)');
    ylabel('# Electrodes');
    set(gca,'FontSize',16,'LineWidth',2);
    
    saveas(gcf,[outDir filesep 'modDepth_speech.png'],'png');
    saveas(gcf,[outDir filesep 'modDepth_speech.svg'],'svg');
    
    %%
    %neural push
    filterSet = filterNames{d};
    nFilters = length(filterSet);
    varNames = {'X Push','Y Push','||Push||'};
    movWindow = [-190, 190];
            
    figure('Position',[134         454        1218         644]);
    for filtIdx = 1:nFilters
        dec = load([paths.dataPath filesep 'BG Datasets' filesep filterSet{filtIdx}]);
        K = dec.model.K([2 4],1:192);
        neuralPush_speech = (1/0.06)*1000*gaussSmooth_fast(alignDat_acoustic_c.rawSpikes*K',2.5);

        concatBaseline = triggeredAvg(neuralPush_speech, alignDat_acoustic_c.eventIdx(wordCueNum==6), movWindow);
        basePush = squeeze(mean(mean(concatBaseline,1),2));

        wNum = 1:6;
        colors = jet(length(wNum)-1)*0.8;
        colors = [colors; [0.4 0.4 0.4]];
        timeAxis = (movWindow(1):movWindow(2))*0.01;

        for dimIdx=1:2
            subplot(3,nFilters,nFilters*(dimIdx-1)+filtIdx);
            hold on;

            for w=1:length(wNum)
                concat = triggeredAvg(neuralPush_speech(:,dimIdx), alignDat_acoustic_c.eventIdx(wordCueNum==wNum(w)), movWindow);
                concat = concat - basePush(dimIdx);

                [mn,~,CI] = normfit(concat);
                plot(timeAxis, mn,'Color',colors(w,:),'LineWidth',2);
                fHandle = errorPatch( timeAxis', CI' , colors(w,:), 0.2 );
            end
            ylim([-0.35,0.25]); 
            set(gca,'LineWidth',2,'FontSize',14);
            set(gca,'XTickLabel',[]);
            if filtIdx==1
                ylabel(varNames{dimIdx});
            else
                set(gca,'YTickLabel',[]);
            end
            if dimIdx==1
                title(['Filter 00' num2str(filtIdx)]);
            end
        end

        subplot(3,nFilters,nFilters*2+filtIdx)
        hold on;       
        for w=1:length(wNum)
            concat = triggeredAvg(neuralPush_speech, alignDat_acoustic_c.eventIdx(wordCueNum==wNum(w)), movWindow);
            concat(:,:,1) = concat(:,:,1) - basePush(1);
            concat(:,:,2) = concat(:,:,2) - basePush(2);

            nBins = size(concat,2);
            np = zeros(nBins,1);

            for t=1:nBins
                [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( squeeze(concat(:,t,:)), zeros(size(concat,1),2) );
                np(t) = lessBiasedEstimate;
            end
            
            %concat = squeeze(mean(concat,1));
            %mn = matVecMag(concat,2);

            plot(timeAxis, np,'Color',colors(w,:),'LineWidth',2);
        end
        ylim([-0.1,0.40]);
        xlabel('Time (s)');
        set(gca,'FontSize',14,'LineWidth',2);
        if filtIdx==1
            ylabel(varNames{end});
        end
    end
    
    saveas(gcf,[outDir filesep 'neuralPush.png'],'png');
    saveas(gcf,[outDir filesep 'neuralPush.svg'],'svg');
    
    %%
    %compare to internal baseline, meanSubtract
    movWindow = [-20 20];
    baselineWindow = [-120, -80];

    trlIdx = find(wordCueNum~=6);
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( wordCueNum(trlIdx), smoothSnippetMatrix_acoustic_c, ...
        alignDat_acoustic_c.eventIdx(trlIdx), movWindow, baselineWindow, {1:5}, 'subtractMean' );
    singleTrialBarPlot( {1:5}, rawProjPoints_marg, cVar_marg, wordList(1:5) );

    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_subtractMean.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline_subtractMean.svg'],'svg');
    
    %%
    %classifier
    neuralToClassify = {smoothSnippetMatrix_acoustic_c, smoothSnippetMatrix_acoustic};
    datToClassify = {alignDat_acoustic_c, alignDat_acoustic};
    datNames = {'acousticCorrected','acoustic'};
    
    for datIdx=1:length(datToClassify)

        dat = datToClassify{datIdx};
        dataIdxStart = -40:-30;
        nDecodeBins = 8;

        allFeatures = [];
        allCodes = wordCueNum;
        for t=1:length(dat.eventIdx)
            tmp = [];
            dataIdx = dataIdxStart;
            for binIdx=1:nDecodeBins
                loopIdx = dataIdx + dat.eventIdx(t);
                tmp = [tmp, mean(neuralToClassify{datIdx}(loopIdx,:))];
                dataIdx = dataIdx + length(dataIdx);
            end

            allFeatures = [allFeatures; tmp];
        end

        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        predLabels = kfoldPredict(cvmodel);

        C = confusionmat(allCodes, predLabels);
        C_counts = C;
        for rowIdx=1:size(C,1)
            C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
        end

        for r=1:size(C_counts,1)
            [PHAT, PCI] = binofit(C_counts(r,r),sum(C_counts(r,:)),0.01); 
            disp(PCI);
        end

        colors = [173,150,61;
        119,122,205;
        91,169,101;
        197,90,159;
        202,94,74]/255;

        figure('Position',[212   524   808   567]);
        hold on;

        imagesc(C);
        set(gca,'XTick',1:length(wordList),'XTickLabel',wordList,'XTickLabelRotation',45);
        set(gca,'YTick',1:length(wordList),'YTickLabel',wordList);
        set(gca,'FontSize',16);
        set(gca,'LineWidth',2);
        colorbar;
        title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

        axis tight;

        saveas(gcf,[outDir filesep 'linearClassifier_' datNames{datIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'linearClassifier_' datNames{datIdx} '.svg'],'svg');
    end
    
end %datasets