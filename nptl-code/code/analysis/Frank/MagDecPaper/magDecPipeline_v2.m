%%
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = [paths.dataPath '/BG Datasets/'];
sortDir = [paths.dataPath '/CaseDerived/sortedUnits/'];
plotDir = [paths.dataPath '/CaseDerived/psth/'];

sessionList = { 't8','t8.2016.07.15_Cart2D_Replay',[12:18 21],'centerOut','case3d';
    't9','t9.2016.08.01 Intention Estimator Comparison',[4:12],'centerOut','twigs';
    't10','t10.2017.04.03 PMd vs M1',[6 8 10 12 14 16 18 20],'centerOut_PMDvsMI','radial2015'
    't5','t5.2016.09.28',[4 6],'centerOut','centerOut_t5'
    
    't8','t8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp',[4:11],'fittsImmediate','case3d'
    't9','t9.2016.08.11 CLAUS GP & Kalman',[8 10 13 15],'fittsImmediate','brownTwigs'
    't10','t10.2016.08.24 Claus Kalman',[8 12 15 22 31 37],'fittsImmediate','brownTwigs'
    't5','t5.2016.09.28',[7 8 9 10],'fittsImmediate','grid_t5'
    };
workspaceSize = [14, 0.5, 0.5, 484, 0.5, 26, 1.2, 1.2, 1000];
featureTypes = {'ncTX and SpikePower','Sorted'};

%%
for s = 3
    for featureIdx = 1:2
        %%
        %prepare save directory
        saveDir = [plotDir sessionList{s,2} ' ' sessionList{s,4} filesep featureTypes{featureIdx}];
        mkdir(saveDir);
        
        %%
        %load and format blocks
        if strcmp(sessionList{s,1},'t5')
            [ R, cursorPos, targetPos, reaches, decoder, targRad, features, featLabels, decFeatures, allZero, decVel ] = ...
                convertStanfordToBrownFormat( [dataDir filesep sessionList{s,2}], sessionList{s,3}, sessionList{s,5} );
            
            if strcmp(featureTypes{featureIdx},'Sorted')
                fullSortDir =  [sortDir sessionList{s,2} '.' num2str(sessionList{s,3}(1)) '-' num2str(sessionList{s,3}(end))];
                if ~exist([fullSortDir filesep 'binnedRates.mat'],'file')
                    binSortedUnits(fullSortDir, R, 20);
                end
                tmp = load([fullSortDir filesep 'binnedRates.mat']);
                
                meanRate = mean(tmp.allBinnedRates);
                lowRate = meanRate<0.1;
                
                features = zscore(tmp.allBinnedRates);
                allZero = all(features==0);
                features(:,allZero | lowRate) = [];
                features((length(cursorPos)+1):end,:) = [];
                
                featLabels = cell(size(tmp.allBinnedRates,2),1);
                for n=1:length(featLabels)
                    featLabels{n} = ['U' num2str(tmp.unitChan(n)) '-' num2str(tmp.unitClass(n))];
                end
                featLabels(allZero | lowRate) = [];
            end
        else
            [ slc, cursorPos, targetPos, reaches, decoder, decNorms, targRad, decVel, sData ] = ...
                prepareDataForPSTH( [dataDir filesep sessionList{s,2}], sessionList{s,3}, sessionList{s,5} );
            if strcmp(sessionList{s,2},'t10.2017.04.03 PMd vs M1')
                setIdx = expandEpochIdx(sData.setPeriods);
                delayTrls = zeros(size(reaches,1),1);
                for x=1:length(reaches)
                    delayTrls(x) = any(setIdx==reaches(x,1)-1);
                end
                reaches(logical(delayTrls),:) = [];
            end
            if strcmp(sessionList{s,2},'t8.2016.07.15_Cart2D_Replay')
                P = slcDataToPFile(slc);
                replayIdx = P.loopMat.aperture(reaches(:,1)+5)==single(50.01);
                reaches(replayIdx,:) = [];
            end
            if strcmp(sessionList{s,1},'t10')
                decoder = decoder(:,[97:192, 289:384]);
            end

            %load features
            [ features, featLabels, decFeatures, allZero ] = prepareFeaturesForPSTH( slc, decNorms, featureTypes{featureIdx}, [sortDir sessionList{s,2}], sessionList{s,1} );
        end
        
        %%
        %prepare for model fitting and psth plotting
        [ psthOpts, in, forPCA ] =  preparePSTHAndFitOpts_v2( sessionList{s,2}, sessionList{s,4}, sessionList{s,5}, saveDir, ...
            cursorPos, targetPos, reaches, features, featLabels, 'targetAppear');
        
        %%
        [ popResponse, sfResponse, fullModel, in, modelVectors] =  fit4DimModel( saveDir, in );
        
        %%
        %magnitude decoding
        %singleTrialDecoding(saveDir, in, targRad);
        
        %%
        %basic PSTH
        if exist([saveDir filesep 'psthOut.mat'],'file')
           psthOpts.neuralData{2} = sfResponse;
           load([saveDir filesep 'psthOut.mat'],'psthOut');
        else
            psthOpts.prefix = 'Single';
            makePSTH_simple( psthOpts );
            close all;

            psthOpts.neuralData{2} = sfResponse;
            
            compOpts = psthOpts;
            if strcmp(sessionList{s,4},'fittsImmediate')
                compOpts.conditionGrouping(1) = [];
            end
            compOpts.prefix = 'Single Comparison';
            barDat = cell(size(compOpts.neuralData{1},2),1);
            for f=1:size(compOpts.neuralData{1},2)
                barDat{f} = abs(fullModel{1}.tuningCoef(2:end,f));
                barDat{f} = barDat{f} / max(barDat{f});
            end
            compOpts.bar = barDat;
            psthOut = makePSTH_simple( compOpts );
            close all;
            
            save([saveDir filesep 'psthOut.mat'],'psthOut','psthOpts');
        end

        %%
        %plot trajectory
        if strcmp(sessionList{s,4},'centerOut') || strcmp(sessionList{s,4},'centerOut_PMDvsMI')
            targetByTrial = targetPos(reaches(:,1)+2,:);
            [targList,~,targIdx] = unique(targetByTrial,'rows');
            isOuter = find(targIdx~=5);
            targIdx(targIdx==5)=-1;
            targIdx(targIdx>5) = targIdx(targIdx>5)-1;
            medRad = median(targRad);
            if strcmp(sessionList{s,4},'centerOut')
                targList(5,:) = [];
            end
            
            isOuter = isOuter((8*3+1):(8*6));
            
            figure
            hold on
            for r=1:length(isOuter)
                loopIdx = reaches(isOuter(r),1):reaches(isOuter(r),2);
                plot(cursorPos(loopIdx,1), cursorPos(loopIdx,2), 'Color', psthOpts.lineArgs{targIdx(isOuter(r))}{2}, 'LineWidth', 2);
            end
            for t=1:size(targList,1)
                rectangle('Position',[targList(t,1)-medRad, targList(t,2)-medRad, medRad*2, medRad*2], 'Curvature', [1 1], 'LineWidth', 2);
            end
            axis equal;
            axis off;
            exportPNGFigure(gcf, [saveDir filesep 'traj']);
        elseif strcmp(sessionList{s,4},'fittsImmediate')       
            
            %21 22 23
            %32 33 34
            %74 75 76
            trlToPlot = {[74 75 76],[42 43 44],[30 31 32],[66 67 68]+27};
            sessIdx = find(strcmp(sessionList{s,2},{'t8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp', ...
                't9.2016.08.11 CLAUS GP & Kalman', 't10.2016.08.24 Claus Kalman','t5.2016.09.28'}));
            trlIdx = trlToPlot{sessIdx};
            
            figure
            hold on
            for r=1:length(trlIdx)
                if r==length(trlIdx)
                    loopIdx = reaches(trlIdx(r),1):reaches(trlIdx(r),2);
                else
                    loopIdx = reaches(trlIdx(r),1):reaches(trlIdx(r)+1,1);
                end
                
                centeredPos = bsxfun(@plus, cursorPos(loopIdx,:), -cursorPos(loopIdx(1),:));
                centeredTarg = targetPos(loopIdx(2),:) -cursorPos(loopIdx(1),:);

                plot(cursorPos(loopIdx,1), cursorPos(loopIdx,2), psthOpts.lineArgs{psthOpts.trialConditions(trlIdx(r))}{:}, 'LineWidth', 2);
                tR = targRad(loopIdx(2));
                if sessIdx~=4
                    rectangle('Position',[targetPos(loopIdx(2),1)-tR, targetPos(loopIdx(2),2)-tR, tR*2, tR*2], ...
                        'Curvature', [1 1], 'LineWidth', 2, 'EdgeColor', 'k');
                end
                if r==1
                    plot(cursorPos(loopIdx(1),1), cursorPos(loopIdx(1),2), 'ko','LineWidth',2,'MarkerSize',8);
                end
            end
            if sessIdx==1
                rectangle('Position',[-13, -13, 26, 26]+[0, 40.5, 0, 0],'EdgeColor',[0.5 0.5 0.5],'LineWidth',2);
            elseif sessIdx==2 || sessIdx==3
                rectangle('Position',[-0.711, -0.4, (0.711)*2, 0.8],'EdgeColor',[0.5 0.5 0.5],'LineWidth',2);
            elseif sessIdx==4
                xu = unique(targetPos(round(end/2):end,1));
                yu = unique(targetPos(round(end/2):end,2));
                tr = 111.1111/2;
                for xIdx=1:length(xu)
                    for yIdx=1:length(yu)
                        rectangle('Position',[xu(xIdx)-tr, yu(yIdx)-tr, tr*2, tr*2], 'EdgeColor',[0.5 0.5 0.5],'LineWidth',1.4);
                    end
                end
            end
            axis equal;
            axis off;

            exportPNGFigure(gcf, [saveDir filesep 'traj']);
        end
        close all;
        
        %%
        %behavior kinematics
        accThreshold = [60, 60, 60, 1000, 60, 60, 60, 1000];
        cursorVel = diff([0 0; cursorPos])/psthOpts.timeStep/workspaceSize(s);
        cursorAcc = diff([0 0; cursorVel])/psthOpts.timeStep;
        cursorSpeed = matVecMag(cursorVel,2);
        outlierIdx = find(cursorSpeed>std(cursorSpeed)*6 | matVecMag(cursorAcc,2)>accThreshold(s));
        cursorVel(outlierIdx,:) = 0;

        [B,A] = butter(3, 5/25);
        cursorVel = filtfilt(B, A, cursorVel);
        conditionList = unique(forPCA.pcaConditions);

        figure('Position',[96   430   337   510]);
        for x=1:2
            subtightplot(4,2,x,[0.01 0.03],[0.1 0.05],[0.06 0.01]);
            hold on;
            for y=1:length(conditionList)
                trlIdx = forPCA.pcaConditions==conditionList(y);
                concatDat = triggeredAvg( cursorVel(:,x), forPCA.pcaEvents(trlIdx), psthOpts.timeWindow );
                tmpAvg = mean(concatDat);

                timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*psthOpts.timeStep;
                plot(timeAxis, tmpAvg, psthOpts.lineArgs{y}{:});
                ylim([-1.2 1.2]);
            end
            plot([0 0],get(gca,'YLim'),'--k','LineWidth',1.5);
            plot(get(gca,'XLim'),[0 0],'-k');
            xlim([timeAxis(1), timeAxis(end)]);
            set(gca,'FontSize',16);
            set(gca,'LineWidth',1.5);
            xlabel('Time (s)');
            if x==1
                %title('X Vel');
            elseif x==2
                %title('Y Vel');
                set(gca,'YTick',[]);
            end
            %ylabel(yLabels{x});
        end
        exportPNGFigure(gcf, [saveDir filesep 'cursorVelocity']);
        
        cursorSpeed = matVecMag(decVel,2);
        if strcmp(sessionList{s,4},'fittsImmediate')
            nearIdx = find(ismember(forPCA.pcaConditions,1:2:8));
            farIdx = find(ismember(forPCA.pcaConditions,2:2:8));
            
            avgNearTrace = triggeredAvg( cursorSpeed, forPCA.pcaEvents(nearIdx), psthOpts.timeWindow );
            avgNearTrace = nanmean(avgNearTrace)';
            
            avgFarTrace = triggeredAvg( cursorSpeed, forPCA.pcaEvents(farIdx), psthOpts.timeWindow );
            avgFarTrace = nanmean(avgFarTrace)';
            
            avgSpeedTrace = [avgFarTrace, avgNearTrace];
        else
            avgSpeedTrace = triggeredAvg( cursorSpeed, forPCA.pcaEvents, psthOpts.timeWindow );
            avgSpeedTrace = nanmean(avgSpeedTrace)';
        end
        
        %%
        %decoder null space analysis
        if strcmp(featureTypes{featureIdx},'ncTX and SpikePower') && ~strcmp(sessionList{s,5},'simData')
            %decoder-alignment for model dimensions
            normDec = decoder';
            normDec(:,1) = normDec(:,1)/norm(normDec(:,1));
            normDec(:,2) = normDec(:,2)/norm(normDec(:,2));
            normDec(allZero,:) = [];
            normEnc = bsxfun(@times, fullModel{1}.tuningCoef(2:end,:)', 1./matVecMag(fullModel{1}.tuningCoef(2:end,:)',1));
            daFactor = normEnc' * normDec;
            subAngle = zeros(size(normEnc,2),1);
            for x=1:size(normEnc,2)
                subAngle(x) = cos(subspace(normEnc(:,x), normDec));
            end
            
            %plot output
            decOpts = psthOpts;
            decOpts.neuralData{1} = gaussSmooth_fast(decFeatures(:,~allZero), 1.5) * normDec;
            decOpts.neuralData(2) = [];
            decOpts.orderBySNR = false;
            decOpts.prefix = 'Decoder';
            decOutFull = makePSTH_simple( decOpts );
            
            %decoder output along model dimensions
            E = fullModel{1}.tuningCoef(2:end,:)';
            projMat = (E'*E)\E';
            scores = features * projMat';
            dOut = zeros(size(scores,1), size(scores,2), 2);
            for d=1:4
                dOut(:,d,:) = (scores(:,d)*E(:,d)') * normDec;
            end
            
            decOpts = psthOpts;
            decOpts.neuralData{1} = squeeze(dOut(:,:,1));
            decOpts.neuralData(2) = [];
            decOpts.orderBySNR = false;
            decOpts.prefix = 'Decoder Split X';
            ds{1} = makePSTH_simple( decOpts );
            
            decOpts = psthOpts;
            decOpts.neuralData{1} = squeeze(dOut(:,:,2));
            decOpts.neuralData(2) = [];
            decOpts.orderBySNR = false;
            decOpts.prefix = 'Decoder Split Y';
            ds{2} = makePSTH_simple( decOpts );
            
            nCon = length(psthOpts.conditionGrouping{1});
            
            figure('Position',[128   179   542   761]);
            for d=1:4
                for decIdx=1:2
                    subplot(4,2,(d-1)*2 + decIdx);
                    hold on
                    for c=1:nCon
                        plot(ds{decIdx}.timeAxis{c}, ds{decIdx}.psth{c}(:,d,1));
                    end
                    ylim([-1.5 1.5]);
                end
            end
            exportPNGFigure(gcf, [saveDir filesep 'decoderOutputByModelDim']);
            
            totalVar = zeros(nCon, 2);
            varFrac = zeros(nCon, 4, 2);
            for c=1:nCon
                for dim=1:2
                    totalVar(c,dim) = sum(decOutFull.psth{c}(:,dim,1).^2);
                    for modelIdx=1:4
                        varFrac(c,modelIdx,dim) = sum(ds{dim}.psth{c}(:,modelIdx,1).^2);
                    end
                end
            end
            
            daVarFactor = zeros(4,2);
            for modelIdx=1:4
                for dim=1:2
                    daVarFactor(modelIdx, dim) = mean(varFrac(:,modelIdx,dim)./sum(varFrac(:,:,dim),2));
                end
            end
            save([saveDir filesep 'daFactor.mat'],'daFactor','daVarFactor');
            
            close all;
        end

        %%
        %PCA on raw data        
        meanSNR = mean(psthOut.dimSNR,2);
        [~,sortIdx] = sort(meanSNR,'descend');
        if strcmp(featureTypes{featureIdx},'Sorted')
            if strcmp(sessionList{s,1},'t5')
                tunedIdx = sortIdx(1:min(length(sortIdx),80));
            else
                tunedIdx = sortIdx(1:min(length(sortIdx),40));
            end
        else
            tunedIdx = sortIdx(1:min(length(sortIdx),140));
        end
        smoothData = gaussSmooth_fast(psthOpts.neuralData{1}(:,tunedIdx), 1.5);
        popModel = fullModel{1}.modelVectors(:,2:5);
        popModel = gaussSmooth_fast(popModel, 1.5);
        
        [fHandles, pcaOut] = apply_dPCA( smoothData, forPCA.pcaEvents, forPCA.pcaConditions, [], ...
            psthOpts.timeWindow, true, [], [], popModel, fullModel{1}.tuningCoef(2:end,tunedIdx)' );
        
        if strcmp(featureTypes{featureIdx},'ncTX and SpikePower') && ~strcmp(sessionList{s,5},'simData')
            %alginment between dPCA encoder and BCI decoder
            pcaOut.atten = zeros(1, size(pcaOut.V,2));
            pcaOut.atten_pca = zeros(1, size(pcaOut.V,2));
            for x=1:size(pcaOut.V,2)
                pcaOut.atten(x) = cos(subspace(pcaOut.V(:,x), normDec(tunedIdx,:)));
                pcaOut.atten_pca(x) = cos(subspace(pcaOut.W_pca(:,x), normDec(tunedIdx,:)));
            end
            
            %pcaOut.atten = mean(abs(pcaOut.V' * normDec(tunedIdx,:)),2)';
            %pcaOut.atten_pca = mean(abs(pcaOut.W_pca' * normDec(tunedIdx,:)),2)';
        end
        
        timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
        reconCoef = plot_dPCA_Out( pcaOut, forPCA.pcaColors, forPCA.lineStyles, timeAxis, false, true, avgSpeedTrace );
        set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
        exportPNGFigure(gcf, [saveDir filesep 'dPCA Zoom']);
            
        plotRecon = [false, true];
        reconSuffix = {'',' recon'};
        for pIdx=1:length(plotRecon)
            timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
            reconCoef = plot_dPCA_Out( pcaOut, forPCA.pcaColors, forPCA.lineStyles, timeAxis, plotRecon(pIdx), false, avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            exportPNGFigure(gcf, [saveDir filesep 'dPCA Dim' reconSuffix{pIdx}]);
           
            timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
            plot_PCA_Out( pcaOut, forPCA.pcaColors, forPCA.lineStyles, timeAxis, plotRecon(pIdx), avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            exportPNGFigure(gcf, [saveDir filesep 'PCA Dim' reconSuffix{pIdx}]);
        end
        
        exportPNGFigure(fHandles(1), [saveDir filesep 'PCA']);
        exportPNGFigure(fHandles(2), [saveDir filesep 'PCA Marg']);
        exportPNGFigure(fHandles(3), [saveDir filesep 'jPCA Time']);
        exportPNGFigure(fHandles(4), [saveDir filesep 'jPCA Plane']);
        exportPNGFigure(fHandles(5), [saveDir filesep 'dPCA']);
        exportPNGFigure(fHandles(6), [saveDir filesep 'PCA vs Model']);
        close all;

        save([saveDir filesep 'model pca FVAF.mat'],'pcaOut');
        
        if strcmp(sessionList{s,4},'centerOut')
            [fHandles, pcaOutPos] = apply_dPCA( smoothData, forPCA.pcaEventsPos, forPCA.pcaConditionsPos, [], psthOpts.timeWindow, false, [], [], popModel, [] );
            
            timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
            plot_dPCA_Out( pcaOutPos, forPCA.pcaColorsPos, forPCA.lineStylesPos, timeAxis, false, false, avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            exportPNGFigure(gcf, [saveDir filesep 'dPCA Dim Pos']);
            
            plot_PCA_Out( pcaOutPos, forPCA.pcaColorsPos, forPCA.lineStylesPos, timeAxis, false, avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            exportPNGFigure(gcf, [saveDir filesep 'PCA Dim pos']);
            
            %2-factor analysis
            returnFactor = ismember(forPCA.pcaConditionsPos,[12 13 14 15])+1;
            dirFactor = forPCA.pcaConditionsPos;
            dirFactor(dirFactor==12 | dirFactor==16) = 1;
            dirFactor(dirFactor==13 | dirFactor==17) = 2;
            dirFactor(dirFactor==14 | dirFactor==18) = 3;
            dirFactor(dirFactor==15 | dirFactor==19) = 4;
            
            [fHandles, pcaOutPos_2factor] = apply_dPCA( smoothData, forPCA.pcaEventsPos, dirFactor, returnFactor, [0 100], false, [], [], [], [] );
            save([saveDir filesep 'model pca FVAF pos.mat'],'pcaOutPos','pcaOutPos_2factor');
            close all;
        end
        
        %%
        %PCA on modeled data
        if ~strcmp(featureTypes{featureIdx},'Sorted') 
            rIdxAll = expandEpochIdx(in.reachEpochs);
            Q = cov(sfResponse(rIdxAll,:) - features(rIdxAll,:));
            noisyData = sfResponse + mvnrnd(zeros(size(features,2),1), Q, size(psthOpts.neuralData{1},1));

            smoothData = gaussSmooth_fast(noisyData(:,tunedIdx), 1.5);

            [fHandles, pcaOut_model] = apply_dPCA( smoothData, forPCA.pcaEvents, forPCA.pcaConditions, [], psthOpts.timeWindow, true, [], [], [], [] );

            if strcmp(featureTypes{featureIdx},'ncTX and SpikePower') && ~strcmp(sessionList{s,5},'simData')
                pcaOut_model.atten = zeros(1, size(pcaOut_model.V,2));
                pcaOut_model.atten_pca = zeros(1, size(pcaOut_model.V,2));
                for x=1:size(pcaOut_model.V,2)
                    pcaOut_model.atten(x) = cos(subspace(pcaOut_model.V(:,x), normDec(tunedIdx,:)));
                    pcaOut_model.atten_pca(x) = cos(subspace(pcaOut_model.W_pca(:,x), normDec(tunedIdx,:)));
                end

                %pcaOut_model.atten = mean(abs(pcaOut_model.V' * normDec(tunedIdx,:)),2)';
                %pcaOut_model.atten_pca = mean(abs(pcaOut_model.W_pca' * normDec(tunedIdx,:)),2)';
            end

            timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
            plot_dPCA_Out( pcaOut_model, forPCA.pcaColors, forPCA.lineStyles, timeAxis, false, false, avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'dPCA Dim model.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA Dim model.svg'],'svg');

            timeAxis = (psthOpts.timeWindow(1):psthOpts.timeWindow(2))*0.02;
            plot_PCA_Out( pcaOut_model, forPCA.pcaColors, forPCA.lineStyles, timeAxis, false, avgSpeedTrace );
            set(gcf,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
            saveas(gcf,[saveDir filesep 'PCA Dim model.png'],'png');
            saveas(gcf,[saveDir filesep 'PCA Dim model.svg'],'svg');

            saveas(fHandles(1),[saveDir filesep 'model PCA.png'],'png');
            saveas(fHandles(2),[saveDir filesep 'model PCA Marg.png'],'png');
            saveas(fHandles(3),[saveDir filesep 'model jPCA Time.png'],'png');
            saveas(fHandles(4),[saveDir filesep 'model jPCA Plane.png'],'png');
            saveas(fHandles(5),[saveDir filesep 'model dPCA.png'],'png');

            saveas(fHandles(1),[saveDir filesep 'model PCA.svg'],'svg');
            saveas(fHandles(2),[saveDir filesep 'model PCA Marg.svg'],'svg');
            saveas(fHandles(3),[saveDir filesep 'model jPCA Time.svg'],'svg');
            saveas(fHandles(4),[saveDir filesep 'model jPCA Plane.svg'],'svg');
            saveas(fHandles(5),[saveDir filesep 'model dPCA.svg'],'svg');
            close all;

            %noisy reconstruction
            plot_dPCA_noisyRecon( pcaOut, pcaOut_model, forPCA.pcaColors, forPCA.lineStyles, timeAxis, ...
                fullModel{1}.tuningCoef(2:end,tunedIdx), avgSpeedTrace );
            exportPNGFigure(gcf, [saveDir filesep 'dPCA dim noisy recon']);
            close all;
        end
        %%
        %model the population response and plot
        tDistForFit = matVecMag(in.kin.posErrForFit,2);
        distWeight = interp1([fullModel{1}.fTarg(:,1); fullModel{1}.fTarg(end,1)+0.01], ...
            [fullModel{1}.fTarg(:,2); fullModel{1}.fTarg(end,2)], tDistForFit, 'linear', 'extrap');
        cisWeight = interp1([fullModel{1}.fTime(:,1); fullModel{1}.fTime(end,1)+0.01], ...
            [fullModel{1}.fTime(:,2); fullModel{1}.fTime(end,2)], in.kin.timePostGo(:,2), 'linear', 'extrap');
        predictors = [bsxfun(@times, in.kin.posErrForFit, distWeight./tDistForFit), distWeight, cisWeight];
        predictors(isnan(predictors))=0;
        predictors(isinf(predictors))=0;

        rIdxAll = expandEpochIdx(reaches);
        pd1 = buildLinFilts(popResponse(rIdxAll,1), [ones(length(rIdxAll),1), predictors(rIdxAll,1)], 'standard');
        pd2 = buildLinFilts(popResponse(rIdxAll,2), [ones(length(rIdxAll),1), predictors(rIdxAll,2)], 'standard');
        pd3 = buildLinFilts(popResponse(rIdxAll,3), [ones(length(rIdxAll),1), predictors(rIdxAll,3)], 'standard');
        pd4 = buildLinFilts(popResponse(rIdxAll,4), [ones(length(rIdxAll),1), predictors(rIdxAll,4)], 'standard');
        modeledPop = [[ones(length(predictors),1), predictors(:,1)]*pd1, [ones(length(predictors),1), predictors(:,2)]*pd2, ...
            [ones(length(predictors),1), predictors(:,3)]*pd3, [ones(length(predictors),1), predictors(:,4)]*pd4];

       psthOpts.neuralData{1} = popResponse;
       psthOpts.neuralData{2} = modeledPop;
       psthOpts.orderBySNR = false;
       psthOpts.prefix = 'Population';
       psthOpts.plotsPerPage = 5;
       
       psthPopOut = makePSTH_simple( psthOpts );

       %%
       close all;
        
    end %feature type
end %session