datasets = {'t6.2014.09.12',{[5 7 9 16],[6 8 14 17]},{'M','I'},[5];
    't6.2014.09.12',{[15]},{'BCI'},[15];
    't6.2014.09.15',{[5 7 9 13],[4 6 8 11 14]},{'M','I'},[5];};

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
    [ R, stream ] = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.0, datasets{d,4}, filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
        end
        allR = [allR, R{x}];
    end
    
    speedThresh = 0.06;
    moveOccurred = false(size(allR));
    %for t=1:length(allR)
    %    moveOccurred(t) = any(allR(t).glove_speed>speedThresh);
    %end

    %smoothWidth = 0;
    %datFields = {'glove','cursorPosition','currentTarget','xk'};
    %binMS = 20;
    %unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );

    afSet = {'timeGoCue'};
    twSet = {[-1000,2000]};
    pfSet = {'goCue'};
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 30;
        datFields = {'glove','cursorPosition','currentTarget','glove_speed'};
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
            if strcmp(datasets{d,3}{blockSetIdx},'I')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
            elseif strcmp(datasets{d,3}{blockSetIdx},'M')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]';
            end
            trlIdx = find(trlIdx);

            if strcmp(afSet{alignSetIdx},'trialLength')
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)-10,1:2);
            else
                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
            end
            [targList, ~, targCodes] = unique(tPos,'rows');
            centerCode = find(all(targList==0,2));
            outerIdx = find(targCodes~=centerCode);
            
            trlIdx = trlIdx(outerIdx);
            targCodes = targCodes(outerIdx);
            
            %single-factor
            smooth_HLFP = gaussSmooth_fast(alignDat.zScoreHLFP, 1.5);
            dPCA_out = apply_dPCA_simple( smooth_HLFP, alignDat.eventIdx(trlIdx), ...
                targCodes, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(targList)-1,1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            bField = 'timeGoCue';
            colors = jet(8)*0.8;
            useCodeIdx = [1:4, 6:9];
            figure
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));

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
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));
                cd = triggeredAvg(alignDat.glove_speed, alignDat.eventIdx(plotIdx), [0, 50]);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:8));

            figure
            for codeIdx=1:8
                plotIdx = trlIdx(find(targCodes==useCodeIdx(codeIdx)));
                cd = triggeredAvg(diff(alignDat.glove(:,1:2)), alignDat.eventIdx(plotIdx), [0, 50]);
                tmpMean = squeeze(nanmean(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
                plot(traj(end,1), traj(end,2),'o','Color',colors(codeIdx,:),'MarkerFaceColor',colors(codeIdx,:));
            end
            axis equal;
            legend(mat2stringCell(1:8));

            figure;
            hold on;
            for codeIdx=1:8
                plot(targList(useCodeIdx(codeIdx),1), targList(useCodeIdx(codeIdx),2),...
                    'o','Color',colors(codeIdx,:),'MarkerFaceColor',colors(codeIdx,:));
            end
            axis equal;
            
            if strcmp(pfSet{alignSetIdx},'goCue')
                pNames = {'Delay','Move'};
                periodTime = {[-1000,0],[0,2000]};
                dimTitles = {'X','Y'};
                figure('Position',[322         596        1229         502]);
                for p=1:length(periodTime)
                    binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
                    binIdx(binIdx<1)=[];

                    for dimIdx=1:2
                        tmpDat = [];
                        for codeIdx=1:length(codeList)
                            plotIdx = trlIdx(targCodes==codeList(codeIdx));
                            cd = triggeredAvg(diff(alignDat.glove), alignDat.eventIdx(plotIdx), timeWindow/binMS);

                            tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
                            tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
                        end

                        pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
                        subplot(2,2,(dimIdx-1)*2+p);
                        boxplot(tmpDat(:,1), tmpDat(:,2));
                        %set(gca,'XTickLabel',codeLegend);
                        title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
                        set(gca,'FontSize',16);
                    end
                end
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');
            end
        end %block set
    end %alignment set
    
end
