%--align to LFADS start?
%--add open-loop and/or fake closed-loop controls to eliminate variability
%concerns
%--dimensionality of LFADS signals within a certain window

%%
datasets = {'R_2016-02-02_1_arm', ...
    'J_2015-04-14', ...
    'L_2015-06-05', ...
    'J_2015-01-20', ...
    'L_2015-01-14', ...
    'J_2014-09-10', ...
    't5-2017-09-20', ...
    'R_2017-10-04_1_bci', ...
    'R_2017-10-04_1_arm', ...
    'R_2017-10-12_1_arm', ...
    'R_2017-10-12_1_bci_gain1', ...
    'R_2017-10-12_1_bci_gain2', ...
    'R_2017-10-12_1_bci_gain3', ...
    'R_2017-10-12_1_bci_gain4', ...
    'R_2017-10-12_1_auto', ...
    'R_2017-10-16_1_arm', ...
    'R_2017-10-16_1_bci_gain1', ...
    'R_2017-10-16_1_bci_gain2', ...
    'R_2017-10-16_1_bci_gain3', ...
    'R_2017-10-16_1_bci_gain4', ...
    'R_2017-10-16_1_auto', ...
    'R_2017-10-19_1_bci_gain2', ...
    'R_2017-10-19_1_arm',...
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
    for d=1

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

        for alignIdx = 1:2
            
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
                tmpKin = predata.allKin{alignIdx};
                
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
                kinStack = zeros(size(tmpKin,1)*size(tmpKin,2),size(tmpKin,3));
                for t = 1:size(tmp,1)
                    neuralStack(stackIdx,:) = tmp(t,:,:);
                    kinStack(stackIdx,:) = tmpKin(t,:,:);
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

                nCon = length(unique(trialCodes));
                lineArgs = cell(8,1);
                colors = hsv(nCon)*0.8;
                for c=1:nCon
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
                %prep ratio
                windows = {[-0.5,-0.3],[-0.2,0]};
                cVar = zeros(size(dPCA_out.Z,2), length(windows));
                for wIdx = 1:length(windows)
                    timeIdx = find(predata.timeAxis{alignIdx}>=windows{wIdx}(1) & ...
                        predata.timeAxis{alignIdx}<=windows{wIdx}(2));
                    
                    cdIdx = find(dPCA_out.whichMarg==1);
                    for x=1:size(dPCA_out.Z,2)
                        tmp = squeeze(dPCA_out.Z(cdIdx(1:8),x,timeIdx))';
                        cVar(x,wIdx) = mean(sqrt(sum(tmp.^2,2)));
                    end
                end
                PR = cVar(:,1) ./ cVar(:,2);
                
                figure
                hold on
                plot(ones(size(PR))+(rand(size(PR))-0.5)*0.05, PR,'o');
                boxplot(PR);
                title(median(PR));
                saveas(gcf,[saveDir filesep 'prepRatio' savePostfix '.fig'],'fig');
                saveas(gcf,[saveDir filesep 'prepRatio' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'prepRatio' savePostfix '.svg'],'svg');
                
                %%
                %prep vs. move correlation for each neuron
                allCorr = zeros(size(dPCA_out.featureAverages,1),1);
                for n=1:size(dPCA_out.featureAverages,1)
                    %prep corr
                    windows = {[-0.55,-0.25],[-0.05, 0.25]};
                    dat = cell(length(windows),1);
                    for wIdx = 1:length(windows)
                        timeIdx = find(predata.timeAxis{alignIdx}>=windows{wIdx}(1) & ...
                            predata.timeAxis{alignIdx}<=windows{wIdx}(2));

                        dat{wIdx} = squeeze(dPCA_out.featureAverages(n,:,timeIdx));
                    end
                    allCorr(n) = corr(dat{1}(:), dat{2}(:));
                end
                
                %%
                %prep vs. move cross condition decoding
                movIdx = expandEpochIdx([eventIdx-5, eventIdx+25]);
                prepIdx = expandEpochIdx([eventIdx-55, eventIdx-25]);
                allIdx = expandEpochIdx([eventIdx-55, eventIdx+25]);
                
                dirVec = kinStack(:,6:7) - kinStack(:,1:2);
                dirVec = bsxfun(@times, dirVec, 1./matVecMag(dirVec,2));
                
                dirVec_prep = dirVec;
                dirVec_prep(movIdx,:) = 0;
                
                dirVec_move = dirVec;
                dirVec_move(prepIdx,:) = 0;
                
                filtPrep_only = buildLinFilts(dirVec_prep(allIdx,:), [ones(length(allIdx),1), neuralStack(allIdx,:)], 'standard');
                filtMov_only = buildLinFilts(dirVec_move(allIdx,:), [ones(length(allIdx),1), neuralStack(allIdx,:)], 'standard');
                filtPrep = buildLinFilts(dirVec(prepIdx,:), [ones(length(prepIdx),1), neuralStack(prepIdx,:)], 'standard');
                filtMov = buildLinFilts(dirVec(movIdx,:), [ones(length(movIdx),1), neuralStack(movIdx,:)], 'standard');
                
                decPrep = [ones(length(neuralStack),1), neuralStack] * filtPrep;
                decMov = [ones(length(neuralStack),1), neuralStack] * filtMov;
                decPrep_only = [ones(length(neuralStack),1), neuralStack] * filtPrep_only;
                decMov_only = [ones(length(neuralStack),1), neuralStack] * filtMov_only;
                
                psthOpts = makePSTHOpts();
                psthOpts.gaussSmoothWidth = 0;
                psthOpts.neuralData = {[decPrep; decMov; decPrep_only; decMov_only]};
                psthOpts.timeWindow = timeWindow;
                psthOpts.trialEvents = [eventIdx; eventIdx+length(decPrep); eventIdx+length(decPrep)*2; eventIdx+length(decPrep)*3];
                psthOpts.trialConditions = [trialCodes; trialCodes+8; trialCodes+16; trialCodes+24];
                psthOpts.conditionGrouping = {1:8, 9:16, 17:24, 25:32};
                psthOpts.lineArgs = [lineArgs; lineArgs; lineArgs; lineArgs];

                psthOpts.plotsPerPage = 10;
                psthOpts.plotDir = [saveDir filesep 'PSTH_' savePostfix];
                mkdir(psthOpts.plotDir);
                psthOpts.featLabels = {'X','Y'};
                psthOpts.orderBySNR = 0;
                psthOpts.subtractConMean = 1;
                psthOpts.bgSignal = avgSpeed;
                
                psthOpts.prefix = 'prepMovDec';
                pOut = makePSTH_simple(psthOpts); 
                close all;
                
                %encoding
                coefPrep = buildLinFilts(neuralStack(prepIdx,:), [ones(length(prepIdx),1), dirVec(prepIdx,:)], 'standard');
                coefMov = buildLinFilts(neuralStack(movIdx,:), [ones(length(movIdx),1), dirVec(movIdx,:)], 'standard');
                cMat = corr(coefPrep',coefMov');
                
                figure('Position',[680   714   776   384]);
                subplot(1,2,1);
                hold on;
                plot(coefPrep(2,:), coefMov(2,:), 'o');
                %plot([-1,1],[-1, 1],'--k');
                axis equal;
                xlabel('Prep');
                ylabel('Move');
                title(['Corr X ' num2str(cMat(2,2))]);
                
                subplot(1,2,2);
                hold on
                plot(coefPrep(3,:), coefMov(3,:), 'o');
                %plot([-1,1],[-1, 1],'--k');
                axis equal;
                xlabel('Prep');
                ylabel('Move');
                title(['Corr Y ' num2str(cMat(3,3))]);
                
                saveas(gcf,[saveDir filesep 'PrepMovePD' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'PrepMovePD' savePostfix '.svg'],'svg');
                
                %ole to separate
                filtOLE = buildLinFilts([dirVec_prep(allIdx,:), dirVec_move(allIdx,:)], ...
                    neuralStack(allIdx,:), 'inverseLinear');
                decAll = neuralStack * filtOLE;
                
                psthOpts = makePSTHOpts();
                psthOpts.gaussSmoothWidth = 0;
                psthOpts.neuralData = {decAll};
                psthOpts.timeWindow = timeWindow;
                psthOpts.trialEvents = [eventIdx];
                psthOpts.trialConditions = [trialCodes];
                psthOpts.conditionGrouping = {1:8};
                psthOpts.lineArgs = [lineArgs];

                psthOpts.plotsPerPage = 10;
                psthOpts.plotDir = [saveDir filesep 'PSTH_' savePostfix];
                mkdir(psthOpts.plotDir);
                psthOpts.featLabels = {'XPrep','YPrep','XMov','YMov'};
                psthOpts.orderBySNR = 0;
                psthOpts.subtractConMean = 1;
                psthOpts.bgSignal = avgSpeed;
                
                psthOpts.prefix = 'prepMovOLEDec';
                pOut = makePSTH_simple(psthOpts); 
                %%
                %single sample PCA
                [pcaOut.COEFF, pcaOut.SCORE, pcaOut.LATENT, pcaOut.TSQUARED, pcaOut.EXPLAINED] = pca(neuralStack); 

                figure
                plot(0:10, [0; cumsum(pcaOut.EXPLAINED(1:10))],'-o','LineWidth',2);
                set(gca,'LineWidth',1.5,'FontSize',16);

                saveas(gcf,[saveDir filesep 'PCA_cumExpl_' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'PCA_cumExpl_' savePostfix '.svg'],'svg');

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
                psthOpts.conditionGrouping = {1:8};
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
                psthOpts.subtractConMean = 1;
                psthOpts.bgSignal = avgSpeed;
                
                psthOpts.prefix = '8dir';
                pOut = makePSTH_simple(psthOpts); 
                close all;

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

                if strcmp(predata.alignTypes{alignIdx},'Go') || strcmp(predata.alignTypes{alignIdx},'NeuralWarp')
                    timeSweep = -50:50:200;
                elseif strcmp(predata.alignTypes{alignIdx},'MovStart')
                    timeSweep = -200:50:0;
                else
                    timeSweep = -400:50:0;
                end

                Projections = cell(length(timeSweep),2);
                jPCA_Summaries = cell(length(timeSweep),2);
                windowWidths = [250, 400];
                for timeIdx = 1:length(timeSweep)
                    %short window
                    jPCATimes = timeSweep(timeIdx):predata.binMS:(timeSweep(timeIdx)+windowWidths(1));
                    for x = 1:length(jPCATimes)
                        [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                        jPCATimes(x) = Data(1).times(minIdx);
                    end

                    [Projections{timeIdx,1}, jPCA_Summaries{timeIdx,1}] = jPCA(Data, jPCATimes, jPCA_params);
                    
                    %long window
                    jPCATimes = timeSweep(timeIdx):predata.binMS:(timeSweep(timeIdx)+windowWidths(2));
                    for x = 1:length(jPCATimes)
                        [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                        jPCATimes(x) = Data(1).times(minIdx);
                    end

                    [Projections{timeIdx,2}, jPCA_Summaries{timeIdx,2}] = jPCA(Data, jPCATimes, jPCA_params);
                end

                %%
                figure('Position',[113         565        1568         533]);
                for timeIdx = 1:length(timeSweep)
                    subplot(2,length(timeSweep),timeIdx);
                    params.planes2plot = 1;
                    params.reusePlot = 1;
                    params.useLabel = 0;
                    phaseSpace(Projections{timeIdx,1}, jPCA_Summaries{timeIdx,1}, params);  % makes the plot
                    set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);
                    title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(1)) ' (' ...
                        num2str(jPCA_Summaries{timeIdx,1}.varCaptEachPlane(1)*100,3) '%)']);
                    
                    subplot(2,length(timeSweep),timeIdx+length(timeSweep));
                    params.planes2plot = 1;
                    params.reusePlot = 1;
                    params.useLabel = 0;
                    phaseSpace(Projections{timeIdx,2}, jPCA_Summaries{timeIdx,2}, params);  % makes the plot
                    set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);
                    title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(2)) ' (' ...
                        num2str(jPCA_Summaries{timeIdx,2}.varCaptEachPlane(1)*100,3) '%)']);
                end

                saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'jPCA_Plane' savePostfix '.svg'],'svg');

                %%
                lengthNames = {'short','long'};
                for lengthIdx = 1:2
                    colors = hsv(length(Projections{1}))*0.8;

                    fHandles(3)=figure('Position',[14         621        1627         419]);
                    for timeIdx = 1:length(timeSweep)
                        subplot(2,length(timeSweep),timeIdx);
                        hold on
                        for p=1:length(Projections{1})
                            plot(Projections{timeIdx,lengthIdx}(p).allTimes, Projections{timeIdx,lengthIdx}(p).projAllTimes(:,1),...
                                'Color',colors(p,:),'LineWidth',2);
                        end
                        set(gca,'LineWidth',1.5,'FontSize',16);
                        xlabel('Time (s)');
                        ylabel('jPC1');
                        axis tight;
                        title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(lengthIdx))]);

                        subplot(2,length(timeSweep),timeIdx + length(timeSweep));
                        hold on
                        for p=1:length(Projections{1})
                            plot(Projections{timeIdx,lengthIdx}(p).allTimes, Projections{timeIdx,lengthIdx}(p).projAllTimes(:,2),...
                                'Color',colors(p,:),'LineWidth',2);
                        end
                        set(gca,'LineWidth',1.5,'FontSize',16);
                        xlabel('Time (s)');
                        ylabel('jPC2');
                        axis tight;
                    end
                    saveas(gcf,[saveDir filesep 'jPCA_Time_' lengthNames{lengthIdx} savePostfix '.png'],'png');
                    saveas(gcf,[saveDir filesep 'jPCA_Time_' lengthNames{lengthIdx} savePostfix '.svg'],'svg');
                end
                
                %%
                %single trial jPCA
                catNeural = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
                Data = struct();
                for n=1:length(eventIdx)
                    Data(n).A = squeeze(catNeural(n,:,:));
                    Data(n).times = int32(predata.timeAxis{alignIdx}*1000);
                end

                jPCA_params.normalize = false;
                jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
                jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
                jPCA_params.meanSubtract = true;
                jPCA_params.numPCs = 6;  % default anyway, but best to be specific

                if strcmp(predata.alignTypes{alignIdx},'Go') || strcmp(predata.alignTypes{alignIdx},'NeuralWarp')
                    timeSweep = -50:50:200;
                elseif strcmp(predata.alignTypes{alignIdx},'MovStart')
                    timeSweep = -200:50:0;
                else
                    timeSweep = -400:50:0;
                end

                Projections_single = cell(length(timeSweep),2);
                jPCA_Summaries_single = cell(length(timeSweep),2);
                windowWidths = [250, 400];
                for timeIdx = 1:length(timeSweep)
                    %short window
                    jPCATimes = timeSweep(timeIdx):predata.binMS:(timeSweep(timeIdx)+windowWidths(1));
                    for x = 1:length(jPCATimes)
                        [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                        jPCATimes(x) = Data(1).times(minIdx);
                    end

                    [Projections_single{timeIdx,1}, jPCA_Summaries_single{timeIdx,1}] = jPCA(Data, jPCATimes, jPCA_params);
                    
                    %long window
                    jPCATimes = timeSweep(timeIdx):predata.binMS:(timeSweep(timeIdx)+windowWidths(2));
                    for x = 1:length(jPCATimes)
                        [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                        jPCATimes(x) = Data(1).times(minIdx);
                    end

                    [Projections_single{timeIdx,2}, jPCA_Summaries_single{timeIdx,2}] = jPCA(Data, jPCATimes, jPCA_params);
                end
        
                %%
                %find example trials, then only plot those
                toPlotIdx = [];
                codeList = unique(trialCodes);
                for c=1:length(codeList)
                    trlIdx = find(trialCodes==codeList(c));
                    trlIdx = trlIdx(randperm(length(trlIdx)));
                    toPlotIdx = [toPlotIdx; trlIdx(1)];
                end
                
                for x=1:numel(Projections_single)
                    Projections_single{x} = Projections_single{x}(toPlotIdx);
                end
                
                figure('Position',[113         565        1568         533]);
                for timeIdx = 1:length(timeSweep)
                    subplot(2,length(timeSweep),timeIdx);
                    params.planes2plot = 1;
                    params.reusePlot = 1;
                    params.useLabel = 0;
                    phaseSpace(Projections_single{timeIdx,1}, jPCA_Summaries_single{timeIdx,1}, params);  % makes the plot
                    set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);
                    title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(1)) ' (' ...
                        num2str(jPCA_Summaries_single{timeIdx,1}.varCaptEachPlane(1)*100,3) '%)']);
                    
                    subplot(2,length(timeSweep),timeIdx+length(timeSweep));
                    params.planes2plot = 1;
                    params.reusePlot = 1;
                    params.useLabel = 0;
                    phaseSpace(Projections_single{timeIdx,2}, jPCA_Summaries_single{timeIdx,2}, params);  % makes the plot
                    set(gca,'XTickLabel',[],'YTickLabel',[],'LineWidth',1.5,'FontSize',16);
                    title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(2)) ' (' ...
                        num2str(jPCA_Summaries_single{timeIdx,2}.varCaptEachPlane(1)*100,3) '%)']);
                end

                saveas(gcf,[saveDir filesep 'jPCA_single_Plane' savePostfix '.png'],'png');
                saveas(gcf,[saveDir filesep 'jPCA_single_Plane' savePostfix '.svg'],'svg');
                
                lengthNames = {'short','long'};
                for lengthIdx = 1:2
                    colors = hsv(length(Projections_single{1}))*0.8;

                    fHandles(3)=figure('Position',[14         621        1627         419]);
                    for timeIdx = 1:length(timeSweep)
                        subplot(2,length(timeSweep),timeIdx);
                        hold on
                        for p=1:length(Projections_single{1})
                            plot(Projections_single{timeIdx,lengthIdx}(p).allTimes, Projections_single{timeIdx,lengthIdx}(p).projAllTimes(:,1),...
                                'Color',colors(p,:),'LineWidth',2);
                        end
                        set(gca,'LineWidth',1.5,'FontSize',16);
                        xlabel('Time (s)');
                        ylabel('jPC1');
                        axis tight;
                        title([num2str(timeSweep(timeIdx)) ' to ' num2str(timeSweep(timeIdx)+windowWidths(lengthIdx))]);

                        subplot(2,length(timeSweep),timeIdx + length(timeSweep));
                        hold on
                        for p=1:length(Projections_single{1})
                            plot(Projections_single{timeIdx,lengthIdx}(p).allTimes, Projections_single{timeIdx,lengthIdx}(p).projAllTimes(:,2),...
                                'Color',colors(p,:),'LineWidth',2);
                        end
                        set(gca,'LineWidth',1.5,'FontSize',16);
                        xlabel('Time (s)');
                        ylabel('jPC2');
                        axis tight;
                    end
                    saveas(gcf,[saveDir filesep 'jPCA_single_Time_' lengthNames{lengthIdx} savePostfix '.png'],'png');
                    saveas(gcf,[saveDir filesep 'jPCA_single_Time_' lengthNames{lengthIdx} savePostfix '.svg'],'svg');
                end

                %%
                out.jPCA_Summary = jPCA_Summaries;
                out.jPCA_Summary_single = jPCA_Summaries_single;
                out.dPCA_out = dPCA_out;
                out.avgSpeed = avgSpeed;
                out.pcaOut = pcaOut;
                save([saveDir filesep 'mat_result' savePostfix '.mat'],'out');

            end %array set
        end %alignment type
    end %dataset
end %apply LFADS