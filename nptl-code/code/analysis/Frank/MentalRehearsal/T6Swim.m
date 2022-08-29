datasets = {'t6.2013.04.12',{[1 8 16],[2 9],[3 10],[7 15]},{'M','I','W','S'},[1];
    't6.2013.08.08',{[3 7 12],[4 8],[6 11],[5 10]},{'M','I','W','S'},[3]
    't6.2013.09.04',{[0 5 6 10],[1 2 7],[3 8],[4 9]},{'M','I','W','S'},[3]
    't6.2013.10.09',{[0 4],[1],[2],[3]},{'M','I','W','S'},[3]
    't6.2014.01.07',{[3 7 12],[4 8],[6 11],[5 10]},{'M','I','W','S'},[3]
    't6.2013.04.09',{[0],[4 8],[6 11],[5 10]},{'M','I','W','S'},[3]};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    filtOpts.filtFields = {'glove'};
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, datasets{d,4}, filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
        end
        allR = [allR, R{x}];
    end
    
    speedThresh = 0.06;
    moveOccurred = false(size(allR));
    for t=1:length(allR)
        moveOccurred(t) = any(allR(t).glove_speed>speedThresh);
    end

    %smoothWidth = 0;
    %datFields = {'glove','cursorPosition','currentTarget','xk'};
    %binMS = 20;
    %unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );

    afSet = {'goCue'};
    twSet = {[-500,1500]};
    pfSet = {'goCue'};
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 30;
        datFields = {'glove','currentMovement','glove_speed'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        for blockSetIdx = 1:length(datasets{d,2})
            
            %all activity
            %if strcmp(datasets{d,3}{blockSetIdx},'I')
            %    trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
            %elseif strcmp(datasets{d,3}{blockSetIdx},'M')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
            %end
            trlIdx = find(trlIdx);
            movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));
            codeList = unique(movCues);
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(codeList),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            bField = 'goCue';
            colors = jet(length(codeList))*0.8;
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));

                hold on
                for t=1:length(plotIdx)
                    outerTrlIdx = plotIdx(t);
                    gloveSpeed = double(allR(outerTrlIdx).glove_speed');

                    showIdx = allR(outerTrlIdx).(bField):(allR(outerTrlIdx).(bField)+1000);
                    showIdx(showIdx>length(gloveSpeed))=[];
                    showIdx(showIdx<1) = [];
                    plot(gloveSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(alignDat.glove_speed, alignDat.eventIdx(plotIdx), [0, 50]);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:length(codeList)));

            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(diff(alignDat.glove), alignDat.eventIdx(plotIdx), [0, 50]);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
            end
            
        end %block set
    end %alignment set
    
end
