%%
blockSetsPerSession = {{[4 6 9 11 13 15 17],[5 8 10 12 14 16 18]},...
    {[4 7 9 11 13 15 18 20],[6 8 10 12 14 17 19 21]},...
    {[2 5 7 9 11 13 15 18], [4 6 8 10 12 14 16 19]}};
setNamesPerSession = {{'head','arm'},{'head','arm'},{'head','arm'}};
sessionNames = {'t5.2019.05.06', 't5.2019.05.31', 't5.2019.06.03'};

conditionLabels1 = {'right1a','right2a','right3a','right4a','right5a','right6a',...
        'up1a','up2a','up3a','up4a','up5a','up6a',...
        'left1a','left2a','left3a','left4a','left5a','left6a',...
        'down1a','down2a','down3a','down4a','down5a','down6a',...
        'rd1a','rd2a','rd3a','rd4a','rd5a','rd6a','rd7a','rd8a','rd9a','rd10a','rd11a','rd12a','rd13a','rd14a','rd15a','r1d6a'};
conditionLabels2 = {'right1h','right2h','right3h','right4h','right5h','right6h','right7h','right8h','right9h','right10h',...
        'up1h','up2h','up3h','up4h','up5h','up6h','up7h','up8h','up9h','up10h',...
        'left1h','left2h','left3h','left4h','left5h','left6h','left7h','left8h','left9h','left10h'...
        'down1h','down2h','down3h','down4h','down5h','down6h','down7h','down8h','down9h','down10h',...
        'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
         };
 conditionLabels3 = {
    'rd1c','rd2c','rd3c','rd4c','rd5c','rd6c','rd7c','rd8c','rd9c','rd10c','rd11c','rd12c','rd13c','rd14c','rd15c','rd16c',...
    'rd1m','rd2m','rd3m','rd4m','rd5m','rd6m','rd7m','rd8m','rd9m','rd10m','rd11m','rd12m','rd13m','rd14m','rd15m','rd16m',...
    'rd1f','rd2f','rd3f','rd4f','rd5f','rd6f','rd7f','rd8f','rd9f','rd10f','rd11f','rd12f','rd13f','rd14f','rd15f','rd16f',...
     };
 
allConLabels = {conditionLabels1, conditionLabels2, conditionLabels3};

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'dataTensorsForSharing' filesep];
mkdir(outDir);

for sessionIdx=1:length(sessionNames)
    sessionName = sessionNames{sessionIdx};
    setNames = setNamesPerSession{sessionIdx};
    blockSets = blockSetsPerSession{sessionIdx};
    
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];
    for blockSetIdx=1:length(blockSets)
        %%       
        bNums = horzcat(blockSets{blockSetIdx});
        movField = 'rigidBodyPosXYZ';
        filtOpts.filtFields = {'rigidBodyPosXYZ'};
        filtOpts.filtCutoff = 10/500;
        R = getStanfordRAndStream( sessionPath, bNums, 4.5, bNums(1), filtOpts );

        allR = []; 
        for x=1:length(R)
            for t=1:length(R{x})
                R{x}(t).blockNum=bNums(x);
                R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
            end
            allR = [allR, R{x}];
        end

        for t=1:length(allR)
            allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
        end

        alignFields = {'goCue'};
        smoothWidth = 0;
        datFields = {'rigidBodyPosXYZ','currentMovement','headVel','windowsPC1GazePoint','windowsMousePosition'};
        timeWindow = [-1000,4000];
        binMS = 10;
        alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 1.0;
        alignDat.rawSpikes(:,tooLow) = [];
        alignDat.meanSubtractSpikes(:,tooLow) = [];
        alignDat.zScoreSpikes(:,tooLow) = [];

        alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
        alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

        smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
        smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

        trlCodes = alignDat.currentMovement(alignDat.eventIdx);
        uniqueCodes = unique(trlCodes);

        codeSets = {uniqueCodes};
        
        %%
        %get head kinematics
        avgHeadVel = cell(length(uniqueCodes),1);
        for codeIdx=1:length(uniqueCodes)
            trlIdx = find(trlCodes==uniqueCodes(codeIdx));
            
            [ concatDat ] = triggeredAvg( alignDat.headVel, alignDat.eventIdx(trlIdx), [0,80] );
            avgHeadVel{codeIdx} = squeeze(mean(concatDat,1));
        end
        
        figure
        hold on;
        for x=1:length(avgHeadVel)
            tmp = cumsum(avgHeadVel{x});
            plot(tmp(:,1), tmp(:,2));
        end
        axis equal;
        
        %%
        %quickly look at prep geometry
        timeWindow_mpca = [-500,1500];
        tw =  timeWindow_mpca/binMS;
        tw(1) = tw(1) + 1;
        tw(2) = tw(2) - 1;

        margGroupings = {{1, [1 2]}, {2}};
        margNames = {'Condition-dependent', 'Condition-independent'};
        opts_m.margNames = margNames;
        opts_m.margGroupings = margGroupings;
        opts_m.nCompsPerMarg = 5;
        opts_m.makePlots = true;
        opts_m.nFolds = 10;
        opts_m.readoutMode = 'singleTrial';
        opts_m.alignMode = 'rotation';
        opts_m.plotCI = true;
        opts_m.nResamples = 10;

        mpCodeSets = codeSets;
        mPCA_out = cell(length(codeSets),1);
        for pIdx=1:length(mpCodeSets) 
            trlIdx = find(ismember(trlCodes, mpCodeSets{pIdx}));
            mc = trlCodes(trlIdx)';
            [~,~,mc_oneStart] = unique(mc);

            mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, alignDat.eventIdx(trlIdx), ...
                mc_oneStart, tw, binMS/1000, opts_m );
        end

        prepDataTensor = mPCA_out{1}.featureVals(:,:,1:50,:);
        dimLabel = 'Electrodes x Condition x Time Step (fifty 10 ms bins) x Trial';
        conditionLabels = allConLabels{sessionIdx};
        
        save([outDir sessionName '_' setNames{blockSetIdx} '.mat'],'prepDataTensor','dimLabel','conditionLabels','avgHeadVel');
        
        %%
        close all;
    end
end