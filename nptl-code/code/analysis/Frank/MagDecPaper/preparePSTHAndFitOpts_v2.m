function [ psthOpts, in, forPCA ] =  preparePSTHAndFitOpts_v2( sessionName, sessionType, gameType, saveDir, cursorPos, targetPos, reaches, features, featLabels, triggerType)

    psthOpts = makePSTHOpts();
    psthOpts.timeStep = 0.02;
    psthOpts.neuralData = {features};
    psthOpts.timeWindow = [-50 100];
    psthOpts.plotDir = saveDir;
    psthOpts.orderBySNR = true;
    psthOpts.gaussSmoothWidth = 1.5;
    psthOpts.featLabels = featLabels;
    psthOpts.plotsPerPage = 12;

    targDist = matVecMag(targetPos-cursorPos,2);
    maxDist = prctile(targDist(reaches(:,1)+2),90);

    in.cursorPos = cursorPos;
    in.targetPos = targetPos;
    in.reachEpochs = reaches;
    in.reachEpochs_fit = reaches;
    in.features = features;
    in.maxDist = maxDist;
    in.plot = false;

    if strcmp(sessionName, 't9.2016.08.01 Intention Estimator Comparison')
        in.outlierRemoveForCIS = true;
    else
        in.outlierRemoveForCIS = false;
    end
    
    if strcmp(sessionType,'smoothing')
        in.gameType = 'coImmediate';

        targetByTrial = targetPos(reaches(:,1)+2,:);
        [targList,~,targIdx] = unique(targetByTrial,'rows');
        isOuter = find(targIdx~=5);
        targIdx(targIdx==5)=-1;
        targIdx(targIdx>5) = targIdx(targIdx>5)-1;

        returnIdx = cell(4,1);
        returnIdx{1} = find(targIdx==1)+1;
        returnIdx{2} = find(targIdx==4)+1;
        returnAll = vertcat(returnIdx{:});
        returnAll(returnAll>length(reaches))=[];
        for c=1:length(returnIdx)
            returnIdx{c}(returnIdx{c}>length(reaches))=[];
        end

        triggerEvent = reaches(:,1);
        tableIdx = find(strcmp(sessionList{s,2}, smoothConditions(:,1)));
        smoothCon = smoothConditions{tableIdx, 2}(relativeBlockNums(triggerEvent));
        nSmoothCon = length(unique(smoothCon));

        rightIdx = [find(targIdx==8); returnIdx{1}];
        upIdx = [find(targIdx==5); returnIdx{2}];
        conAll = 8+nSmoothCon+[smoothCon(rightIdx)'; smoothCon(upIdx)'+nSmoothCon];

        psthOpts.trialEvents = [triggerEvent(isOuter,1); triggerEvent(:,1); triggerEvent([rightIdx; upIdx],1);];
        psthOpts.trialConditions = [targIdx(isOuter); 8+smoothCon'; conAll];

        dirColors = hsv(8)*0.8;
        purpleMap = [203 201 226; 158 154 200; 106 81 163; 84 39 143]/255;
        orangeMap = [253 190 133; 253 141 60; 217 71 1; 166 54 3]/255;
        if nSmoothCon==4
            smoothColors = purpleMap;
            smoothColors2 = [smoothColors; orangeMap];
        elseif nSmoothCon==3
            smoothColors = [purpleMap(2,:); purpleMap(3,:); purpleMap(4,:)];
            smoothColors2 = [smoothColors; orangeMap(2,:); orangeMap(3,:); orangeMap(4,:)];
        elseif nSmoothCon==2
            smoothColors = [purpleMap(2,:); purpleMap(4,:)];
            smoothColors2 = [smoothColors; orangeMap(2,:); orangeMap(4,:)];
        end

        colors = [dirColors; smoothColors; smoothColors2];
        psthOpts.lineArgs = cell(size(colors,1),1);
        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5};
        end

        if nSmoothCon==4
            psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10 11 12],[13 14 15 16 17 18 19 20]};
        elseif nSmoothCon==3
            psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10 11],[12 13 14 15 16 17]};
        elseif nSmoothCon==2
            psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10],[11 12 13 14]};
        end

        forPCA.pcaEvents = psthOpts.trialEvents((end-length(conAll)+1):end);
        forPCA.pcaConditions = psthOpts.trialConditions((end-length(conAll)+1):end);
        forPCA.pcaColors = smoothColors2;       
        forPCA.lineStyles = cell(size(forPCA.pcaColors,1),1);
        for c=1:size(forPCA.pcaColors,1)
            forPCA.lineStyles{c} = '-';
        end
        
    elseif strcmp(sessionType,'centerOut_PMDvsMI')
        in.gameType = 'coImmediate';

        targetByTrial = targetPos(reaches(:,1)+2,:);
        [targList,~,targIdx] = unique(targetByTrial,'rows');

        if strcmp(triggerType,'targetAppear')
            triggerEvent = reaches(:,1);
        elseif strcmp(triggerType,'targetAcq')
            triggerEvent = reaches(:,2);
        end 
        movTimes = reaches(:,2)-reaches(:,1);
        fastIdx = find(movTimes<median(movTimes));
        slowIdx = find(movTimes>=median(movTimes));

        psthOpts.trialEvents = [triggerEvent(:,1); triggerEvent(:,1); ...
            triggerEvent(fastIdx,1); triggerEvent(slowIdx,1);];
        psthOpts.trialConditions = [targIdx; repmat(5,length(triggerEvent),1); ...
            repmat(6,length(fastIdx),1); repmat(7,length(slowIdx),1);];

        dirColors = hsv(4)*0.8;
        dirColors = dirColors([3 4 2 1],:);
        purpleMap = [203 201 226; 158 154 200; 106 81 163; 84 39 143]/255;
        distColors = [purpleMap(2,:); purpleMap(1,:); purpleMap(3,:)];
        colors = [dirColors; distColors];
        psthOpts.lineArgs = cell(size(colors,1),1);
        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5};
        end

        psthOpts.conditionGrouping = {[1 2 3 4],[5 6 7]};
        forPCA.pcaEvents = psthOpts.trialEvents(1:length(triggerEvent));
        forPCA.pcaConditions = psthOpts.trialConditions(1:length(triggerEvent));
        forPCA.pcaColors = colors(1:4,:);
        forPCA.lineStyles = cell(size(forPCA.pcaColors,1),1);
        for c=1:size(forPCA.pcaColors,1)
            forPCA.lineStyles{c} = '-';
        end
        
    elseif strcmp(sessionType,'centerOut')
        in.gameType = 'coImmediate';

        targetByTrial = targetPos(reaches(:,1)+2,:);
        [targList,~,targIdx] = unique(targetByTrial,'rows');
        isOuter = find(targIdx~=5);
        targIdx(targIdx==5)=-1;
        targIdx(targIdx>5) = targIdx(targIdx>5)-1;
        isCardinal = ismember(targIdx, [1 4 5 8]);
        
        %  5
        %1   8
        %  4
        returnIdx = cell(4,1);
        returnIdx{1} = find(targIdx==1)+1;
        returnIdx{2} = find(targIdx==4)+1;
        returnIdx{3} = find(targIdx==8)+1;
        returnIdx{4} = find(targIdx==5)+1;
        
        returnAll = vertcat(returnIdx{:});
        returnAll(returnAll>length(reaches))=[];
        for c=1:length(returnIdx)
            returnIdx{c}(returnIdx{c}>length(reaches))=[];
        end

        returnCodes = zeros(size(returnAll,1),1);
        globalIdx = 1;
        for c=1:length(returnIdx)
            returnCodes(globalIdx:(globalIdx+length(returnIdx{c})-1)) = 15+c;
            globalIdx = globalIdx + length(returnIdx{c});
        end
        cardinalCodes = targIdx(isCardinal);
        cardinalCodes(cardinalCodes==8) = 12;
        cardinalCodes(cardinalCodes==5) = 13;
        cardinalCodes(cardinalCodes==1) = 14;
        cardinalCodes(cardinalCodes==4) = 15;
        
        if strcmp(triggerType,'targetAppear')
            triggerEvent = reaches(:,1);
        elseif strcmp(triggerType,'targetAcq')
            triggerEvent = reaches(:,2);
        end   
        movTimes = reaches(isOuter,2)-reaches(isOuter,1);
        fastIdx = find(movTimes<median(movTimes));
        slowIdx = find(movTimes>=median(movTimes));

        psthOpts.trialEvents = [triggerEvent(isOuter,1); triggerEvent(isOuter,1); ...
            triggerEvent(isOuter(fastIdx),1); triggerEvent(isOuter(slowIdx),1); ...
            triggerEvent(isCardinal,1); triggerEvent(returnAll,1); ];
        psthOpts.trialConditions = [targIdx(isOuter); repmat(9,length(isOuter),1); ...
            repmat(10,length(fastIdx),1); repmat(11,length(slowIdx),1); ...
            cardinalCodes; returnCodes];

        dirColors = hsv(8)*0.8;
        dirColors = dirColors([5 6 4 7 3 8 2 1],:);
        purpleMap = [203 201 226; 158 154 200; 106 81 163; 84 39 143]/255;
        distColors = [purpleMap(2,:); purpleMap(1,:); purpleMap(3,:)];
        dirColors2 = hsv(4)*0.8;

        colors = [dirColors; distColors; [dirColors2; dirColors2]];
        psthOpts.lineArgs = cell(size(colors,1),1);
        for c=1:size(colors,1)
            if c>=(size(colors,1)-3)
                psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5,'LineStyle','--'};
            else
                psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5};
            end
        end

        psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10 11],[12 13 14 15 16 17 18 19]};
        forPCA.pcaEvents = psthOpts.trialEvents(1:length(isOuter));
        forPCA.pcaConditions = psthOpts.trialConditions(1:length(isOuter));
        forPCA.pcaColors = colors(1:8,:);

        posTrials = ismember(psthOpts.trialConditions, psthOpts.conditionGrouping{3});
        forPCA.pcaEventsPos = psthOpts.trialEvents(posTrials);
        forPCA.pcaConditionsPos = psthOpts.trialConditions(posTrials);
        forPCA.pcaColorsPos = [dirColors2; dirColors2];
        
        forPCA.lineStyles = cell(size(forPCA.pcaColors,1),1);
        for c=1:size(forPCA.pcaColors,1)
            forPCA.lineStyles{c} = '-';
        end
        forPCA.lineStylesPos = {'-','-','-','-','--','--','--','--'};
        
        in.isOuter = isOuter;
    elseif strcmp(sessionType,'fittsImmediate')
        if strcmp(gameType,'brownTwigs')
            in.gameType = 'fittsShort';
        else
            in.gameType = 'fittsImmediate';
        end
        reachEpochs = reaches;

        [ ~, distCodes_4, ~, ~ ] = makeFittsTargetCodes( in.cursorPos, in.targetPos, reachEpochs, ...
            4, 4 );

        if strcmp(sessionName, 't9.2016.08.11 CLAUS GP & Kalman') || strcmp(sessionName, 't10.2016.08.24 Claus Kalman')
            rectangleOption = true;
        else
            rectangleOption = false;
        end
        [ dirCodes, ~, muxCodes, ~ ] = makeFittsTargetCodes( in.cursorPos, in.targetPos, reachEpochs, ...
            4, 2, rectangleOption );
 
        goodMuxCodes = find(~isnan(muxCodes));
        triggerEvent = reachEpochs(:,1);
        psthOpts.trialEvents = [triggerEvent(goodMuxCodes,1); triggerEvent(:,1); triggerEvent(:,1)];
        psthOpts.trialConditions = [muxCodes(goodMuxCodes); dirCodes+8; distCodes_4+12];

        allColors = zeros(8,3);
        allColors(1:2:end,:) = hsv(4)*0.8;
        allColors(2:2:end,:) = hsv(4)*0.8;
        
%         allColors = [189 215 231; 8 81 156; 203 201 226; 84 39 143; ...
%             86 228 179; 0 109 44; 252 174 145; 165 15 21]/255;
        distColors = [253 204 138; 252 141 89; 227 74 51; 179 0 0]/255;
        dirColors = hsv(4)*0.8;

        colors = [allColors; dirColors; distColors];
        psthOpts.lineArgs = cell(size(colors,1),1);
        for c=1:size(colors,1)
            if ismember(c, [1 3 5 7])
                psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5, 'LineStyle', '--'};
            else
                psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5};
            end
        end

        psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10 11 12],[13 14 15 16]};
        
        forPCA.pcaEvents = psthOpts.trialEvents(1:length(goodMuxCodes));
        forPCA.pcaConditions = psthOpts.trialConditions(1:length(goodMuxCodes));
        forPCA.pcaColors = allColors;
        
        forPCA.lineStyles = cell(size(forPCA.pcaColors,1),1);
        for c=1:size(forPCA.pcaColors,1)
            if ismember(c, [1 3 5 7])
                forPCA.lineStyles{c} = ':';
            else
                forPCA.lineStyles{c} = '-';
            end
        end
            
   elseif strcmp(sessionType,'centerOut4BC')
        in.gameType = 'coImmediate';

        targetByTrial = targetPos(reaches(:,1)+1,:);
        [targList,~,targIdx] = unique(targetByTrial,'rows');
        distRemap = [2 1 2 1 1 2 1 2];
        dirRemap = [1 1 2 2 3 3 4 4];

        triggerEvent = reaches(:,1);
        psthOpts.trialEvents = [triggerEvent(:,1); triggerEvent(:,1); triggerEvent(:,1)];
        psthOpts.trialConditions = [targIdx; dirRemap(targIdx)'+8; distRemap(targIdx)'+12;];

        distColors = [1 0.4 0.4; 0.8 0 0];
        dirColors = hsv(4)*0.8;
        allColors = [dirColors(1,:); dirColors(1,:); dirColors(2,:); dirColors(2,:); ...
            dirColors(3,:); dirColors(3,:); dirColors(4,:); dirColors(4,:)];

        colors = [allColors; dirColors; distColors];
        psthOpts.lineArgs = cell(size(colors,1),1);
        lineStyles = {'-','--','-','--','--','-','--','-',...
            '-','-','-','-','-','-'};
        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1.5, 'LineStyle', lineStyles{c}};
        end

        psthOpts.conditionGrouping = {[1 2 3 4 5 6 7 8],[9 10 11 12],[13 14]};
        
        forPCA.lineStyles = lineStyles(1:8);
        forPCA.pcaColors = allColors(1:8,:);
        forPCA.pcaEvents = psthOpts.trialEvents(1:(end/3));
        forPCA.pcaConditions = psthOpts.trialConditions(1:(end/3));
    end
end

