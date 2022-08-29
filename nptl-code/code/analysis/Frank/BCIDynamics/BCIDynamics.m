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

%%
datasets = {'R_2016-02-02_1', ...
    'R_2017-01-19_1', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    'R_2014-08-24', ...
    't5-2017-09-20'};

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
    
    predata.alignTypes = {'Go','MovStart','TargEnter'};
    if length(predata.metaData.arrayNames)==2
        arraySets = {[1],[2],[1 2]};
    else
        arraySets = {[1]};
    end
    
    for alignIdx = 1:length(predata.alignTypes)
        for arraySetIdx = 1:length(arraySets)
            %file saving
            savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];
                
            %get binned rates
            tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
            
            %smooth
            for t=1:size(tmp,1)
                tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
            end
            
            %stack
            eventIdx = [];
            [~,eventOffset] = min(abs(predata.timeAxis));

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
            timeWindow = [-eventOffset+1, length(predata.timeAxis)-eventOffset];
            trialCodes = predata.allCon{alignIdx};
            timeStep = 0.01;
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
            
            %SFA-rotated dPCA
            sfaOut = sfaRot_dPCA( dPCA_out );
            oneFactor_dPCA_plot( sfaOut, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'sfa_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'sfa_' savePostfix '.svg'],'svg');
            
            %dPCA variance accounted for in CD dimensions
            figure
            plot(dPCA_out.explVar.componentVar(dPCA_out.whichMarg==1),'-o','LineWidth',2);
            set(gca,'FontSize',16,'LineWidth',1.5);
            xlabel('CD Dimension');
            ylabel('Variance');
            saveas(gcf,[saveDir filesep 'dPCA_varExp' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_varExp' savePostfix '.svg'],'svg');
            
            close all;
            
            %%
            %jPCA
            Data = struct();
            for n=1:size(dPCA_out.featureAverages,2)
                Data(n).A = squeeze(dPCA_out.featureAverages(:,n,:))';
                Data(n).times = predata.timeAxis*1000;
            end

            jPCA_params.normalize = false;
            jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.meanSubtract = true;
            jPCA_params.numPCs = 6;  % default anyway, but best to be specific

            startTimes = -204:20:406;
            Projection = cell(length(startTimes),2);
            jPCA_Summary = cell(length(startTimes),2);
            for s=1:length(startTimes)
                times = startTimes(s):predata.binMS:(startTimes(s)+250);
                [Projection{s,1}, jPCA_Summary{s,1}] = jPCA(Data, times, jPCA_params);

                times = startTimes(s):predata.binMS:(startTimes(s)+1000);
                [Projection{s,2}, jPCA_Summary{s,2}] = jPCA(Data, times, jPCA_params);
            end

            %%
            jPCA_Small = [jPCA_Summary{:,1}];
            R2 = [jPCA_Small.R2_Mskew_kD];
            [~, bestIdx] = max(R2);

            figure('Position',[17         108        1417         994]);
            for plotIdx=1:26
                jPCA_inner = jPCA_Small(plotIdx);
                Projection_Small = Projection{plotIdx,1};
                jPCA_inner.startTime = startTimes(plotIdx);

                subtightplot(5,6,plotIdx,[0.05 0.05],[0.05 0.05],[0.05 0.05]);
                params.planes2plot = 1;
                params.reusePlot = 1;
                phaseSpace(Projection_Small, jPCA_inner, params);  % makes the plot
                set(gca,'XTickLabel',[],'YTickLabel',[]);
                
                title([num2str(startTimes(plotIdx)) ' to ' num2str(startTimes(plotIdx)+250)]);
            end
            saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.svg'],'svg');

            %%
            colors = hsv(length(Projection_Small))*0.8;
            Projection_Small = Projection{bestIdx,1};

            fHandles(3)=figure('Position',[680   688   958   290]);
            subplot(1,2,1);
            hold on
            for p=1:length(Projection_Small)
                plot(Projection_Small(p).allTimes, Projection_Small(p).projAllTimes(:,1),'Color',colors(p,:),'LineWidth',1);
            end
            xlabel('Time (s)');
            ylabel('jPC1');

            subplot(1,2,2);
            hold on
            for p=1:length(Projection_Small)
                plot(Projection_Small(p).allTimes, Projection_Small(p).projAllTimes(:,2),'Color',colors(p,:),'LineWidth',1);
            end
            xlabel('Time (s)');
            ylabel('jPC2');
            
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.svg'],'svg');

            %%
            figure
            hold on
            plot(startTimes, [jPCA_Small.R2_Mbest_kD] ./ [jPCA_Small.R2_Mskew_kD],'-o','LineWidth',2);
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlabel('Start Time (ms)');
            ylabel('Variance Ratio Best/Skew');
            
            saveas(gcf,[saveDir filesep 'jPCA_Ratio' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Ratio' savePostfix '.svg'],'svg');
            
            out.eig = (abs(eig(jPCA_Small(bestIdx).Mskew))*(1000/predata.binMS))/(2*pi);
            out.bestIdx = bestIdx;
            out.jPCA_Summary = jPCA_Summary;
        end
    end
end
