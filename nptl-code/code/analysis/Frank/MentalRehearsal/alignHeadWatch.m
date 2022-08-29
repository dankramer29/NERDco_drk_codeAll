%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Lateral/NSP Data/28_cursorTask_Complete_t5_bld(028)029.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('28.wav',analogData/1000,30000);

movCues28 = {'up',[0,31.466];
    'down',[0,35.767];
    'left',[0,40.229];
    'right',[0,44.774];
    'down',[0,49.040];
    'up',[0,53.479];
    'left',[0,57.949];
    'right',[1,02.102];
    'up',[1,06.344];
    'left',[1,10.618];
    'down',[1,14.906];
    'right',[1,19.383];
    'left',[1,23.601];
    'down',[1,27.982];
    'right',[1,32.351];
    'up',[1,36.604];
    'right',[1,41.208];
    'down',[1,45.753];
    'up',[1,50.052];
    'left',[1,54.572];
    'up',[1,58.815];
    'right',[2,03.440];
    'down',[2,07.986];
    'left',[2,12.262];
    'left',[2,16.804];
    'right',[2,21.221];
    'up',[2,25.671];
    'down',[2,30.007];
    'down',[2,34.611];
    'left',[2,38.933];
    'up',[2,43.490];
    'right',[2,47.869];
    'right',[2,52.377];
    'down',[2,56.899];
    'up',[3,01.167];
    'left',[3,05.408];
    'right',[3,09.964];
    'up',[3,14.264];
    'left',[3,18.622];
    'down',[3,23.188];};
[~,~,mc28] = unique(movCues28(:,1));
mct28 = vertcat(movCues28{:,2});
mct28 = mct28(:,1)*60 + mct28(:,2);

ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Medial/NSP Data/28_cursorTask_Complete_t5_bld(028)027.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct28_xpc = 1000*mct28 - offset_ms(end);

%%
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Lateral/NSP Data/29_cursorTask_Complete_t5_bld(029)030.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:98');
analogData = double(analogData.Data{end}');
audiowrite('29.wav',analogData/1000,30000);

movCues29 = {'up',[0,20.255];
    'down',[0,24.555];
    'left',[0,29.021];
    'right',[0,33.564];
    'down',[0,37.830];
    'up',[0,42.268];
    'left',[0,46.568];
    'right',[0,50.893];
    'up',[0,55.136];
    'left',[0,59.410];
    'down',[1,3.699];
    'right',[1,8.172];
    'left',[1,12.392];
    'down',[1,16.776];
    'right',[1,21.141];
    'up',[1,25.398];
    'right',[1,30];
    'down',[1,34.538];
    'up',[1,38.847];
    'left',[1,43.364];
    'up',[1,47.607];
    'right',[1,52.231];
    'down',[1,56.780];
    'left',[2,01.054];
    'left',[2,05.6];
    'right',[2,10.014];
    'up',[2,14.461];
    'down',[2,18.802];
    'down',[2,23.402];
    'left',[2,27.727];
    'up',[2,32.286];
    'right',[2,36.659];
    'right',[2,41.174];
    'down',[2,45.688];
    'up',[2,49.958];
    'left',[2,54.201];
    'right',[2,58.753];
    'up',[3,03.052];
    'left',[3,07.417];
    'down',[3,11.982];};
    
[clist,~,mc29] = unique(movCues29(:,1));
mct29 = vertcat(movCues29{:,2});
mct29 = mct29(:,1)*60 + mct29(:,2);

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.19/Data/_Medial/NSP Data/29_cursorTask_Complete_t5_bld(029)028.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

mct29_xpc = 1000*mct29 - offset_ms(end);

%%
datasets = {
    't5.2018.02.19',{[28],[29],[28 29]},{'W1','W2','W12'},[28];};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Wia_movCue' filesep datasets{d,1}];
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
    [ R, stream ] = getStanfordRAndStream( sessionPath, unique(horzcat(datasets{d,2}{:})), 3.5, datasets{d,4}, filtOpts );
    
    s1 = [stream{1}.spikeRaster, stream{1}.spikeRaster2];
    s2 = [stream{2}.spikeRaster, stream{2}.spikeRaster2];
    an = [s1; s2];
    allNeural = gaussSmooth_fast(double(an),60);
    
    wmp = [stream{1}.continuous.windowsMousePosition; stream{2}.continuous.windowsMousePosition];
    [B,A] = butter(4,10/500);
    wmp = filtfilt(B,A,wmp);
    wmp_speed = matVecMag(diff(wmp),2);
    
    allCues = [mc28; mc29];
    allCueTimes = round([mct28_xpc; mct29_xpc+length(s1)]);
    bNumPerTrial = [repmat(28,length(mc28),1); repmat(29,length(mc29),1)];
    
    binMS=20;
    binNeural = allNeural(1:20:end,:);
    binCueTimes = round(allCueTimes/20);
    binWMP = wmp(1:20:end,:);
    binWMP_speed = wmp_speed(1:20:end);
    
    twSet = {[-1500,3000]};
    pfSet = {'goCue'};

    for alignSetIdx=1:length(pfSet)
        timeWindow = twSet{alignSetIdx};

        for blockSetIdx = 1:length(datasets{d,2})
            
            trlIdx = ismember(bNumPerTrial, datasets{d,2}{blockSetIdx});
            trlIdx = find(trlIdx);
            movCues = allCues(trlIdx);
            codeList = unique(movCues);
            
            %single-factor
            dPCA_out = apply_dPCA_simple( binNeural, binCueTimes(trlIdx), ...
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
        
            %%
            bField = 'goCue';
            colors = jet(length(codeList))*0.8;
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));

                hold on
                for t=1:length(plotIdx)
                    loopIdx = (binCueTimes(plotIdx(t))-75):(binCueTimes(plotIdx(t))+150);
                    loopIdx(loopIdx>length(binWMP_speed))=[];
                    plot(binWMP_speed(loopIdx),'Color',colors(codeIdx,:),'LineWidth',2);
                end
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_speedProfiles_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(binWMP_speed, binCueTimes(plotIdx), timeWindow/binMS);
                hold on
                plot(nanmean(cd),'Color',colors(codeIdx,:));
            end
            legend(mat2stringCell(1:length(codeList)));
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgSpeed_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(diff(binWMP), binCueTimes(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmedian(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj,'Color',colors(codeIdx,:),'LineWidth',2);
            end
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            figure
            for codeIdx=1:length(codeList)
                plotIdx = trlIdx(movCues==codeList(codeIdx));
                cd = triggeredAvg(diff(binWMP), binCueTimes(plotIdx), timeWindow/binMS);
                tmpMean = squeeze(nanmedian(cd,1));
                traj = cumsum(tmpMean);

                hold on
                plot(traj(:,1), traj(:,2),'Color',colors(codeIdx,:),'LineWidth',2);
            end
            legend({'Right','Left','Up','Down'});
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_avgTraj_' pfSet{alignSetIdx} '.svg'],'svg');
            
            close all;
        end %block set
        
        if strcmp(datasets{d,1},'t5.2018.02.19')
            
            %eIdx = find(ismember(alignDat.bNumPerTrial, [18 22 24]));
            eIdx = find(ismember(alignDat.bNumPerTrial, [20]));
            iIdx = find(ismember(alignDat.bNumPerTrial, [23 25]));
            allIdx = [eIdx; iIdx];
            
            %end
            movCues = alignDat.currentMovement(alignDat.eventIdx(allIdx));
            codeList = unique(movCues);
            
            movType = zeros(length(allIdx),1);
            movType(1:length(eIdx)) = 0;
            movType((length(eIdx)+1):end) = 1;
            
            dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes, alignDat.eventIdx(allIdx), ...
                [movType, movCues], timeWindow/binMS, binMS/1000, {'IM', 'Dir', 'CI', 'IM x Dir'} );
            
        
            lineArgs = cell(2,4);
            colors = jet(4)*0.8;
            ls = {'-',':'};
            for x=1:2
                for c=1:4
                    lineArgs{x,c} = {'Color',colors(c,:),'LineWidth',2,'LineStyle',ls{x}};
                end
            end
            
            %2-factor dPCA
            [yAxesFinal, allHandles] = twoFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
                lineArgs, {'IM', 'Dir', 'CI', 'IM x Dir'}, 'sameAxes');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.png'],'png');
            saveas(gcf,[outDir filesep datasets{d,3}{blockSetIdx} '_2fac_2dir_dPCA_' pfSet{alignSetIdx} '.svg'],'svg');
        end
    end %alignment set
end
