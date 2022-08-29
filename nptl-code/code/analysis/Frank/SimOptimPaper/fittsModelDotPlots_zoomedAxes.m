function fittsModelDotPlots_zoomedAxes( sessions, resultsDir, visModelType )
    
    mkdir([resultsDir filesep 'figures' filesep 'fittsDotPlots']);
     
    %%
    err = [];
    chanceErr = [];
    perfFields = {'translateTime','exDialTime','ttt','pathEff'};
    modelStr = getSimString_v2( visModelType );
    
    tmp = load([resultsDir filesep 'conditionTables' filesep 'observedTable fittsPredict _all.mat']); 
    cTableObs = tmp.conTable;
    tmp = load([resultsDir filesep 'conditionTables' filesep 'tableSim' modelStr(5:end) '_all.mat']); 
    cTableSim = tmp.conTable;
    
    for s=1:length(sessions)
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        innerIdx = 1:12;
        for t=1:(length(tableIdx)/12)
            tmpErr = zeros(length(perfFields),2);
            for p=1:length(perfFields)
                tmpErr(p,1) = getDecoderPerformance(cTableSim{tableIdx(innerIdx),perfFields{p}}, ...
                    cTableObs{tableIdx(innerIdx),perfFields{p}}, 'MAE');
                tmpErr(p,2) = getDecoderPerformance(repmat(cTableSim{tableIdx(innerIdx(2)),perfFields{p}},12,1), ...
                    cTableObs{tableIdx(innerIdx),perfFields{p}}, 'MAE');
            end
            chanceErr = [chanceErr; tmpErr(:,2)'];
            err = [err; tmpErr(:,1)'];
            innerIdx = innerIdx + 12;
        end
    end
    
    %%
    err = [];
    chanceErr = [];
    perfFields = {'translateTime','exDialTime','ttt','pathEff'};
    
    for s=1:length(sessions)
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        innerIdx = 1:12;
        for t=1:(length(tableIdx)/12)
            tmpErr = zeros(length(perfFields),2);
            for p=1:length(perfFields)
                tmpErr(p,1) = getDecoderPerformance(cTableSim{tableIdx(innerIdx),perfFields{p}}, ...
                    cTableObs{tableIdx(innerIdx),perfFields{p}}, 'MAE');
                tmpErr(p,2) = getDecoderPerformance(repmat(cTableSim{tableIdx(innerIdx(5)),perfFields{p}},12,1), ...
                    cTableObs{tableIdx(innerIdx),perfFields{p}}, 'MAE');
            end
            chanceErr = [chanceErr; tmpErr(:,2)'];
            err = [err; tmpErr(:,1)'];
            innerIdx = innerIdx + 12;
        end
    end
    
    %%
    perfFields = {'exDialTime','translateTime','ttt',};
    perfTitles = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)'};
    fontSizeMult = 1.75;
    
    gap = [0.04 0.06];
    marg_h = [0.08 0.04];
    marg_w = [0.13 0.03];
    colorsRad = hsv(3)*0.8;
    colorsDist = copper(4)*0.8;
    [~,~,subjectNums] = unique(vertcat(sessions.subject));
  
    sGroups = {[3 4 5 6 7],[8 9 11 12]};
    limits = [5 4 7];
    
    for groupIdx = 1:length(sGroups)
        figure('Position',[486   110   570   1076]);
        sToPlot = sGroups{groupIdx};
        setIdx = 1;
        for s=1:length(sToPlot)
            tableIdx = find(cTableObs{:,'sessionIdx'}==sToPlot(s));
            gainList = unique(cTableSim{tableIdx,'nativeGain'});
            for t=1:length(gainList)
                innerIdx = find(cTableSim{tableIdx,'nativeGain'}==gainList(t));
                [~,~,rGroup] = unique(cTableSim{tableIdx(innerIdx),'targRad'});
                
                nGroups = length(cTableSim{tableIdx(innerIdx),'targDist'});
                dGroup = zeros(nGroups,1);
                tmpIdx = 1:(nGroups/4);
                for targIdx=1:4
                    dGroup(tmpIdx) = targIdx;
                    tmpIdx = tmpIdx + (nGroups/4);
                end
                
                %if any(cTableSim{tableIdx(innerIdx),'targDist'}>10)
                %    [~,~,dGroup] = unique(round(cTableSim{tableIdx(innerIdx),'targDist'}/1.0)*1.0);
                %else
                %    [~,~,dGroup] = unique(round(cTableSim{tableIdx(innerIdx),'targDist'}/0.02)*0.02);
                %end
                
                for p=1:length(perfFields)
                    subtightplot(6,length(perfFields),(setIdx-1)*length(perfFields) + p, gap, marg_h, marg_w);
                    hold on
                    %plot(cTableSim{tableIdx(innerIdx(1)),perfFields{p}},cTableObs{tableIdx(innerIdx(1)),perfFields{p}},'ro','MarkerSize',3);
                    if p==2
                        colors = colorsDist;
                    else
                        colors = colorsRad;
                    end
                    for x=1:length(tableIdx(innerIdx))
                        if p==2
                            colorIdx = dGroup(x);
                        else
                            colorIdx = rGroup(x);
                        end
                        plot(cTableSim{tableIdx(innerIdx(x)),perfFields{p}},cTableObs{tableIdx(innerIdx(x)),perfFields{p}},'o','MarkerSize',5,...
                            'Color',colors(colorIdx,:),'LineWidth',1);
                        plot([cTableSim{tableIdx(innerIdx(x)),perfFields{p}}, cTableSim{tableIdx(innerIdx(x)),perfFields{p}}],...
                            [cTableObs{tableIdx(innerIdx(x)),[perfFields{p} 'Low']}, cTableObs{tableIdx(innerIdx(x)),[perfFields{p} 'High']}],'-','LineWidth',1,...
                            'Color',colors(colorIdx,:));
                    end

                    %plot([0 limits(p)],[0 limits(p)],'--k');
                    %xlim([0 limits(p)]);
                    %ylim([0 limits(p)]);
                    
                    axis tight;
                    xLim = get(gca,'XLim');
                    yLim = get(gca,'YLim');
                    plot(xLim,yLim,'--k');

                    if p==1
                        dateText = [sessions(sToPlot(s)).name{1}(4:13)];
                        dateText = strrep(dateText,'.','/');
                        dateText = [dateText(6:end) '/' dateText(1:4)];
                        text(-0.5,0.6,sessions(sToPlot(s)).subject{1} ,'Units','Normalized','FontSize',12*fontSizeMult);
                        text(0.05,0.9,dateText,'Units','Normalized','FontSize',7*fontSizeMult);
                        text(0.7,0.3,['D=' num2str(cTableSim{tableIdx(innerIdx(1)),'dwellTime'},2)],'Units','Normalized','FontSize',7*fontSizeMult);
                        text(0.7,0.2,['\beta=' num2str(cTableObs{tableIdx(innerIdx(1)),'TDS'},2)],'Units','Normalized','FontSize',7*fontSizeMult);
                        text(0.7,0.1,['\alpha=' num2str(cTableSim{tableIdx(innerIdx(1)),'alpha'},2)],'Units','Normalized','FontSize',7*fontSizeMult);
                    end

                    if setIdx==1
                        title(perfTitles{p},'FontWeight','normal','FontSize',10*fontSizeMult);
                    end
                    if setIdx==6 && groupIdx==1
                        if p==1
                            xlabel('Predicted','FontSize',8*fontSizeMult);
                            ylabel('Observed','FontSize',8*fontSizeMult);
                        end
                    end
                    
                    xLim(1) = xLim(1) + diff(xLim)*0.1;
                    xLim(2) = xLim(2) - diff(xLim)*0.1;
                    yLim(1) = yLim(1) + diff(yLim)*0.1;
                    yLim(1) = yLim(1) - diff(yLim)*0.1;
                    
                    set(gca,'XTick',xLim,'XTickLabel',{num2str(xLim(1),2), num2str(xLim(2),2)});
                    set(gca,'YTick',yLim,'YTickLabel',{num2str(xLim(1),2), num2str(xLim(2),2)});
                    set(gca,'FontSize',8*fontSizeMult,'LineWidth',1);
                end
                setIdx = setIdx + 1;
            end
        end
        set(gcf,'PaperPositionMode','auto');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsBySession' num2str(groupIdx) '_zoomedAxes'],'svg');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsBySession' num2str(groupIdx) '_zoomedAxes'],'fig');
    end
    
    %%
    %two example sessions translate time, dial-in time, movement time as a
    %function of rad/dist factor
    sToPlot = [5 8];
    perfFields = {'exDialTime','translateTime'};
    perfTitles = {'Dial-in Time (s)','Translation Time (s)'};
    limits = [4.5 2.5];
    
    figure('Position',[ 624   456   774   522]);
    for s=1:length(sToPlot)
        tableIdx = find(cTableObs{:,'sessionIdx'}==sToPlot(s));
        [~,~,rGroup] = unique(cTableSim{tableIdx,'targRad'});
        [dList,~,dGroup] = unique(cTableSim{tableIdx,'targDist'});
        
        for p=1:length(perfFields)
            subplot(length(sToPlot),length(perfFields),(s-1)*2+p);
            hold on
            rIdx = 1:3;
            tickIdx = 1:3;
            for d=1:length(dList)
                lHandles(1)=errorbar(tickIdx, cTableObs{tableIdx(rIdx),perfFields{p}}, ...
                    cTableObs{tableIdx(rIdx),perfFields{p}}-cTableObs{tableIdx(rIdx),[perfFields{p} 'Low']}, ...
                    cTableObs{tableIdx(rIdx),[perfFields{p} 'High']}-cTableObs{tableIdx(rIdx),perfFields{p}}, '-ok', 'LineWidth', 2);
                lHandles(2)=plot(tickIdx, cTableSim{tableIdx(rIdx),perfFields{p}}, '-r', 'LineWidth', 2);
                rIdx = rIdx + 3;
                tickIdx = tickIdx + 4;
            end
            set(gca,'XTick',[1 2 3 5 6 7 9 10 11 13 14 15]);
            set(gca,'XTickLabel',{'S','M','L','S','M','L','S','M','L','S','M','L'});
            xlim([0 16]);
            ylim([0 limits(p)]);
            ylabel(perfTitles{p});
            
            if s==1 && p==1
                legend(lHandles,{'Observed','Predicted'});
            end
            if p==2
                set(gca,'YTick',[0 1 2]);
            end
        end
    end
    
    %%
    modelStr = getSimString_v2( visModelType );
    
    tmp = load([resultsDir filesep 'conditionTables' filesep 'observedTable fittsPredict _tRad.mat']); 
    cTableObsRad = tmp.conTable;
    tmp = load([resultsDir filesep 'conditionTables' filesep 'tableSim' modelStr(5:end) '_tRad.mat']); 
    cTableSimRad = tmp.conTable;
    
    tmp = load([resultsDir filesep 'conditionTables' filesep 'observedTable fittsPredict _tDist.mat']); 
    cTableObsDist = tmp.conTable;
    tmp = load([resultsDir filesep 'conditionTables' filesep 'tableSim' modelStr(5:end) '_tDist.mat']); 
    cTableSimDist = tmp.conTable;
    
    ws = [0.8 26];
    sToPlot = [5 8];
    perfFields = {'exDialTime','translateTime','ttt'};
    perfTitles = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)'};
    limits = [4.5 2.5];
    
    figure('Position',[118   460   985   522]);
    for s=1:length(sToPlot)
        load([resultsDir filesep 'figures' filesep 'fittsLawFigures' filesep sessions(sToPlot(s)).name{1} ...
            filesep 'fittsTable'],'fittsTable');
       
        subplot(length(sToPlot),3,(s-1)*3+1);
        hold on
  
        tableIdx = find(cTableObsRad{:,'sessionIdx'}==sToPlot(s));
        lHandles(1)=errorbar(cTableObsRad{tableIdx,'targRad'}/ws(s), cTableObsRad{tableIdx,'exDialTime'}, ...
            cTableObsRad{tableIdx,'exDialTime'}-cTableObsRad{tableIdx,'exDialTimeLow'}, ...
            cTableObsRad{tableIdx,'exDialTimeHigh'}-cTableObsRad{tableIdx,'exDialTime'}, '-ok', 'LineWidth', 2);
        lHandles(2)=plot(cTableObsRad{tableIdx,'targRad'}/ws(s), cTableSimRad{tableIdx,'exDialTime'}, '-r', 'LineWidth', 2);
        set(gca,'YTick',[0 1 2]);
        xlim([0.05 0.18]);
        xlabel('Target Radius');
        ylabel('Dial-in Time (s)');
        text(-0.55, 0.5, sessions(sToPlot(s)).subject{1}, 'Units','Normalized','FontSize',16,'FontWeight','bold');
        
        subplot(length(sToPlot),3,(s-1)*3+2);
        hold on
        
        tableIdx = find(cTableObsDist{:,'sessionIdx'}==sToPlot(s));
        lHandles(1)=errorbar(cTableObsDist{tableIdx,'targDist'}/ws(s), cTableObsDist{tableIdx,'translateTime'}, ...
            cTableObsDist{tableIdx,'translateTime'}-cTableObsDist{tableIdx,'translateTimeLow'}, ...
            cTableObsDist{tableIdx,'translateTimeHigh'}-cTableObsDist{tableIdx,'translateTime'}, '-ok', 'LineWidth', 2);
        lHandles(2)=plot(cTableObsDist{tableIdx,'targDist'}/ws(s), cTableSimDist{tableIdx,'translateTime'}, '-r', 'LineWidth', 2);
        set(gca,'YTick',[0 1 2]);
        xlim([0.2 0.85]);
        xlabel('Target Distance');
        ylabel('Translation Time (s)');
        
        subplot(length(sToPlot),3,(s-1)*3+3);
        hold on
           
        colorsDark = hsv(3)*0.4;
        colorsBright = hsv(3);
        tableIdx = find(cTableObs{:,'sessionIdx'}==sToPlot(s));
        [rList,~,rGroup] = unique(cTableSim{tableIdx,'targRad'});
        for r=1:length(rList)
            innerIdx = tableIdx(rGroup==r);
            ID = log2(cTableObs{innerIdx,'targDist'}./cTableObs{innerIdx,'targRad'});
            lHandles(1)=errorbar(ID, cTableObs{innerIdx,'ttt'}, ...
                cTableObs{innerIdx,'ttt'}-cTableObs{innerIdx,'tttLow'}, ...
                cTableObs{innerIdx,'tttHigh'}-cTableObs{innerIdx,'ttt'}, '-o', 'LineWidth', 1, 'Color', colorsDark(r,:));
            lHandles(2)=plot(ID, cTableSim{innerIdx,'ttt'}, '-', 'LineWidth', 2, 'Color', colorsBright(r,:));
        end
        xlim([0 4]);
        xlabel('ID = log_2(D/R)');
        ylabel('Movement Time (s)');
    end
    
    set(gcf,'PaperPositionMode','auto');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsExample'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsExample'],'fig');

    %%
    %example 12 panels of trajectories + simulated trajectories
    sToPlot = 8;
    load([resultsDir '\prefitFiles\prefit_' sessions(sToPlot).name{1} '.mat']);
    testCell = load([resultsDir filesep 'testFiles' filesep 'testCell_6_fittsPredict.mat']);
    prefitFileSim = testResultsToPrefitFile( testCell, sToPlot, 'fittsPredict', prefitFile );  
    
    pFiles = {prefitFile, prefitFileSim};
    for p=1:length(pFiles)
        tRadByTrl = pFiles{p}.loopMat.targetRad(pFiles{p}.trl.reaches(:,1))/pFiles{p}.workspaceSize;
        tDistByTrl = pFiles{p}.loopMat.targDist(pFiles{p}.trl.reaches(:,1))/pFiles{p}.workspaceSize;
        [~,tDistByTrl] = histc(tDistByTrl, [0.15 0.3 0.45 0.6 0.75]);
        
        trlIdx = pFiles{p}.conditions.trialNumbers{2};
        tRadList = unique(tRadByTrl(trlIdx));
        rotatePos = rotateTraj( pFiles{p}.loopMat.positions/pFiles{p}.workspaceSize, ...
            pFiles{p}.loopMat.targetPos/pFiles{p}.workspaceSize, pFiles{p}.trl.reaches );
        
        figure('Position',[ 212   407   757   450]);
        for d=1:4
            for r=1:3
                subtightplot(4,3,(d-1)*3 + r);
                hold on
                
                innerIdx = intersect(find(tRadByTrl==tRadList(r) & tDistByTrl==d), trlIdx);
                innerIdx = innerIdx(1:10);
                for x=1:length(innerIdx)
                    loopIdx = pFiles{p}.trl.reaches(innerIdx(x),1):pFiles{p}.trl.reaches(innerIdx(x),2);
                    plot(rotatePos(loopIdx,1), rotatePos(loopIdx,2), 'b-');
                end
                rectangle('Position',[-tRadList(r) -tRadList(r), tRadList(r)*2, tRadList(r)*2],'Curvature',[1 1],'LineWidth',2); 
                set(gca,'XTick',[],'YTick',[]);
                axis equal;
                xlim([-1 0.3]);
                ylim([-0.3 0.3]);
            end
        end
        
        set(gcf,'PaperPositionMode','auto');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsExampleTraj_' num2str(p)],'svg');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fittsExampleTraj_' num2str(p)],'fig');
    end
    
    %%
    setIdx = 1;
    figure
    for s=[3:9,11:12]
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        innerIdx = 1:12;
        for t=1:(length(tableIdx)/12)
            for p=1:length(perfFields)
                subplot(2,2,p);
                hold on;
                plot(cTableObs{tableIdx(innerIdx),perfFields{p}}, ...
                    cTableSim{tableIdx(innerIdx),perfFields{p}}, 'o', 'Color', colors(subjectNums(s),:), 'MarkerSize', 3);
            end
            setIdx = setIdx + 1;
            innerIdx = innerIdx + 12;
        end
    end
    
    lim = [5 4 6 1];
    for p=1:length(perfFields)
        subplot(2,2,p);
        hold on;
        plot([0 lim(p)],[0 lim(p)],'--k');
        axis equal;
        xlim([0 lim(p)]);
        ylim([0 lim(p)]);
    end
    
    %%
    sessionGroups = {{'t6.2014.12.03.GainSmooth','t6.2014.12.05.SmoothGain'},{'t6.2015.03.06.FittsSmoothGain','t8.2015.03.11_Fitts',...
        't6.2015.03.16.FittsSmoothGain','t8.2015.03.17_Fitts','t6.2015.03.23.FittsHighSpeed','t8.2015.05.12_Fitts',...
        't8.2015.05.28_FittsSquared','t8.2015.08.31_Fitts_low_high_gain','t8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp'}};
    sessionGroupNames = {'T6 four gain.dwell conditions','T6+T8 single.double gain conditions'};
    perfFields = {'exDialTime','translateTime','ttt','pathEff','overshoots','isSuccessfulReach'};
    fittsSuffixes = {'_all','_tRad','_tDist'};
    colors = [0.8 0 0; 0 0 0.8];
    for f=1:length(fittsSuffixes)
        %load performance tables
        tmp = load([resultsDir filesep 'conditionTables' filesep 'observedTable fittsExplain ' fittsSuffixes{f} '.mat']); 
        cTableObs = tmp.conTable;

        modelStr = getSimString_v2( visModelType );
        tmp = load([resultsDir filesep 'conditionTables' filesep 'tableSim' modelStr(5:end) fittsSuffixes{f} '.mat']); 
        cTableSim = tmp.conTable;
    
        if f==1
            insets = {'exDialTime',[0 0.5];
                'translateTime',[0.6 2];};
        elseif f==2
            insets = {'exDialTime',[0 0.5];
                'translateTime',[0.8 2];};
        elseif f==3
            insets = {'exDialTime',[0 0.5];
                'translateTime',[0.6 2];};
        end

        for s=1:length(sessionGroups)
            [~,sessionIdx] = ismember(sessionGroups{s},vertcat(sessions.name));
            tableRows = find(ismember(cTableObs{:,'sessionIdx'},sessionIdx));
            dotAndErrorPlotFromTable(cTableObs, cTableSim, perfFields, tableRows, [], [], colors, {'T6','T8'},[],insets);
            saveas(gcf, [resultsDir filesep 'figures' filesep 'fittsDotPlots' filesep sessionGroupNames{s} modelStr fittsSuffixes{f} '.fig'], 'fig');
        end
        close all;
    end
      
    %%
    %find training conditions for each session to exclude
    trainingIdx = cell(length(sessions),1);
    for s=1:length(sessions)
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        tRad = cTableSim{tableIdx,'targRad'};
        tDist = cTableSim{tableIdx,'targDist'};
        gain = cTableSim{tableIdx,'nativeGain'};
        dwell = cTableSim{tableIdx,'dwellTime'};
        
        gdValues = unique([gain, dwell],'rows');
        trainIdx = [];
        for g=1:size(gdValues,1)
            innerIdx = find(gain==gdValues(g,1) & dwell==gdValues(g,2));
            [radList,~,radIdx]=unique(tRad(innerIdx));
            smallRadIdx = find(radIdx==1);
            [~,maxDistIdx] = max(tDist(innerIdx(smallRadIdx)));
            trainIdx = [trainIdx, tableIdx(innerIdx(smallRadIdx(maxDistIdx)))];
        end
        trainingIdx{s} = trainIdx;
    end
        
    %err
    metrics  = {'exDialTime','translateTime','ttt','pathEff'};
    metricErr = zeros(0,4);
    metricErrControl = zeros(0,4);
    metricR2 = zeros(0,4);
    
    simPred = zeros(0,4);
    trueValues = zeros(0,4);
    
    simPred_u = zeros(0,4);
    trueValues_u = zeros(0,4);
    sToPlot = [3 4 5 6 7,8 9 11 12];
    
    for sessIdx=1:length(sToPlot)
        s = sToPlot(sessIdx);
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        trainIdx = trainingIdx{s};
        
        testIdx = setdiff(tableIdx, trainIdx);
        newData = zeros(length(testIdx),length(metrics));
        controlData = zeros(length(testIdx),length(metrics));
        newR2 = zeros(1,length(metrics));
        
        for m=1:length(metrics)
            newData(:,m) = abs(cTableSim{testIdx,metrics{m}} - cTableObs{testIdx,metrics{m}});
            controlData(:,m) = abs(cTableObs{testIdx,metrics{m}}-mean(cTableObs{testIdx,metrics{m}}));
            newR2(m) = getDecoderPerformance(cTableSim{testIdx,metrics{m}},cTableObs{testIdx,metrics{m}},'R2');
        end
        
        metricErr = [metricErr; newData];
        metricErrControl = [metricErrControl; controlData];
        metricR2 = [metricR2; newR2];
        
        simPred = [simPred; cTableSim{testIdx,metrics}];
        trueValues = [trueValues; cTableObs{testIdx,metrics}];
        
        sv = cTableSim{testIdx,metrics};
        %sv = sv(randperm(size(sv,1)),:);
        simPred_u = [simPred_u; sv-nanmean(cTableObs{testIdx,metrics})];
        trueValues_u = [trueValues_u; cTableObs{testIdx,metrics}-nanmean(cTableObs{testIdx,metrics})];
    end
    
    lineStats = cell(size(simPred_u,2),2);
    for x=1:size(simPred_u,2)
        lineStats{x,1} = regstats(double(simPred(:,x)),double(trueValues(:,x)),'linear');
        lineStats{x,2} = regstats(double(simPred_u(:,x)),double(trueValues_u(:,x)),'linear');
        %[B,BINT,R,RINT,STATS] = regress(simPred_u(:,x),[ones(size(trueValues_u,1),1), trueValues_u(:,x)]);
        %lineStats{x,2} = BINT;
    end
    
    %%
    plotNames = {'Raw','Corrected'};
    for plotIdx=1:2
        subjectList = {'T6','T8'};
        sListLegend = cell(length(subjectList),1);
        for s=1:length(subjectList)
            sListLegend{s} = ['Participant ' subjectList{s}];
        end

        lHandles = zeros(length(subjectList),1);
        colors = [0 0 0; 0.8 0 0; 0 0 0.8];

        roundedTable = [0.01*round(cTableObs{:,'TDS'}/0.01),0.001*round(cTableObs{:,'alpha'}/0.001)];
        [pairList, idxToTable, tableToIdx] = unique(roundedTable,'rows');
        subjectNums = cTableObs{:,'subjectNum'};

        figure('Position',[159   499   376   574]);
        p = panel();
        p.pack('v',{2/5,3/5});
        p(2).pack(2,2);
        p(1).select();
        hold on;
        for s=1:length(sessions)
            tableIdx = find(cTableObs{:,'sessionIdx'}==s);
            if strcmp(sessions(s).subject,'T6')
                [~,conIdx] = max(roundedTable(tableIdx,1));
            else
                [~,conIdx] = min(roundedTable(tableIdx,1));
            end
            plot(roundedTable(tableIdx(conIdx),1), roundedTable(tableIdx(conIdx),2),'kx','MarkerSize',4);
        end
        for pIdx=1:size(pairList,1)
            nValues = length(find(tableToIdx==pIdx));
            originalTableIdx = idxToTable(pIdx);
            subjectIdx = subjectNums(originalTableIdx,1);

            lHandles(subjectIdx)=plot(roundedTable(originalTableIdx,1), roundedTable(originalTableIdx,2),'o','Color',colors(subjectIdx,:));
        end

        title('Parameters Tested');
        ylabel('Smoothing (\alpha)');
        xlabel('Gain (\beta)');
        set(gca,'XScale','log','YScale','linear');

        l=legend(lHandles,sListLegend,'Location','SouthEast');
        xlim([0 10]);
        ylim([0.75 1]);

        subjectNames = unique(vertcat(sessions.subject));
        [~,~,subjectNums] = unique(vertcat(sessions.subject));
        
        sToPlot = [3 4 5 6 7,8 9 11 12];
        sessionOrder = sToPlot(randperm(length(sToPlot)));

        perfFields = {'exDialTime','translateTime','ttt','pathEff'};
        perfNames = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)','Path Efficiency'};
        pairedIdx = [1 1; 1 2; 2 1; 2 2];
        if plotIdx==1
            limits = [3 5 5 1.0];
        else
            limits = [1.5 3 3 0.5];
        end
        
        for perfIdx=1:length(perfFields)
            p(2,pairedIdx(perfIdx,1),pairedIdx(perfIdx,2)).select();
            hold on;

            for s=1:length(sessionOrder)
                tableIdx = find(cTableObs{:,'sessionIdx'}==sessionOrder(s));
                trainIdx = trainingIdx{sessionOrder(s)};
                pIdx = setdiff(tableIdx, trainIdx);
                
                if plotIdx==1
                    meanToSub = 0;
                else
                    meanToSub = mean(cTableObs{pIdx,perfFields{perfIdx}});
                end
                
                plot(cTableObs{pIdx,perfFields{perfIdx}}-meanToSub, cTableSim{pIdx,perfFields{perfIdx}}-meanToSub, 'o', 'MarkerSize', 5, 'Color', colors(subjectNums(sessionOrder(s)),:));
                %plot(cTableObs{tableIdx(conIdx),perfFields{perfIdx}}, cTableSim{tableIdx(conIdx),perfFields{perfIdx}}, 'kx', 'MarkerSize', 4);
            end
            if plotIdx==1
                xlim([0, limits(perfIdx)]);
                ylim([0, limits(perfIdx)]);
            else  
                xlim([-limits(perfIdx), limits(perfIdx)]);
                ylim([-limits(perfIdx), limits(perfIdx)]);
            end
            %plot(get(gca,'XLim'), get(gca,'YLim'), '--k');
            
            xLimits = get(gca,'XLim');
            regressionAxis = linspace(xLimits(1), xLimits(2), 100);
            regressionY = regressionAxis*lineStats{perfIdx,plotIdx}.beta(2) + lineStats{perfIdx,plotIdx}.beta(1);
            plot(regressionAxis, regressionY, '-k');
            
            title(perfNames{perfIdx});
            if perfIdx==3
                xlabel('Observed');
                ylabel('Predicted');
            end
            set(gca,'YTick',get(gca,'XTick'));
            
            text(0.1,0.9,['y=' num2str(lineStats{perfIdx,plotIdx}.beta(1),3) ' + ' num2str(lineStats{perfIdx,1}.beta(2),3) '*x'],...
                'Units','normalized');
            text(0.1,0.8,['R2=' num2str(lineStats{perfIdx,plotIdx}.rsquare,2)],...
                'Units','normalized');
            text(0.1,0.7,['p=' num2str(lineStats{perfIdx,plotIdx}.tstat.pval(2),3)],...
                'Units','normalized');
            text(0.1,0.6,['MAE=' num2str(nanmean(metricErr(:,perfIdx)),3)],...
                'Units','normalized');
        end

        p(2,1,1).select();
        text(-0.25,1.15,'B','Units','Normalized','FontSize',26,'FontWeight','bold');

        p(1).select();
        text(-0.1,1.05,'A','Units','Normalized','FontSize',26,'FontWeight','bold');

        p(1).marginbottom = 22;
        p.marginleft=16;
        p.margintop=8;
        p.fontsize = 14;

        set(gcf,'PaperPositionMode','auto');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fitts_dotPlot' plotNames{plotIdx}],'svg');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fitts_dotPlot'  plotNames{plotIdx}],'fig');
    end

end

