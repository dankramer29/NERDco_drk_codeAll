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
    
    %%
    afSet = {'goCue','goCue'};
    twSet = {[-1500,3000],[-1500,0]};
    pfSet = {'goCue','prep'};

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

            for x=1:2
                cdIdx = find(dPCA_out.whichMarg==x);
                if x==1
                    Z = squeeze(dPCA_out.Z(cdIdx,1,:,compIdx)) - squeeze(dPCA_out.Z(cdIdx,2,:,compIdx));
                elseif x==2
                    Z = squeeze(dPCA_out.Z(cdIdx,:,1,compIdx)) - squeeze(dPCA_out.Z(cdIdx,:,2,compIdx));
                end
                ed = sqrt(sum(Z(:).^2))/2;
                totalSummary_2fac(blockSetIdx,x) = ed;
            end
            
        end %block set
        save([outDir filesep 'varianceLossSummary_' pfSet{alignSetIdx} '.mat'],'totalSummary','totalSummary_os','totalSummary_2fac');
    end %alignment set
end
