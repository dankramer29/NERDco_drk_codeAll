function plot_dPCA_blocks(blockNums)
    global modelConstants
    addpath(genpath([modelConstants.sessionRoot modelConstants.projectDir '/' modelConstants.codeDir ...
        modelConstants.analysisDir 'Frank']));

    %%
    %load cued movement dataset
    if modelConstants.isSim
        rmsFactor = 1;
    else
        rmsFactor = 3.5;
    end
    R = getSTanfordBG_RStruct( modelConstants.sessionRoot, blockNums, [], rmsFactor );

    alignFields = {'timeGoCue'};
    smoothWidth = 30;
    datFields = {'windowsMousePosition','cursorPosition','currentTarget'};
    timeWindow = [-800, 2000];
    binMS = 20;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    tooLow = meanRate < 0.5;
    alignDat.rawSpikes(:,tooLow) = [];
    alignDat.meanSubtractSpikes(:,tooLow) = [];
    alignDat.zScoreSpikes(:,tooLow) = [];

    %%
    %dPCA, head vs. bci
    crossCon = 1:length(blockNums);
    
    crossPostfix = cell(length(blockNums)+1,1);
    for c=2:length(crossPostfix)
        crossPostfix{c} = ['_block' num2str(blockNums(c-1))];
    end
    crossPostfix{1} = '_within';
    
    movTypeText = cell(length(blockNums),1);
    for c=1:length(movTypeText)
        movTypeText{c} = ['Block ' num2str(blockNums(c))];
    end
    
    movTypesPlot = cell(length(blockNums),1);
    for c=1:length(movTypesPlot)
        movTypesPlot{c} = blockNums(c);
    end
    
    dPCA_out = cell(size(movTypesPlot,1),1);
    for pIdx = 1:size(movTypesPlot,1)
        trlIdx = find(ismember(alignDat.bNumPerTrial, movTypesPlot{pIdx,1}));
        posErr = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+2,1:2) - alignDat.cursorPosition(alignDat.eventIdx(trlIdx)+2,1:2);
        dirCodes = dirTrialBin( posErr, 8 );
        
        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
        [targList, ~, targCodes] = unique(tPos,'rows');
        outerIdx = find(targCodes~=5);

        dPCA_out{pIdx} = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx((outerIdx))), ...
            dirCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CI','CD'} );
        close(gcf);
    end    

    dPCA_cross = cell(length(crossCon),1);
    for crossIdx = 1:length(crossCon)
        dPCA_cross{crossIdx} = dPCA_out;
        for c=1:length(dPCA_out)
            dPCA_cross{crossIdx}{c}.whichMarg = dPCA_out{crossCon(crossIdx)}.whichMarg;
            for axIdx=1:20
                for conIdx=1:size(dPCA_cross{crossIdx}{c}.Z,2)
                    dPCA_cross{crossIdx}{c}.Z(axIdx,conIdx,:) = dPCA_out{crossCon(crossIdx)}.W(:,axIdx)' * squeeze(dPCA_cross{crossIdx}{c}.featureAverages(:,conIdx,:));
                end
            end
        end            
    end
    
    outDir = [modelConstants.sessionRoot modelConstants.analysisDir 'dPCA' filesep num2str(blockNums)] ;
    mkdir(outDir);
    for plotCross = 1:length(crossPostfix)
        topN = 4;
        plotIdx = 1;

        timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
        yLims = [];
        axHandles=[];   

        figure('Position',[272          82         652        100+(115*length(movTypesPlot))],'Name',crossPostfix{plotCross});
        for pIdx=1:length(movTypesPlot)
            cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
            for c=1:topN
                axHandles(plotIdx) = subtightplot(length(movTypesPlot),topN,(pIdx-1)*topN+c);
                hold on

                colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
                for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                    if plotCross==1
                        plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                    else
                        plot(timeAxis, squeeze(dPCA_cross{plotCross-1}{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
                    end
                end

                axis tight;
                yLims = [yLims; get(gca,'YLim')];
                plotIdx = plotIdx + 1;

                plot(get(gca,'XLim'),[0 0],'k');
                plot([0, 0],[-100, 100],'--k');
                set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

                if pIdx==length(movTypesPlot)
                    xlabel('Time (s)');
                else
                    set(gca,'XTickLabel',[]);
                end
                if pIdx==1
                    title(['Dim ' num2str(c)],'FontSize',11)
                end
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);

                if c==1
                    ylabel(movTypeText{pIdx});
                    %text(-0.05,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
                end
                set(gca,'FontSize',14);
                set(gca,'YLim',yLims(end,:));
            end
        end

        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
        for p=1:length(axHandles)
           set(axHandles(p), 'YLim', finalLimits);
        end

        saveas(gcf,[outDir filesep 'dPCA_all' crossPostfix{plotCross} '.png'],'png');
    end
end