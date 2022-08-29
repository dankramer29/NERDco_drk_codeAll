%--align to LFADS start?
%--add open-loop and/or fake closed-loop controls to eliminate variability
%concerns
%--dimensionality of LFADS signals within a certain window

%%
datasets = {
    'R_2017-10-11_1_arm',...
    'R_2017-10-11_1_bci'
    };

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for doLFADS = 0
    for d=1:2

        if doLFADS
            saveDir = [resultDir filesep datasets{d} '_LFADS'];
        else
            saveDir = [resultDir filesep datasets{d}];
        end
        mkdir(saveDir);

        fileName = [dataDir filesep datasets{d} '.mat'];
        predata = load(fileName);

        if length(predata.metaData.arrayNames)==2
            arraySets = {[1],[2],[1 2]};
        else
            arraySets = {[1]};
        end

        for alignIdx = 2
            
            if doLFADS
                %substitute LFADS-smoothed neural data for raw data
                lfadsData = load([lfadsResultDir filesep datasets{d} '_' predata.alignTypes{alignIdx} '.mat']);

                predata.allNeural{alignIdx,1}(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(1:96,:,:)),[3 2 1]);
                predata.allNeural{alignIdx,1}(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(1:96,:,:)),[3 2 1]);

                predata.allNeural{alignIdx,2}(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(97:end,:,:)),[3 2 1]);
                predata.allNeural{alignIdx,2}(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(97:end,:,:)),[3 2 1]);
            end
            
            for arraySetIdx = 1:length(arraySets)
                %clear
                close all;

                %file saving
                savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];

                %get binned rates
                tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});

                %smooth
                if isfield(predata,'neuralType') && ~strcmp(predata.neuralType,'LFADS')
                    for t=1:size(tmp,1)
                        tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
                    end
                elseif ~isfield(predata,'neuralType')
                    for t=1:size(tmp,1)
                        tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
                    end
                end

                %stack
                eventIdx = [];
                [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

                stackIdx = 1:size(tmp,2);
                neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
                for t = 1:size(tmp,1)
                    neuralStack(stackIdx,:) = tmp(t,:,:);
                    eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
                    stackIdx = stackIdx + size(tmp,2);
                end

                %normalize
                neuralStack = zscore(neuralStack);

                %information needed for unrolling functions
                timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
                trialCodes = predata.allCon{alignIdx};
                timeStep = predata.binMS/1000;
                margNames = {'CD', 'CI'};
                
                %dPCA within a single direction axis <-->
                ringCodes = {[36 35 31 29 25 21 19 15 13 14 18 20 24 28 30 34], ...
                    [43 42 40 33 26 17 10 8 6 7 9 16 23 32 39 41], ...
                    [48 47 45 38 27 12 5 3 1 2 4 11 22 37 44 46]};
                codeSets = cell(8,1);
                for c=1:length(codeSets)
                    rightIdx = c;
                    leftIdx = c+8;
                    codeSets{c} = [ringCodes{3}(leftIdx), ringCodes{2}(leftIdx), ringCodes{1}(leftIdx), ...
                        ringCodes{1}(rightIdx), ringCodes{2}(rightIdx), ringCodes{3}(rightIdx)];
                end
                
                dPCA_out = cell(length(codeSets),1);
                dPCA_axes = cell(length(codeSets),1);
                for c=1:length(codeSets)
                    %simple dPCA
                    [trlIdx, recodeIdx] = ismember(trialCodes, codeSets{c});
                    dPCA_out{c} = apply_dPCA_simple( neuralStack, eventIdx(trlIdx), recodeIdx(trlIdx), ...
                        timeWindow, timeStep, margNames );
                    close(gcf);
                    
                    lineArgs = cell(6,1);
                    colors = [1.0 0 0;
                        0.75 0 0
                        0.5 0 0
                        0 0 0.5
                        0 0 0.75
                        0 0 1.0];
                    for x=1:6
                        lineArgs{x} = {'LineWidth',2,'Color',colors(x,:),'LineWidth',2};
                    end

                    timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
                    margNamesShort = {'Dir','CI'};
                    avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
                    
                    dPCA_axes{c} = oneFactor_dPCA_plot( dPCA_out{c}, timeAxis, lineArgs, margNames, 'zoom', avgSpeed );
                    saveas(gcf,[saveDir filesep 'dPCA_dir ' num2str(c) '_' savePostfix '.png'],'png');
                    saveas(gcf,[saveDir filesep 'dPCA_dir' num2str(c) '_' savePostfix '.svg'],'svg');
                end
                    
                %%
                if alignIdx==1
                    continue;
                end
                
                %%
                chanIdx = {1:96, 97:192};
                chanIdx = [chanIdx{arraySets{arraySetIdx}}];
                normFilts = bsxfun(@times, predata.filts(chanIdx,:), 1./predata.featStd(chanIdx)');
                
                %fit linear dynamics model across trial-averaged data
                %time window = [-100, 400] for arm, [-100, 1000] for bci
                topNDim = 10;
                if strcmp(predata.metaData.controlType,'arm')
                    timeIdx = (-20:60) + 70;
                else
                    timeIdx = (-20:100) + 70;
                end
                concatNeural = [];
                tmp = cat(3,predata.neuralAvg{alignIdx, arraySets{arraySetIdx}});
                tmp = bsxfun(@plus, tmp, -reshape(predata.featMean(chanIdx), [1 1 length(chanIdx)]));
                tmp = bsxfun(@times, tmp, 1./reshape(predata.featStd(chanIdx), [1 1 length(chanIdx)]));
                timeAvg = mean(tmp,1);
                tmp = bsxfun(@plus, tmp, -timeAvg);
                
                for t=1:size(tmp,1)
                    smoothNeural = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
                    concatNeural = [concatNeural; smoothNeural];
                end
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(concatNeural,'Centered','off');
                sNeural = SCORE(:,1:topNDim);
                
                modelFitIdx = [];
                globalOffset = 0;
                for t=1:size(tmp,1)
                    modelFitIdx = [modelFitIdx, timeIdx + globalOffset];
                    globalOffset = globalOffset + 180;
                end
                
                dynMat = buildLinFilts(sNeural(modelFitIdx+1,:), sNeural(modelFitIdx,:), 'standard');
                diffMat =  buildLinFilts(sNeural(modelFitIdx+1,:)-sNeural(modelFitIdx,:), sNeural(modelFitIdx,:), 'standard');
                
                %reconstruct neural trajectories with the LDS
                reconNeural = zeros(size(tmp));
                globalOffset = 0;
                for t=1:size(tmp,1)
                    currentState = sNeural(globalOffset + timeIdx(1),:)';
                    for x=1:length(timeIdx)
                        reconNeural(t,timeIdx(x),:) = COEFF(:,1:topNDim)*currentState;
                        currentState = dynMat * currentState;
                    end
                    globalOffset = globalOffset + 180;
                end
                
                %%
                %plot reconstructed neural activity using same dPCA axes
                for c=1:length(codeSets)
                    %simple dPCA
                    new_dpca = dPCA_out{c};
                    for t=1:length(codeSets{c})
                        for dimIdx=1:20
                            new_dpca.Z(dimIdx,t,:) = squeeze(reconNeural(codeSets{c}(t),:,:)) * new_dpca.W(:,dimIdx);
                        end
                    end
                    
                    lineArgs = cell(6,1);
                    colors = [1.0 0 0;
                        0.75 0 0
                        0.5 0 0
                        0 0 0.5
                        0 0 0.75
                        0 0 1.0];
                    for x=1:6
                        lineArgs{x} = {'LineWidth',2,'Color',colors(x,:),'LineWidth',2};
                    end

                    timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
                    margNamesShort = {'Dir','CI'};
                    avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
                    
                    oneFactor_dPCA_plot( new_dpca, timeAxis, lineArgs, margNames, 'zoom', avgSpeed );
                    saveas(gcf,[saveDir filesep 'dPCA_lds ' num2str(c) '_' savePostfix '.png'],'png');
                    saveas(gcf,[saveDir filesep 'dPCA_lds' num2str(c) '_' savePostfix '.svg'],'svg');
                end
                
                %%
                %try computing new filters to decode position error
                tmpKin = reshape(permute(predata.kinAvg{alignIdx},[2 1 3]),[],7);
                tmpNeural = reshape(permute(reconNeural,[2 1 3]),[],length(chanIdx));
                newFilts = buildLinFilts(tmpKin(:,6:7)-tmpKin(:,1:2), tmpNeural, 'standard');
                newDecVel = tmpNeural * newFilts;
                reconVel = permute(reshape(newDecVel, [180 48 2]),[2 1 3]);
                
                %decode velocity using reconstructed neural activity                
                reconVel = zeros(size(reconNeural,1), size(reconNeural,2), 2);
                for t=1:size(reconVel,1)
                  neuralData = squeeze(reconNeural(t,:,:));
                  reconVel(t,:,:) = neuralData * predata.filts(chanIdx,:);
                end
                
                endPos = [];
                colors = hsv(16)*0.8;
                figure
                hold on
                for t=1:size(reconVel,1)
                    reconPos = cumsum(squeeze(reconVel(t,:,:)));
                    if ismember(t, ringCodes{1})
                        rIdx = 1;
                        lWidth = 1;
                        [~,dirIdx] = ismember(t, ringCodes{1});
                    elseif ismember(t, ringCodes{2})
                        rIdx = 2;
                        lWidth = 2;
                        [~,dirIdx] = ismember(t, ringCodes{2});
                    elseif ismember(t, ringCodes{3})
                        rIdx = 3;
                        lWidth = 4;
                        [~,dirIdx] = ismember(t, ringCodes{3});
                    end
                    plot(reconPos(:,1), reconPos(:,2), 'Color', colors(dirIdx,:), 'LineWidth', lWidth);
                    plot(reconPos(end,1), reconPos(end,2), 'o', 'Color', colors(dirIdx,:),'LineWidth',lWidth,'MarkerSize',lWidth*6);
                    endPos = [endPos; [rIdx, dirIdx, reconPos(end,1), reconPos(end,2)]];
                end
                axis equal;
                saveas(gcf,[saveDir filesep 'decodedTraj_lds_' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'decodedTraj_lds_' savePostfix '.svg'],'svg');
                
                figure
                hold on;
                for r=1:3
                    plotIdx = find(endPos(:,1)==r);
                    tmp = endPos(plotIdx,:);
                    [~,sortIdx] = sort(tmp(:,2));
                    tmp = tmp(sortIdx,:);
                    tmp = [tmp; tmp(1,:)];
                    
                    plot(tmp(:,3), tmp(:,4),'LineWidth',r*2);
                end
                saveas(gcf,[saveDir filesep 'decodedEP_lds_' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'decodedEP_lds_' savePostfix '.svg'],'svg');
                %%
                %decode velocity on actual neural activity
                na = cat(3,predata.neuralAvg{alignIdx, arraySets{arraySetIdx}});
                na = bsxfun(@plus, na, -reshape(predata.featMean(chanIdx), [1 1 length(chanIdx)]));
                na = bsxfun(@times, na, 1./reshape(predata.featStd(chanIdx), [1 1 length(chanIdx)]));
                timeAvg = mean(na,1);
                na = bsxfun(@plus, na, -timeAvg);
                
                concat_na = [];
                for t=1:size(na,1)
                    concat_na = [concat_na; squeeze(na(t,:,:))];
                end
                
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(concat_na,'Centered','off');
                sNeural = SCORE(:,1:topNDim) * COEFF(:,1:topNDim)';
                globalIdx = 1;
                for t=1:size(na,1)
                    na(t,:,:) = sNeural((globalIdx):(globalIdx+179),:);
                    globalIdx = globalIdx + 180;
                end
                
                reconVel = zeros(size(na,1), length(timeIdx), 2);
                for t=1:size(reconVel,1)
                    neuralData = squeeze(na(t,:,:));
                    neuralData = gaussSmooth_fast(neuralData, 2.5);
                    reconVel(t,:,:) = neuralData(timeIdx,:) * predata.filts(chanIdx,:);
                end
                               
                endPos = [];
                colors = hsv(16)*0.8;
                figure
                hold on
                for t=1:size(reconVel,1)
                    reconPos = cumsum(squeeze(reconVel(t,:,:)));
                    if ismember(t, ringCodes{1})
                        rIdx = 1;
                        lWidth = 1;
                        [~,dirIdx] = ismember(t, ringCodes{1});
                    elseif ismember(t, ringCodes{2})
                        rIdx = 2;
                        lWidth = 2;
                        [~,dirIdx] = ismember(t, ringCodes{2});
                    elseif ismember(t, ringCodes{3})
                        rIdx = 3;
                        lWidth = 4;
                        [~,dirIdx] = ismember(t, ringCodes{3});
                    end
                    plot(reconPos(:,1), reconPos(:,2), 'Color', colors(dirIdx,:), 'LineWidth', lWidth);
                    plot(reconPos(end,1), reconPos(end,2), 'o', 'Color', colors(dirIdx,:),'LineWidth',lWidth,'MarkerSize',lWidth*6);
                    endPos = [endPos; [rIdx, dirIdx, reconPos(end,1), reconPos(end,2)]];
                end
                axis equal;
                saveas(gcf,[saveDir filesep 'decodedTraj_' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'decodedTraj_' savePostfix '.svg'],'svg');
                
                figure
                hold on;
                for r=1:3
                    plotIdx = find(endPos(:,1)==r);
                    tmp = endPos(plotIdx,:);
                    [~,sortIdx] = sort(tmp(:,2));
                    tmp = tmp(sortIdx,:);
                    tmp = [tmp; tmp(1,:)];
                    
                    plot(tmp(:,3), tmp(:,4),'LineWidth',r*2);
                end
                saveas(gcf,[saveDir filesep 'decodedEP_' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'decodedEP_' savePostfix '.svg'],'svg');
                %save([saveDir filesep 'mat_result' savePostfix '.mat'],'out');

            end %array set
        end %alignment type
    end %dataset
end %apply LFADS