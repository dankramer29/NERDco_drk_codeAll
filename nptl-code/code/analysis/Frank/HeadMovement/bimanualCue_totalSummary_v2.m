%%
datasets = {
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

%%
for d=1:length(datasets)
    
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
    R = getStanfordRAndStream( sessionPath, horzcat(datasets{d,2}{:}), 3.5, datasets{d,4}, filtOpts );
    
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
    clear R;
    
    %%
    afSet = {'goCue','goCue'};
    twSet = {[-1500,3000],[-1500,0]};
    pfSet = {'goCue','prep'};
    
    pcaMode = 'pca';

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
        nBins = 225;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 0.5;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        pcaMode = 'dPCA';
        totalSummary = zeros(length(datasets{d,2}),4);
        totalSummary_os = zeros(length(datasets{d,2}),2);
        totalSummary_2fac = zeros(length(datasets{d,2}),2);
        
        for blockSetIdx = 1:length(datasets{d,2})
            
            if strcmp(pfSet{alignSetIdx},'goCue')
                compIdx = -timeWindow(1)/binMS + (10:55);
            else
                compIdx = -timeWindow(1)/binMS + (-50:0);
            end
            nDim = 3;
            
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
            trlIdx = find(trlIdx);
            movCues = alignDat.currentMovement(alignDat.eventIdx(trlIdx));

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

            colors = [0.8 0 0; 0.8 0 0; 0 0 0.8; 0 0 0.8];
            colors = repmat(colors,2,1);
            lineStyles = {'-',':','-',':','-',':','-',':'};
            
            nCues = 8;
            lineArgs = cell(nCues,1);
            for x=1:nCues
                lineArgs{x} = {'LineWidth',2,'Color',colors(x,:),'LineStyle',lineStyles{x}};
            end

            eventIdx = (-timeWindow(1)/binMS):nBins:size(alignDat.zScoreSpikes,1);
            
            [~,~,remapCodes] = unique(movCues);
            isoIdx = ismember(remapCodes,1:4);
            isoEventIdx = eventIdx(trlIdx(isoIdx));
            isoCodes = remapCodes(isoIdx);
            
            simIdx = ismember(remapCodes,5:8);
            simEventIdx = eventIdx(trlIdx(simIdx));
            
            simCodes1 = remapCodes(simIdx);
            simCodes1(remapCodes(simIdx)==5)=5;
            simCodes1(remapCodes(simIdx)==6)=5;
            simCodes1(remapCodes(simIdx)==7)=6;
            simCodes1(remapCodes(simIdx)==8)=6;
            
            simCodes2 = remapCodes(simIdx);
            simCodes2(simCodes2==5)=7;
            simCodes2(simCodes2==6)=8;
            
            psthOpts = makePSTHOpts();
            psthOpts.gaussSmoothWidth = 0;
            psthOpts.neuralData = {alignDat.zScoreSpikes};
            psthOpts.timeWindow = timeWindow/binMS;
            psthOpts.trialEvents = [isoEventIdx, simEventIdx, simEventIdx];
            psthOpts.trialConditions = [isoCodes; simCodes1; simCodes2];
            psthOpts.conditionGrouping = {1:4, 5:8};
            psthOpts.lineArgs = lineArgs;

            psthOpts.plotsPerPage = 10;
            psthOpts.plotDir = outDir;
            psthOpts.prefix = [datasets{d,3}{blockSetIdx} '_avg'];

            featLabels = cell(192,1);
            chanIdx = find(~tooLow);
            for f=1:length(chanIdx)
                featLabels{f} = num2str(chanIdx(f));
            end
            psthOpts.featLabels = featLabels;
            %makePSTH_simple(psthOpts);
            %close all;

            %%
            colorsIso = [0.8 0 0; 0 0 0.8; 0.4 0.4 0.4; 0.4 0.4 0.4];
            colorsSim = [0.8 0 0; 0.8 0 0; 0 0 0.8; 0 0 0.8];
            colors = [colorsIso; colorsSim];
            lineStyles = {'--','--','-',':','-',':','-',':'};
            
            nCues = 8;
            lineArgs = cell(nCues,1);
            for x=1:nCues
                lineArgs{x} = {'LineWidth',2,'Color',colors(x,:),'LineStyle',lineStyles{x}};
            end

            eventIdx = (-timeWindow(1)/binMS):nBins:size(alignDat.zScoreSpikes,1);
            [~,~,remapCodes] = unique(movCues);
            
            psthOpts = makePSTHOpts();
            psthOpts.gaussSmoothWidth = 0;
            psthOpts.neuralData = {alignDat.zScoreSpikes};
            psthOpts.timeWindow = timeWindow/binMS;
            psthOpts.trialEvents = eventIdx(trlIdx);
            psthOpts.trialConditions = remapCodes;
            psthOpts.conditionGrouping = {1:4, 5:8};
            psthOpts.lineArgs = lineArgs;

            psthOpts.plotsPerPage = 10;
            psthOpts.plotDir = outDir;
            psthOpts.prefix = [datasets{d,3}{blockSetIdx} '_raw'];

            featLabels = cell(192,1);
            chanIdx = find(~tooLow);
            for f=1:length(chanIdx)
                featLabels{f} = num2str(chanIdx(f));
            end
            psthOpts.featLabels = featLabels;
            %makePSTH_simple(psthOpts);
            %close all;
            
            %%
            %distance analysis
            compSubsets = {{[187 188]},{[191 192]},{[195 199],[196 200]},{[195 196],[199 200]}};
            edSummary = zeros(length(compSubsets),1);
            
            for x=1:length(compSubsets)
                disp(x);
                allED = [];
                for y=1:length(compSubsets{x})
                    useIdx = find(ismember(movCues, compSubsets{x}{y}));
                    dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                        movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                    close(gcf);
                
                    if strcmp(pcaMode,'pca')
                        dPCA_out = dPCA_out.pca_result;
                    end
                    
                    cdIdx = find(dPCA_out.whichMarg==1);
                    Z = squeeze(dPCA_out.Z(cdIdx,1,:)) - squeeze(dPCA_out.Z(cdIdx,2,:));
                    Z = Z(1:nDim, compIdx);
                    
                    %ed = mean(matVecMag(Z',2));
                    ed = sqrt(sum(Z(:).^2));
                    allED = [allED; ed];
                end
                
                edSummary(x) = mean(allED);
            end
            totalSummary(blockSetIdx,:) = edSummary;
            
            %%
            %with original subspace            
            oneDSubsets = {[187 188],[191 192]};
            originalSpaces = cell(length(oneDSubsets),1);
            for x=1:length(oneDSubsets)
                useIdx = find(ismember(movCues, oneDSubsets{x}));
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                    movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                close(gcf);
                
                if strcmp(pcaMode,'pca')
                    dPCA_out = dPCA_out.pca_result;
                end
                originalSpaces{x} = dPCA_out;
            end
            
            compSubsets = {{[195 199],[196 200]},{[195 196],[199 200]}};
            edSummary = zeros(length(compSubsets),1);
            
            for x=1:length(compSubsets)
                disp(x);
                allED = [];
                for y=1:length(compSubsets{x})
                    useIdx = find(ismember(movCues, compSubsets{x}{y}));
                    dPCA_simul = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                        movCues(useIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                    close(gcf);
                    
                    if strcmp(pcaMode,'pca')
                        dPCA_simul = dPCA_simul.pca_result;
                    end
                    
                    dPCA_simul.whichMarg = originalSpaces{x}.whichMarg;
                    for axIdx=1:20
                        for conIdx=1:size(dPCA_simul.Z,2)
                            dPCA_simul.Z(axIdx,conIdx,:) = originalSpaces{x}.W(:,axIdx)' * squeeze(dPCA_simul.featureAverages(:,conIdx,:));
                        end
                    end       
                    
                    cdIdx = find(dPCA_simul.whichMarg==1);
                    Z = squeeze(dPCA_simul.Z(cdIdx,1,:)) - squeeze(dPCA_simul.Z(cdIdx,2,:));
                    Z = Z(1:nDim, compIdx);
                    
                    %ed = mean(matVecMag(Z',2));
                    ed = sqrt(sum(Z(:).^2));
                    allED = [allED; ed];
                end
                
                edSummary(x) = mean(allED);
            end
            totalSummary_os(blockSetIdx,:) = edSummary;
            
            %%
            %two-factor
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
            
            useIdx = find(ismember(movCues, [195 196 199 200]));
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx(useIdx)), ...
                movFactors(useIdx,:), timeWindow/binMS, binMS/1000, {'Dir L', 'Dir R', 'CI', 'L x R'} );
            close(gcf);
            
            if strcmp(pcaMode,'pca')
                dPCA_out = dPCA_out.pca_result;
            end

            for x=1:2
                cdIdx = find(dPCA_out.whichMarg==x);
                cdIdx = cdIdx(1:nDim);
                if x==1
                    Z = squeeze(dPCA_out.Z(cdIdx,1,:,compIdx)) - squeeze(dPCA_out.Z(cdIdx,2,:,compIdx));
                elseif x==2
                    Z = squeeze(dPCA_out.Z(cdIdx,:,1,compIdx)) - squeeze(dPCA_out.Z(cdIdx,:,2,compIdx));
                end
                ed = sqrt(sum(Z(:).^2))/2;
                totalSummary_2fac(blockSetIdx,x) = ed;
            end
            
            %%            
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
            close(gcf);
        end %block set
        save([outDir filesep 'varianceLossSummary_' pfSet{alignSetIdx} '_v2.mat'],'totalSummary','totalSummary_os','totalSummary_2fac');
    end %alignment set
end
