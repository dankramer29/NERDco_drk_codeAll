%%
datasets = {
    't5.2018.05.30',{[14 15 16 17 18 19 21 22 23 24]},{'ArmLegDir'},[2];
    't5.2018.06.04',{[10 11 12 13 14 15 16 17 18 19 20 21 22 23]},{'ArmHeadDir'},[2];
    
    't5.2018.03.19',{[8 12 18 19],[20 21 22],[24 25 26],[28 29 30],[31 32 33]},{'HeadTongue','LArmRArm','HeadRArm','LLegRLeg','LLegRArm'},[20];
    't5.2018.03.21',{[3 4 5],[6 7 8]},{'HeadRArm','RArmRLeg'},[3];
    't5.2018.04.02',{[3 4 5],[6 7 8],[9 10 11],[13 14 15],[16 19 20],[21 22 23],[24 25 26],[27 28 29]},...
        {'HeadRLeg','HeadLLeg','HeadLArm','LArmRLeg','LArmLLeg','LLegRLeg','LLegRArm','RLegRArm'},[3];
        
    't5.2018.06.18',{[4 6 7 8 9 10 12],[18 19 20 21 22]},{'LArmRArm','EyeRArm'},[4];
};

effNames = {{{'RLeg','RArm'}};
    {{'Head','RArm'}};
    {{'Head','Tongue'},{'LArm','RArm'},{'Head','RArm'},{'LLeg','RLeg'},{'LLeg','RArm'}};
    {{'Head','RArm'},{'RLeg','RArm'}};
    {{'Head','RLeg'},{'Head','LLeg'},{'Head','LArm'},{'LArm','RLeg'},{'LArm','LLeg'},{'LLeg','RLeg'},{'LLeg','RArm'},{'RLeg','RArm'}};
    {{'LArm','RArm'},{'Eyes','RArm'}}};

%%
for d=1:length(datasets)
    
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
            %PD correlations
            movCues = alignDat.currentMovement(alignDat.eventIdx);
            useTrlIdx = find(ismember(movCues,187:194));
            
            dPCA_all = apply_dPCA_simple( alignDat_smooth.zScoreSpikes, alignDat_smooth.eventIdx(useTrlIdx), ...
                movCues(useTrlIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
            
            nCon = size(dPCA_all.featureAverages,2);
            cWindow = (10:50)-timeWindow(1)/binMS;

            simMatrix = zeros(nCon, nCon);
            fa = dPCA_all.featureAverages(:,:,cWindow);
            fa = fa(:,:)';
            fa = mean(fa);

            subractEffMean = true;
            if nDirCon==4
                setIdx = {[1:4],[5:8]};
            else
                setIdx = {[1:2],[3:4]};
            end
            effMeans = zeros(length(fa), length(setIdx));
            setMemberships = zeros(nCon,1);

            for s=1:length(setIdx)
                tmp = dPCA_all.featureAverages(:,setIdx{s},cWindow);
                tmp = tmp(:,:);

                effMeans(:,s) = mean(tmp');
                setMemberships(setIdx{s}) = s;
            end

            for x=1:nCon
                avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
                avgTraj = mean(avgTraj(cWindow,:));%-fa;
                if subractEffMean
                    avgTraj = avgTraj - effMeans(:,setMemberships(x))';
                end

                for y=1:nCon
                    avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
                    avgTraj_y = mean(avgTraj_y(cWindow,:));%-fa;
                    if subractEffMean
                        avgTraj_y = avgTraj_y - effMeans(:,setMemberships(y))';
                    end

                    simMatrix(x,y) = corr(avgTraj', avgTraj_y');
                end
            end

            movLabels = {
                'Arm Left','Arm Right','Arm Up','Arm Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down'};
            cMap = diverging_map(linspace(0,1,100),[1 0 0],[0 0 1]);

            plotSets = {1:nCon};
            fPos = {[680   678   560   420],[721   767   406   302]};
            for plotIdx=1:length(plotSets)
                figure('Position',fPos{plotIdx});
                imagesc(simMatrix(plotSets{plotIdx},plotSets{plotIdx}),[-1 1]);
                set(gca,'XTick',1:nCon,'XTickLabel',movLabels(plotSets{plotIdx}),'XTickLabelRotation',45);
                set(gca,'YTick',1:nCon,'YTickLabel',movLabels(plotSets{plotIdx}));
                set(gca,'FontSize',16);
                set(gca,'YDir','normal');
                colormap(cMap);
                colorbar;

                if plotIdx==1
                    colors = [173,150,61;
                        119,122,205;]/255;
                    idxSets = {1:4, 5:8}; 
                else
                    colors = [91,169,101;
                        197,90,159;]/255;
                    idxSets = {1:6,7:12}; 
                end

                for setIdx = 1:length(idxSets)
                    newIdx = idxSets{setIdx};
                    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(setIdx,:));
                end
                axis tight;

                saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '.png'],'png');
                saveas(gcf,[outDir filesep 'corrMatrix_' num2str(plotIdx) '.svg'],'svg');
            end

            %%
            %classifier across all single movements
            colors = [100,168,96;
                153,112,193;
                185,141,62;
                204,84,94]/255;
            movLabels = {
                'Arm Left','Arm Right','Arm Up','Arm Down',...
                'Leg Left','Leg Right','Leg Up','Leg Down'};

            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            for windowSetIdx=1:length(windowIdx)
                allFeatures = [];
                allCodes = [];
                for trlIdx=1:length(alignDat.eventIdx)
                    loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trlIdx);
                    allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                    allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                end

                useCodes = 187:194;
                useIdx = ismember(allCodes, useCodes);
                allCodes = allCodes(useIdx);
                allFeatures = allFeatures(useIdx,:);

                reorder = [
                    187, 188, 189, 190, ...
                    191, 192, 193, 194];

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

                figure('Position',[252   129   400   294]); 
                hold on;
                imagesc(C);
                set(gca,'XTick',1:length(remapCodes),'XTickLabel',movLabels,'XTickLabelRotation',45);
                set(gca,'YTick',1:length(remapCodes),'YTickLabel',movLabels);
                set(gca,'FontSize',16);
                set(gca,'LineWidth',2);
                set(gca,'YDir','normal');
                colorbar('LineWidth',2','FontSize',16);
                title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
                
                boxSets = {1:4, 5:8};
                for c=1:length(boxSets)
                    newIdx = boxSets{c};
                    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(c,:));
                end
                axis tight;

                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allSingleClassifier_' windowNames{windowSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allSingleClassifier_' windowNames{windowSetIdx} '.svg'],'svg');
                save([outDir filesep datasets{d,3}{outerMovSetIdx} '_allSingleClassifier_' windowNames{windowSetIdx}],'C','L');
            end
            
            %%
            %classifier across all dual movement cues   
            colors = linspecer(6);
%             colors = [127,201,127
%                     190,174,212
%                     253,192,134
%                     255,255,153
%                     56,108,176
%                     240,2,127]/255;
            movLabels = {
                'Arm L','Arm R','Arm U','Arm D',...
                'Leg L','Leg R','Leg U','Leg D',...
                'Leg L','Leg R','Leg U','Leg D',...
                'Leg L','Leg R','Leg U','Leg D',...
                'Leg L','Leg R','Leg U','Leg D',...
                'Leg L','Leg R','Leg U','Leg D'};
            
            %movLabels = {'Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?',...
            %    'Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?',...
            %    'Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?',...
            %    'Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?','Leg ? Arm ?'};
            
            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            for windowSetIdx=1:length(windowIdx)
                allFeatures = [];
                allCodes = [];
                for trlIdx=1:length(alignDat.eventIdx)
                    loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trlIdx);
                    allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                    allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                end

                useCodes = 187:210;
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
                set(gca,'XTick',1:length(reorder),'XTickLabel',movLabels,'XTickLabelRotation',45);
                set(gca,'YTick',1:length(reorder),'YTickLabel',movLabels);
                set(gca,'FontSize',16);
                set(gca,'LineWidth',2);
                set(gca,'YDir','normal');
                colorbar('LineWidth',2','FontSize',16);
                title(['Cross-Validated Decoding Accuracy: ' num2str(100*(1-L),3) '%']);
                
                boxSets = {1:4, 5:8, 9:12, 13:16, 17:20, 21:24};
                for c=1:length(boxSets)
                    newIdx = boxSets{c};
                    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(c,:));
                end
                axis tight;

                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allClassifier_' windowNames{windowSetIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_allClassifier_' windowNames{windowSetIdx} '.svg'],'svg');
                
                save([outDir filesep datasets{d,3}{outerMovSetIdx} '_allSingleClassifier_' windowNames{windowSetIdx}],'C','L');
                 
                %count: center confusions vs. outer confusions
                C_reduced = C(9:end,9:end);
            end
            
            %%
            %classifier across single movements only            
            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            allL = zeros(2,length(windowIdx));
            allC = cell(2,length(windowIdx));
            for effectorIdx=1:2
                if effectorIdx==1
                    useCodes = [187, 188, 189, 190];
                else
                    useCodes = [191, 192, 193, 194];
                end
                
                for windowSetIdx=1:length(windowIdx)
                    allFeatures = [];
                    allCodes = [];
                    for trlIdx=1:length(alignDat.eventIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trlIdx);
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                    end

                    useIdx = ismember(allCodes, useCodes);
                    allCodes = allCodes(useIdx);
                    allFeatures = allFeatures(useIdx,:);
                    
                    nClasses = length(unique(allCodes));

                    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                    cvmodel = crossval(obj);
                    L = kfoldLoss(cvmodel);
                    predLabels = kfoldPredict(cvmodel);

                    C = confusionmat(allCodes, predLabels);

                    figure; 
                    imagesc(C);
                    title(['Accuracy=' num2str(1-L)]);
                    set(gca,'FontSize',16);
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_singleMovClassifier_' num2str(effectorIdx) '_' windowNames{windowSetIdx} '.png'],'png');
                
                    allL(effectorIdx, windowSetIdx) = L;
                    allC{effectorIdx, windowSetIdx} = C;
                end
            end
            save([outDir filesep datasets{d,3}{outerMovSetIdx} '_singleMovClassifier'],'allC','allL');
            
            %%
            %single effector classifier trained in dual movement context     
            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            allL = zeros(2,length(windowIdx));
            allC = cell(2,length(windowIdx));
            for effectorIdx=1:2
                if effectorIdx==1
                    codeSets = {[195, 196, 197, 198],[199, 200, 201, 202],[203, 204, 205, 206],[207, 208, 209, 210]};
                else
                    codeSets = {[195, 199, 203, 207],[196, 200, 204, 208],[197, 201, 205, 209],[198, 202, 206, 210]};
                end
                
                for windowSetIdx=1:length(windowIdx)
                    allFeatures = [];
                    allCodes = [];
                    for trlIdx=1:length(alignDat.eventIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trlIdx);
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                    end
                    
                    remapCodes = allCodes;
                    for x=1:length(codeSets)
                        tmp = ismember(allCodes, codeSets{x});
                        remapCodes(tmp) = x;
                    end

                    useIdx = ismember(allCodes, horzcat(codeSets{:}));
                    allCodes = remapCodes(useIdx);
                    allFeatures = allFeatures(useIdx,:);
                    
                    nClasses = length(unique(allCodes));
                    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                    cvmodel = crossval(obj);
                    L = kfoldLoss(cvmodel);
                    predLabels = kfoldPredict(cvmodel);

                    C = confusionmat(allCodes, predLabels);

                    figure; 
                    imagesc(C);
                    title(['Accuracy=' num2str(1-L)]);
                    set(gca,'FontSize',16);
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_singleMovDualContextClassifier_' num2str(effectorIdx) '_' windowNames{windowSetIdx} '.png'],'png');
                
                    allL(effectorIdx, windowSetIdx) = L;
                    allC{effectorIdx, windowSetIdx} = C;
                end
            end
            
            save([outDir filesep datasets{d,3}{outerMovSetIdx} '_singleMovDualContextClassifier'],'allC','allL');
            
            %%
            %classifier trained on single movements, applied to dual
            %movement context
            allFeatures = [];
            allCodes = [];
            
            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            allL = zeros(2,length(windowIdx));
            allC = cell(2,length(windowIdx));
            for effectorIdx=1:2
                if effectorIdx==1
                    trainCodes = [187, 188, 189, 190];
                    testCodes = {[195, 196, 197, 198],[199, 200, 201, 202],[203, 204, 205, 206],[207, 208, 209, 210]};
                else
                    trainCodes = [191, 192, 193, 194];
                    testCodes = {[195, 199, 203, 207],[196, 200, 204, 208],[197, 201, 205, 209],[198, 202, 206, 210]};
                end
                
                for windowSetIdx=1:length(windowIdx)
                    %train
                    allFeatures = [];
                    allCodes = [];
                    
                    trainIdx = find(ismember(alignDat.currentMovement(alignDat.eventIdx), trainCodes));
                    for trlIdx=1:length(trainIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trainIdx(trlIdx));
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                    end
                    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                    
                    %test
                    allFeatures = [];
                    allCodes = [];
                    
                    testIdx = find(ismember(alignDat.currentMovement(alignDat.eventIdx), horzcat(testCodes{:})));
                    for trlIdx=1:length(testIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(testIdx(trlIdx));
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        
                        for codeSetIdx=1:length(testCodes)
                            if ismember(alignDat.currentMovement(loopIdx(1)), testCodes{codeSetIdx})
                                allCodes = [allCodes; trainCodes(codeSetIdx)];
                            end
                        end
                    end
                    
                    predCodes = predict(obj, allFeatures);
                    accuracy = sum(predCodes==allCodes)/length(predCodes);
                    C = confusionmat(allCodes, predCodes);

                    figure; 
                    imagesc(C);
                    title(['Accuracy=' num2str(accuracy)]);
                    set(gca,'FontSize',16);
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_crossMovSingleToDualClassifier_' num2str(effectorIdx) '_' windowNames{windowSetIdx} '.png'],'png');
                
                    allL(effectorIdx, windowSetIdx) = L;
                    allC{effectorIdx, windowSetIdx} = C;
                end
            end
            
            save([outDir filesep datasets{d,3}{outerMovSetIdx} '_crossMovSingleToDualClassifier'],'allC','allL');
            
            %%
            %classifier trained on dual movements, applied to single
            %movement context
            allFeatures = [];
            allCodes = [];
            
            windowIdx = {10:50, -25:0};
            windowNames = {'mov','delay'};
            allL = zeros(2,length(windowIdx));
            allC = cell(2,length(windowIdx));
            for effectorIdx=1:2
                if effectorIdx==1
                    testCodes = [187, 188, 189, 190];
                    trainCodes = {[195, 196, 197, 198],[199, 200, 201, 202],[203, 204, 205, 206],[207, 208, 209, 210]};
                else
                    testCodes = [191, 192, 193, 194];
                    trainCodes = {[195, 199, 203, 207],[196, 200, 204, 208],[197, 201, 205, 209],[198, 202, 206, 210]};
                end
                
                for windowSetIdx=1:length(windowIdx)
                    %train
                    allFeatures = [];
                    allCodes = [];
                    
                    testIdx = find(ismember(alignDat.currentMovement(alignDat.eventIdx), horzcat(trainCodes{:})));
                    for trlIdx=1:length(testIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(testIdx(trlIdx));
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        
                        for codeSetIdx=1:length(trainCodes)
                            if ismember(alignDat.currentMovement(loopIdx(1)), trainCodes{codeSetIdx})
                                allCodes = [allCodes; testCodes(codeSetIdx)];
                            end
                        end
                    end
                    obj = fitcdiscr(allFeatures,allCodes,'DiscrimType','diaglinear');
                    
                    %test
                    allFeatures = [];
                    allCodes = [];
                    
                    trainIdx = find(ismember(alignDat.currentMovement(alignDat.eventIdx), testCodes));
                    for trlIdx=1:length(trainIdx)
                        loopIdx = windowIdx{windowSetIdx} + alignDat.eventIdx(trainIdx(trlIdx));
                        allFeatures = [allFeatures; mean(alignDat.zScoreSpikes(loopIdx,:))];
                        allCodes = [allCodes; alignDat.currentMovement(loopIdx(1))];
                    end
                    
                    predCodes = predict(obj, allFeatures);
                    accuracy = sum(predCodes==allCodes)/length(predCodes);
                    C = confusionmat(allCodes, predCodes);

                    figure; 
                    imagesc(C);
                    title(['Accuracy=' num2str(accuracy)]);
                    set(gca,'FontSize',16);
                    saveas(gcf,[outDir filesep datasets{d,3}{outerMovSetIdx} '_crossMovDualToSingleClassifier_' num2str(effectorIdx) '_' windowNames{windowSetIdx} '.png'],'png');
                
                    allL(effectorIdx, windowSetIdx) = L;
                    allC{effectorIdx, windowSetIdx} = C;
                end
            end
            save([outDir filesep datasets{d,3}{outerMovSetIdx} '_crossMovDualToSingleClassifier'],'allC','allL');

            close all;
            
            %%
            %look at PD changes
            
        end %move set
    end %alignSet
end %datasets
