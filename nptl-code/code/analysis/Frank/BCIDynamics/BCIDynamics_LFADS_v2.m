%suite of neural population activity summaries applied to hand control,
%brain control datasets

%dynamics measures for BMI vs. hand control:

%--qualitative, SFA-sorted dPCA plots
%--qualitative jPCA rotation & time series plots, for various windows
%--amount of variance explained by non-velocity dimensions (3rd, 4th, etc.)
%relative to velocity dimensions
%--Mskew vs. Mfull variance
%--rotation angle distribution
%--rate-constrained RNN generation of neural activity, performance
%--trial-averaged vs. non-trial-averaged vs. LFADS versions of each measure
%--neural speed?
%--% unexplained by 4-dim model

%%
datasets = {'R_2016-02-02_1', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm',...
    't5-2017-09-20'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
lfadsResultDir = [paths.dataPath filesep 'Derived' filesep 'post_LFADS' filesep 'BCIDynamics' filesep 'collatedMatFiles'];
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=7
    
    saveDir = [resultDir filesep datasets{d} '_LFADS'];
    mkdir(saveDir);
    
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
    
    if length(predata.metaData.arrayNames)==2
        arraySets = {[1],[2],[1 2]};
    else
        arraySets = {[1]};
    end
    
    for alignIdx = 1:length(predata.alignTypes)
        
        %substitute LFADS-smoothed neural data for raw data
        lfadsData = load([lfadsResultDir filesep datasets{d} '_' predata.alignTypes{alignIdx} '.mat']);
        
        predata.allNeural{alignIdx,1}(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(1:96,:,:)),[3 2 1]);
        predata.allNeural{alignIdx,1}(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(1:96,:,:)),[3 2 1]);
        
        predata.allNeural{alignIdx,2}(lfadsData.matInput.trainIdx,:,:) = permute(squeeze(lfadsData.allResults{1,1}(97:end,:,:)),[3 2 1]);
        predata.allNeural{alignIdx,2}(lfadsData.matInput.validIdx,:,:) = permute(squeeze(lfadsData.allResults{1,2}(97:end,:,:)),[3 2 1]);
        
        figure
        imagesc(squeeze(lfadsData.matInput.all_data(:,:,1)));
        
        pdNeural = cat(3, predata.allNeural{1,1}, predata.allNeural{1,2});
        
        figure
        imagesc(squeeze(pdNeural(1,:,:))');
        
        for arraySetIdx = 1:length(arraySets)
            %clear
            close all;
            
            %file saving
            savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];
                
            %get binned rates
            binCountMat = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
            
            %stack
            eventIdx = [];
            [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

            stackIdx = 1:size(binCountMat,2);
            neuralStack = zeros(size(binCountMat,1)*size(binCountMat,2),size(binCountMat,3));
            trlEpochs = [];
            for t = 1:size(binCountMat,1)
                neuralStack(stackIdx,:) = binCountMat(t,:,:);
                trlEpochs = [trlEpochs; [stackIdx(1), stackIdx(end)]];
                eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
                stackIdx = stackIdx + size(binCountMat,2);
            end
                
            %normalize
            neuralStack = zscore(neuralStack);
                        
            %information needed for unrolling functions
            timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
            trialCodes = predata.allCon{alignIdx};
            timeStep = predata.binMS/1000;
            margNames = {'CD', 'CI'};
            
            %simple dPCA
            dPCA_out = apply_dPCA_simple( neuralStack, eventIdx, trialCodes, timeWindow, timeStep, margNames );
            
            lineArgs = cell(8,1);
            colors = hsv(8)*0.8;
            for c=1:8
                lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
            end
            
            timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
            margNamesShort = {'Dir','CI'};
            avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
            
            oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'dPCA_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_' savePostfix '.svg'],'svg');
            
            oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'dPCA_sameAxes_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_sameAxes_' savePostfix '.svg'],'svg');
                   
            %%
            %single sample PCA
            [pcaOut.COEFF, pcaOut.SCORE, pcaOut.LATENT, pcaOut.TSQUARED, pcaOut.EXPLAINED] = pca(neuralStack); 
            
            figure
            plot(0:10, [0; cumsum(pcaOut.EXPLAINED(1:10))],'-o','LineWidth',2);
            set(gca,'LineWidth',1.5,'FontSize',16);
            
            saveas(gcf,[saveDir filesep 'PCA_cumExpl_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'PCA_cumExpl_' savePostfix '.svg'],'svg');
            
            %%
            %single trial projections
            codeList = unique(trialCodes);
            colors = hsv(8)*0.8;
            
            figure
            for dimIdx=1:6
                subplot(1,6,dimIdx);
                hold on;
                for c=1:length(codeList)
                    trlIdx = find(trialCodes==codeList(c),1,'last');
                    loopIdx = trlEpochs(trlIdx,1):trlEpochs(trlIdx,2);
                    
                    plot(pcaOut.SCORE(loopIdx,dimIdx),'LineWidth',2,'Color',colors(c,:));
                end
                ylim([-10 10]);
            end
            
            %%
            %neural speed
            ns = zeros(size(binCountMat,1),size(binCountMat,2));
            for c=1:size(ns,1)
                ns(c,2:end) = matVecMag(diff(squeeze(binCountMat(c,:,:))),2);
            end
            ns(:,1) = ns(:,2);
            
            figure
            hold on;
            plot(timeAxis, median(ns), 'LineWidth', 2);
            xlabel('Time');
            ylabel('Neural Speed');
            plotBackgroundSignal( timeAxis, avgSpeed );
            set(gca,'LineWidth',1.5,'FontSize',16);
            saveas(gcf,[saveDir filesep 'neuralSpeed_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'neuralSpeed_' savePostfix '.svg'],'svg');
            
            %%
            %neural angle
            binCountMat_ms = binCountMat;
            for c=1:size(binCountMat_ms,3)
                tmp = binCountMat_ms(:,:,c);
                tmp = tmp(:);
                mn = mean(tmp);
                sd = std(tmp);
                binCountMat_ms(:,:,c) = (binCountMat_ms(:,:,c) - mn)/sd;
            end
            
            binCountMat_sc = zeros(size(binCountMat,1),size(binCountMat,2),10);
            for c=1:size(binCountMat_sc,1)
                binCountMat_sc(c,:,:) = squeeze(binCountMat_ms(c,:,:))*pcaOut.COEFF(:,1:10);
            end
            
            na = zeros(size(binCountMat_sc,1),size(binCountMat_sc,2));
            for c=1:size(na,1)
                neuralPos = squeeze(binCountMat_sc(c,:,:));
                neuralVel = diff(neuralPos);
                neuralVel = bsxfun(@times, neuralVel, 1./matVecMag(neuralVel,2));
                neuralPosUnit = bsxfun(@times, neuralPos, 1./matVecMag(neuralPos,2));
                
                neuralAngle = zeros(size(neuralVel,1),1);
                for t=1:length(neuralAngle)
                    neuralAngle(t) = subspace(neuralVel(t,:)', neuralPosUnit(t,:)')*180/pi;
                end
                
                na(c,2:end) = neuralAngle;
            end
            na(:,1) = na(:,2);
            
            figure
            hold on;
            plot(timeAxis, mean(na), 'LineWidth', 2);
            xlabel('Time');
            ylabel('Neural Angle');
            plotBackgroundSignal( timeAxis, avgSpeed );
            set(gca,'LineWidth',1.5,'FontSize',16);
            saveas(gcf,[saveDir filesep 'neuralAngle_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'neuralAngle_' savePostfix '.svg'],'svg');

            %%
            save([saveDir filesep 'matResult_' savePostfix '.mat'],'dPCA_out','pcaOut','avgSpeed','na','ns','timeAxis','lineArgs','margNames','neuralStack', ...
                'eventIdx', 'trialCodes', 'timeWindow', 'timeStep');


        end
    end
end
