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
shortNames = {'t8.2015.11.19','t9.2016.08.11','t10.2016.08.24','t5.2016.09.28'};
workspaceSize = [26, 1.2, 1.2, 1000];
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
        out = prepareXValRNNData(in, workspaceSize(s), shortNames{s}, [paths.dataPath '/Derived/rnnDecoding/']);
        save([saveDir filesep 'rnnResults.mat'],'out');
        
    end %feature type
end %session

%%