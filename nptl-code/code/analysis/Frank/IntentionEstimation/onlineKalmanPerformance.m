%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/BrainGate2'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));
resultsDirRoot = '/Users/frankwillett/Data/CaseDerived/';
bg2FileDir = '/Users/frankwillett/Data/BG Datasets';

%1 = Unit Vector
%2 = Refit
%3 = Model
mkdir([resultsDirRoot filesep 'FBCDecoder']);
mkdir('/Users/frankwillett/Data/CaseDerived/IntentionEstimationOnline/');

sessionList = {'t8.2016.03.01_Different_Filter_Assumptions',4:5,6:20,'T8';
    't8.2016.03.02_Different_Filter_Assumptions',3,4:21,'T8';
    't9.2016.08.01 Intention Estimator Comparison',3,[4:12],'T9';
    't9.2016.09.13 Intention Estimator Comparison',3,[4:9],'T9'};
blockCodes = cell(size(sessionList,1),1);

%blocknum, method, gain
blockCodes{1} = [6 2 1;
    7 1 1;
    8 3 1;
    9 1 1;
    10 2 1;
    11 3 1;
    12 3 2;
    13 2 2;
    14 1 2;
    15 2 2;
    16 3 2;
    17 1 2;
    18 1 2;
    19 3 2;
    20 2 2;
    ];
blockCodes{2} = [4 3 1;
    5 1 1;
    6 2 1;
    7 2 1;
    8 3 1;
    9 1 1;
    10 1 2;
    11 2 2;
    12 3 2;
    13 3 2;
    14 1 2;
    15 2 2;
    16 2 2;
    17 3 2;
    18 1 2;
    19 1 2;
    20 2 2;
    21 3 2;
    ];
blockCodes{3} = [4 3 1;
    5 1 1;
    6 2 1;
    7 1 1;
    8 2 1;
    9 3 1;
    10 2 1;
    11 1 1;
    12 3 1;
    ];
blockCodes{4} = [4 2 2;
    5 1 2;
    6 3 2;
    7 1 2;
    8 2 2;
    9 3 2;
    ];
%1 = Unit Vector
%2 = Refit
%3 = Model



%%
%example trajectories
%blockwise average performance, for two gains
%distance vs. time curves, for two gains
methods = {'UnitVec','ReFIT','PLM'};
exampleTraj = {'t8.2016.03.02_Different_Filter_Assumptions',[4:6],'t8.2016.03.02_Different_Filter_Assumptions',[19:21];
     't9.2016.08.01 Intention Estimator Comparison',[4:6], 't9.2016.09.13 Intention Estimator Comparison',[4:6];};

 for e=1:size(exampleTraj,1)
    figure;
    
    for g=1:2
        sessionName = exampleTraj{e,(g-1)*2+1};
        blockNums = exampleTraj{e,g*2};
        sessIdx = find(strcmp(sessionName, sessionList(:,1)));
        
        files = loadBG2Files([bg2FileDir filesep sessionName],blockNums,{'slc'});
        for b=1:3
            rowIdx = find(ismember(blockCodes{sessIdx}(:,1),blockNums));
            plotIdx = find(blockCodes{sessIdx}(rowIdx,2)==b);
            
            sBLOCKS = struct;
            sBLOCKS.sGInt.Name = 'BG2D';
            if strcmp(sessionName(1:2),'t8')
                sBLOCKS.sGInt.GameName = 'Case 3d Targets';
            else
                sBLOCKS.sGInt.GameName = 'Twigs';
            end
            sBLOCKS.sBLK.SaveTo=1;
            P = slcDataToPFile(files.slc{plotIdx}, sBLOCKS);
            
            if isfield(P.loopMat,'wristPos')
                pos = P.loopMat.wristPos(:,1:2);
                targets = P.loopMat.targetWristPos(:,1:2);
                tRad = median(P.loopMat.targetEndpointRad(P.trl.reaches(:,1)+2));
            else
                pos = P.loopMat.cursorPos;
                targets = P.loopMat.targetPos;
                tRad = median(P.loopMat.targetRad(P.trl.reaches(:,1)+2) + P.loopMat.cursorRad(P.trl.reaches(:,1)+2));
            end
            
            [targList,~,targCode] = unique(targets(P.trl.reaches(:,1)+2,:),'rows');
            isOuterReach = (targCode~=5);
            colorIdx = targCode;
            returnToCenterIdx = find(~isOuterReach);
            returnToCenterIdx(returnToCenterIdx<2) = [];
            colorIdx(returnToCenterIdx) = colorIdx(returnToCenterIdx-1);
            colorIdx(colorIdx>4) = colorIdx(colorIdx>4)-1;
            
            subtightplot(2,3,(g-1)*3+b);
            hold on;
            plotColoredTrajectories2D( pos, colorIdx(isOuterReach), P.trl.reaches(isOuterReach,:), false, targList([1:4 6:9],:), tRad, true );
            if strcmp(sessionName(1:2),'t8')
                xlim([-20 20]);
                ylim([-20 20]+40.5);
            else
                xlim([-0.6 0.6]);
                ylim([-0.6 0.6]);
            end
            axis off;
            
            if g==1
                title(methods{b},'FontSize',12);
            end
        end
    end
    
    exportPNGFigure(gcf, [resultsDir filesep 'IntentionEstimationOnline' filesep 'ExampleTraj ' sessionName(1:2)]);
 end

%%
trialTable = [];
meanTable = [];
dvtTable = cell(2,2,3);
for s=1:size(sessionList,1)
    blockNums = sessionList{s,3};
    sessionName = sessionList{s,1};
    files = loadBG2Files([bg2FileDir filesep sessionName],blockNums,{'slc','ncs'});
    
    filtDir = dir([bg2FileDir filesep sessionName filesep 'Data' filesep 'NCS Data' filesep 'Filters*']);
    filtDate = datenum(vertcat(filtDir.date));
    [~,lastIdx] = max(filtDate);
    
    tmp=load([bg2FileDir filesep sessionName filesep 'Data' filesep 'NCS Data' filesep filtDir(lastIdx).name]);
    filtTrainBlocks = zeros(length(files.ncs),1);
    for n=1:length(files.ncs)
        filtNum = files.ncs{n}.singleBlock.sBLK.NeuralCursorFromFilter;
        filtTrainBlocks(n) = tmp.sFILTERS(filtNum).TrainingBlockList(end);
    end

    for b=1:length(blockNums)
        sBLOCKS.sGInt.Name = 'BG2D';
        if strcmp(sessionName(1:2),'t8')
            sBLOCKS.sGInt.GameName = 'Case 3d Targets';
        else
            sBLOCKS.sGInt.GameName = 'Twigs';
        end
        P = slcDataToPFile(files.slc{b}, sBLOCKS);
        
        if isfield(P.loopMat,'wristPos')
            pos = P.loopMat.wristPos(:,1:2);
            targets = P.loopMat.targetWristPos(:,1:2);
            tRad = P.loopMat.targetEndpointRad;
        else
            pos = P.loopMat.cursorPos;
            targets = P.loopMat.targetPos;
            tRad = P.loopMat.targetRad + P.loopMat.cursorRad;
        end
        
        decVel = P.loopMat.kalmanOut(:,1:2) - files.slc{b}.task.velocityBias(:,1:2);
        [ perfTable, perfHeader ] = computeBasicPerformance_v2( pos, targets, tRad, ...
            P.loopMat.sysTime, 8, repmat(0.75,size(P.trl.reaches,1),1), P.trl.reaches );
        
        targDist = matVecMag(targets-pos,2);
        angErrByTrial = zeros(size(perfTable,1),1);
        for t=1:size(perfTable,1)
            loopIdx = (P.trl.reaches(t,1)+15):P.trl.reaches(t,2);
            loopIdx(targDist(loopIdx)<tRad(loopIdx))=[];
            angErrByTrial(t) = (180/pi)*mean(abs(getAngularError(decVel(loopIdx,:), targets(loopIdx,:)-pos(loopIdx,:))));
        end
        
        newRow = zeros(1,19);
        [newRow(1),~,newRow(2:3)]=normfit(perfTable(:,2)); %mov time
        [newRow(4),~,newRow(5:6)]=normfit(perfTable(~isnan(perfTable(:,6)),6)); %trans time
        [newRow(7),~,newRow(8:9)]=normfit(perfTable(~isnan(perfTable(:,8)),8)); %dial time
        [newRow(10),~,newRow(11:12)]=normfit(perfTable(:,11)); %path eff
        [newRow(13),~,newRow(14:15)]=normfit(angErrByTrial); %ang err
        
        rowIdx = find(blockCodes{s}(:,1)==blockNums(b));
        newRow(16) = s; %session idx
        newRow(17) = b; %block idx
        newRow(18) = blockCodes{s}(rowIdx,2); %method code
        newRow(19) = blockCodes{s}(rowIdx,3); %gain code
        newRow(20) = strcmp(sessionList{s,end},'T9')+1;
        trainBlockNum = find(filtTrainBlocks(b)==blockNums);
        if ~isempty(trainBlockNum)
            newRow(21) = blockCodes{s}(filtTrainBlocks(b)==blockNums,2);
        else
            newRow(21) = 1;
        end
        
        meanTable = [meanTable; newRow];
        
        newTable = [perfTable(:,[2 6 8 9]) angErrByTrial repmat(newRow(16:end), length(angErrByTrial), 1)];
        
        badIdx = find(P.trl.reaches(:,2)-P.trl.reaches(:,1)>420);
        newTable(badIdx,:) = [];
        trialTable = [trialTable; newTable];
        
        tmpDVT = nan(size(P.trl.reaches,1),1000);
        for t=1:size(P.trl.reaches,1)
            loopIdx = P.trl.reaches(t,1):P.trl.reaches(t,2);
            tmpDVT(t,1:length(loopIdx)) = targDist(loopIdx);
        end
%         if s~=4
%            badIdx = find(P.trl.reaches(:,2)-P.trl.reaches(:,1)>300);
%            tmpDVT(badIdx,:)=[];
%            disp(length(find(badIdx)));
%         end
        dvtTable{newRow(20), newRow(19), newRow(18)} = [dvtTable{newRow(20), newRow(19), newRow(18)}; tmpDVT];
    end
end

%%
sList = {'T8','T9'};
meanAcquireTimes = zeros(2,2,3);
metricIdx = [2 3 4 5];
metricNames = {'Translation Time (s)','Dial-in Time (s)','Path Efficiency','Mean Angular Error (°)'};
for sCode = 1:2
    cMap = [1 0.6 0.6; 0.6 1 0.6; 0.6 0.6 1; 0 0 0; 1 0.6 0.6; 0.6 1 0.6; 0.6 0.6 1;];
    labels = [methods, {''}, methods];
    
    figure('Position',[680   458   697   520]);
    for m=1:length(metricIdx)
        subplot(2,2,m);
        hold on;
        
        rowIdxLow = find(trialTable(:,8)==1 & trialTable(:,9)==1 & trialTable(:,10)==sCode);
        rowIdxHigh = find(trialTable(:,8)==1 & trialTable(:,9)==2 & trialTable(:,10)==sCode);
        allData = nan(max(length(rowIdxLow), length(rowIdxHigh)), 7);
        
        for methodIdx=1:3
            rowIdxLow = find(trialTable(:,8)==methodIdx & trialTable(:,9)==1 & trialTable(:,10)==sCode);
            rowIdxHigh = find(trialTable(:,8)==methodIdx & trialTable(:,9)==2 & trialTable(:,10)==sCode);
            allData(1:length(rowIdxLow), methodIdx) = trialTable(rowIdxLow, metricIdx(m));
            allData(1:length(rowIdxHigh), methodIdx+4) = trialTable(rowIdxHigh, metricIdx(m));
            meanAcquireTimes(sCode,1,methodIdx) = mean(trialTable(rowIdxLow,1));
            meanAcquireTimes(sCode,2,methodIdx) = mean(trialTable(rowIdxHigh,1));
        end
        
        barGraphOptions( allData, labels, cMap );
        yLimits = get(gca,'YLim');
        if sCode==2 && m==4
            yLimits = [0 80];
        end
        yLimits(1) = max(0, yLimits(1));
        ylim(yLimits);

        
        textPoint = yLimits(2);
        text(2, textPoint, 'Low Gain', 'HorizontalAlignment','Center','FontSize',12);
        text(6, textPoint, 'High Gain','HorizontalAlignment','Center','FontSize',12);
        ylabel(metricNames{m});
        set(gca,'XTick',[1 2 3 5 6 7],'XTickLabel',[methods methods]);
        set(gca,'FontSize',14);
    end
    exportPNGFigure(gcf, [resultsDir filesep 'IntentionEstimationOnline' filesep 'Bar ' sList{sCode}]);
end

normFactors = [14 0.5];
colors = [1 0 0; 0 1 0; 0 0 1]*0.8;
for sCode = 1:2
    if sCode==1
        targRad = 100*(4/14);
    else
        targRad = 100*(0.0947/0.5);
    end
    
    figure('Position',[680   720   735   258]);
    for g=1:2
        subplot(1,2,g);
        hold on;
        lHandles = zeros(1,3);
        tAxis = ((1:1000)-1)*0.02;
        for m=1:3
            lineCI = zeros(1000,2);
            for t=1:1000
                tmp = dvtTable{sCode, g, m}(:,t);
                tmp(isnan(tmp))=[];
                [~,~,lineCI(t,:)] = normfit(tmp);
            end
            lineCI(lineCI<0)=0.0001;
            badRows = any(isinf(lineCI) | isnan(lineCI),2);
            plotIdx = round(meanAcquireTimes(sCode,g,m)*50);
            
            lHandles(m) = plot(tAxis(1:plotIdx), 100*(nanmean(dvtTable{sCode, g, m}(:,1:plotIdx))/normFactors(sCode)), 'Color', colors(m,:), 'LineWidth', 2);
            errorPatch(tAxis(1:plotIdx)', 100*lineCI(1:plotIdx,:)/normFactors(sCode), colors(m,:), 0.2);
        end
        
        xlim([0 max(meanAcquireTimes(sCode,g,:))+0.5]);
        plot(get(gca,'XLim'),[targRad targRad],'--k');
        ylabel('Distance from Target (%)');
        xlabel('Time (s)');
        set(gca,'YScale','log');
        %if sCode==1
        %    ylim([0.15 1.2]*100);
        %else
        	ylim([0.10 1.2]*100);
            set(gca,'YTickLabels',[10 100]);
        %end
        if g==1
            legend(lHandles, methods);
        end
        set(gca,'FontSize',14);
        
        if g==1
            title('Low Gain');
        else
            title('High Gain');
        end
    end
    exportPNGFigure(gcf, [resultsDir filesep 'IntentionEstimationOnline' filesep 'DvT ' sList{sCode}]);
end

%%
for sCode = 1:2
    figure;
    hold on;
    
    colors = [0 0 1; 1 0 0]*0.9;
    rowIdx = find(meanTable(:,20)==sCode);
    subTable = meanTable(rowIdx,:);
    setIdx = 1:3;
    
    for t=1:(size(subTable,1)/3)
        plmIdx = find(meanTable(setIdx,18)==3);
        jitter = (rand(3,1)-0.5)*0.3;
        
        subplot(2,2,1);
        hold on;
        plot(meanTable(setIdx,18)+jitter, meanTable(setIdx,4)-meanTable(setIdx(plmIdx),4), 'o', 'Color', colors(meanTable(setIdx(1),19),:));
        for x=1:3
            plot([meanTable(setIdx(x),18)+jitter(x) meanTable(setIdx(x),18)+jitter(x)], ...
                meanTable(setIdx(x),5:6)-meanTable(setIdx(plmIdx),4), '-', 'Color', colors(meanTable(setIdx(1),19),:));
        end
        
        subplot(2,2,2);
        hold on;
        plot(meanTable(setIdx,18)+jitter, meanTable(setIdx,7)-meanTable(setIdx(plmIdx),7), 'o', 'Color', colors(meanTable(setIdx(1),19),:));
        for x=1:3
            plot([meanTable(setIdx(x),18)+jitter(x) meanTable(setIdx(x),18)+jitter(x)], ...
                meanTable(setIdx(x),8:9)-meanTable(setIdx(plmIdx),7), '-', 'Color', colors(meanTable(setIdx(1),19),:));
        end
        
        subplot(2,2,3);
        hold on;
        plot(meanTable(setIdx,18)++jitter, meanTable(setIdx,10)-meanTable(setIdx(plmIdx),10), 'o', 'Color', colors(meanTable(setIdx(1),19),:));
        for x=1:3
            plot([meanTable(setIdx(x),18)+jitter(x) meanTable(setIdx(x),18)+jitter(x)], ...
                meanTable(setIdx(x),11:12)-meanTable(setIdx(plmIdx),10), '-', 'Color', colors(meanTable(setIdx(1),19),:));
        end
        
        subplot(2,2,4);
        hold on;
        plot(meanTable(setIdx,18)+jitter, meanTable(setIdx,13)-meanTable(setIdx(plmIdx),13), 'o', 'Color', colors(meanTable(setIdx(1),19),:));
        for x=1:3
            plot([meanTable(setIdx(x),18)+jitter(x) meanTable(setIdx(x),18)+jitter(x)], ...
                meanTable(setIdx(x),14:15)-meanTable(setIdx(plmIdx),13), '-', 'Color', colors(meanTable(setIdx(1),19),:));
        end
        
        setIdx = setIdx + 3;
    end
    
    for x=1:4
        subplot(2,2,x);
        hold on;
        plot(get(gca,'XLim'),[0 0],'--k');
    end
end

%%
%split into repeat vs. non-repeat modes
sList = {'T8','T9'};
metricIdx = [2 3 4 5];
metricNames = {'Translation Time (s)','Dial-in Time (s)','Path Efficiency','Mean Angular Error (°)'};
for sCode = 1:2
    cMotif = [1 0.6 0.6; 0.6 1 0.6; 0.6 0.6 1];
    cMap = [cMotif; cMotif; [0 0 0]; cMotif; cMotif];
    labels = {'UnitVec','ReFIT','PLM',...
        'UnitVec','ReFIT','PLM',...
        '',...
        'UnitVec','ReFIT','PLM',...
        'UnitVec','ReFIT','PLM'};
    
    figure('Position',[44         282        1134         805]);
    for m=1:length(metricIdx)
        subplot(2,2,m);
        hold on;
        
        rowIdxLow = find(trialTable(:,8)==1 & trialTable(:,9)==1 & trialTable(:,10)==sCode);
        rowIdxHigh = find(trialTable(:,8)==1 & trialTable(:,9)==2 & trialTable(:,10)==sCode);
        allData = nan(max(length(rowIdxLow), length(rowIdxHigh)), 6*2 + 1);
        
        for methodIdx=1:3
            rowIdxLow_repeat = find(trialTable(:,11)==methodIdx & trialTable(:,8)==methodIdx & trialTable(:,9)==1 & trialTable(:,10)==sCode);
            rowIdxHigh_repeat = find(trialTable(:,11)==methodIdx & trialTable(:,8)==methodIdx & trialTable(:,9)==2 & trialTable(:,10)==sCode);
            
            rowIdxLow_diff = find(trialTable(:,11)~=methodIdx & trialTable(:,8)==methodIdx & trialTable(:,9)==1 & trialTable(:,10)==sCode);
            rowIdxHigh_diff = find(trialTable(:,11)~=methodIdx & trialTable(:,8)==methodIdx & trialTable(:,9)==2 & trialTable(:,10)==sCode);
            
            allData(1:length(rowIdxLow_repeat), methodIdx) = trialTable(rowIdxLow_repeat, metricIdx(m));
            allData(1:length(rowIdxLow_diff), methodIdx+3) = trialTable(rowIdxLow_diff, metricIdx(m));
            
            allData(1:length(rowIdxHigh_repeat), methodIdx+7) = trialTable(rowIdxHigh_repeat, metricIdx(m));
            allData(1:length(rowIdxHigh_diff), methodIdx+10) = trialTable(rowIdxHigh_diff, metricIdx(m));
        end
        
        barGraphOptions( allData, labels, cMap );
        yLimits = get(gca,'YLim');
        if sCode==2 && m==4
            yLimits = [0 80];
        end
        yLimits(1) = max(0, yLimits(1));
        ylim(yLimits);

        textPoint = yLimits(2);
        text(3.5, textPoint, 'Low Gain', 'HorizontalAlignment','Center','FontSize',12);
        text(10.5, textPoint, 'High Gain','HorizontalAlignment','Center','FontSize',12);
        
        textPoint = yLimits(2)-diff(yLimits)*0.2;
        text(2, textPoint, 'Repeat', 'HorizontalAlignment','Center','FontSize',12);
        text(5, textPoint, 'Different','HorizontalAlignment','Center','FontSize',12);
        
        text(9, textPoint, 'Repeat', 'HorizontalAlignment','Center','FontSize',12);
        text(12, textPoint, 'Different','HorizontalAlignment','Center','FontSize',12);
        
        ylabel(metricNames{m});
        set(gca,'FontSize',18,'LineWidth',1.5);
    end
    exportPNGFigure(gcf, [resultsDir filesep 'IntentionEstimationOnline' filesep 'Bar repeat ' sList{sCode}]);
end
