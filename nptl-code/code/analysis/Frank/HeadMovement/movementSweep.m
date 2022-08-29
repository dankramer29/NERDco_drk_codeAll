%%
%see movementTypes.m for code definitions
datasets = {'t5.2017.10.16',[5 6],'head'
    't5.2017.10.16',[5 6],'headXY'
    't5.2017.10.16',[5 6],'headTF'
    't5.2017.10.16',[8 9],'face'
    't5.2017.10.16',[12 13],'arm'
    't5.2017.10.16',[16 17],'leg'
    't5.2017.10.16',[18 19],'eyes'
    't5.2017.10.16',[20 21],'tongue'
    't5.2017.10.16',[5 6 18 19],'headXY_eyes'
    't5.2017.10.16',[5 6 20 21],'headXY_tongue'};

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;

%%
alignFields = {'goCue','returnCue'};
for alignIdx=1:length(alignFields)
    for d=1:length(datasets)
        saveableName = [strrep(datasets{d,1},'.','-')];
        outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep datasets{d,3} '_' alignFields{alignIdx}];
        mkdir(outDir);

        %%
        %load cursor filter for threshold values, use these across all movement types
        model = load([paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep 'Data' filesep 'Filters' filesep ...
            '002-blocks002-thresh-4.5-ch50-bin15ms-smooth25ms-delay0ms.mat']);

        %load dataset
        sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];
        R = getSTanfordBG_RStruct( sessionPath, datasets{d,2}, model.model );
        
        trlCodes = zeros(size(R));
        for t=1:length(trlCodes)
            trlCodes(t) = R(t).startTrialParams.currentMovement;
        end

        removeIdx = [];
        if strcmp(datasets{d,3},'headXY')
            removeIdx = trlCodes>73;
        elseif strcmp(datasets{d,3},'headTF')
            removeIdx = trlCodes<=73;
        elseif strcmp(datasets{d,3},'headXY_eyes')
            removeIdx = ismember(trlCodes, [74 75 76 77]);
        elseif strcmp(datasets{d,3},'headXY_tongue')
            removeIdx = ismember(trlCodes, [74 75 76 77]);
        end
        R(removeIdx) = [];
        trlCodes(removeIdx) = [];
        [trlCodeList,~,trlCodesRemap] = unique(trlCodes);

        timeWindow = [-1200 1500];
        alignField = alignFields{alignIdx};

        allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
        meanRate = mean(allSpikes)*1000;
        tooLow = meanRate < 0.5;
        allSpikes(:,tooLow) = [];

        allSpikes = gaussSmooth_fast(allSpikes, 30);

        globalIdx = 0;
        alignEvents = zeros(size(R));
        for t=1:length(R)
            alignEvents(t) = globalIdx + R(t).(alignField);
            globalIdx = globalIdx + size(R(t).spikeRaster,2);
        end

        nBins = (timeWindow(2)-timeWindow(1))/binMS;
        globalIdx = 0;
        allBlocks = zeros(size(allSpikes,1),1);
        for t=1:length(R)
            loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
            allBlocks(loopIdx) = R(t).blockNum;
            globalIdx = globalIdx + size(R(t).spikeRaster,2);
        end

        snippetMatrix = [];
        blockRows = [];
        validTrl = false(length(R),1);
        for t=1:length(R)
            loopIdx = (alignEvents(t)+timeWindow(1)):(alignEvents(t)+timeWindow(2));

            if loopIdx(end)>size(allSpikes,1)
                loopIdx(loopIdx>size(allSpikes,1))=[];
            else
                validTrl(t) = true;
            end
                
            newRow = zeros(nBins, size(allSpikes,2));
            binIdx = 1:binMS;
            for b=1:nBins
                if binIdx(end)>length(loopIdx)
                    continue;
                end
                newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
                binIdx = binIdx + binMS;
            end

            blockRows = [blockRows; repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1)];
            snippetMatrix = [snippetMatrix; newRow];
        end
        
        %%
        for b=1:length(datasets{d,2})
            disp(b);
            binIdx = find(blockRows==datasets{d,2}(b));
            snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
        end
        snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

        %%
        eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
        dPCA_out = apply_dPCA_simple( snippetMatrix, eventIdx, ...
            trlCodesRemap, timeWindow/binMS, binMS/1000, {'CI','CD'} );

        lineArgs = cell(length(trlCodeList),1);
        if strcmp(datasets{d,3},'headXY_eyes')
            colors = hsv(4)*0.8;
            lineArgs = {{'LineWidth',2,'Color',colors(1,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(2,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(3,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(4,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(3,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(4,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(2,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(1,:),'LineStyle',':'}
                };
        elseif strcmp(datasets{d,3},'headXY_tongue')
            colors = hsv(4)*0.8;
            lineArgs = {{'LineWidth',2,'Color',colors(1,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(2,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(3,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(4,:),'LineStyle','-'}
                {'LineWidth',2,'Color',colors(3,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(4,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(2,:),'LineStyle',':'}
                {'LineWidth',2,'Color',colors(1,:),'LineStyle',':'}
                };
        else
            colors = hsv(length(trlCodeList))*0.8;
            for c=1:length(trlCodeList)
                lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
            end
        end

        timeAxis = ((timeWindow(1)/binMS):(timeWindow(2)/binMS))*binMS;
        margNamesShort = {'Dir','CI'};

        oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'zoomedAxes' );
        saveas(gcf,[outDir filesep 'dPCA.png'],'png');
        saveas(gcf,[outDir filesep 'dPCA.svg'],'svg');

        oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, {'CD','CI'}, 'sameAxes' );
        saveas(gcf,[outDir filesep 'dPCA_sameAx.png'],'png');
        saveas(gcf,[outDir filesep 'dPCA_sameAx.svg'],'svg');

        %%
        psthOpts = makePSTHOpts();
        psthOpts.gaussSmoothWidth = 0;
        psthOpts.neuralData = {snippetMatrix};
        psthOpts.timeWindow = timeWindow/binMS;
        psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
        psthOpts.trialConditions = trlCodesRemap;
        psthOpts.conditionGrouping = {1:length(trlCodeList)};
        psthOpts.lineArgs = lineArgs;

        psthOpts.plotsPerPage = 10;
        psthOpts.plotDir = outDir;

        featLabels = cell(192,1);
        chanIdx = find(~tooLow);
        for f=1:length(chanIdx)
            featLabels{f} = num2str(chanIdx(f));
        end
        psthOpts.featLabels = featLabels;

        psthOpts.prefix = datasets{d,3};
        pOut = makePSTH_simple(psthOpts);
        close all;

    end
end

%      TURN_HEAD_RIGHT(67)
%       
%       %FRW - head movement experiment 2017-09-23
%       TURN_HEAD_LEFT(71)
%       TURN_HEAD_UP(72)
%       TURN_HEAD_DOWN(73)
%       
%       %FRW broad movement sweep for 2017-10-15
%       HEAD_TILT_RIGHT(74)
%       HEAD_TILT_LEFT(75)
%       HEAD_FORWARD(76)
%       HEAD_BACKWARD(77)
%       
%       TONGUE_UP(78)
%       TONGUE_DOWN(79)
%       TONGUE_LEFT(80)
%       TONGUE_RIGHT(81)
%       
%       EYES_UP(82)
%       EYES_DOWN(83)
%       EYES_LEFT(84)
%       EYES_RIGHT(85)
%       
%       MOUTH_OPEN(86)
%       JAW_CLENCH(87)
%       PUCKER_LIPS(88)
%       RAISE_EYEBROWS(89)
%       NOSE_WRINKLE(90)
%       
%       SHO_SHRUG(91)
%       ARM_RAISE(92)
%       ARM_LOWER(93)
%       ELBOW_FLEX(94)
%       ELBOW_EXT(95)
%       WRIST_EXT(96)
%       WRIST_FLEX(97)
%       CLOSE_HAND(98)
%       OPEN_HAND(99)
%       
%       THUMB_JOY_FORWARD(100)
%       THUMB_JOY_BACK(101)
%       THUMB_JOY_RIGHT(102)
%       THUMB_JOY_LEFT(103)
%       
%       ANKLE_UP(104)
%       ANKLE_DOWN(105)
%       KNEE_EXTEND(106)
%       KNEE_FLEX(107)
%       LEG_UP(108)
%       LEG_DOWN(109)
%       TOE_CURL(110)
%       TOE_OPEN(111)
%       
%       TORSO_UP(112)
%       TORSO_DOWN(113)
%       TORSO_TWIST_RIGHT(114)
%       TORSO_TWIST_LEFT(115)
% 
%       INDEX_RAISE(116)
%       THUMB_UP(117)