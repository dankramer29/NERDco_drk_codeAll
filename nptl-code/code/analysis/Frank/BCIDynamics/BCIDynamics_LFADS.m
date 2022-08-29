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
datasets = {
    't5-2017-09-20-LFADS1'
    't5-2017-09-20-LFADS2'
    't5-2017-09-20-LFADS3'
    't5-2017-09-20-LFADS4'
    't5-2017-09-20-LFADS5'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=1:length(datasets)
    
    saveDir = [resultDir filesep datasets{d}];
    mkdir(saveDir);
    
    fileName = [dataDir filesep datasets{d} '.mat'];
    predata = load(fileName);
    
    if length(predata.metaData.arrayNames)==2
        arraySets = {[1],[2],[1 2]};
    else
        arraySets = {[1]};
    end
    
    for alignIdx = 1:length(predata.alignTypes)
        for arraySetIdx = 1:length(arraySets)
            %clear
            close all;
            
            %file saving
            savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];
                
            %get binned rates
            tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
            
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
            %dPCA var explained?
            
            %%
            %single sample PCA
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(neuralStack); 
            
            figure
            plot([0; cumsum(EXPLAINED(1:10))],'-o');
            %%
            %single trial neural speed
            
            %%
            %single trial neural rotation angle
            
            
            %%
            %dPCA on single trial exemplar
            dPCA_out = apply_dPCA_simple( neuralStack, eventIdx(9:16), trialCodes(9:16), timeWindow, timeStep, margNames );
            
            lineArgs = cell(8,1);
            colors = hsv(8)*0.8;
            for c=1:8
                lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
            end
            
            timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
            margNamesShort = {'Dir','CI'};
            avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
            
            oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'dPCA_singleTrial_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_singleTrial_' savePostfix '.svg'],'svg');
         
            %%
            %trial alignment? 
            conIdx = 1;
            trlCodes = predata.allCon{alignIdx};
            trlIdx = find(trlCodes==conIdx);
            
            figure('Position',[2          82        1746         981]);
            for chanIdx = 1:size(predata.allNeural{alignIdx},3)
                subtightplot(14,14,chanIdx);
                hold on;
                for t=1:length(trlIdx)
                    plot(predata.allNeural{alignIdx}(trlIdx(t),:,chanIdx));
                end
                set(gca,'XTick',[],'YTick',[]);
                ylim([0 2]);
                title(num2str(chanIdx));
            end
            
            sequences_mv = cell(length(trlIdx),1);
            for s=1:length(sequences)
                sequences_mv{s} = squeeze(predata.allNeural{alignIdx}(trlIdx(s),:,:));
            end
            avgSeq_mv = DBA_mv(sequences_mv);
            
            chanIdx = 50;
            sequences = cell(length(trlIdx),1);
            for s=1:length(sequences)
                sequences{s} = squeeze(predata.allNeural{alignIdx}(trlIdx(s),:,chanIdx))';
            end
            avgSeq = DBA(sequences);
            
            figure
            hold on
            for t=1:10
                plot(predata.allNeural{alignIdx}(trlIdx(t),:,chanIdx),'LineWidth',1.5);
            end
            plot(avgSeq,'k','LineWidth',3);
            plot(avgSeq_mv(:,chanIdx),'g','LineWidth',3);
            plot(squeeze(predata.neuralAvg{alignIdx}(conIdx,:,chanIdx)),'--k','LineWidth',3);
            set(gca,'LineWidth',1.5,'FontSize',16);
            saveas(gcf,[saveDir filesep 'singleChan_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'singleChan_' savePostfix '.svg'],'svg');
            
            %%
            %dPCA on DBA-aligned data
            alignedAvg = zeros(size(predata.neuralAvg{alignIdx}));
            for c=1:size(alignedAvg,1)
                trlIdx = find(trlCodes==c);
                for chanIdx=1:size(alignedAvg,3)
                    disp(chanIdx);
                    sequences = cell(length(trlIdx),1);
                    for s=1:length(sequences)
                        sequences{s} = squeeze(predata.allNeural{alignIdx}(trlIdx(s),:,chanIdx))';
                    end
                    alignedAvg(c,:,chanIdx) = DBA(sequences);
                end
            end
            save([saveDir filesep 'alignedAvg_' savePostfix '.mat'],'alignedAvg');
            
            %stack
            neuralStack = [];
            for c=1:size(alignedAvg,1)
                neuralStack = [neuralStack; squeeze(alignedAvg(c,:,:))];
            end
            eventIdx = 1:size(alignedAvg,2):length(neuralStack);
            
            %normalize
            neuralStack = zscore(neuralStack);
                        
            %information needed for unrolling functions
            timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
            trialCodes = predata.allCon{alignIdx};
            timeStep = predata.binMS/1000;
            margNames = {'CD', 'CI'};
            
            %simple dPCA
            dPCA_out = apply_dPCA_simple( neuralStack, eventIdx, trialCodes(1:8), timeWindow, timeStep, margNames );
            
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

            %%
            %single trial jpca
            Data = struct();
            for n=1:size(predata.allNeural{alignIdx},1)
                Data(n).A = squeeze(predata.allNeural{alignIdx}(n,:,:));
                Data(n).times = int32(predata.timeAxis{alignIdx}*1000);
            end

            jPCA_params.normalize = false;
            jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.meanSubtract = true;
            jPCA_params.numPCs = 6;  % default anyway, but best to be specific

            startTime = 250;
            jPCATimes = int32(startTime:predata.binMS:(startTime + 250));
            [Projection, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
            
            figure;
            params.planes2plot = 1;
            params.reusePlot = 1;
            phaseSpace(Projection, jPCA_Summary, params);  % makes the plot
            set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);

            %%
            colors = hsv(8)*0.8;

            fHandles(3)=figure('Position',[680   688   958   290]);
            subplot(1,2,1);
            hold on
            for p=1:length(Projection)
                plot(Projection(p).allTimes, Projection(p).projAllTimes(:,1),'Color',colors(trlCodes(p),:));
            end
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlabel('Time (s)');
            ylabel('jPC1');

            subplot(1,2,2);
            hold on
            for p=1:length(Projection)
                plot(Projection(p).allTimes, Projection(p).projAllTimes(:,2),'Color',colors(trlCodes(p),:));
            end
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlabel('Time (s)');
            ylabel('jPC2');
            
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.svg'],'svg');

        end
    end
end
