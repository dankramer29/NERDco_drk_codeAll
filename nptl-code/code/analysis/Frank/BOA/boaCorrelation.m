%%
datasets = {
    't5.2019.02.27',{[4 8 11 15 18 21],[6 9 12 16 19 22],[7 10 14 17 20 23]};
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'BOA' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 4.5, bNums(1), filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
        end
        allR = [allR, R{x}];
    end
    
    clear R;
    
    %%
    %add target pos for each time step
    for t=1:length(allR)
        allR(t).targetPos = repmat(allR(t).posTarget,1,length(allR(t).clock));
        allR(t).trialLen = length(allR(t).clock);
    end

    %%
    %bin and align spikes for each trial
    
    alignFields = {'timeGoCue'};
    smoothWidth = 0;
    datFields = {'targetPos','cursorPosition','windowsMousePosition','replayTrial','replayTrialIndx','windowsMousePosition_speed'};
    timeWindow = [0,2000];
    binMS = 20;
    alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 1.0;
    alignDat.zScoreSpikes(:,tooLow) = [];
    
    alignDat.eventIdx(end) = [];
    
    %%
    %assign a condition number to each trial
    conNumber = zeros(size(alignDat.eventIdx));
    blockSets = datasets{d,2};
    for b=1:length(blockSets)
        trlIdx = find(ismember(alignDat.bNumPerTrial, blockSets{b}));
        replayNum = alignDat.replayTrialIndx(alignDat.eventIdx(trlIdx)+10);
        replayTrl = alignDat.replayTrial(alignDat.eventIdx(trlIdx)+10);
        
        if b==1
            %OL
            curveTrl = ismember(replayNum,[1 2 3]);
            straightTrl = ~curveTrl;
            
            conNumber(trlIdx(straightTrl)) = 1;
            conNumber(trlIdx(curveTrl)) = 2;
        elseif b==2
            %CL
            curveReplay = ismember(replayNum,2:2:20) & replayTrl==1;
            straightReplay = ismember(replayNum,1:2:20) & replayTrl==1;
            normalCL = replayTrl==0;
            
            conNumber(trlIdx(curveReplay)) = 5;
            conNumber(trlIdx(straightReplay)) = 4;
            conNumber(trlIdx(normalCL)) = 3;
        elseif b==3
            %Replay BCI
            replayBCI = replayTrl==1;
            lieCI = replayTrl==0;
            
            conNumber(trlIdx(replayBCI)) = 6;
            conNumber(trlIdx(lieCI)) = 7;
        end
    end
    
    %%
    %verify conditions
    figure
    hold on
    for t=1:length(alignDat.eventIdx)
        loopIdx = (alignDat.eventIdx(t)+1):(alignDat.eventIdx(t)+40);
        if conNumber(t)==4
            plot(alignDat.cursorPosition(loopIdx,1), alignDat.cursorPosition(loopIdx,2),'b');
        elseif conNumber(t)==5
            plot(alignDat.cursorPosition(loopIdx,1), alignDat.cursorPosition(loopIdx,2),'r');
        end
    end
    
    %%
    %filter out unsuccessful trials
    isSucc = [allR.isSuccessful];
    badTrials = ~isSucc;
    badTrials = filtfilt(ones(2,1),1,double(badTrials));
    badTrials = badTrials>0.5;
    badTrials = badTrials';
    
    %%
    %compute PDs for each condition
    tPos = alignDat.targetPos(:,1:2)/409;
    [targList, ~, targNum] = unique(tPos(alignDat.eventIdx+10,:),'rows');
    
    movWindow = [10,20];
    
    nCon = 7;
    PD = cell(nCon,1);
    for c=1:nCon
        %find the time steps that correspond to this condition
        conTrl = find(conNumber(1:length(badTrials))==c & ~badTrials & targNum~=3);
        conIdx = [];
        for t=1:length(conTrl)
            trlStart = alignDat.eventIdx(conTrl(t));
            conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
        end
        
        %fit PDs using above time steps
        Y = alignDat.zScoreSpikes(conIdx,:);
        X = [ones(length(conIdx),1), tPos(conIdx,:)];
        PD{c} = X \ Y;
        PD{c} = PD{c}';
    end
    
    %%
    %correlate PDs
    corrMat = zeros(nCon,nCon);
    for rowIdx=1:nCon
        for colIdx=1:nCon
            xCorr = corr(PD{rowIdx}(:,2), PD{colIdx}(:,2));
            yCorr = corr(PD{rowIdx}(:,3), PD{colIdx}(:,3));
            corrMat(rowIdx, colIdx) = mean([xCorr, yCorr]);
        end
    end
    
    %%
    %plot correlations
    conNames = {'OL Straight','OL Curve','CL','CL Straight','CL Curve','BCI Replay','LieCI'};
    
    figure
    imagesc(corrMat);
    set(gca,'YDir','normal','XTick',1:nCon','YTick',1:nCon,'XTicklabel',conNames,'YTickLabel',conNames,'XTickLabelRotation',45);
    set(gca,'FontSize',16);
    colorbar;
    
    for rowIdx=1:nCon
        for colIdx=1:nCon
            text(colIdx, rowIdx, num2str(corrMat(rowIdx, colIdx),2), 'Color', 'k',...
                'HorizontalAlignment','Center','FontSize',12,'FontWeight','b')
        end
    end
    
    %%
    %unbiased correlation metric with resampling for CI
    %first compute PDs and unbiased PD vector norms for each condition
    windowStart = 10:90;
    allCMat = cell(length(windowStart),1);
    for winIdx=1:length(windowStart)
        
        tPos = alignDat.targetPos(:,1:2)/409;
        [targList, ~, targNum] = unique(tPos(alignDat.eventIdx+10,:),'rows');
        movWindow = [windowStart(winIdx), windowStart(winIdx)+10];

        nCon = 7;
        PD = cell(nCon,1);
        pdNorms = cell(nCon,1);
        for c=1:nCon
            conTrl = find(conNumber(1:length(badTrials))==c & ~badTrials & targNum~=3);

            %unbiased PD vector norms
            nTrl = length(conTrl);
            nFolds = 10;
            foldTrlIdx = repmat(1:nFolds, 1, ceil(nTrl/nFolds));
            foldTrlIdx = foldTrlIdx(1:nTrl);
            foldTrlIdx = foldTrlIdx(randperm(nTrl));

            foldPDNorms = zeros(nFolds,2);
            for foldIdx=1:nFolds
                trlSets = {conTrl(foldTrlIdx==foldIdx), conTrl(foldTrlIdx~=foldIdx)};
                pdSets = cell(2,1);
                for setIdx=1:2
                    setTrl = trlSets{setIdx};
                    conIdx = [];
                    for t=1:length(setTrl)
                        trlStart = alignDat.eventIdx(setTrl(t));
                        conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
                    end

                    Y = alignDat.zScoreSpikes(conIdx,:);
                    X = [ones(length(conIdx),1), tPos(conIdx,:)];
                    pdSets{setIdx} = X \ Y;
                    pdSets{setIdx} = pdSets{setIdx}';
                    pdSets{setIdx} = pdSets{setIdx} - mean(pdSets{setIdx});
                end
                foldPDNorms(foldIdx,:) = diag(pdSets{1}(:,2:3)'*pdSets{2}(:,2:3));
            end
            pdNorms{c} = sqrt(mean(foldPDNorms));

            %full PD
            conIdx = [];
            for t=1:length(conTrl)
                trlStart = alignDat.eventIdx(conTrl(t));
                conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
            end

            Y = alignDat.zScoreSpikes(conIdx,:);
            X = [ones(length(conIdx),1), tPos(conIdx,:)];
            PD{c} = X \ Y;
            PD{c} = PD{c}';
            PD{c} = PD{c} - mean(PD{c});
        end

        %correlate PDs
        corrMat_unbiased = zeros(nCon,nCon);
        for rowIdx=1:nCon
            for colIdx=1:nCon
                xCorr = PD{rowIdx}(:,2)'*PD{colIdx}(:,2)/(pdNorms{rowIdx}(1)*pdNorms{colIdx}(1));
                yCorr = PD{rowIdx}(:,3)'*PD{colIdx}(:,3)/(pdNorms{rowIdx}(2)*pdNorms{colIdx}(2));
                corrMat_unbiased(rowIdx, colIdx) = mean([xCorr, yCorr]);
            end
        end

        for c=1:nCon
            corrMat_unbiased(c,c)=1;
        end
        
        allCMat{winIdx} = corrMat_unbiased;
    end
    
    %%
    %over time
    timeLines = zeros(length(allCMat),2);
    for x=1:length(allCMat)
        timeLines(x,1) = allCMat{x}(1,4);
        timeLines(x,2) = allCMat{x}(2,5);
    end
    
    timeAxis = windowStart/50;
    
    figure
    hold on;
    plot(timeAxis(1:55), timeLines(1:55,1), 'LineWidth', 2);
    plot(timeAxis(1:70), timeLines(1:70,2), 'LineWidth', 2);
    legend({'Straight','Curved'});
    set(gca,'FontSize',16);
    xlabel('Time (s)');
    ylabel('Correlation');
    
    %%
    conNames = {'OL Straight','OL Curve','CL','CL Straight','CL Curve','BCI Replay','LieCI'};
    
    figure
    imagesc(allCMat{1});
    set(gca,'YDir','normal','XTick',1:nCon','YTick',1:nCon,'XTicklabel',conNames,'YTickLabel',conNames,'XTickLabelRotation',45);
    set(gca,'FontSize',16);
    colorbar;
    
    for rowIdx=1:nCon
        for colIdx=1:nCon
            text(colIdx, rowIdx, num2str(allCMat{1}(rowIdx, colIdx),2), 'Color', 'k',...
                'HorizontalAlignment','Center','FontSize',12,'FontWeight','b')
        end
    end
    
    %%
    %decoding
    movWindow = [10, 40];
    conTrl = find(conNumber(1:length(badTrials))==1 & ~badTrials & targNum~=3);
    conIdx = [];
    for t=1:length(conTrl)
        trlStart = alignDat.eventIdx(conTrl(t));
        conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
    end
    olDec = buildLinFilts(tPos(conIdx,:), alignDat.zScoreSpikes(conIdx,:), 'inverseLinear');
    
    movWindow = [10, 40];
    conTrl = find(conNumber(1:length(badTrials))==3 & ~badTrials & targNum~=3);
    conIdx = [];
    for t=1:length(conTrl)
        trlStart = alignDat.eventIdx(conTrl(t));
        conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
    end
    clDec = buildLinFilts(tPos(conIdx,:), alignDat.zScoreSpikes(conIdx,:), 'inverseLinear');
    
    movWindow = [10, 40];
    conTrl = find(ismember(conNumber(1:length(badTrials)),[1 3]) & ~badTrials & targNum~=3);
    conIdx = [];
    for t=1:length(conTrl)
        trlStart = alignDat.eventIdx(conTrl(t));
        conIdx = [conIdx, (trlStart+movWindow(1)):(trlStart+movWindow(2))];
    end
    bothDec = buildLinFilts(tPos(conIdx,:), alignDat.zScoreSpikes(conIdx,:), 'inverseLinear');

    decOut_ol = alignDat.zScoreSpikes*olDec;
    decOut_cl = alignDat.zScoreSpikes*clDec;
    decOut_both = alignDat.zScoreSpikes*bothDec;
    
    avgOut = zeros(nCon,4,91,2);
    avgPos = zeros(nCon,4,91,2);
    
    targSet = [1 2 4 5];
    for c=1:nCon
        for targIdx=1:length(targSet)
            conTrl = find(conNumber(1:length(badTrials))==c & ~badTrials & targNum==targSet(targIdx));
            
            if c==1 || c==2
                concatDat_dec = triggeredAvg( decOut_both, alignDat.eventIdx(conTrl), [0 90] );
            else
                concatDat_dec = triggeredAvg( decOut_both, alignDat.eventIdx(conTrl), [0 90] );
            end
            
            concatDat_pos = triggeredAvg( alignDat.cursorPosition(:,1:2), alignDat.eventIdx(conTrl), [0 90] );
            
            avgOut(c,targIdx,:,:) = nanmean(concatDat_dec,1);
            avgPos(c,targIdx,:,:) = nanmean(concatDat_pos,1);
        end
    end
    
    conSet = [1 2 4 5];
    figure
    for c=1:length(conSet)
        con = conSet(c);
        subplot(2,2,c);
        hold on;
        
        if con==1 || con==4
            endTime = 60;
        else
            endTime = 88;
        end
        
        for targIdx=1:4
            pos = squeeze(avgPos(con,targIdx,:,:));
            decO = squeeze(avgOut(con,targIdx,:,:));
            
            plot(pos(2:endTime,1), pos(2:endTime,2));
            
            spacer = 2;
            quiver(pos(2:spacer:endTime,1),pos(2:spacer:endTime,2),decO(2:spacer:endTime,1),decO(2:spacer:endTime,2),1.2);
            
            %curved
            if con==2 || con==5
                plot(pos(35,1), pos(35,2), 'ro','MarkerSize',8);
            end
        end
    end
    
    %angle trajectories
    conSet = [1 2 4 5];
    figure;
    hold on;
    
    for c=1:length(conSet)
        con = conSet(c);
        
        if con==1 || con==4
            endTime = 55;
        else
            endTime = 88;
        end
        
        angles = zeros(size(avgOut,3),4);
        for targIdx=1:4
            decO = squeeze(avgOut(con,targIdx,:,:));
            targVec = targList(targSet(targIdx),:);
            
            angles(:,targIdx) = (decO*targVec'./matVecMag(decO,2));
        end
        
        timeAxis = (10:endTime)/50;
        plot(timeAxis, mean(angles(10:endTime,:),2),'LineWidth',2);
    end
    
    legend({'OL Straight','OL Curved','CL Straight','CL Curved'});
    xlabel('Time (s)');
    ylabel('cos(theta)');
    set(gca,'FontSize',16);
    
    %%
    %mPCA on curved trials    
    smoothSnippetMatrix = gaussSmooth_fast(alignDat.zScoreSpikes, 1.5);
    
    margGroupings = {{1, [1 3]}, ...
    {2, [2 3]}, ...
    {[1 2] ,[1 2 3]}, ...
    {3}};
    margNames = {'Target','Context','C x T','Time'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 3;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'parametric';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;

    trlIdx = find(ismember(conNumber(1:length(badTrials)),[2 5]) & ~badTrials & targNum~=3);
    contextFactor = conNumber(trlIdx);
    targFactor = targNum(trlIdx);
    
    [~,~,targFactor] = unique(targFactor);
    [~,~,contextFactor] = unique(contextFactor);

    mPCA_out = apply_mPCA_general( smoothSnippetMatrix, alignDat.eventIdx(trlIdx), ...
        [targFactor, contextFactor], [1 50], binMS/1000, opts_m );

end