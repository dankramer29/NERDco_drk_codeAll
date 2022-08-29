%%
datasets = {
    't5.2018.05.30',{[2 3 4 8 9 10 11 12 13]},{'DualArm'},[2];
    't5.2018.06.04',{[2 3 4 5 6]},{'DualArm'},[2];
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
        afSet = {'goCue','goCue'};
        twSet = {[-1500,3000],[-1500,0]};
        pfSet = {'goCue','delay'};
    else
        afSet = {'goCue'};
        twSet = {[-1500,6500]};
        pfSet = {'goCue'};
    end
    
%     SHO_SHRUG(91)
%     ELBOW_FLEX(94)
%     WRIST_EXT(96)
%     CLOSE_HAND(98)
% 
%     SHRUG_AND_ELBOW(211)
%     SHRUG_AND_WRIST(212)
%     SHRUG_AND_HAND(213)
% 
%     ELBOW_AND_WRIST(214)
%     ELBOW_AND_HAND(215)
%     WRIST_AND_HAND(216)     

    movSets = {[91 94 211],[91 96 212],[91 98 213],[94 96 214],[94 98 215],[96 98 216]};

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
            trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx});
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
            allCoef = zeros(length(movSets),3);
            allVar = zeros(length(movSets),3);
            for setIdx=1:length(movSets)
                trlIdx = find(ismember(movCues, movSets{setIdx}));
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(trlIdx), ...
                    movCues(trlIdx), timeWindow/binMS, binMS/1000, {'CD','CI'}, 20, 'standard' );
                close(gcf);
                
                [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dPCA_out.featureAverages(:,:)');
                rScore = reshape(SCORE', size(dPCA_out.featureAverages));
                
                for x=1:3
                    tmp = squeeze(rScore(:,x,:));
                    %allVar(setIdx,x) = sum(tmp(:).^2);
                    allVar(setIdx,x) = var(tmp(:).^2);
                end
                
                Y = squeeze(rScore(1:10,3,:))';
                X = squeeze(rScore(1:10,1:2,:));
                X = permute(X,[3 1 2]);
                X_unroll = reshape(X,[size(X,1)*size(X,2), size(X,3)]);
                Y_unroll = reshape(Y,[size(Y,1)*size(Y,2), 1]);
                
                [B,BINT,R,RINT,STATS] = regress(Y_unroll, [ones(size(X_unroll,1),1), X_unroll]);
                allCoef(setIdx,:) = B;
                %for dimIdx=1:10
                %    [B,BINT,R,RINT,STATS] = regress(Y(:,dimIdx), [ones(size(Y,1),1), squeeze(X(dimIdx,:,:))']);
                %end
            end
            
            %%
            %using CD dimensions only
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx, ...
                movCues, timeWindow/binMS, binMS/1000, {'CD','CI'}, 20, 'standard' );
            close(gcf);
                
            cdIdx = find(dPCA_out.whichMarg==1);
            cdIdx = cdIdx(1:6);
            
            cueList = unique(movCues);
            allCoef = zeros(length(movSets),3);
            allVar = zeros(length(movSets),3);
            allR2 = zeros(length(movSets),3);
            
            for setIdx=1:length(movSets)
                [~,conIdx] = ismember(movSets{setIdx}, cueList);
                rScore = squeeze(dPCA_out.Z(cdIdx,conIdx,:));
                
                for x=1:3
                    tmp = squeeze(rScore(:,x,:));
                    %allVar(setIdx,x) = sum(tmp(:).^2);
                    allVar(setIdx,x) = var(tmp(:).^2);
                end
                
                Y = squeeze(rScore(:,3,:))';
                X = squeeze(rScore(:,1:2,:));
                X = permute(X,[3 1 2]);
                X_unroll = reshape(X,[size(X,1)*size(X,2), size(X,3)]);
                Y_unroll = reshape(Y,[size(Y,1)*size(Y,2), 1]);
                
                [B,BINT,R,RINT,STATS] = regress(Y_unroll, [ones(size(X_unroll,1),1), X_unroll]);
                allCoef(setIdx,:) = B;
                allR2(setIdx,1) = STATS(1);
                
                %mean
                pred = sum(X_unroll,2);
                err = Y_unroll-pred;
                R2 = 1 - (sum(err(:).^2)/sum(Y_unroll(:).^2));
                allR2(setIdx,2) = R2;
                
                %sum
                pred = mean(X_unroll,2);
                err = Y_unroll-pred;
                R2 = 1 - (sum(err(:).^2)/sum(Y_unroll(:).^2));
                allR2(setIdx,3) = R2;
            end
            
        end %block set
    end %alignment set
end  
