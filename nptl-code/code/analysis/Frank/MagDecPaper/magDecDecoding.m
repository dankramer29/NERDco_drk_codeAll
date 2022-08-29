%%
paths = getFRWPaths( );

addpath(genpath([paths.ajiboyeCodePath '/Projects']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/Velocity BCI Simulator']));
addpath(genpath([paths.ajiboyeCodePath '/Projects/vkfTools']));
addpath(genpath([paths.codePath '/code/analysis/Frank']));
addpath(genpath([paths.codePath '/code/submodules/nptlDataExtraction']));

dataDir = [paths.dataPath '/BG Datasets/'];
sortDir = [paths.dataPath '/CaseDerived/sortedUnits/'];
plotDir = [paths.dataPath '/Derived/rnnDecoding/'];

sessionList = {
    't8','t8.2015.11.19_Fitts_Low_Gain_Elbow_Wrist_to_Grasp',[4:11],'fittsImmediate','case3d'
    't9','t9.2016.08.11 CLAUS GP & Kalman',[8 10 13 15],'fittsImmediate','brownTwigs'
    't10','t10.2016.08.24 Claus Kalman',[8 12 15 22 31 37],'fittsImmediate','brownTwigs'
    't5','t5.2016.09.28',[7 8 9 10],'fittsImmediate','grid_t5'
    };
workspaceSize = [14, 0.5, 0.5, 484, 26, 1.2, 1.2, 1000];
featureTypes = {'ncTX and SpikePower','Sorted'};

%%
for s = 1:size(sessionList,1)
    for featureIdx = 1
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
            [ slc, cursorPos, targetPos, reaches, decoder, decNorms, targRad, decVel ] = ...
                prepareDataForPSTH( [dataDir filesep sessionList{s,2}], sessionList{s,3}, sessionList{s,5} );
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
        %vector decoder
        out = rnnDecoders_gru(in);
        save([saveDir filesep 'rnnResults.mat'],'out');
        
    end %feature type
end %session

%%
for s = 1:size(sessionList,1)
    for featureIdx = 1
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
            [ slc, cursorPos, targetPos, reaches, decoder, decNorms, targRad, decVel ] = ...
                prepareDataForPSTH( [dataDir filesep sessionList{s,2}], sessionList{s,3}, sessionList{s,5} );
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
        %mg only
        rnnResult = load([saveDir filesep 'rnnResults_mg.mat']);
        rnnResult = rnnResult.outMag;
        rnnResult.xValOut(5:6) = rnnResult.xValOutLin;
        rnnResult.xValOut{5} = matVecMag(rnnResult.xValOut{5},2);
        rnnResult.xValOut{6} = matVecMag(rnnResult.xValOut{6},2);

        evalIdx = intersect(find(rnnResult.xValOut{1}(:,1)~=0), expandEpochIdx([in.reachEpochs(:,1)+10, in.reachEpochs(:,2)]));
        for x=1:length(rnnResult.xValOut)
           rnnResult.xValOut{x}(evalIdx,:) = zscore(rnnResult.xValOut{x}(evalIdx,:));
        end
        
        decPerf = zeros(length(rnnResult.xValOut),3);
        posErr = targetPos - cursorPos;
        targDist = matVecMag(posErr,2);
        inTarget = targDist<targRad;
        inTargIdx = intersect(evalIdx, find(inTarget));
        outTargIdx = intersect(evalIdx, find(~inTarget));
        
        inTargLabels = zeros(length(evalIdx),1);
        inTargLabels(inTarget(evalIdx)) = 1;
        inTargLabels(~inTarget(evalIdx)) = 0;
        
        targHist = cell(length(rnnResult.xValOut),2);
        
        for decIdx = 1:length(rnnResult.xValOut)
            mnFar = mean(rnnResult.xValOut{decIdx}(outTargIdx));
            mnNear = mean(rnnResult.xValOut{decIdx}(inTargIdx));
            sdAll = std(rnnResult.xValOut{decIdx}(evalIdx));
            
            decPerf(decIdx,1) = corr(rnnResult.xValOut{decIdx}(evalIdx), targDist(evalIdx));
            decPerf(decIdx,2) = (mnFar - mnNear) / sdAll;
            
            targHist{decIdx,1} = rnnResult.xValOut{decIdx}(outTargIdx);
            targHist{decIdx,2} = rnnResult.xValOut{decIdx}(inTargIdx);
            
            [X,Y,T,decPerf(decIdx,3)] = perfcurve(inTargLabels,rnnResult.xValOut{decIdx}(evalIdx),0);
        end
        
        binEdges = linspace(0,3,20);
        binCenters = binEdges(1:(end-1)) + (binEdges(2)-binEdges(1))/2;
        
        figure('Position',[135         936        1145         159]);
        for decIdx = 1:length(rnnResult.xValOut)
            subplot(1,6,decIdx);
            hold on;
            N = histcounts(targHist{decIdx,1},binEdges);
            plot(binCenters, N/sum(N), 'LineWidth', 2);
            
            N = histcounts(targHist{decIdx,2},binEdges);
            plot(binCenters, N/sum(N), 'r', 'LineWidth', 2);
            
            set(gca,'FontSize',16,'LineWidth',1.5);
            ylim([0 0.4]);
            xlim([0 3]);
        end
        
        %%
        %magnitude decoding
        rnnResult = load([saveDir filesep 'rnnResults.mat']);
        rnnResult = rnnResult.out;
        rnnResult.xValOut(5:6) = rnnResult.xValOutLin;
        
        evalIdx = intersect(find(rnnResult.xValOut{1}(:,1)~=0), expandEpochIdx([in.reachEpochs(:,1)+10, in.reachEpochs(:,2)]));
        for x=1:length(rnnResult.xValOut)
            rnnResult.xValOut{x}(evalIdx,:) = zscore(rnnResult.xValOut{x}(evalIdx,:));
        end
        
        decPerf = zeros(length(rnnResult.xValOut),4);
        posErr = targetPos - cursorPos;
        inTarget = matVecMag(posErr,2)<targRad;
        inTargIdx = intersect(evalIdx, find(inTarget));
        outTargIdx = intersect(evalIdx, find(~inTarget));
        targHist = cell(length(rnnResult.xValOut),2);
        rocCurves = cell(length(rnnResult.xValOut),3);
        
        for decIdx = 1:length(rnnResult.xValOut)
            mnFar = mean(matVecMag(rnnResult.xValOut{decIdx}(outTargIdx,:),2));
            mnNear = mean(matVecMag(rnnResult.xValOut{decIdx}(inTargIdx,:),2));
            sdAll = std(matVecMag(rnnResult.xValOut{decIdx}(evalIdx,:),2));
            
            decPerf(decIdx,1) = nanmean(getAngularError(rnnResult.xValOut{decIdx}(evalIdx,:), posErr(evalIdx,:)))*(180/pi);
            decPerf(decIdx,2) = mnFar / mnNear;
            decPerf(decIdx,3) = mean(diag(corr(rnnResult.xValOut{decIdx}(evalIdx,:), posErr(evalIdx,:))));
            decPerf(decIdx,4) = (mnFar - mnNear) / sdAll;
            
            targHist{decIdx,1} = matVecMag(rnnResult.xValOut{decIdx}(outTargIdx,:),2);
            targHist{decIdx,2} = matVecMag(rnnResult.xValOut{decIdx}(inTargIdx,:),2);
        end
        
        binEdges = linspace(0,3,20);
        binCenters = binEdges(1:(end-1)) + (binEdges(2)-binEdges(1))/2;
        
        figure('Position',[135         936        1145         159]);
        for decIdx = 1:length(rnnResult.xValOut)
            subplot(1,6,decIdx);
            hold on;
            N = histcounts(targHist{decIdx,1},binEdges);
            plot(binCenters, N, 'LineWidth', 2);
            
            N = histcounts(targHist{decIdx,2},binEdges);
            plot(binCenters, N, 'r', 'LineWidth', 2);
            
            set(gca,'FontSize',16,'LineWidth',1.5);
            ylim([0 10000]);
        end
        
    end %feature type
end %session