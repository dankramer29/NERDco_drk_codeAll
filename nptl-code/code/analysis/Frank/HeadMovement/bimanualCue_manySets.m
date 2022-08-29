%%
datasets = {
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

%%
for d=1:size(datasets,1)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load cued movement dataset
    bNums = horzcat(datasets{d,2}{:});
    if strcmp(datasets{d,1}(1:2),'t5')
        movField = 'windowsMousePosition';
        filtOpts.filtFields = {'windowsMousePosition'};
    else
        movField = 'glove';
        filtOpts.filtFields = {'glove'};
    end
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, datasets{d,4}, filtOpts );
    
    allR = []; 
    for x=1:length(R)
        for t=1:length(R{x})
            R{x}(t).blockNum=bNums(x);
            if strcmp(datasets{d,1}(1:2),'t5')
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
        end
        allR = [allR, R{x}];
    end
    
    %speedThresh = 0.06;
    %moveOccurred = false(size(allR));
    %for t=1:length(allR)
    %    moveOccurred(t) = any(allR(t).glove_speed>speedThresh);
    %end

    %smoothWidth = 0;
    %datFields = {'glove','cursorPosition','currentTarget','xk'};
    %binMS = 20;
    %unrollDat = binAndUnrollR( allR, binMS, smoothWidth, datFields );

    if strcmp(datasets{d,1}(1:2),'t5')
        afSet = {'goCue'};
        twSet = {[-1500,3000]};
        pfSet = {'goCue'};
    else
        afSet = {'goCue'};
        twSet = {[-1500,6500]};
        pfSet = {'goCue'};
    end
        
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 60;
        if strcmp(datasets{d,1}(1:2),'t5')
            datFields = {'windowsMousePosition','currentMovement','windowsMousePosition_speed'};
        else
            datFields = {'glove','currentMovement','glove_speed'};
        end
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        allOutCell = cell(length(datasets{d,2}),1);
        for blockSetIdx = 1:length(datasets{d,2})
            
            %all activity
            %if strcmp(datasets{d,3}{blockSetIdx},'I')
            %    trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [allR.isSuccessful]' & ~moveOccurred';
            %elseif strcmp(datasets{d,3}{blockSetIdx},'M')
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
            %end
            trlIdx = find(trlIdx);
            movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));
            codeList = unique(movCues);
            
            codeLegend = cell(length(codeList),1);
            for c=1:length(codeList)
                tmp = getMovementText(codeList(c));
                codeLegend{c} = tmp(10:end);
            end
            
            %single-factor
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'} );
            lineArgs = cell(length(codeList),1);
            colors = jet(length(lineArgs))*0.8;
            for l=1:length(lineArgs)
                lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
            end
            oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'CD','CI'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        
            allOutCell{blockSetIdx} = dPCA_out;
            
            %%
            %distance analysis
            compSubsets = {{[187 188]},{[191 192]},{[195 199],[196 200]},{[195 196],[199 200]}};
            compIdx = -timeWindow(1)/binMS + (6:25);
            nDim = 3;
            edSummary = zeros(length(compSubsets),1);
            
            for x=1:length(compSubsets)
                disp(x);
                allED = [];
                for y=1:length(compSubsets{x})
                    useIdx = find(ismember(movCues, compSubsets{x}{y}));
                    dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                        movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                    close(gcf);
                    
                    cdIdx = find(dPCA_out.whichMarg==1);
                    Z = squeeze(dPCA_out.Z(cdIdx,1,:)) - squeeze(dPCA_out.Z(cdIdx,2,:));
                    Z = Z(1:nDim, compIdx);
                    
                    %ed = mean(matVecMag(Z',2));
                    ed = sqrt(sum(Z(:).^2));
                    allED = [allED; ed];
                end
                
                edSummary(x) = mean(allED);
            end
            
            %%
            %two factor
            codeList = unique(movCues);
            
%           BI_LEFT_NO(187)
%           BI_RIGHT_NO(188)
% 
%           BI_NO_LEFT(191)
%           BI_NO_RIGHT(192)

%           BI_LEFT_LEFT(195)
%           BI_LEFT_RIGHT(196)
% 
%           BI_RIGHT_LEFT(199)
%           BI_RIGHT_RIGHT(200)
            
            factorMap = [187, 1, 1;
                188, 1, 2;
                191, 2, 1;
                192, 2, 2;
                
                195, 1, 1;
                196, 1, 2;
                199, 2, 1;
                200, 2, 2; ];            
            movFactors = zeros(length(movCues),2);
            for x=1:length(movCues)
                fIdx = find(factorMap(:,1)==movCues(x));
                movFactors(x,:) = factorMap(fIdx,2:3);
            end
            
            oneDSubsets = {[187 188],[191 192],[195 199],[195 196],[191 192 199 200],[187 188 196 200]};
            for x=1:length(oneDSubsets)
                useIdx = find(ismember(movCues, oneDSubsets{x}));
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                    movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                close(gcf);
                
                lineArgs = cell(length(oneDSubsets{x}),1);
                colors = [0.8 0 0; 0 0 0.8; 0.8 0 0; 0 0 0.8];
                lStyles = {'-','-',':',':'};
                for l=1:length(lineArgs)
                    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle',lStyles{l}};
                end
                oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'CD','CI'}, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac' num2str(x) '_dPCA_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac' num2str(x) '_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            end
            
            %%
%           BI_LEFT_NO(187)
%           BI_RIGHT_NO(188)
% 
%           BI_NO_LEFT(191)
%           BI_NO_RIGHT(192)

%           BI_LEFT_LEFT(195)
%           BI_LEFT_RIGHT(196)
% 
%           BI_RIGHT_LEFT(199)
%           BI_RIGHT_RIGHT(200)

            setMaps = {{[187 188],[196 200]},{[191 192],[195 196]}};
            setMapNames = {'E1','E2'};
            for setMapIdx = 1:length(setMaps)
                %useIdx = find(ismember(movCues, [187 188]));
                %useIdx = find(ismember(movCues, [191 192]));
                useIdx = find(ismember(movCues, setMaps{setMapIdx}{1}));
                dPCA_uni = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                    movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                close(gcf);

                %useIdx = find(ismember(movCues, [196 200]));
                %useIdx = find(ismember(movCues, [195 199]));
                %useIdx = find(ismember(movCues, [195 196]));
                useIdx = find(ismember(movCues, setMaps{setMapIdx}{2}));
                dPCA_simul = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                    movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                close(gcf);

                dPCA_simul.whichMarg = dPCA_uni.whichMarg;
                for axIdx=1:20
                    for conIdx=1:size(dPCA_simul.Z,2)
                        dPCA_simul.Z(axIdx,conIdx,:) = dPCA_uni.W(:,axIdx)' * squeeze(dPCA_simul.featureAverages(:,conIdx,:));
                    end
                end         

                lineArgs = cell(2,1);
                colors = [0.8 0 0; 0 0 0.8;];
                lStyles = {'-','-'};
                for l=1:length(lineArgs)
                    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2,'LineStyle',lStyles{l}};
                end

                yAx = oneFactor_dPCA_plot( dPCA_uni,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'CD','CI'}, 'sameAxes');

                oneFactor_dPCA_plot( dPCA_simul,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'CD','CI'}, 'sameAxes', [], yAx);
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac' num2str(x) '_xdPCA_' setMapNames{setMapIdx} '_' pfSet{alignSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac' num2str(x) '_xdPCA_' setMapNames{setMapIdx} '_' pfSet{alignSetIdx} '.svg'],'svg');
            end
            
            %%
            %effector by direction
            useIdx = find(ismember(movCues, [187 188 191 192]));
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                movFactors(useIdx,:), timeWindow/binMS, binMS/1000, {'Effector', 'Dir', 'CI', 'E x D'} );
            
            lineArgs = cell(2);
            colors = [0.8 0 0; 0 0 0.8];
            ls = {'-',':'};
            for x=1:2
                for c=1:2
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Effector', 'Dir', 'CI', 'E x D'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_ED_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_ED_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %%
            %direction1 by direction2
            useIdx = find(ismember(movCues, [195 196 199 200]));
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                movFactors(useIdx,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'} );
            
            lineArgs = cell(2);
            colors = [0.8 0 0; 0 0 0.8];
            ls = {'-',':'};
            for x=1:2
                for c=1:2
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'Dir 1', 'Dir 2', 'CI', '1 x 2'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_DD_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_DD_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
            
            %%
%             bField = 'goCue';
%             colors = jet(length(codeList))*0.8;
%             
%             %if ~any(strcmp(datasets{d,3}{blockSetIdx},{'Head'}))
%             %    rejectThresh = 0.15*10e-4;
%             %    cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(trlIdx), timeWindow/binMS);
%             %    highSpeedTrl = (any(cd>rejectThresh,2));
%             %else
%                 highSpeedTrl = false(size(trlIdx));
%             %end
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
% 
%                 hold on
%                 for t=1:length(plotIdx)
%                     outerTrlIdx = plotIdx(t);
%                     gloveSpeed = double(allR(outerTrlIdx).([movField '_speed'])');
% 
%                     showIdx = (allR(outerTrlIdx).(bField)+timeWindow(1)):(allR(outerTrlIdx).(bField)+timeWindow(2));
%                     showIdx(showIdx>length(gloveSpeed))=[];
%                     showIdx(showIdx<1) = [];
%                     plot(gloveSpeed(showIdx),'Color',colors(codeIdx,:),'LineWidth',2);
%                 end
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(alignDat.([movField '_speed']), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 hold on
%                 plot(nanmean(cd),'Color',colors(codeIdx,:));
%             end
%             legend(codeLegend);
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 tmpMean = squeeze(nanmedian(cd,1));
%                 traj = cumsum(tmpMean);
% 
%                 hold on
%                 plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             figure
%             for codeIdx=1:length(codeList)
%                 plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                 cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                 tmpMean = squeeze(nanmean(cd,1));
%                 traj = cumsum(tmpMean);
% 
%                 hold on
%                 plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
%             end
%             legend(codeLegend);
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.png'],'png');
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj2_' pfSet{alignSetIdx} '.svg'],'svg');
%             
%             %anova for the three time periods
%             pNames = {'Delay','Beep1','Beep2'};
%             periodTime = {[-1500,0],[0,1500],[1500,3000]};
%             dimTitles = {'X','Y'};
%             figure('Position',[322         596        1229         502]);
%             for p=1:length(periodTime)
%                 binIdx = (round(periodTime{p}(1)/binMS):round(periodTime{p}(2)/binMS)) - timeWindow(1)/binMS;
%                 binIdx(binIdx<1)=[];
%                 
%                 for dimIdx=1:2
%                     tmpDat = [];
%                     for codeIdx=1:length(codeList)
%                         plotIdx = trlIdx(movCues==codeList(codeIdx) & ~highSpeedTrl);
%                         cd = triggeredAvg(diff(alignDat.(movField)), alignDat.eventIdx(plotIdx), timeWindow/binMS);
%                         
%                         tmp = mean(squeeze(cd(:,binIdx,dimIdx)),2);
%                         tmpDat = [tmpDat; [tmp, repmat(codeIdx,length(tmp),1)]];
%                     end
%                     
%                     pVal = anova1(tmpDat(:,1), tmpDat(:,2), 'off');
%                     subplot(2,3,(dimIdx-1)*3+p);
%                     boxplot(tmpDat(:,1), tmpDat(:,2));
%                     set(gca,'XTickLabel',codeLegend);
%                     title([pNames{p} ' ' dimTitles{dimIdx} ' p=' num2str(pVal)]);
%                     set(gca,'FontSize',16);
%                 end
%             end
%             saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_anova_.png'],'png');
% 
            close all;
        end %block set
    end %alignment set
end
