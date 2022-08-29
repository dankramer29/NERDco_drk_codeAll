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
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    't5-2017-09-20', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm',...
    't5-2017-09-20-LFADS1',...
    't5-2017-09-20-LFADS5'};

%%
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];
resultDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsResults'];
mkdir(resultDir);

%%
for d=8:9
    
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
            saveas(gcf,[saveDir filesep 'dPCA_sameAx_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_sameAx_' savePostfix '.svg'],'svg');
            
            %SFA-rotated dPCA
            sfaOut = sfaRot_dPCA( dPCA_out );
            oneFactor_dPCA_plot( sfaOut, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'sfa_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'sfa_' savePostfix '.svg'],'svg');
            
            %SFA-rotated dPCA
            sfaOut = sfaRot_dPCA( dPCA_out );
            oneFactor_dPCA_plot( sfaOut, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'sfa_sameAx_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'sfa_sameAx_' savePostfix '.svg'],'svg');
            
            %dPCA variance accounted for in CD dimensions
            figure
            plot(dPCA_out.explVar.componentVar(dPCA_out.whichMarg==1),'-o','LineWidth',2);
            set(gca,'FontSize',16,'LineWidth',1.5);
            xlabel('CD Dimension');
            ylabel('Variance');
            saveas(gcf,[saveDir filesep 'dPCA_varExp' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_varExp' savePostfix '.svg'],'svg');
            
            %%
            %limited dPCA
            %------X-------
            useTrl = ismember(trialCodes,[1 5]);
            dPCA_out_2dir = apply_dPCA_simple( neuralStack, eventIdx(useTrl), trialCodes(useTrl), timeWindow, timeStep, margNames );
            
            timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
            margNamesShort = {'Dir','CI'};
            avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
            
            oneFactor_dPCA_plot( dPCA_out_2dir, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'dPCA_Xdir_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_Xdir_' savePostfix '.svg'],'svg');
            
            %------Y-----
            useTrl = ismember(trialCodes,[3 7]);
            dPCA_out_2dir = apply_dPCA_simple( neuralStack, eventIdx(useTrl), trialCodes(useTrl), timeWindow, timeStep, margNames );
            
            timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
            margNamesShort = {'Dir','CI'};
            avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
            
            oneFactor_dPCA_plot( dPCA_out_2dir, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
            saveas(gcf,[saveDir filesep 'dPCA_Ydir_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'dPCA_Ydir_' savePostfix '.svg'],'svg');
            
            %%
            %PSTH
            psthOpts = makePSTHOpts();
            psthOpts.gaussSmoothWidth = 0;
            psthOpts.neuralData = {neuralStack};
            psthOpts.timeWindow = timeWindow;
            psthOpts.trialEvents = eventIdx;
            psthOpts.trialConditions = trialCodes;
            psthOpts.conditionGrouping = {[1 5], [3 7]};
            psthOpts.lineArgs = lineArgs;

            psthOpts.plotsPerPage = 10;
            psthOpts.plotDir = [saveDir filesep 'PSTH_' savePostfix];
            mkdir(psthOpts.plotDir);
            featLabels = cell(size(neuralStack,2),1);
            for f=1:length(featLabels)
                featLabels{f} = ['TX' num2str(f)];
            end
            psthOpts.featLabels = featLabels;
            psthOpts.orderBySNR = 1;

            psthOpts.prefix = ['2dir'];
            pOut = makePSTH_simple(psthOpts); 
            
            %%
            %neural speed
            axIdx = find(dPCA_out.whichMarg==1);
            axIdx = axIdx(1:6);
            ns = zeros(size(dPCA_out.Z,2), size(dPCA_out.Z,3));
            for c=1:size(ns,1)
                tmp = squeeze(dPCA_out.Z(axIdx,c,:))';
                tmp = gaussSmooth_fast(tmp, 5);
                ns(c,2:end) = matVecMag(diff(tmp),2);
            end
            
            figure
            hold on;
            plot(timeAxis, mean(ns), 'LineWidth', 2);
            xlabel('Time');
            ylabel('Neural Speed');
            plotBackgroundSignal( timeAxis, avgSpeed );
            set(gca,'LineWidth',1.5,'FontSize',16);
            saveas(gcf,[saveDir filesep 'neuralSpeed_' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'neuralSpeed_' savePostfix '.svg'],'svg');
            
            %%
            %neural angle
            na = zeros(size(dPCA_out.Z,2), size(dPCA_out.Z,3));
            for c=1:size(na,1)
                neuralPos = squeeze(dPCA_out.Z(axIdx,c,:))';
                neuralPos = gaussSmooth_fast(neuralPos, 5);
                neuralVel = diff(neuralPos);
                neuralVel = bsxfun(@times, neuralVel, 1./matVecMag(neuralVel,2));
                neuralPosUnit = bsxfun(@times, neuralPos, 1./matVecMag(neuralPos,2));
                
                neuralAngle = zeros(size(neuralVel,1),1);
                for t=1:length(neuralAngle)
                    neuralAngle(t) = subspace(neuralVel(t,:)', neuralPosUnit(t,:)')*180/pi;
                end
                
                na(c,2:end) = neuralAngle;
            end
            
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
            %jPCA
            Data = struct();
            for n=1:size(dPCA_out.featureAverages,2)
                Data(n).A = squeeze(dPCA_out.featureAverages(:,n,:))';
                Data(n).times = predata.timeAxis{alignIdx}*1000;
            end

            jPCA_params.normalize = false;
            jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.meanSubtract = true;
            jPCA_params.numPCs = 6;  % default anyway, but best to be specific

            if strcmp(predata.alignTypes{alignIdx},'Go')
                startTime = 106;
            elseif strcmp(predata.alignTypes{alignIdx},'MovStart')
                startTime = -104;
            else
                startTime = -404;
            end
                
            jPCATimes = startTime:predata.binMS:(startTime+250);
            [Projection, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
                
            %%
            figure;
            params.planes2plot = 1;
            params.reusePlot = 1;
            phaseSpace(Projection, jPCA_Summary, params);  % makes the plot
            set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);
            title([num2str(startTime) ' to ' num2str(startTime+250)]);
            
            saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.svg'],'svg');

            %%
            colors = hsv(length(Projection))*0.8;

            fHandles(3)=figure('Position',[680   688   958   290]);
            subplot(1,2,1);
            hold on
            for p=1:length(Projection)
                plot(Projection(p).allTimes, Projection(p).projAllTimes(:,1),'Color',colors(p,:),'LineWidth',2);
            end
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlabel('Time (s)');
            ylabel('jPC1');

            subplot(1,2,2);
            hold on
            for p=1:length(Projection)
                plot(Projection(p).allTimes, Projection(p).projAllTimes(:,2),'Color',colors(p,:),'LineWidth',2);
            end
            set(gca,'LineWidth',1.5,'FontSize',16);
            xlabel('Time (s)');
            ylabel('jPC2');
            
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.png'],'png');
            saveas(gcf,[saveDir filesep 'jPCA_Time' savePostfix '.svg'],'svg');

            %%
            out.varRatio = jPCA_Summary.R2_Mskew_kD./jPCA_Summary.R2_Mbest_kD;
            out.eig = (abs(eig(jPCA_Summary.Mskew))*(1000/predata.binMS))/(2*pi);
            out.jPCA_Summary = jPCA_Summary;
            out.dPCA_out = dPCA_out;
            out.avgSpeed = avgSpeed;
            out.neuralSpeed = mean(ns);
            save([saveDir filesep 'mat_result' savePostfix '.mat'],'out');
            
        end
    end
end
