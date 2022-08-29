%extract TX and spike power features from raw .ns5 files for old movement
%cue datasets, and align them to the task
addpath(genpath('/net/home/fwillett/nptlBrainGateRig/code/analysis/Frank'))

readDir = '/net/home/fwillett/movementSweepDatasets';
saveDir = [readDir '/features'];
datasetDir = [readDir '/processedDatasets'];
mkdir(saveDir);

subjectCodes = {'t7','t9','t3','t1'};
sessionList = {'t7.2013.08.23 Whole body cued movts, new cable (TOUCH)',[4 6 8 9 10 11 12 13 14 15 16 17 18 19],'east';
    't9.2015.03.30 Cued Movements',[8 9 10 11 13 14 15],'east';
    't3.2011.07.20 Cued Movements',[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 22 23],'t3';
    't1.2010.05.10 Cued Movements v2',[1,2,3],'t1';
    't1.2010.03.15 imagined cued movements',[1],'t1_2';
    't1.2010.05.13 Cued Movements v2',[1 2 3 4],'t1_3'};

t1FileNames = {'CuedMovesblock1_2010.05.10.12.07002','CuedMovesblock2_2010.05.10.12.15003','CuedMovesblock3_2010.05.10.12.23004'};
t1FileNames_2 = {'CuedMovesFast_2010.03.15.12.26001'};
t1FileNames_3 = {'CuedMovesblock1_2010.05.13.12.11002','CuedMovesblock2_2010.05.13.12.18003','CuedMovesblock3_2010.05.13.12.26004','CuedMovesblock4_2010.05.13.12.33005'};

%%
%feature extraction
for s=6:size(sessionList,1)
    disp(sessionList{s,1});
    
    if strcmp(sessionList{s,3},'east')
        fileNames = getEastNS5FileNames( [readDir filesep sessionList{s,1}], sessionList{s,2}, subjectCodes{s} );
    elseif strcmp(sessionList{s,3},'west')
        fileNames = getWestNS5FileNames( [readDir filesep sessionList{s,1}], sessionList{s,2}, subjectCodes{s} );
    elseif strcmp(sessionList{s,3},'t1')
        fileNames = cell(length(t1FileNames),1);
        for f=1:length(fileNames)
            fileNames{f,1} = [readDir filesep sessionList{s,1} filesep 'Data' filesep 'NSPTG2 Data' filesep t1FileNames{f} '.ns5'];
        end
    elseif strcmp(sessionList{s,3},'t1_2')
        fileNames = cell(length(t1FileNames_2),1);
        for f=1:length(t1FileNames_2)
            fileNames{f,1} = [readDir filesep sessionList{s,1} filesep 'Data' filesep 'NSPTG2 Data' filesep t1FileNames_2{f} '.ns5'];
        end
    elseif strcmp(sessionList{s,3},'t1_3')
        fileNames = cell(length(t1FileNames_3),1);
        for f=1:length(t1FileNames_3)
            fileNames{f,1} = [readDir filesep sessionList{s,1} filesep 'Data' filesep 'NSPTG2 Data' filesep t1FileNames_3{f} '.ns5'];
        end
    end

    disp(fileNames)
    
    opts.fileNames = fileNames;
    opts.doLFP = true;
    opts.binMS = 20;
    opts.bands_lo = [];
    opts.bands_hi = [250 5000];
    opts.doTX = true;
    opts.txThresh = [-3.5,-4.5,-5.5,-6.5];
    opts.nCarChans = 60;
    opts.blockList = sessionList{s,2};
    opts.resultDir = [saveDir filesep sessionList{s,1}];
    opts.syncType = sessionList{s,3};
    mkdir(opts.resultDir);
    getBinnedFeaturesFromSession( opts );
end

%%
% %align features with dataset
% for setIdx=1:length(sessSets)
%     currSet = sessSets{setIdx};
%     for s=1:size(currSet,1)
%         disp(currSet{s,1});
%         load([datasetDir currSet{s,1} '.mat']);
%         if strcmp(currSet{s,3},'west')
%             dataset.nspClocks = double(dataset.nspClocks) / 30000.0;
%         end
% 
%         tx = zeros(size(dataset.TX,1),size(dataset.TX,2),5);
%         sp = zeros(size(dataset.TX,1),size(dataset.TX,2));
% 
%         for b=1:length(dataset.blockList)
%             disp(b);
%             if ~exist([saveDir filesep currSet{s,1} filesep num2str(dataset.blockList(b)) ' LFP.mat'],'file')
%                 continue;
%             end
%             lfp_ns5 = load([saveDir filesep currSet{s,1} filesep num2str(dataset.blockList(b)) ' LFP.mat']);
%             tx_ns5 = load([saveDir filesep currSet{s,1} filesep num2str(dataset.blockList(b)) ' TX.mat']);
%             loopIdx = find(dataset.blockNums==dataset.blockList(b));
% 
%             if strcmp(currSet{s,3},'east')
%                 alignMethod = 'syncPulse';
%             else
%                 if strcmp(lfp_ns5.metaTags.FileSpec,'2.2')
%                     alignMethod = 'bncSync';
%                 else
%                     alignMethod = 'clock';
%                 end
%             end
% 
%             if strcmp(alignMethod, 'bncSync')
%                 sync = load([saveDir filesep currSet{s,1} filesep num2str(dataset.blockList(b)) ' SyncPulse.mat']);
%                 xpcClock = double(dataset.sysClock(loopIdx));
%                 
%                 nArrays = length(sync.siTot);
%                 offsetTime = zeros(nArrays,1);
%                 for a=1:nArrays
%                     offsetTime(a) = mean(sync.siTot{a}.cbTimeMS - sync.siTot{a}.xpcTime);
%                 end
%                 offsetTime = round(offsetTime/opts.binMS);
%                 
%                 arrayChans = {1:96, 97:192};
%                 for a=1:nArrays
%                     sp_ns = lfp_ns5.bandPowAllArrays{a}{1};
%                     if offsetTime(a)>0
%                         sp_ns = sp_ns((offsetTime(a)+1):end,:);
%                         endIdx = min(length(loopIdx), length(sp_ns));
%                         sp(loopIdx(1:endIdx),arrayChans{a}) = sp_ns(1:endIdx,:);
%                         for t=1:size(tx_ns5.binnedTX,2)
%                             tx_ns = tx_ns5.binnedTX{a,t};
%                             tx_ns = tx_ns((offsetTime(a)+1):end,:);
%                             endIdx = min(length(loopIdx), length(tx_ns));
%                             tx(loopIdx(1:endIdx),arrayChans{a},t) = tx_ns(1:endIdx,:);
%                         end
%                     elseif offsetTime(a)<0
%                         error('Negative offset, figure this out');
%                     end
%                 end
%             elseif strcmp(alignMethod,'syncPulse')
%                 sync = load([saveDir filesep currSet{s,1} filesep num2str(dataset.blockList(b)) ' SyncPulse.mat']);
%                 [r,lags]=xcorr(sync.pulse, dataset.syncSig(loopIdx,:));
%                 [~,maxIdx] = max(r);
%                 offset = lags(maxIdx);
% 
%                 nArrays = 2;
%                 arrayChans = {1:96, 97:192};
%                 for a=1:nArrays
%                     sp_ns = lfp_ns5.bandPowAllArrays{a}{1};
%                     if offset>0
%                         sp_ns = sp_ns((offset+1):end,:);
%                         endIdx = min(length(loopIdx), length(sp_ns));
%                         sp(loopIdx(1:endIdx),arrayChans{a}) = sp_ns(1:endIdx,:);
%                         for t=1:size(tx_ns5.binnedTX,2)
%                             tx_ns = tx_ns5.binnedTX{a,t};
%                             tx_ns = tx_ns((offset+1):end,:);
%                             endIdx = min(length(loopIdx), length(tx_ns));
%                             tx(loopIdx(1:endIdx),arrayChans{a},t) = tx_ns(1:endIdx,:);
%                         end
%                     elseif offset<0
%                         error('Negative offset, figure this out');
%                     end
%                 end
%             elseif strcmp(alignMethod,'clock')
%                 pullIdx = zeros(length(loopIdx),1);
%                 for x=1:length(loopIdx)
%                     [~,minIdx] = min(abs(dataset.nspClocks(loopIdx(x),1) - lfp_ns5.timeAxes{1}));
%                     [~,minIdx2] = min(abs(dataset.nspClocks(loopIdx(x),2) - lfp_ns5.timeAxes{2}));
%                     sp(loopIdx(x),:) = [lfp_ns5.bandPowAllArrays{1}{1}(minIdx,:), lfp_ns5.bandPowAllArrays{2}{1}(minIdx2,:)];
%                     pullIdx(x) = minIdx;
% 
%                     [~,minIdx] = min(abs(dataset.nspClocks(loopIdx(x),1)-tx_ns5.binTimes{1,1}/1000));
%                     [~,minIdx2] = min(abs(dataset.nspClocks(loopIdx(x),2)-tx_ns5.binTimes{2,1}/1000));
%                     for t=1:size(tx_ns5.binnedTX,2)
%                         tx(loopIdx(x),:,t) = [tx_ns5.binnedTX{1,t}(minIdx,:), tx_ns5.binnedTX{2,t}(minIdx2,:)];
%                     end
%                 end
%             elseif strcmp(alignMethod,'neural')
%                 offset = zeros(nArrays,1);
%                 arrayChanSets = {1:96,97:192};
%                 for a=1:nArrays
%                     txRaw = zscore(tx_ns5.binnedTX{a,2});
%                     loopIdx = find(dataset.blockNums==dataset.blockList(b));
%                     txDat = zscore(dataset.TX(loopIdx,arrayChanSets{a}));
%                     chanLags = zeros(size(txRaw,2),1);
%                     for chan=1:size(txRaw,2)
%                         [r,lags]=xcorr(txRaw(:,chan), txDat(:,chan),'none');
%                         [~,maxIdx] = max(r);
%                         chanLags(chan) = lags(maxIdx);
%                     end
%                     offset(a) = median(chanLags);
%                 end
% 
%                 nArrays = 2;
%                 arrayChans = {1:96, 97:192};
%                 for a=1:nArrays
%                     sp_ns = lfp_ns5.bandPowAllArrays{a}{1};
%                     if offset(a)>0
%                         sp_ns = sp_ns((offset(a)+1):end,:);
%                         endIdx = min(length(loopIdx), length(sp_ns));
%                         sp(loopIdx(1:endIdx),arrayChans{a}) = sp_ns(1:endIdx,:);
%                         for t=1:size(tx_ns5.binnedTX,2)
%                             tx_ns = tx_ns5.binnedTX{a,t};
%                             tx_ns = tx_ns((offset(a)+1):end,:);
%                             endIdx = min(length(loopIdx), length(tx_ns));
%                             tx(loopIdx(1:endIdx),arrayChans{a},t) = tx_ns(1:endIdx,:);
%                         end
%                     elseif offset(a)<0
%                         error('Negative offset, figure this out');
%                     end
%                 end
%             end
%         end
% 
%         posErr = dataset.targetPos - dataset.cursorPos; 
%         zFeat = zscore([double(squeeze(dataset.TX(loopIdx,:)))]);
%         posErr = posErr(loopIdx,:);
%         %zFeat = zscore(double(dataset.TX));
%         
%         filts = zFeat \ posErr;
%         decPosErr = zFeat * filts;
%         disp(corr(posErr, decPosErr));
% 
%         save([datasetDir t5sess{s,1} '_features.mat'],'sp','tx');
%     end
% end