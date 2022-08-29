%%
datasets = {
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
};

effNames = {
    {{'Head','Tongue'},{'LArm','RArm'},{'Head','RArm'},{'LLeg','RLeg'},{'LLeg','RArm'}};
    {{'Head','RArm'},{'RLeg','RArm'}};
    {{'Head','RLeg'},{'Head','LLeg'},{'Head','LArm'},{'LArm','RLeg'},{'LArm','LLeg'},{'LLeg','RLeg'},{'LLeg','RArm'},{'RLeg','RArm'}}};

%%
for d=1:size(datasets,1)
    
    if any(strcmp(datasets{d,1},{'t5.2018.03.19', 't5.2018.03.21', 't5.2018.04.02'}))
        nDirCon = 2;
    else
        nDirCon = 4;
    end
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'bimanualMovCue' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    afSet = {'goCue'};
    twSet = {[-1500,3000]};
    pfSet = {'goCue'};
        
    for alignSetIdx=1:length(afSet)        
        for outerMovSetIdx=1:length(datasets{d,2})

            %load cued movement dataset
            clear alignDat alignDat_smooth
            
            bNums = horzcat(datasets{d,2}{outerMovSetIdx});
            if strcmp(datasets{d,1}(1:2),'t5')
                movField = 'windowsMousePosition';
                filtOpts.filtFields = {'windowsMousePosition'};
            else
                movField = 'glove';
                filtOpts.filtFields = {'glove'};
            end
            filtOpts.filtCutoff = 10/500;
            R = getStanfordRAndStream( sessionPath, bNums, 4.5, bNums(1), filtOpts );

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
            %bin
            alignFields = afSet(alignSetIdx);
            smoothWidth = 0;
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

            smoothWidth = 60;
            alignDat_smooth = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );
            alignDat_smooth.zScoreSpikes(:,tooLow) = [];
             
            %%
            %classifier across all dual movement cues   
            colors = linspecer(6);
            windowIdx = {20:100, -40:0};
            windowNames = {'mov','delay'};
            for windowSetIdx=1:length(windowIdx)
                allFeatures = [];
                allCodes = [];
                for trlIdx=1:length(alignDat.eventIdx)
                    loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trlIdx);
                    allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                    allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                end

                useCodes = 195:210;
                useIdx = ismember(allCodes, useCodes);
                allCodes = allCodes(useIdx);
                allFeatures = allFeatures(useIdx,:);

                reorder = [
                    187, 188, 189, 190, ...
                    191, 192, 193, 194, ...
                    195, 199, 203, 207, ...
                    196, 200, 204, 208, ...
                    197, 201, 205, 209, ...
                    198, 202, 206, 210];

                remapCodes = allCodes;
                for x=1:length(reorder)
                    remapIdx = allCodes==reorder(x);
                    remapCodes(remapIdx) = x;
                end

                nClasses = length(unique(remapCodes));

                obj = fitcdiscr(allFeatures,remapCodes,'DiscrimType','diaglinear');
                cvmodel = crossval(obj);
                L = kfoldLoss(cvmodel);
                predLabels = kfoldPredict(cvmodel);

                C = confusionmat(remapCodes, predLabels);
                for rowIdx=1:size(C,1)
                    C(rowIdx,:) = C(rowIdx,:)/sum(C(rowIdx,:));
                end

                figure('Position',[222   483   630   446]); 
                hold on;
                imagesc(C);
                set(gca,'XTick',1:length(reorder),'XTickLabelRotation',45);
                set(gca,'YTick',1:length(reorder));
                set(gca,'FontSize',16);
                set(gca,'LineWidth',2);
                set(gca,'YDir','normal');
                colorbar('LineWidth',2','FontSize',16);
                title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);

                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allClassifier_' windowNames{windowSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allClassifier_' windowNames{windowSetIdx} '.svg'],'svg');
                
                save([outDir filesep datasets{d,3}{outerMovSetIdx} '_allDualClassifier_' windowNames{windowSetIdx}],'C','L');
            end
        end %move set
        close all;
    end %alignSet
end %datasets
