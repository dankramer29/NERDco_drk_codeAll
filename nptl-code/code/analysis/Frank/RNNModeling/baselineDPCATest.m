loadDir = '/Users/frankwillett/Data/Monk/JenkinsData/vmrDataForJonathan/';
datasets = {'R_2017-04-24_1',{[2],[4],[8]},{'Baseline','45','60'},{{[2],[4]},{[2],[8]}},{'Baseline_v_45','Baseline_v_60'};
    'R_2018-03-15_1',{[1],[3]},{'Baseline','45'},{{[1],[3]}},{'Baseline_v_45'}};
speedThresh = 50;

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'VMR' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [loadDir datasets{d,1} '.mat'];

    %%
    %load cued movement dataset
    load(sessionPath);
    R = preprocessMonkR( R, horzcat(datasets{d,2}{:}), 2 );
    
    for t=1:length(R)
        tto = R(t).timeTargetOn;
        tto(isnan(tto)) = 50;
        R(t).timeTargetOn_nonan = tto;
    end
    
    smoothWidth = 0;
    datFields = {'cursorPos','currentTarget'};
    binMS = 20;
    unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

    afSet = {'timeTargetOn_nonan','rtTime'};
    twSet = {[-300,1000],[-740,740]};
    pfSet = {'goCue','moveOnset'};
    
    for alignSetIdx=1:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 0;
        datFields = {'cursorPos','currentTarget'};
        timeWindow = twSet{alignSetIdx};
        binMS = 20;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );
        
        alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,1.5);
        %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        %tooLow = meanRate < 0.5;
        %alignDat.zScoreSpikes(:,tooLow) = [];
        
        chanSet = {[1:96],[97:192]};
        arrayNames = {'M1','PMd'};
        for arrayIdx=1:length(chanSet)
            
            %two-factor comparisons
            for compSetIdx = 1:length(datasets{d,4})
                allBlocks = [datasets{d,4}{compSetIdx}{:}];
                trlIdx = ismember(alignDat.bNumPerTrial, allBlocks) & [R.isSuccessful]' & ~isnan([R.timeTargetOn]');
                trlIdx = find(trlIdx);

                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
                [targList, ~, targCodes] = unique(tPos,'rows');
                centerCode = find(all(targList==0,2));
                outerIdx = find(targCodes~=centerCode);
                
                %two-factor
                blockSetFactor = ismember(alignDat.bNumPerTrial(trlIdx), datasets{d,4}{compSetIdx}{1});

                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
                    [targCodes(outerIdx), blockSetFactor(outerIdx)], timeWindow/binMS, binMS/1000, {'Dir', 'VMR', 'CI', 'Dir x VMR'} );
                close(gcf);
                
                nVMR = 2;
                nDir = size(targList,1)-1;
                lineArgs = cell(nDir, nVMR);
                colors = hsv(nDir)*0.8;
                ls = {':','-'};

                for vmrIdx=1:nVMR
                    for dirIdx=1:nDir
                        lineArgs{dirIdx,vmrIdx} = {'Color',colors(dirIdx,:),'LineWidth',2,'LineStyle',ls{vmrIdx}};
                    end
                end

                %2-factor dPCA
                [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'Dir', 'VMR', 'CI', 'Dir x VMR'}, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,5}{compSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,5}{compSetIdx} '_2fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');
            end
            
            %single factor
            for blockSetIdx = 1:length(datasets{d,2})

                %all activity
                trlIdx = ismember(alignDat.bNumPerTrial, datasets{d,2}{blockSetIdx}) & [R.isSuccessful]' & ~isnan([R.timeTargetOn]');
                trlIdx = find(trlIdx);

                tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,1:2);
                [targList, ~, targCodes] = unique(tPos,'rows');
                centerCode = find(all(targList==0,2));
                outerIdx = find(targCodes~=centerCode);

                %single-factor
                dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
                    targCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
                lineArgs = cell(length(targList)-1,1);
                colors = jet(length(lineArgs))*0.8;
                for l=1:length(lineArgs)
                    lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
                end
                oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                    lineArgs, {'CD','CI'}, 'sameAxes');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.png'],'png');
                saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_1fac_dPCA_' pfSet{alignSetIdx} '_' arrayNames{arrayIdx} '.svg'],'svg');
            end %block set
        end %array
    end %alignment set
    
end


%%
tmp=load('/Users/frankwillett/Data/Derived/MovementScale/head/t5.2018.01.22/T5_2018_01_22_prep.mat');
for taskCode=1:3
    trlIdx = find(prepTable(:,7)==taskCode);
    tPos = prepTable(trlIdx,5:6);
    [distList, ~, distCodes] = unique(round(matVecMag(tPos,2)));
    
    anova1(prepTable(trlIdx,2), distCodes);
end
