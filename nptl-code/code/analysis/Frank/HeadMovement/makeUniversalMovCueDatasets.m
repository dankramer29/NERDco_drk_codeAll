%%
rootDir = '/Users/frankwillett/Data/BG Datasets/movementSweepDatasets';
featureDir = [rootDir filesep 'features'];
saveDir = [rootDir filesep 'processedDatasets'];

%%
%modern SLC format (t7, t9); 20 ms bins
sessionList = {'t7.2013.08.23 Whole body cued movts, new cable (TOUCH)',[4 6 8 9 10 11 12 13 14 15 16 17 18 19],'east';
    't9.2015.03.30 Cued Movements',[8 9 10 11 13 14 15],'east'};

for sessIdx=1:size(sessionList,1)
%for sessIdx=2
    %first make a concatenated dataset from the SLC files
    slcDir = [rootDir filesep sessionList{sessIdx,1} filesep 'Data' filesep 'SLC Data'];
    
    dataset = struct;
    dataset.features.slcTX = [];
    dataset.features.slcSP = [];
    dataset.goCueIdx = [];
    dataset.movCues = [];
    dataset.blockIdx = [];
    dataset.nsp1Clock = [];
    dataset.nsp2Clock = [];
    dataset.offset = [];
    
    %cue names
    if strcmp(sessionList{sessIdx,1}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
        dataset.cueLabels = {'HandOpen','HandClose','WristFlex','WristExtend','WristClockwise','WristCClockwise',...
            'ElbowFlex','ElbowExtend','ArmUp','ArmDown','ArmSideUp','ArmSideDown','HeadTiltForward','HeadTiltBack',...
            'HeadLeft','HeadRight','Smile','Frown','TongueOut','TongueIn','EyesUp','EyesDown','EyesLeft','EyesRight','LegExtend','LegFlex',...
            'AnklePress','AnkleLift'};
        dataset.cueOrdering = 1:length(dataset.cueLabels);
    else
        cueLabels_go = {'TongueG','AnkleG','ShoulderG','ElbowG','WristG','RFistG','FingersG','PalmG','LFistG'};
        cueLabels_return = {'TongueR','AnkleR','ShoulderR','ElbowR','WristR','RFistR','FingersR','PalmR','LFistR'};
        dataset.cueLabels = [fliplr(cueLabels_return), cueLabels_go];  
        dataset.cueOrdering = [1,18,2,17,3,16,4,15,5,14,6,13,7,12,8,11,9,10];
    end
    
    blockStats = zeros(length(sessionList{sessIdx,2}), 2);
    for blockIdx=1:length(sessionList{sessIdx,2})
        fname = dir([slcDir filesep '*(' num2str(sessionList{sessIdx,2}(blockIdx)) ')*.mat']);
        slcDat = load([slcDir filesep fname(end).name]);
        if strcmp(sessionList{sessIdx,1}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
            slcDat = slcDat.SLCdata;
        end
        
        blockStats(blockIdx,1) = size(slcDat.ncTX.values,1)*0.02;

        cues = slcDat.task.receivedState.values;
        if strcmp(sessionList{sessIdx,1}, 't7.2013.08.23 Whole body cued movts, new cable (TOUCH)')
            tmpList = unique(cues);
            count = hist(cues, tmpList);
            [a,sortIdx]=sort(count,'descend');
        
            activeCues = tmpList(sortIdx(1:2));
            switchIdx = find(ismember(cues(2:end), activeCues) & cues(1:(end-1))==0)+1;
            
            dataset.movCues = [dataset.movCues; cues(switchIdx+5)];
            dataset.goCueIdx = [dataset.goCueIdx; switchIdx+length(dataset.blockIdx)];
                
            nTrials = length(cues(switchIdx+5));
        else
            addpath([rootDir filesep sessionList{sessIdx,1} filesep 'Documents']);
            T9_2015_03_30_Notes;
            
            goIdx = find(cues(2:end)==7 & cues(1:(end-1))~=7)+1;
            returnIdx = find(cues(2:end)>7 & cues(1:(end-1))==7)+1;
            keepIdx = [];
            for triplets=1:18
                tripIdx = ((triplets-1)*3+1):(triplets*3);
                if ismember(triplets, actions.(['Block' num2str(sessionList{sessIdx,2}(blockIdx))]))
                    keepIdx = [keepIdx, tripIdx];
                end
            end

            goIdx = goIdx(keepIdx);
            returnIdx = returnIdx(keepIdx);
            
            dataset.movCues = [dataset.movCues; -cues(returnIdx+5); cues(returnIdx+5)];
            dataset.goCueIdx = [dataset.goCueIdx; goIdx+length(dataset.blockIdx); returnIdx+length(dataset.blockIdx)];
            nTrials = length(returnIdx)*2;
            
            figure;
            hold on; 
            plot(cues); 
            plot(goIdx, cues(goIdx), 'go'); 
            plot(returnIdx, cues(returnIdx), 'ro');
        end
        
        dataset.nsp1Clock = [dataset.nsp1Clock; slcDat.clocks.nspClock];
        dataset.nsp2Clock = [dataset.nsp2Clock; slcDat.clocks.nsp2Clock];
        
        blockStats(blockIdx,2) = nTrials;
        dataset.features.slcTX = [dataset.features.slcTX; slcDat.ncTX.values];
        dataset.features.slcSP = [dataset.features.slcSP; slcDat.spikePower.values];
        dataset.blockIdx = [dataset.blockIdx; repmat(sessionList{sessIdx,2}(blockIdx), length(cues), 1)];
        
        %now sync the features made directly from the .ns5 files
        features_SP = load([featureDir filesep sessionList{sessIdx,1} filesep num2str(sessionList{sessIdx,2}(blockIdx)) ' LFP.mat']);
        features_TX = load([featureDir filesep sessionList{sessIdx,1} filesep num2str(sessionList{sessIdx,2}(blockIdx)) ' TX.mat']);

        nArrays = 2;
        offset = nan(nArrays,1);
        arrayChanSets = {1:96,97:192};
        for a=1:nArrays
            if isempty(features_SP.bandPowAllArrays{a})
                continue
            end
            spikePowFeature = features_SP.bandPowAllArrays{a}{1};
            slcSpikePow = slcDat.spikePower.values(:,arrayChanSets{a});

            chanLags = zeros(size(spikePowFeature,2),1);
            for chan=1:size(spikePowFeature,2)
                [r,lags]=xcorr(spikePowFeature(:,chan), slcSpikePow(:,chan),'none');
                [~,maxIdx] = max(r);
                chanLags(chan) = lags(maxIdx);
            end
            offset(a) = mode(chanLags);
        end
        
        dataset.offset = [dataset.offset; offset'];
        disp(offset);

        nThresh = size(features_TX.binnedTX,2);
        alignedFeat = cell(nArrays, nThresh+1);
        for x=1:size(alignedFeat,2)
            for a=1:nArrays
                alignedFeat{a,x} = zeros(length(cues), 96);
            end
        end
        
        originalFeat = cell(nArrays, nThresh+1);
        originalFeat{1,1} = features_SP.bandPowAllArrays{1,1}{1};
        if ~isempty(features_SP.bandPowAllArrays{2,1})
            originalFeat{2,1} = features_SP.bandPowAllArrays{2,1}{1};
        end
        for x=1:nThresh
            for a=1:nArrays
                originalFeat{a,1+x} = features_TX.binnedTX{a,x};
            end
        end
        
        featNames = cell(nThresh+1,1);
        featNames{1} = 'nsp_sp';
        for x=1:nThresh
            featNames{x+1} = ['nsp_tx' num2str(x)];
        end

        for a=1:nArrays
            if isnan(offset(a))
                continue
            end
            for featIdx=1:length(featNames)
                if offset(a)>0
                    replaceIdx = offset(a):size(originalFeat{a, featIdx},1);
                    alignedFeat{a, featIdx}(1:(end-offset(a)+1),:) = originalFeat{a, featIdx}(replaceIdx(1:(length(alignedFeat{a, featIdx})-offset(a)+1)),:);
                elseif offset(a)<=0
                    replaceIdx = (-offset(a)+1):size(alignedFeat{a, featIdx},1);
                    if length(replaceIdx)>size(originalFeat{a, featIdx},1)
                        replaceIdx = replaceIdx(1:size(originalFeat{a, featIdx},1));
                    end 
                    alignedFeat{a, featIdx}(replaceIdx,:) = originalFeat{a, featIdx}(1:length(replaceIdx),:);
                end
            end
        end
        
        for featIdx=1:length(featNames)
            if blockIdx==1
                dataset.features.(featNames{featIdx}) = [];
            end
            dataset.features.(featNames{featIdx}) = [dataset.features.(featNames{featIdx}); horzcat(alignedFeat{:,featIdx})];
        end
    end
    
    save([saveDir filesep sessionList{sessIdx,1} '.mat'], 'dataset');
end

%%
%legacy SLC format (t3); 50 ms bins
sessionList = {'t3.2011.07.20 Cued Movements',[2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 22 23]};

for sessIdx=1:size(sessionList,1)

    %first make a concatenated dataset from the SLC files
    slcDir = [rootDir filesep sessionList{sessIdx,1} filesep 'Data' filesep 'SLC Data'];
    
    dataset = struct;
    dataset.features.slcTX = [];
    dataset.features.slcSP = [];
    dataset.goCueIdx = [];
    dataset.movCues = [];
    dataset.blockIdx = [];
    
    %cue names
    dataset.cueLabels = {'RHandOpen1','RHandOpen2','LHandOpen1','LHandOpen2','WristDev1','WristDev2','WristFlex1','WristFlex2',...
        'WristPS1','WristPS2','HeadTilt1','HeadTilt2','SmileFrown1','SmileFrown2','TongueBlink1','TongueBlink2',...
        'Torso1','Torso2','RArmUp1','RArmUp2','LArmUp1','LArmUp2','RArmPush1','RArmPush2','LArmPush1','LArmPush2',...
        'LegKick1','LegKick2','EyesUp1','EyesUp2','EyesLeft1','EyesLeft2','ElbowFlex1','ElbowFlex2',...
        'ElbowPS1','ElbowPS2','ShoForward1','ShoForward2','ShoSide1','ShoSide2'}; 
    dataset.cueOrdering = 1:length(dataset.cueLabels);
    
    for blockIdx=1:length(sessionList{sessIdx,2})
        fname = dir([slcDir filesep '*(' num2str(sessionList{sessIdx,2}(blockIdx)) ')*.mat']);
        slcDat = load([slcDir filesep fname(end).name]);
        slcDat = slcDat.SLCdata;
             
        cues = slcDat.receivedState.values;
        tmpList = unique(cues);
        count = hist(cues, tmpList);
        [a,sortIdx]=sort(count,'descend');

        activeCues = tmpList(sortIdx(1:2));
        switchIdx = find(ismember(cues(2:end), activeCues) & cues(1:(end-1))==0)+1;

        dataset.movCues = [dataset.movCues; cues(switchIdx+5)];
        dataset.goCueIdx = [dataset.goCueIdx; switchIdx+length(dataset.blockIdx)];

        dataset.features.slcTX = [dataset.features.slcTX; slcDat.ncTX.values];
        dataset.features.slcSP = [dataset.features.slcSP; slcDat.spikePower.values];
        dataset.blockIdx = [dataset.blockIdx; repmat(sessionList{sessIdx,2}(blockIdx), length(cues), 1)];
    end
    
    save([saveDir filesep sessionList{sessIdx,1} '.mat'], 'dataset');
end

%%
%pre-SLC format (t1)
sessionList = {'t1.2010.03.15 imagined cued movements',[1];
    't1.2010.05.10 Cued Movements v2',[1,2,3]
    't1.2010.05.13 Cued Movements v2',[1,3]};

for sessIdx=1:size(sessionList,1)

    %first make a concatenated dataset from the SLC files
    cuedMovesDir = [rootDir filesep sessionList{sessIdx,1} filesep 'Data' filesep 'Cued Movements Data'];
    nspDir = [rootDir filesep sessionList{sessIdx,1} filesep 'Data' filesep 'NSPTG2 Data'];
    
    dataset = struct;
    dataset.features.slcTX = [];
    dataset.features.slcSP = [];
    dataset.goCueIdx = [];
    dataset.movCues = [];
    dataset.blockIdx = [];

%     MoveType = { ...
%     'Move eyes side to side'
%     'Move eyes to look up and down'
%     'Smile'
%     'Wiggle fingers'
%     'Hands apart/together'
%     'Hand open/close'  
%     'Wrist flex/extend'
%     'Wrist pronate/supinate'
%     'Wrist deviation' %  horizontal plane 
%     'Wave' % coronal plane. Testing rotation ability. 
%     'Touch monitor' 
%     'Elbow flex/extend'
%     'Arm straight to side/return' % abduct/adduct
%     'Shoulder forward/backward'
%     'Neck rotate' 
%     'Neck forward'
%     'Turn hips'
%     'Bow' % movement about hip axis
%     'Stand on one leg' % core postural muscles, hip flexion
%     'Knee flex/extend'
%     'Lift leg'
%     'Tap foot' };

    if strcmp(sessionList{sessIdx,1}, 't1.2010.03.15 imagined cued movements')
        dataset.cueLabels = {'WiggleFingers1','WiggleFingers2','WiggleLeftFingers1','WiggleLeftFingers2','ClenchHand1','ClenchHand2','ClenchLeftHand1','ClenchLeftHand2',...
            'WristFlex1','WristFlex2','WristDev1','WristDev1','WristDevLeft1','WristDevLeft2','WristPS1','WristPS2','TouchNose1','TouchNose2','TouchMonitor1','TouchMonitor2',...
            'ArmStraight1','ArmStraight2','DoorKnob1','DoorKnob2','DoorKnobLeft1','DoorKnobLeft2','Smile1','Smile2','EyesSide1','EyesSide2','EyesUpDown1','EyesUpDown2',...
            'KickLeg1','KickLeg2','KickLegLeft1','KickLegLeft2','TapFoot1','TapFoot2'}; 
        dataset.cueOrdering = 1:length(dataset.cueLabels);
    else
        dataset.cueLabels = {'EyesSide1','EyesSide2','EyesUpDown1','EyesUpDown2','Smile1','Smile2','WiggleFingers1','WiggleFingers2',...
            'HandOpenClose1','HandOpenClose2','HandsApart1','HandsApart2','WristFlex1','WristFlex2','WristPS1','WristPS2',...
            'WristDev1','WristDev2','Wave1','Wave2','ElbowFlex1','ElbowFlex2','ShoForward1','ShoForward2',...
            'ArmSide1','ArmSide2','TouchMonitor1','TouchMonitor2','NeckForward1','NeckForward2','NeckRotate1','NeckRotate2',...
            'TurnHips1','TurnHips2','Bow1','Bow2','OneLeg1','OneLeg2','Knee1','Knee2','LiftLeg1','LiftLeg2','TapFoot1','TapFoot2'}; 
        dataset.cueOrdering = 1:length(dataset.cueLabels);
    end
    
    for blockIdx=1:length(sessionList{sessIdx,2})
        fname = dir([cuedMovesDir filesep '*block' num2str(sessionList{sessIdx,2}(blockIdx)) '*.mat']);
        cueDat = load([cuedMovesDir filesep fname(end).name]);
        
        %get time offset between nsp features and cues
        fname = dir([cuedMovesDir filesep '*block' num2str(sessionList{sessIdx,2}(blockIdx)) '*.txt']);
        syncDat = load([cuedMovesDir filesep fname(end).name]);
        gameTimes = syncDat(:,2);
        
        fname = dir([nspDir filesep '*block' num2str(sessionList{sessIdx,2}(blockIdx)) '*.nev']);
        nevFile = openNEV([nspDir filesep fname(end).name]);
        nevTimes = nevFile.Data.SerialDigitalIO.TimeStampSec';
        
        timeOffset = mean(nevTimes - gameTimes);
        cueTimesInNSPAxis = vertcat(cueDat.data.cueTock{:});
        cueIdx = round(cueTimesInNSPAxis/0.02);
        
        cueTypes = [];
        
        if strcmp(sessionList{sessIdx,1}, 't1.2010.03.15 imagined cued movements')
            alternateIdx = zeros(20,1);
            alternateIdx(1:2:end) = 1;
            alternateIdx(2:2:end) = 2;
            for x=1:19
                newCues = (x-1)*2+alternateIdx;
                cueTypes = [cueTypes; newCues];
            end
        else
            alternateIdx = zeros(6,1);
            alternateIdx(1:2:end) = 1;
            alternateIdx(2:2:end) = 2;
            for x=1:22
                newCues = (x-1)*2+alternateIdx;
                cueTypes = [cueTypes; newCues];
            end
        end
             
        dataset.movCues = [dataset.movCues; cueTypes];
        dataset.goCueIdx = [dataset.goCueIdx; cueIdx+length(dataset.blockIdx)];

        dataset.features.slcTX = [dataset.features.slcTX; slcDat.ncTX.values];
        dataset.features.slcSP = [dataset.features.slcSP; slcDat.spikePower.values];
        dataset.blockIdx = [dataset.blockIdx; repmat(sessionList{sessIdx,2}(blockIdx), length(cueTypes), 1)];
        
        features_SP = load([featureDir filesep sessionList{sessIdx,1} filesep num2str(sessionList{sessIdx,2}(blockIdx)) ' LFP.mat']);
        features_TX = load([featureDir filesep sessionList{sessIdx,1} filesep num2str(sessionList{sessIdx,2}(blockIdx)) ' TX.mat']);

        originalFeat = cell(nThresh+1,1);
        originalFeat{1} = features_SP.bandPowAllArrays{1,1}{1};
        for x=1:nThresh
            originalFeat{1+x} = features_TX.binnedTX{x};
        end
        
        featNames = cell(nThresh+1,1);
        featNames{1} = 'nsp_sp';
        for x=1:nThresh
            featNames{x+1} = ['nsp_tx' num2str(x)];
        end
        
        for featIdx=1:length(featNames)
            if blockIdx==1
                dataset.features.(featNames{featIdx}) = [];
            end
            dataset.features.(featNames{featIdx}) = [dataset.features.(featNames{featIdx}); originalFeat{featIdx}];
        end
    end
    
    save([saveDir filesep sessionList{sessIdx,1} '.mat'], 'dataset');
end