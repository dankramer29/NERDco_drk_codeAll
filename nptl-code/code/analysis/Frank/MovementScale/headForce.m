%%
dataDir = '/Users/frankwillett/Data/BG Datasets/';
sortDir = 'C:\Users\Frank\Documents\Big Data\frwSimulation\BCI Modeling Results\sortedUnits\';
plotDir = '/Users/frankwillett/Data/headForce/';

addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/'));
addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank'));

sessionList = { 't8','t8.2017.05.02_Neck_Force',[3:9 11 12],'ipsi';
    't8','t8.2017.05.02_Neck_Force',[9 11 12],'ipsi3';
    't8','t8.2017.05.02_Neck_Force',[13 14 15],'contra';
    };
featureTypes = {'ncTX','spikePower','ncTX and SpikePower'};

%%
for s=1:size(sessionList,1)
    disp(sessionList{s,2});
    for featureIdx = 1:length(featureTypes)
        %%
        %load and format blocks
        slc = LoadSLC(sessionList{s,3}, [dataDir filesep sessionList{s,2}]);
        sBLOCKS(1).sGInt.Name = 'BG2D';
        sBLOCKS(1).sGInt.GameName = 'Case 3d Targets';
        sBLOCKS(1).sBLK.SaveTo = NaN;

        P = slcDataToPFile(slc, sBLOCKS);
        force = slc.task.analogAvg(:,3);
        cursorPos = P.loopMat.wristPos(:,2);
        targetPos = P.loopMat.targetWristPos(:,2);
        reaches = P.trl.reaches;
        
        forceDeriv = matVecMag([0; diff(force)],2);
        [B,A] = butter(3, 4/25, 'low');
        forceDeriv = filtfilt(B, A, forceDeriv);

        targetByTrial = targetPos(reaches(:,1)+2,:);
        [targList,~,targIdx] = unique(targetByTrial,'rows');
        nTargs = length(targList);
        
        timeAxis = (-25:100)*0.02;
        colors = jet(nTargs)*0.8;
        figure
        hold on;
        for n=1:nTargs
            c = triggeredAvg(force, reaches(targIdx==n,1), [-25 100]);
            plot(timeAxis, nanmean(c), 'Color', colors(n,:));
        end
        plot([0 0],get(gca,'YLim'),'--k');
        
        %figure
        rtIdx = zeros(size(reaches,1),1);
        for r=1:size(reaches,1)
            %clf;
            %hold on
            
            loopIdx = reaches(r,1):reaches(r,2);
            baselineIdx = (reaches(r,1)-10):(reaches(r,1)+10);
            bm = mean(force(baselineIdx));
            bs = std(force(baselineIdx));
            
            tmp = find( abs((force(loopIdx(11:end))-bm)/bs)>6, 1, 'first')+10;
            if isempty(tmp)
                rtIdx(r)=NaN;
                continue;
            else
                rtIdx(r) = loopIdx(tmp);
            end
            
            %plot(zscore(force(loopIdx)));
            %plot(zscore(forceDeriv(loopIdx)));
            %plot([tmp tmp], get(gca,'YLim'), '--r');
            %pause;
        end
        
        timeAxis = (-25:75)*0.02;
        figure
        hold on;
        for r=2:(length(rtIdx)-1)
            if targIdx(r)>1
                loopIdx = (reaches(r,1)-25):(reaches(r,1)+75);
                plot(timeAxis, force(loopIdx),'Color',colors(targIdx(r),:));
            end
        end
        plot([0 0],get(gca,'YLim'),'--k');
        
        colors = jet(nTargs)*0.8;
        timeAxis = (-25:75)*0.02;
        
        figure
        hold on;
        for r=2:(length(rtIdx)-1)
            if targIdx(r)>1 && ~isnan(rtIdx(r))
                loopIdx = (rtIdx(r)-25):(rtIdx(r)+75);
                plot(timeAxis, force(loopIdx),'Color',colors(targIdx(r),:));
            end
        end
        plot([0 0],get(gca,'YLim'),'--k');
        
        forceMags = zeros(6,1);
        timeAxis = (-25:100)*0.02;
        figure
        hold on;
        for n=1:nTargs
            c = triggeredAvg(force, rtIdx(targIdx==n & ~isnan(rtIdx),1), [-25 100]);
            plot(timeAxis, nanmean(c), 'Color', colors(n,:));
            forceMags(n) = max(nanmean(c));
        end
        plot([0 0],get(gca,'YLim'),'--k');
        
        %%
        %load features
        saveDir = [plotDir sessionList{s,2} ' ' sessionList{s,4} filesep featureTypes{featureIdx}];
        mkdir(saveDir);

        if strcmp(featureTypes{featureIdx},'ncTX and SpikePower')
            features = double([slc.ncTX.values, slc.spikePower.values]);
            featLabels = cell(size(features,2),1);
            nChan = size(features,2)/2;
            for n=1:nChan
                featLabels{n} = ['TX' num2str(n)];
                featLabels{n+nChan} = ['SP' num2str(n)];
            end
        elseif strcmp(featureTypes{featureIdx},'ncTX')
            features = double(slc.ncTX.values);
            featLabels = cell(size(features,2),1);
            for n=1:size(features,2)
                featLabels{n} = ['TX' num2str(n)];
            end
        elseif strcmp(featureTypes{featureIdx},'SpikePower')
            features = double(slc.spikePower.values);
            featLabels = cell(size(features,2),1);
            for n=1:size(features,2)
                featLabels{n} = ['SP' num2str(n)];
            end
        end

        for b=1:(length(slc.blockBreakInds)-1)
            blockIdx = (slc.blockBreakInds(b)+1):slc.blockBreakInds(b+1);
            features(blockIdx,:) = zscore(features(blockIdx,:));
        end
        allZero = all(features==0);
        features(:,allZero)=[];

        %%
        %prepare conditions for PSTHs
        psthOpts = makePSTHOpts();
        psthOpts.timeStep = 0.02;
        psthOpts.neuralData = {features};
        psthOpts.timeWindow = [-50 100];
        psthOpts.plotDir = saveDir;
        psthOpts.orderBySNR = true;
        psthOpts.gaussSmoothWidth = 1.5;
        psthOpts.featLabels = featLabels;
        psthOpts.plotsPerPage = 10;

        plotIdx = targIdx>1 & ~isnan(rtIdx);
        psthOpts.trialEvents = [rtIdx(plotIdx); reaches(plotIdx,1)];
        psthOpts.trialConditions = [targIdx(plotIdx)-1; (targIdx(plotIdx)-1)+5];

        colors = [jet(5)*0.8; jet(5)*0.8];
        for c=1:size(colors,1)
            psthOpts.lineArgs{c} = {'Color', colors(c,:), 'LineWidth', 1};
        end

        psthOpts.conditionGrouping = {[1 2 3 4 5],[6 7 8 9 10]};

        psthOpts.prefix = 'Single';
        makePSTH_simple( psthOpts );
        close all;

        psthOpts.neuralData{2} = repmat(0.2*zscore(force),1,size(psthOpts.neuralData{1},2));
        psthOpts.prefix = 'Force';
        makePSTH_simple( psthOpts );
        close all;
        %%
        %apply dPCA
        smoothFeatures = gaussSmooth_fast(psthOpts.neuralData{1},1.5);
        out = apply_dPCA_simple( smoothFeatures, psthOpts.trialEvents(1:length(find(plotIdx))), ...
            psthOpts.trialConditions(1:length(find(plotIdx))), [-50 100], 0.02, {'Condition-dependent','Condition-independent'} );

        colors = [jet(5)*0.8];
        newLineArgs = cell(5,1);
        for c=1:5
            newLineArgs{c} = {'Color',colors(c,:),'LineWidth',2};
        end
        oneFactor_dPCA_plot( out, (-50:100)*0.02, newLineArgs, {'CD','CI'}, 'zoomedAxes' );
        
        oneFactor_dPCA_plot( out, (-50:100)*0.02, newLineArgs, {'CD','CI'}, 'sameAxes' );
        exportPNGFigure(gcf, [saveDir filesep 'dPCA_sameAxes']);
        
        [modScales, figHandles, modScalesZero] = oneFactor_dPCA_plot_mag( out, (-50:100)*0.02, newLineArgs, {'CD','CI'}, [] );
        exportPNGFigure(figHandles(1), [saveDir filesep 'dPCA']);
        exportPNGFigure(figHandles(2), [saveDir filesep 'dPCA_Mag']);
         
        [B,BINT,R,RINT,STATS] = regress(modScales{1,1},[ones(5,1), forceMags(2:end)]);
        [B,BINT,R,RINT,STATS_zero] = regress(modScalesZero{1,3},[ones(5,1), forceMags(2:end)]);
        
        figure
        subplot(1,2,1);
        plot(forceMags(2:end), modScales{1,1}, '-o','LineWidth',2);
        title(['R2 = ' num2str(STATS(1))]);
        
        subplot(1,2,2);
        plot(forceMags(2:end), -modScalesZero{1,3}, '-o','LineWidth',2);
        title(['R2 = ' num2str(STATS_zero(1))]);
        exportPNGFigure(gcf, [saveDir filesep 'linear_fit']); 
        
        figure
        plot(forceMags(2:end), modScales{1,1}, '-o','LineWidth',2);
        title(['R2 = ' num2str(STATS(1))]);
        xlabel('Force');
        ylabel('Neural Modulation');
        set(gca,'FontSize',16);
        exportPNGFigure(gcf, [saveDir filesep 'linear_fit_1']); 
        %%
        close all;
    end %feature type
end %session
