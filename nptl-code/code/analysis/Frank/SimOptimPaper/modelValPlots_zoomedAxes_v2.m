function modelValPlots_zoomedAxes_v2(resultsDir, sessions, visModelType)
    %summarize effects of gain, smooth, target radius, dwell time, target
    %distance on performance
    mkdir([resultsDir filesep 'figures' filesep 'performanceSummary']);
    tmp = load([resultsDir filesep 'conditionTables' filesep 'observedTable ' visModelType{2} ' _tRad.mat']); 
    cTableObs = tmp.conTable;

    modelStr = getSimString_v2( visModelType );
    tmp = load([resultsDir filesep 'conditionTables' filesep 'tableSim_' num2str(visModelType{1}) '_' visModelType{2} '_all.mat']); 
    cTableSim = tmp.conTable;
    
    %remove calibartion conditions
    calIdx = cTableObs{:,'condition'}==1;
    cTableObs(calIdx,:) = [];
    cTableObs{:,'condition'} = cTableObs{:,'condition'}-1;
    cTableSim(calIdx,:) = [];
    cTableSim{:,'condition'} = cTableSim{:,'condition'}-1;
    
%     %%
%     perfFields = {'exDialTime','translateTime','pathEff'};
%     limits = [3 8 1];
%     sGroups = {1:8, 9:15};
%     gap = [0.02 0.03]*1.3;
%     marg_h = [0.04 0.08];
%     marg_w = [0.14 0.02];
%     fontSizeMult = 1.35;
%     
%     for sGroupIdx = 1:length(sGroups)
%         nRows = 8;
%         
%         figure('Position',[187    63   582   923]);
%         for sessIdx=1:length(sGroups{sGroupIdx})
%             tableIdx = find(cTableObs{:,'sessionIdx'}==sGroups{sGroupIdx}(sessIdx));
%             for p=1:length(perfFields)
%                 %subtightplot(4,length(sessions),(p-1)*length(sessions) + s);
%                 subtightplot(nRows,4,(sessIdx-1)*4 + p, gap, marg_h, marg_w);
%                 hold on
%                 plot(cTableSim{tableIdx,perfFields{p}},cTableObs{tableIdx,perfFields{p}},'bo','MarkerSize',4);
%                 for t=1:length(tableIdx)
%                     plot([cTableSim{tableIdx(t),perfFields{p}}, cTableSim{tableIdx(t),perfFields{p}}],...
%                         [cTableObs{tableIdx(t),[perfFields{p} 'Low']}, cTableObs{tableIdx(t),[perfFields{p} 'High']}],'b-','LineWidth',1);
%                 end
%                 if strcmp(sessions(sGroups{sGroupIdx}(sessIdx)).subject,'T6')
%                     [~,trainIdx] = max(cTableSim{tableIdx,'TDS'});
%                 else
%                     [~,trainIdx] = min(cTableSim{tableIdx,'TDS'});
%                 end
%                 plot(cTableSim{tableIdx(trainIdx),perfFields{p}},cTableObs{tableIdx(trainIdx),perfFields{p}},'ro','MarkerSize',4);
%                 plot([cTableSim{tableIdx(trainIdx),perfFields{p}}, cTableSim{tableIdx(trainIdx),perfFields{p}}],...
%                     [cTableObs{tableIdx(trainIdx),[perfFields{p} 'Low']}, cTableObs{tableIdx(trainIdx),[perfFields{p} 'High']}],'r-','LineWidth',1);
% 
%                 axis tight;
%                 %axis equal;
%                 xlim([0 limits(p)]);
%                 ylim([0 limits(p)]);
%                 
%                 xLim = get(gca,'XLim');
%                 yLim = get(gca,'YLim');
%                 plot(xLim,yLim,'--k');
%                 
%                 if p==1
%                     dateText = [sessions(sGroups{sGroupIdx}(sessIdx)).name{1}(4:13)];
%                     dateText = strrep(dateText,'.','/');
%                     dateText = [dateText(6:end) '/' dateText(1:4)];
%                     text(-0.6,0.6,sessions(sGroups{sGroupIdx}(sessIdx)).subject{1} ,'Units','Normalized','FontSize',12*fontSizeMult);
%                     text(0.05,0.9,dateText,'Units','Normalized','FontSize',6*fontSizeMult);
%                 end
%                 
%                 %if (sGroupIdx==1) && (sessIdx==length(sGroups{sGroupIdx}))
%                     xLim(1) = xLim(1) + diff(xLim)*0.1;
%                     xLim(2) = xLim(2) - diff(xLim)*0.1;
%                     yLim(1) = yLim(1) + diff(yLim)*0.1;
%                     yLim(1) = yLim(1) - diff(yLim)*0.1;
%                     
%                     set(gca,'XTick',xLim,'XTickLabel',{num2str(xLim(1),2), num2str(xLim(2),2)});
%                     set(gca,'YTick',yLim,'YTickLabel',{num2str(xLim(1),2), num2str(xLim(2),2)});
%                 %else
%                 %    set(gca,'XTick',[],'YTick',[]); 
%                 %end
%                 set(gca,'FontSize',8*fontSizeMult);
%             end
% 
%             subtightplot(nRows,4,(sessIdx-1)*4 + 4, gap, marg_h, marg_w);
%             hold on;
%             plot(cTableObs{:,'TDS'}, cTableObs{:,'alpha'},'o','Color',[0.6 0.6 0.6],'MarkerSize',3);
%             plot(cTableObs{tableIdx,'TDS'}, cTableObs{tableIdx,'alpha'},'o','Color',[0 0 1],'MarkerSize',4,'MarkerFaceColor',[0 0 1]);
%             plot(cTableObs{tableIdx(trainIdx),'TDS'}, cTableObs{tableIdx(trainIdx),'alpha'},'o','Color',[1 0 0],'MarkerSize',4,'MarkerFaceColor','r');
%             set(gca,'XScale','log','YScale','linear');
%             xlim([0.1 10]);
%             ylim([0.75 1]);
%             if (sGroupIdx==1) && (sessIdx==length(sGroups{sGroupIdx}))
%                 set(gca,'XTick',[0.1 10],'YTick',[0.75 1]);
%                 xlabel('Gain');
%                 ylabel('Smoothing');
%             else
%                 set(gca,'XTick',[],'YTick',[]);
%             end
%             set(gca,'FontSize',8*fontSizeMult);
%         end
% 
%         subtightplot(nRows,4,(sessIdx-1)*4 + 1, gap, marg_h, marg_w);
%         xlabel('Predicted');
%         ylabel('Observed');
% 
%         subtightplot(nRows,4,1, gap, marg_h, marg_w);
%         title('Dial-in\newlineTime (s)','FontWeight','normal','FontSize',10*fontSizeMult);
% 
%         subtightplot(nRows,4,2, gap, marg_h, marg_w);
%         title('Translation\newlineTime (s)','FontWeight','normal','FontSize',10*fontSizeMult)
% 
%         subtightplot(nRows,4,3, gap, marg_h, marg_w);
%         title('Path\newlineEfficiency','FontWeight','normal','FontSize',10*fontSizeMult)
%         
%         subtightplot(nRows,4,4, gap, marg_h, marg_w);
%         title('Parameters','FontWeight','normal','FontSize',10*fontSizeMult);
%         
%         set(gcf,'PaperPositionMode','auto');
%         saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'gsBySession' num2str(sGroupIdx) '_zoomed' '_' visModelType{2}],'svg');
%         saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'gsBySession' num2str(sGroupIdx) '_zoomed' '_' visModelType{2}],'fig');
%     end
%     figure
%     for s=1:length(sessions)
%         tableIdx = find(cTableObs{:,'sessionIdx'}==s);
%         for p=1:length(perfFields)
%             subtightplot(length(sessions),4,(s-1)*4 + p);
%             hold on
%             plot(cTableObs{tableIdx,perfFields{p}},cTableSim{tableIdx,perfFields{p}},'o','MarkerSize',4);
%             plot([0 limits(p)],[0 limits(p)],'--k');
%             xlim([0 limits(p)]);
%             ylim([0 limits(p)]);
%             
%             set(gca,'XTick',[],'YTick',[]);
%         end
%     end
    
    %%    
    %err
    metrics  = {'exDialTime','translateTime','ttt','pathEff'};
    metricErr = zeros(0,4);
    metricErrControl = zeros(0,4);
    metricR2 = zeros(0,4);
    
    simPred = zeros(0,4);
    trueValues = zeros(0,4);
    
    simPred_u = zeros(0,4);
    trueValues_u = zeros(0,4);
    subjectCode = [];
    
    for s=1:length(sessions)
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        if strcmp(sessions(s).subject,'T6')
            [~,trainIdx] = max(cTableSim{tableIdx,'TDS'});
        else
            [~,trainIdx] = min(cTableSim{tableIdx,'TDS'});
        end
        
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
        simPred_u = [simPred_u; sv-mean(cTableObs{testIdx,metrics})];
        trueValues_u = [trueValues_u; cTableObs{testIdx,metrics}-mean(cTableObs{testIdx,metrics})];
        
        subjectCode = [subjectCode; cTableSim{testIdx,'subjectNum'}];
    end
    
    allR2 = zeros(length(metrics),2);
    allR2CI = zeros(length(metrics),2,2);
    for x=1:length(metrics)
        allR2(x,1) = getDecoderPerformance(simPred(:,x), trueValues(:,x), 'R2');
        allR2(x,2) = getDecoderPerformance(simPred_u(:,x), trueValues_u(:,x), 'R2');
        
        bootfun = @(x,y)getDecoderPerformance(x, y, 'R2');
        allR2CI(x,1,:) = bootci(1000,{bootfun,simPred(:,x),trueValues(:,x)});
        allR2CI(x,2,:) = bootci(1000,{bootfun,simPred_u(:,x),trueValues_u(:,x)});
    end
    
    MAE = zeros(length(metrics),3);
    for x=1:length(metrics)
        MAE(x,1) = mean(metricErr(:,x));
        MAE(x,2:3) = bootci(1000,{@mean,metricErr(:,x)});
    end
    
    allR2_sub = cell(3,1);
    mae_sub = cell(3,1);
    for subjectIdx=1:3
        allR2_sub{subjectIdx,1} = zeros(length(metrics),2,3);
        mae_sub{subjectIdx,1} = zeros(length(metrics),3);
        
        for x=1:length(metrics)
            mae_sub{subjectIdx,1}(x,1) = mean(metricErr(subjectCode==subjectIdx,x));
            mae_sub{subjectIdx,1}(x,2:3) = bootci(1000,{@mean,metricErr(subjectCode==subjectIdx,x)});
        end
        
        sRows = subjectCode==subjectIdx;
        for x=1:length(metrics)
            allR2_sub{subjectIdx,1}(x,1,1) = getDecoderPerformance(simPred(sRows,x), trueValues(sRows,x), 'R2');
            allR2_sub{subjectIdx,1}(x,2,1) = getDecoderPerformance(simPred_u(sRows,x), trueValues_u(sRows,x), 'R2');

            bootfun = @(x,y)getDecoderPerformance(x, y, 'R2');
            allR2_sub{subjectIdx,1}(x,1,2:3) = bootci(1000,{bootfun,simPred(sRows,x),trueValues(sRows,x)});
            allR2_sub{subjectIdx,1}(x,2,2:3) = bootci(1000,{bootfun,simPred_u(sRows,x),trueValues_u(sRows,x)});
        end
    end
    
    lineStats = cell(size(simPred_u,2),2);
    for x=1:size(simPred_u,2)
        lineStats{x,1} = regstats(double(simPred(:,x)),double(trueValues(:,x)),'linear');
        lineStats{x,2} = regstats(double(simPred_u(:,x)),double(trueValues_u(:,x)),'linear');
        %[B,BINT,R,RINT,STATS] = regress(simPred_u(:,x),[ones(size(trueValues_u,1),1), trueValues_u(:,x)]);
        %lineStats{x,2} = BINT;
    end
    
    save([resultsDir filesep 'figures' filesep 'optiPaper' filesep 'lineStats_' visModelType{1,2} '.mat'],'allR2','allR2CI','MAE','allR2_sub','mae_sub');
           
    %%
    plotNames = {'Raw','Corrected'};
    for plotIdx=1:2
        subjectList = {'T6','T7','T8'};
        sListLegend = cell(length(subjectList),1);
        for s=1:length(subjectList)
            sListLegend{s} = ['Participant ' subjectList{s}];
        end

        lHandles = zeros(length(subjectList),1);
        colors = [0.8 0 0; 0 0.6 0; 0 0 0.8];

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
        sessionOrder = randperm(length(sessions));

        perfFields = {'exDialTime','translateTime','ttt','pathEff'};
        perfNames = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)','Path Efficiency'};
        perfUnits = {'s','s','s',''};
        pairedIdx = [1 1; 1 2; 2 1; 2 2];
        if plotIdx==1
            limits = [3 8 8 1.0];
        else
            limits = [1.5 3 3 0.4];
        end
        
        for perfIdx=1:length(perfFields)
            p(2,pairedIdx(perfIdx,1),pairedIdx(perfIdx,2)).select();
            hold on;

            for s=1:length(sessions)
                tableIdx = find(cTableObs{:,'sessionIdx'}==sessionOrder(s));
                if strcmp(sessions(sessionOrder(s)).subject,'T6')
                    [~,conIdx] = max(roundedTable(tableIdx,1));
                else
                    [~,conIdx] = min(roundedTable(tableIdx,1));
                end
                testIdx = setdiff(tableIdx, conIdx);

                if plotIdx==1
                    meanToSub = 0;
                else
                    meanToSub = mean(cTableObs{testIdx,perfFields{perfIdx}});
                end
                
                plot(cTableObs{testIdx,perfFields{perfIdx}}-meanToSub, cTableSim{testIdx,perfFields{perfIdx}}-meanToSub, 'o', 'MarkerSize', 4, 'Color', colors(subjectNums(sessionOrder(s)),:));
                %plot(cTableObs{tableIdx(conIdx),perfFields{perfIdx}}, cTableSim{tableIdx(conIdx),perfFields{perfIdx}}, 'kx', 'MarkerSize', 4);
            end
            if plotIdx==1
                xlim([0, limits(perfIdx)]);
                ylim([0, limits(perfIdx)]);
            else  
                xlim([-limits(perfIdx), limits(perfIdx)]);
                ylim([-limits(perfIdx), limits(perfIdx)]);
            end
            axis square;
            
            xLimit1 = get(gca,'XLim');
            yLimit1 = get(gca,'YLim');
            
            plot(get(gca,'XLim'), get(gca,'YLim'), '-k');
            xLimits = get(gca,'XLim');
            regressionAxis = linspace(xLimits(1), xLimits(2), 100);
            regressionY = regressionAxis*lineStats{perfIdx,plotIdx}.beta(2) + lineStats{perfIdx,plotIdx}.beta(1);
            plot(regressionAxis, regressionY, '--k');
            
            xlim(xLimit1);
            ylim(yLimit1);
            
            title(perfNames{perfIdx});
            if perfIdx==3
                xlabel('Observed');
                ylabel('Predicted');
            end
            set(gca,'YTick',get(gca,'XTick'));
            
            text(0.05,0.90,['FVAF=' num2str(allR2(perfIdx,plotIdx),2)],...
                'Units','normalized');
            text(0.05,0.80,['MAE=' num2str(mean(metricErr(:,perfIdx)),2) ' ' perfUnits{perfIdx}],...
                'Units','normalized');
            
            text(0.5,0.2,['y=' num2str(lineStats{perfIdx,plotIdx}.beta(1),2) ' + ' num2str(lineStats{perfIdx,1}.beta(2),2) '*x'],...
                'Units','normalized');
            text(0.5,0.1,['p=' num2str(lineStats{perfIdx,plotIdx}.tstat.pval(2),3)],...
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
        set(gcf,'Renderer','painters');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig3_' plotNames{plotIdx} '_' visModelType{1,2}],'svg');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig3_'  plotNames{plotIdx} '_' visModelType{1,2}],'fig');
    end
    
    close all;
    return;
    
    %%
    %all trajectories
    testResultsCell = load([resultsDir filesep 'testFiles' filesep 'testCell_' num2str(visModelType{1}) '_' visModelType{2} '.mat']);
 
    %--Single factor plots--
    color = [0 0 0];
    perfFields = {'exDialTime','translateTime','ttt','pathEff'};

    sList = {'t6.2015.01.14.SmoothGain',1:8,'TDS';
        't8.2016.02.01_Fitts_and_2D_Smoothing',6:10,'alpha'};
    perfName = {'Dial-in Time (s)', 'Translation Time (s)','Total Movement Time (s)','Path Efficiency'};
    
    bc = cell(2,1);
    bc{1} = load([resultsDir filesep 'testFiles_sciRep' filesep 'bootCellT6_' num2str(visModelType{1}) '_' visModelType{2} '.mat']);
    bc{2} = load([resultsDir filesep 'testFiles_sciRep' filesep 'bootCellT8_2_' num2str(visModelType{1}) '_' visModelType{2} '.mat']);
    
    modelCI = cell(2,4);
    modelCI{1} = zeros(8,2);
    modelCI{2} = zeros(5,2);
    
    for metricIdx=1:4
        reorderIdx_con = [1 7 2 8 6 3 4 5];
        modelCI{1,metricIdx} = prctile(squeeze(bc{1}.allCurves(:,reorderIdx_con,metricIdx)),[2.5 97.5])';

        reorderIdx_con = {[5 8],[2 6],[1 9],[4 7],[3 10]};
        for c=1:length(reorderIdx_con)
            modelCI{2,metricIdx}(c,:) = prctile(mean(squeeze(bc{2}.allCurves_t8(:,reorderIdx_con{c},metricIdx)),2),[2.5 97.5]);
        end
    end
    
    %T6
%     0.9100    0.3008
%     0.9100    0.9025
%     0.9100    1.8050
%     0.9100    2.1059
%     0.9100    2.4067
%     0.9100    1.5042
%     0.9100    0.6017
%     0.9100    1.2034

    %T8
%     0.9550   18.0961
%     0.9050   18.0961
%     0.9900   18.0962
%     0.9790   18.0961
%     0.8000   18.0962
%     0.9050   18.0962
%     0.9790   18.0961
%     0.8000   18.0961
%     0.9550   18.0961
%     0.9900   18.0962
                
    for s = 1:size(sList,1)
        xAxis = sList{s,3};
        sCon = sList{s,2};
        trajCon = sCon;
        sName = sList{s,1};

        [~,sessionIdx] = ismember(sName,vertcat(sessions.name));

        pf = cell(2,1);
        pf{1} = load([resultsDir filesep 'prefitFiles' filesep 'prefit_' sName '.mat']);
        pf{1} =  pf{1}.prefitFile;
        pf{2} = testResultsToPrefitFile( testResultsCell, sessionIdx, 'predict', pf{1} );

        figure('Position',[633   239   912   759]);
        p = panel();
        p.pack('v',{1/3,1/3,1/3});
        p(1).pack('h',{1/4,1/4,1/4,1/4});
        p(2).pack('h',ones(1,length(trajCon))/length(trajCon));
        p(3).pack('h',ones(1,length(trajCon))/length(trajCon));

        tableIdx = find(cTableObs{:,'sessionIdx'}==sessionIdx & ismember(cTableObs{:,'condition'}, sCon));
        [~,sortIdx] = sort(cTableObs{tableIdx,xAxis},'ascend');
        tableIdx = tableIdx(sortIdx);
        lHandles = zeros(2,1);
        for pIdx=1:length(perfFields)
            p(1,pIdx).select();
            hold on
            %lHandles(1)=plot(cTableObs{tableIdx,xAxis}, cTableObs{tableIdx,perfFields{pIdx}}, '-', 'Color', 'k','LineWidth',2);
            errData = [cTableObs{tableIdx,[perfFields{pIdx} 'Low']},cTableObs{tableIdx,[perfFields{pIdx} 'High']}];
            meanData = cTableObs{tableIdx,perfFields{pIdx}};
            
            lHandles(1)=errorbar(cTableObs{tableIdx,xAxis}, meanData, meanData-errData(:,1), ...
                errData(:,2)-meanData, '-o', 'Color', color, 'LineWidth', 2);
            %errorPatch(cTableObs{tableIdx,xAxis}, errData, [0 0 0], 0.2);

            errData = modelCI{s,pIdx};
            meanData = cTableSim{tableIdx,perfFields{pIdx}};
            
            %lHandles(2)=plot(cTableSim{tableIdx,xAxis}, meanData, '-', 'Color', [0.8 0 0], 'LineWidth', 2);
            %errorPatch(cTableObs{tableIdx,xAxis}, errData, [0.8 0 0], 0.2);
            
            lHandles(2)=errorbar(cTableObs{tableIdx,xAxis}, meanData, meanData-errData(:,1), ...
                errData(:,2)-meanData, '-o', 'Color', [0.8 0 0], 'LineWidth', 2);
            
            %lHandles(2)=plot(cTableSim{tableIdx,xAxis}, cTableSim{tableIdx,perfFields{pIdx}}, '-', 'Color', 'r', 'LineWidth', 2);

            set(gca,'LineWidth',2);
            yLimits = get(gca,'YLim');
            ylim([0 yLimits(end)]);
            ylabel(perfName{pIdx});
            if strcmp(sList{s,3},'TDS')
                xlabel('Gain (\beta)');
                xlim([0.5 5]);
            else
                xlabel('Smoothing (\alpha)');
                xlim([0.79 1]);
            end
            if pIdx==1
                if s==1
                    legend(lHandles, {'Observed','Predicted'},'Position',[0.0754    0.9026    0.1238    0.0596]);
                else
                    legend(lHandles, {'Observed','Predicted'},'Position',[0.1194    0.9092    0.1238    0.0596]);
                end
                legend('Boxoff');
            end
        end

        tableIdx = find(cTableObs{:,'sessionIdx'}==sessionIdx & ismember(cTableObs{:,'condition'}, trajCon));
        [~,sortIdx] = sort(cTableObs{tableIdx,xAxis},'ascend');
        sortedTableIdx = tableIdx(sortIdx);
        trajCon = trajCon(sortIdx);
        for pIdx=1:2
            for cIdx=1:length(trajCon)
                p(pIdx+1,cIdx).select();
                trlIdx = pf{pIdx}.conditions.trialNumbers{trajCon(cIdx)+1};
                if pIdx==2
                    trlIdx = trlIdx(1:length(pf{1}.conditions.trialNumbers{trajCon(cIdx)+1}));
                end
                badIdx = pf{pIdx}.trl.targNums(trlIdx)==0;
                trlIdx(badIdx)=[];
                trlIdx = trlIdx(1:min([length(trlIdx), 60]));

                plotColoredTrajectories2D( pf{pIdx}.loopMat.positions, pf{pIdx}.trl.targNums(trlIdx), ...
                    pf{pIdx}.trl.reaches(trlIdx,:), ...
                    false, pf{pIdx}.trl.targList{trajCon(cIdx)+1}, median(pf{pIdx}.loopMat.targetRad), true );
                axis off;
                if strcmp(sessions(sessionIdx).subject,'T8')
                    xlim([-20 20]);
                    ylim([-20 20]+40.5);
                else
                    xlim([-0.6 0.6]);
                    ylim([-0.6 0.6]);
                end
                if pIdx==1
                    if strcmp(sList{s,3},'TDS')
                        text(0.5, 1.1, ['\beta=' num2str(cTableObs{sortedTableIdx(cIdx),xAxis},2)], 'Units', 'normalized',...
                            'HorizontalAlignment','center','FontWeight','bold','FontSize',16);
                    else
                        text(0.5, 1.1, ['\alpha=' num2str(cTableObs{sortedTableIdx(cIdx),xAxis},2)], 'Units', 'normalized',...
                            'HorizontalAlignment','center','FontWeight','bold','FontSize',16);
                    end
                end
                if pIdx==1 && cIdx==1
                    text(-0.15,0.25,'Observed','Units','normalized','rotation',90,'FontWeight','bold','FontSize',16);
                elseif pIdx==2 && cIdx==1
                    text(-0.15,0.25,'Predicted','Units','normalized','rotation',90,'FontWeight','bold','FontSize',16);
                end
            end
        end

        p.margin=2;
        p.marginleft=18;
        p(1).marginbottom=18;
        p.fontsize = 16;
%         p(2).marginleft = 40;
%         p(3).marginleft = 40;
        for pIdx=1:2
            for cIdx=1:length(trajCon)
                if cIdx~=1
                    p(pIdx+1,cIdx).marginleft=2;
                end
            end
        end
        
        set(gcf,'Renderer','painters');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig' num2str(s)],'svg');
        saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig' num2str(s)],'fig');
    end
    
    %%
%     figure; 
%     plot(cTableObs{:,'TDS'},cTableObs{:,'alpha'},'o'); 
%     set(gca,'YScale','log'); 
%     
%     figure
%     hold on
%     plot(paramsTable(:,6), cTableObs{:,'translateTime'}, 'o')
       
    sListLegend = cell(length(subjectList),1);
    for s=1:length(subjectList)
        sListLegend{s} = ['Participant ' subjectList{s}];
    end
    
    lHandles = zeros(length(subjectList),1);
    colors = [0.8 0 0; 0 0.6 0; 0 0 0.8];
    
    roundedTable = [0.01*round(cTableObs{:,'TDS'}/0.01),0.001*round(cTableObs{:,'alpha'}/0.001)];
    [pairList, idxToTable, tableToIdx] = unique(roundedTable,'rows');
    
    figure('Position',[138    59   655   925]);
    p = panel();
    p.pack('v',{2/5,3/5});
    p(2).pack(2,2);
    p(1).select();
    hold on;
    for s=1:length(sessions)
        tableIdx = find(cTableObs{:,'sessionIdx'}==s);
        if subjectNums(s)==1
            [~,conIdx] = max(roundedTable(tableIdx,1));
        else
            [~,conIdx] = min(roundedTable(tableIdx,1));
        end
        plot(roundedTable(tableIdx(conIdx),1), roundedTable(tableIdx(conIdx),2),'kx','MarkerSize',4);
    end
    for pIdx=1:size(pairList,1)
        nValues = length(find(tableToIdx==pIdx));
        originalTableIdx = idxToTable(pIdx);
        subjectIdx = paramsTable(originalTableIdx,1);
        
        lHandles(subjectIdx)=plot(roundedTable(originalTableIdx,1), roundedTable(originalTableIdx,2),'o','Color',colors(subjectIdx,:));
%         if nValues==2
%             plot(roundedTable(originalTableIdx,1), roundedTable(originalTableIdx,2),'+','Color',colors(subjectIdx,:),'MarkerSize',2);
%         elseif nValues==3
%             plot(roundedTable(originalTableIdx,1), roundedTable(originalTableIdx,2),'+','Color',colors(subjectIdx,:),'MarkerSize',6);
%         elseif nValues==4
%             plot(roundedTable(originalTableIdx,1), roundedTable(originalTableIdx,2),'+','Color',colors(subjectIdx,:),'MarkerSize',9);
%         end
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
    perfFields = {'exDialTime','translateTime','ttt','pathEff'};
    perfNames = {'Dial-in Time (s)','Translation Time (s)','Movement Time (s)','Path Efficiency'};
    pairedIdx = [1 1; 1 2; 2 1; 2 2];
    limits = [3 8 8 1];
    for perfIdx=1:length(perfFields)
        p(2,pairedIdx(perfIdx,1),pairedIdx(perfIdx,2)).select();
        hold on;

        for s=1:length(sessions)
            tableIdx = find(cTableObs{:,'sessionIdx'}==s);
            if subjectNums(s)==1
                [~,conIdx] = max(roundedTable(tableIdx,1));
            else
                [~,conIdx] = min(roundedTable(tableIdx,1));
            end
            plot(cTableObs{tableIdx,perfFields{perfIdx}}, cTableSim{tableIdx,perfFields{perfIdx}}, 'o', 'MarkerSize', 3, 'Color', colors(subjectNums(s),:));
            %plot(cTableObs{tableIdx(conIdx),perfFields{perfIdx}}, cTableSim{tableIdx(conIdx),perfFields{perfIdx}}, 'kx', 'MarkerSize', 4);
        end
        xlim([0 limits(perfIdx)]);
        ylim([0 limits(perfIdx)]);
        plot(get(gca,'XLim'), get(gca,'YLim'), '--k');
        title(perfNames{perfIdx});
        if perfIdx==3
            xlabel('Observed');
            ylabel('Predicted');
        end
        set(gca,'YTick',get(gca,'XTick'));
    end
    
    p(2,1,1).select();
    text(-0.25,1.15,'B','Units','Normalized','FontSize',26,'FontWeight','bold');
    
    p(1).select();
    text(-0.1,1.05,'A','Units','Normalized','FontSize',26,'FontWeight','bold');
    
    p(1).marginbottom = 22;
    p.margintop=8;
    p.fontsize = 12;
    
    set(gcf,'PaperPositionMode','auto');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig3'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig3'],'fig');
end

