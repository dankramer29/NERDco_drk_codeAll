%%
datasets = {
    {'t5.2018.12.12/R_t5.2018.12.12_B7.mat','t5.2018.12.12/R_t5.2018.12.12_B9.mat','t5.2018.12.12/R_t5.2018.12.12_B10.mat','t5.2018.12.12/R_t5.2018.12.12_B12.mat'},[7 9 10 12];
    {'t5.2018.12.17/R_t5.2018.12.17_B8.mat','t5.2018.12.17/R_t5.2018.12.17_B9.mat','t5.2018.12.17/R_t5.2018.12.17_B10.mat','t5.2018.12.17/R_t5.2018.12.17_B11.mat',...
        't5.2018.12.17/R_t5.2018.12.17_B12.mat','t5.2018.12.17/R_t5.2018.12.17_B13.mat','t5.2018.12.17/R_t5.2018.12.17_B16.mat',...
        't5.2018.12.17/R_t5.2018.12.17_B17.mat','t5.2018.12.17/R_t5.2018.12.17_B18.mat','t5.2018.12.17/R_t5.2018.12.17_B19.mat'},[8 9 10 11 12 13 16 17 18 19];
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
    outDir = [paths.dataPath filesep 'Derived' filesep 'sergeySpeechModulation' filesep datasets{d,1}{1}(1:13) filesep 'duringBCI'];
    mkdir(outDir);
    
    R = [];
    for b=1:length(datasets{d,1})
        blockPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1}{b}];
        tmp = load(blockPath);
        for x=1:length(tmp.R)
            tmp.R(x).blockNum = datasets{d,2}(b);
        end
        
        R = [R, tmp.R];
    end
    
    tmp = {R.labelSpeech};
    wordCues = cell(length(tmp),1);
    for w=1:length(tmp)
        if isempty(tmp{w})
            wordCues{w} = 'NoCue';
        else
            wordCues{w} = tmp{w}{1};
        end
    end
    
    [wordList,~,wordCueNum] = unique(wordCues);
    
    %manually determined offsets for each word
    if d==1
        wordOffset = [0,0,0,0];
        speakCon = [2 3];
    else
        wordOffset = [0,0,0,140,230,230,0];
        speakCon = [2 3 4 5 6];
    end

    for t=1:length(R)
        if strcmp(wordCues{t},'NoCue')
            R(t).timeSpeechStart_last = R(t).timeGoCue;
            R(t).timeSpeechStart_corrected = R(t).timeGoCue;
        else
            R(t).timeSpeechStart_last = R(t).timeSpeech(end);
            R(t).timeSpeechStart_corrected = R(t).timeSpeech(end)+wordOffset(wordCueNum(t));
        end
        if ~isnan(R(t).timeCue)
            R(t).timeAudioCue = R(t).timeCue(1);
        else
            R(t).timeAudioCue = R(t).timeGoCue;
        end
    end
    
    rms = channelRMS(R);
    thresh = -4.5*rms;

    nChans = size(R(1).minAcausSpikeBand,1);
    for t=1:length(R)
        R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand(1:96,:), thresh(1:96)');
        if nChans>96
            R(t).spikeRaster2 = bsxfun(@lt, R(t).minAcausSpikeBand(97:end,:), thresh(97:end)');
        end
    end

    %%        
    %bin & format neural data 
    smoothWidth = 0;
    datFields = {'xk'};
    timeWindow = [-2000,2000];
    binMS = 10;
    
    alignFields = {'timeSpeechStart_corrected'};
    alignDat_acoustic_c = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    alignFields = {'timeSpeechStart_last'};
    alignDat_acoustic = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
    alignFields = {'timeGoCue'};
    alignDat_go = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignFields = {'timeAudioCue'};
    alignDat_audio = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
    
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

    trlIdx = find(ismember(wordCueNum, speakCon));
    
    mPCA_acoustic = apply_mPCA_general( smoothSnippetMatrix_acoustic, alignDat_acoustic.eventIdx(trlIdx), ...
        wordCueNum(trlIdx), [-180,180], 0.010, opts_m);
    
    mPCA_acoustic_c = apply_mPCA_general( smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(trlIdx), ...
        wordCueNum(trlIdx), [-180,180], 0.010, opts_m);
    
    save([outDir filesep 'mPCA'],'mPCA_acoustic_c');
    
    %      totalVar_noise: 738.4480
    %     totalVar_signal: 44.3707
         
    mp = mPCA_acoustic_c.margPlot;
    [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( mPCA_acoustic_c.margResample, mp.timeAxis, mp.lineArgs, ...
        mp.plotTitles, 'sameAxes', [], [-1, 2.2], mPCA_acoustic_c.margResample.CIs, mp.lineArgsPerMarg, opts_m.margGroupings, opts_m.plotCI, mp.layoutInfo );
    set(gcf,'Position',[136   510   325   552]);
    saveas(gcf,[outDir filesep 'mPCA_forceAxes.png'],'png');
    saveas(gcf,[outDir filesep 'mPCA_forceAxes.svg'],'svg');
    
    %%
    %compare to silence cue
    movWindow = [-20, 20];
    baselineTrls = triggeredAvg(smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(wordCueNum==length(wordList)), movWindow);
    
    trlIdx = find(ismember(wordCueNum, speakCon));
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_marg( wordCueNum(trlIdx), smoothSnippetMatrix_acoustic_c, alignDat_acoustic_c.eventIdx(trlIdx), ...
        baselineTrls, movWindow, [], [], {speakCon}, 'raw' );
    singleTrialBarPlot( {speakCon}, rawProjPoints_marg, cVar_marg, wordList(speakCon) );
    
    saveas(gcf,[outDir filesep 'bar_vsNothing.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsNothing.svg'],'svg');
    
    %%
    %compare to internal baseline
    movWindow = [-20 20];
    baselineWindow = [-120, -80];

    %trlIdx = find(wordCueNum~=1);
    trlIdx = find(ismember(wordCueNum, speakCon));
    [ cVar_marg, rawProjPoints_marg, scatterPoints ] = modulationMagnitude_internalBaseline( wordCueNum(trlIdx), smoothSnippetMatrix_acoustic_c, ...
        alignDat_acoustic_c.eventIdx(trlIdx), movWindow, baselineWindow, {speakCon}, 'raw' );
    singleTrialBarPlot( {speakCon}, rawProjPoints_marg, cVar_marg, wordList(speakCon) );

    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline.png'],'png');
    saveas(gcf,[outDir filesep 'bar_vsInternalBaseline.svg'],'svg');
    
    %%
    reducedSpikes = alignDat_acoustic_c.rawSpikes*100;
    reducedSpikes = reducedSpikes(:,mean(reducedSpikes)>1);
    
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
    % 1.4851; 12.5
    
    figure
    hist(mean(modDepth,2));
    xlabel('Modulation (Hz)');
    ylabel('# Electrodes');
    set(gca,'FontSize',16,'LineWidth',2);
    
    saveas(gcf,[outDir filesep 'modDepth_speech.png'],'png');
    saveas(gcf,[outDir filesep 'modDepth_speech.svg'],'svg');
    
    %%
    %speech neural push    
    filterSet = filterNames{d};
    nFilters = length(filterSet);
    varNames = {'X Push','Y Push','||Push||'};
    movWindow = [-190, 190];
            
    figure('Position',[134         454        1218         644]);
    for filtIdx = 1:nFilters
        dec = load([paths.dataPath filesep 'BG Datasets' filesep filterSet{filtIdx}]);
        K = dec.model.K([2 4],1:192);
        neuralPush_speech = (1/0.06)*1000*gaussSmooth_fast(alignDat_acoustic_c.rawSpikes*K',2.5);
        
        concat_silence = triggeredAvg(neuralPush_speech, alignDat_acoustic_c.eventIdx(wordCueNum==length(wordList)), movWindow);
        mn_baseline = squeeze(mean(mean(concat_silence,1),2));

        wNum = 1:6;
        colors = jet(length(wNum)-1)*0.8;
        colors = [colors; [0.4 0.4 0.4]];
        timeAxis = (movWindow(1):movWindow(2))*0.01;

        for dimIdx=1:2
            subplot(3,nFilters,nFilters*(dimIdx-1)+filtIdx);
            hold on;

            for w=1:length(wNum)
                concat = triggeredAvg(neuralPush_speech(:,dimIdx), alignDat_acoustic_c.eventIdx(wordCueNum==wNum(w)), movWindow);
                concat = concat - mn_baseline(dimIdx);

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
            concat(:,:,1) = concat(:,:,1) - mn_baseline(1);
            concat(:,:,2) = concat(:,:,2) - mn_baseline(2);
            
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
    %bci neural push    
    filterSet = filterNames{d};
    nFilters = length(filterSet);
    varNames = {'X Push','Y Push','||Push||'};
    movWindow = [-190, 190];
    
    tPos = [R.posTarget]';
    [tList,~,tNum] = unique(tPos,'rows');
    targToUse = [1 2 3 4 6 7 8 9];
    colors = jet(8)*0.8;
            
    figure('Position',[134         454        1218         644]);
    for filtIdx = 1:nFilters
        dec = load([paths.dataPath filesep 'BG Datasets' filesep filterSet{filtIdx}]);
        K = dec.model.K([2 4],1:192);
        neuralPush_go = (1/0.06)*1000*gaussSmooth_fast(alignDat_go.rawSpikes*K',2.5);
        mn_baseline = mean(neuralPush_go);

        timeAxis = (movWindow(1):movWindow(2))*0.01;

        for dimIdx=1:2
            subplot(3,nFilters,nFilters*(dimIdx-1)+filtIdx);
            hold on;

            for targIdx=1:8
                concat = triggeredAvg(neuralPush_go(:,dimIdx), alignDat_go.eventIdx(tNum==targToUse(targIdx)), movWindow);
                concat = concat - mn_baseline(dimIdx);

                [mn,~,CI] = normfit(concat);
                plot(timeAxis, mn,'Color',colors(targIdx,:),'LineWidth',2);
                fHandle = errorPatch( timeAxis', CI' , colors(targIdx,:), 0.2 );
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
        for targIdx=1:8
            concat = triggeredAvg(neuralPush_go, alignDat_go.eventIdx(tNum==targToUse(targIdx)), movWindow);
            concat(:,:,1) = concat(:,:,1) - mn_baseline(1);
            concat(:,:,2) = concat(:,:,2) - mn_baseline(2);
            
            nBins = size(concat,2);
            np = zeros(nBins,1);

            for t=1:nBins
                [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( squeeze(concat(:,t,:)), zeros(size(concat,1),2) );
                np(t) = lessBiasedEstimate;
            end

            %concat = squeeze(mean(concat,1));
            %mn = matVecMag(concat,2);
            
            plot(timeAxis, np,'Color',colors(targIdx,:),'LineWidth',2);
        end
        ylim([-0.1,0.40]);
        xlabel('Time (s)');
        set(gca,'FontSize',14,'LineWidth',2);
        if filtIdx==1
            ylabel(varNames{end});
        end
    end
    
    saveas(gcf,[outDir filesep 'neuralPush_bci.png'],'png');
    saveas(gcf,[outDir filesep 'neuralPush_bci.svg'],'svg');
    
    %%
    %neural push
    dec = load([paths.dataPath filesep 'BG Datasets' filesep filterNames{d}]);
    K = dec.model.K([2 4],1:192);
    neuralPush_speech = 1000*gaussSmooth_fast(alignDat_acoustic_c.rawSpikes*K',2.5);
    neuralPush_go = 1000*gaussSmooth_fast(alignDat_go.rawSpikes*K',2.5);
    
    concat_go = triggeredAvg(neuralPush_go, alignDat_go.eventIdx, [-10,0]);
    mn_go = (mean(mean(concat_go,1),2));
    
    movWindow = [-100, 100];
    wNum = speakCon;
    colors = jet(length(wNum))*0.8;
    timeAxis = (movWindow(1):movWindow(2))*0.01;
    
    %speech cues
    figure
    hold on;
    for w=1:length(wNum)
        concat_speech = triggeredAvg(neuralPush_speech, alignDat_acoustic_c.eventIdx(wordCueNum==wNum(w)), movWindow);
        concat_speech = concat_speech - mn_go;
        mn = squeeze(mean(concat_speech,1));
        np = matVecMag(mn,2);
        
%         nBins = size(concat_speech,2);
%         np = zeros(nBins,1);
%         
%         for t=1:nBins
%             [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( squeeze(concat_speech(:,t,:)), zeros(size(concat_speech,1),2) );
%             np(t) = lessBiasedEstimate;
%         end
        
        plot(timeAxis, np,'Color',colors(w,:),'LineWidth',2);
        %fHandle = errorPatch( timeAxis', CI' , colors(w,:), 0.2 );
    end
    ylim([-0.005,0.025]);
    
    tPos = [R.posTarget]';
    [tList,~,tNum] = unique(tPos,'rows');
    targToUse = [1 2 3 4 6 7 8 9];
    colors = jet(8)*0.8;
    
    %BCI targets
    figure
    hold on;
    for targIdx=1:8
        concat_bci = triggeredAvg(neuralPush_go, alignDat_go.eventIdx(tNum==targToUse(targIdx)), movWindow);
        concat_bci = concat_bci - mn_go;
        mn = squeeze(mean(concat_bci,1));
        np = matVecMag(mn,2);
%         
%         nBins = size(concat_speech,2);
%         np = zeros(nBins,1);
%         
%         for t=1:nBins
%             [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( squeeze(concat_bci(:,t,:)), zeros(size(concat_bci,1),2) );
%             np(t) = lessBiasedEstimate;
%         end
        
        plot(timeAxis, np,'Color',colors(targIdx,:),'LineWidth',2);
        %fHandle = errorPatch( timeAxis', CI' , colors(w,:), 0.2 );
    end
    ylim([-0.005,0.025]);
    
    %%
    %X and Y push
    movWindow = [-180, 180];
    wNum = speakCon;
    velDim = [1 2];
    colors = jet(length(wNum))*0.8;
    timeAxis = (movWindow(1):movWindow(2))*0.01;
    
    figure
    for dimIdx=1:2
        subplot(1,2,dimIdx);
        hold on;
        
        vDim = velDim(dimIdx);
        for w=1:length(wNum)
            concat = triggeredAvg(neuralPush_speech(:,vDim)-mn_go(vDim), alignDat_acoustic_c.eventIdx(wordCueNum==wNum(w)), movWindow);
            
            [mn,~,CI] = normfit(concat);
            plot(timeAxis, mn,'Color',colors(w,:),'LineWidth',2);
            fHandle = errorPatch( timeAxis', CI' , colors(w,:), 0.2 );
        end
        ylim([-0.03,0.03]);
    end
    
    colors = jet(8)*0.8;
    figure
    for dimIdx=1:2
        subplot(1,2,dimIdx);
        hold on;
        
        vDim = velDim(dimIdx);
        for targIdx=1:8
            concat = triggeredAvg(neuralPush_go(:,vDim)-mn_go(vDim), alignDat_go.eventIdx(tNum==targToUse(targIdx)), movWindow);
            
            [mn,~,CI] = normfit(concat);
            plot(timeAxis, mn,'Color',colors(targIdx,:),'LineWidth',2);
            fHandle = errorPatch( timeAxis', CI' , colors(targIdx,:), 0.2 );
        end
        ylim([-0.03,0.03]);
    end
 
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

        useTrl = find(ismember(wordCueNum, speakCon));
        allFeatures = allFeatures(useTrl,:);
        allCodes = allCodes(useTrl,:);
        
        obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
        cvmodel = crossval(obj);
        L = kfoldLoss(cvmodel);
        predLabels = kfoldPredict(cvmodel);

        C = confusionmat(allCodes, predLabels);
        C_counts = C;
        for rowIdx=1:size(C,1)
            C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
        end

        colors = [173,150,61;
        119,122,205;
        91,169,101;
        197,90,159;
        202,94,74]/255;

        figure('Position',[212   524   808   567]);
        hold on;

        imagesc(C);
        set(gca,'XTick',1:size(C,1),'XTickLabel',wordList(2:end),'XTickLabelRotation',45);
        set(gca,'YTick',1:size(C,1),'YTickLabel',wordList(2:end));
        set(gca,'FontSize',16);
        set(gca,'LineWidth',2);
        colorbar;
        title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

        axis tight;

        saveas(gcf,[outDir filesep 'linearClassifier_' datNames{datIdx} '.png'],'png');
        saveas(gcf,[outDir filesep 'linearClassifier_' datNames{datIdx} '.svg'],'svg');
    end
    
end %datasets