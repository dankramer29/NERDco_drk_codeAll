function [ out] = makeTemplateDecoder( in )
    %(T5 starts the O on the right, not at the top)
    rot90 = [[cosd(-90), cosd(0)]; [sind(-90), sind(0)]];
    in.templates{7}(:,1:2) = (rot90*in.templates{7}(:,1:2)')';
    
    %for later days, T5 changes how he writes "x"
    if strcmp(in.sessionName, 't5.2019.05.01') || strcmp(in.sessionName, 't5.2019.05.08')
        in.templates{24}(22:43,2) = -in.templates{24}(22:43,1);
        in.templates{24}(22:43,1) = 0.00001; %avoiding zero exactly, since it has special meaning (end of template)
        in.templates{24}(47:68,1:2) = -in.templates{24}(47:68,1:2);
    end
    
    warpedTemplates = cell(length(in.uniqueCodes_noNothing),1);
    avgDecVel = cell(length(in.uniqueCodes_noNothing),1);
    
    for conIdx=1:length(in.uniqueCodes_noNothing)
        win = in.timeWindows(in.uniqueCodes_noNothing(conIdx)==in.fullCodes,:);
        concatVel = triggeredAvg( in.velInit, in.alignDat.eventIdx(in.trlCodes==in.uniqueCodes_noNothing(conIdx)), win );
        avgVel = squeeze(mean(concatVel,1));
        avgDecVel{conIdx} = avgVel;   
            
        tempIdx = find(in.uniqueCodes_noNothing(conIdx)==in.templateCodes);
        if isempty(tempIdx)
            continue;
        end
        disp(conIdx);

        if strcmp(in.initMode, 'warpToInitialDecode')
            if in.fixTemplateSize
                shiftPossible = -17;
                dilationPossible = 1.2;
            elseif ismember(in.uniqueCodes_noNothing(conIdx), in.curveCodes(1:8))
                %radial 8
                shiftPossible = -40:40;
                dilationPossible = linspace(1.0,6.0,50);
            elseif win(2)>160
                shiftPossible = -20:20;
                dilationPossible = linspace(0.5,5.0,50);                
            else
                shiftPossible = -20:20;
                dilationPossible = linspace(0.5,2.0,50);
            end

            allPerf = zeros(length(dilationPossible), length(shiftPossible));

            for dIdx=1:length(dilationPossible)
                for shiftIdx=1:length(shiftPossible)
                    tmp = in.templates{tempIdx};
                    tmpDilated = interp1(linspace(0,1,size(tmp,1)), tmp, linspace(0,1,size(tmp,1)*dilationPossible(dIdx)));
                    avgDatDilated = [zeros((-win(1)+shiftPossible(shiftIdx)),size(tmp,2)); tmpDilated];
                    avgDatDilated = [avgDatDilated; zeros((win(2)-win(1))-size(avgDatDilated,1)+1,size(tmp,2))];

                    nBins = win(2)-win(1)+1;
                    if size(avgDatDilated,1)>nBins
                        avgDatDilated = avgDatDilated(1:nBins,:);
                    end

                    warpedTemplateXY = avgDatDilated(:,1:2);
                    allPerf(dIdx, shiftIdx) = mean(corr(warpedTemplateXY(:), avgVel(:)));
                end
            end

            [~,maxIdx]=max(allPerf(:));
            [I,J] = ind2sub(size(allPerf),maxIdx);
            bestDilation = dilationPossible(I);
            bestDelay = shiftPossible(J);
            
            tmp = in.templates{tempIdx};
            tmpDilated = interp1(linspace(0,1,size(tmp,1)), tmp, linspace(0,1,size(tmp,1)*bestDilation));
            avgDatDilated = [zeros((-win(1)+bestDelay),size(tmp,2)); tmpDilated];
            avgDatDilated = [avgDatDilated; zeros((win(2)-win(1))-size(avgDatDilated,1)+1,size(tmp,2))];

            nBins = win(2)-win(1)+1;
            if size(avgDatDilated,1)>nBins
                avgDatDilated = avgDatDilated(1:nBins,:);
            end

            warpedTemplates{conIdx} = avgDatDilated;
        else
            preTempIdx = find(in.uniqueCodes_noNothing(conIdx)==in.preWarpCodes);
            if ~isempty(preTempIdx)
                warpedTemplates{conIdx} = in.preWarpTemp{preTempIdx};
            end
        end
    end
    
    %%
    %how did we do?
    if in.makePlot && strcmp(in.initMode, 'warpToInitialDecode')
        [~,idx] = ismember(in.uniqueCodes_noNothing, in.fullCodes);
        reducedLabels = in.allLabels(idx);

        iterIdx = 1;
        for pageIdx=1:ceil(length(in.uniqueCodes_noNothing)/10)
            figure('Position',[680          92         404        1006]);
            for x=1:10
                if iterIdx>length(warpedTemplates)
                    break;
                end
                subtightplot(10,2,(x-1)*2+1);
                hold on;
                if ~isempty(warpedTemplates{iterIdx})
                    plot(zscore(warpedTemplates{iterIdx}(:,1)),'LineWidth',2);
                end
                plot(zscore(avgDecVel{iterIdx}(:,1)),'LineWidth',2);
                axis off;
                title(reducedLabels{iterIdx});

                subtightplot(10,2,(x-1)*2+2);
                hold on;
                if ~isempty(warpedTemplates{iterIdx})
                    plot(zscore(warpedTemplates{iterIdx}(:,2)),'LineWidth',2);
                end
                plot(zscore(avgDecVel{iterIdx}(:,2)),'LineWidth',2);
                axis off;
                title(reducedLabels{iterIdx});

                iterIdx = iterIdx+1;
            end
        end
    end
    
    %%
    %cross-condition decoding
    prepWin = [-49, -0];
    
    targetVel = [];
    neuralLoopIdx = [];
    conIdxByLoop = [];
    neuralLoopIdx_prep = [];
    conIdxByLoop_prep = [];
    targetVel_prep = [];
    for t=1:length(in.trlCodes)
        conIdx = find(in.trlCodes(t)==in.uniqueCodes_noNothing);
        if isempty(conIdx)
            continue;
        end
        
        win = in.timeWindows(in.trlCodes(t)==in.fullCodes,:);
        loopIdx = (in.alignDat.eventIdx(t)+win(1)):(in.alignDat.eventIdx(t)+win(2));
        
        if isempty(warpedTemplates{conIdx})
            tempUse = nan(length(loopIdx),4);
        else
            tempUse = warpedTemplates{conIdx};
        end
        
        tempUse(1:(-win(1)),4) = median(tempUse((-win(1)):(-win(1)+30),4));
        if length(tempUse)<length(loopIdx)
            %extend template with zeros if necessary to match the time
            %window in use
            tempUse = [tempUse; zeros(length(loopIdx)-length(tempUse),size(tempUse,2))];
        end
        
        targetVel = [targetVel; tempUse];
        neuralLoopIdx = [neuralLoopIdx; loopIdx'];
        conIdxByLoop = [conIdxByLoop; zeros(length(loopIdx),1)+conIdx];
        
        loopIdx_prep = (in.alignDat.eventIdx(t)+prepWin(1)):(in.alignDat.eventIdx(t)+prepWin(2));
        neuralLoopIdx_prep = [neuralLoopIdx_prep; loopIdx_prep'];
        conIdxByLoop_prep = [conIdxByLoop_prep; zeros(length(loopIdx),1)+conIdx];
        
        prepValue = mean(tempUse((-win(1)):(-win(1)+30),:));
        targetVel_prep = [targetVel_prep; repmat(prepValue,length(loopIdx_prep),1)];
    end
    
    designMat = [ones(length(neuralLoopIdx),1), in.smoothSpikes_align(neuralLoopIdx,:)];
    useIdx = all(~isnan(targetVel),2);
    [ filts_mov, featureMeans ] = buildLinFilts( targetVel(useIdx,:)*20, designMat(useIdx,:), 'ridge', 1e3 ); %1e3
    
    cvVel = zeros(size(in.alignDat.rawSpikes,1),4);
    for conIdx=1:length(in.uniqueCodes_noNothing)
        disp(conIdx); 

        trainIdx = find(conIdxByLoop~=conIdx & useIdx);
        testIdx = find(conIdxByLoop==conIdx);

        designMat = [ones(length(neuralLoopIdx(trainIdx)),1), in.smoothSpikes_align(neuralLoopIdx(trainIdx),:)];
        [ filts_mov_cv, featureMeans ] = buildLinFilts( targetVel(trainIdx,:)*20, designMat, 'ridge', 1e3 );
        cvVel(neuralLoopIdx(testIdx),:) = [ones(length(neuralLoopIdx(testIdx)),1), in.smoothSpikes_align(neuralLoopIdx(testIdx),:)]*filts_mov_cv;
    end
    
    decVel = [ones(length(in.smoothSpikes_align),1), in.smoothSpikes_align] * filts_mov;
    
    %%
    %measure length
    conLen = nan(length(in.uniqueCodes_noNothing),1);
    for w=1:length(in.uniqueCodes_noNothing)
        if isempty(warpedTemplates{w})
            continue;
        end
        zeroIdx = find(warpedTemplates{w}(100:end,1)==0,1,'first');
        if isempty(zeroIdx)
            continue;
        end
        conLen(w) = zeroIdx + 99 - 50; 
    end
    conLen(isnan(conLen)) = 150;
    
    %%
    out.conLen = conLen;
    out.cvVel = cvVel;
    out.decVel = decVel;
    out.filts_mov = filts_mov;
    out.warpedTemplates = warpedTemplates;

end

