%%
%see movementTypes.m for code definitions

movTypes = {[5 6],'head'
    [8 9],'face'
    [12 13],'arm'
    [16 17],'leg'
    [18 19],'eyes'
    [20 21],'tongue'
    [1],'cursor_OL'
    [2 3],'cursor_CL'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'all'];
mkdir(outDir);

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep 'Data' filesep 'Filters' filesep ...
    '002-blocks002-thresh-4.5-ch50-bin15ms-smooth25ms-delay0ms.mat']);

%load dataset
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep];
R = getSTanfordBG_RStruct( sessionPath, setdiff(blockList,[1 2 3]), model.model );

%%
allBlockNum = [R.blockNum]';
trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end
[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

timeWindow = [-1200 3000];
alignField = 'goCue';

%%
allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 0.5;
allSpikes(:,tooLow) = [];
allSpikes = gaussSmooth_fast(allSpikes, 30);

%%
globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

%%
R_curs = getSTanfordBG_RStruct( sessionPath, [1 2 3], model.model );

R_curs(1) = [];
opts.filter = false;
opts.useDecodeSpeed = true;
data = unrollR_1ms(R, opts);

trlCodes_curs = data.targCodes;
centerIdx = find(trlCodes_curs==5);
trlCodes_curs(centerIdx) = trlCodes_curs(centerIdx-1)+9;

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = [];
blockRows = [];
for t=1:length(R)
    loopIdx = (alignEvents(t,1)+timeWindow(1)):(alignEvents(t,1)+timeWindow(2));

    newRow = zeros(nBins, size(allSpikes,2));
    binIdx = 1:binMS;
    for b=1:nBins
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    blockRows = [blockRows; repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1)];
    snippetMatrix = [snippetMatrix; newRow];
end

%%
for b=1:length(blockList)
    disp(b);
    blockTrl = find([R.blockNum]==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+400)];
    end
    
    binIdx = find(blockRows==blockList(b));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(allSpikes(binIdx,:))*binMS);
end
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

%%
%add 4D cursor control conditions

%%
shuffPostfix = {'','_shuff'};
for doShuff = 1:2
    dPCA_out = cell(size(movTypes,1),1);
    eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
    codes = cell(size(movTypes,1),2);
    for pIdx = 1:size(movTypes,1)
        trlIdx = ismember(allBlockNum, movTypes{pIdx,1});
        codes{pIdx,1} = unique(trlCodes(trlIdx));
        codes{pIdx,2} = unique(trlCodesRemap(trlIdx));

        tmpCodes = trlCodesRemap(trlIdx);
        shuffIdx = randperm(length(tmpCodes));
        if doShuff == 2
            tmpCodes = tmpCodes(shuffIdx);
        end

        dPCA_out{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
            tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    end    

    yLims = [];
    axHandles=[];
    plotIdx = 1;

    movLegends = {{'Right','Left','Up','Down','TiltRight','TiltLeft','Forward','Backward'}
        {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
        {'Shrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','Index','Thumb'}
        {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
        {'EyesUp','EyesDown','EyesLeft','EyesRight'}
        {'TongueUp','TongueDown','TongueLeft','TongueRight'}};

    figure('Position',[680         101        1194         997]);
    for pIdx=1:length(movTypes)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:5
            axHandles(plotIdx) = subtightplot(length(movTypes),5,(pIdx-1)*5+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                plot(squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([-timeWindow(1)/binMS, -timeWindow(1)/binMS],[-100, 100],'--k');
            set(gca,'LineWidth',1.5,'YTick',[]);
            if pIdx~=length(movTypes)
                set(gca,'XTick',[]);
            end

            if c==5
                legend(movLegends{pIdx});
            end
        end
    end

    if doShuff == 1
        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    end
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.svg'],'svg');

    %%
    windows = {140:180, 80:100};
    windowNames = {'Move','Prep'};

    figure('Position',[802         173        1197         897]);
    for windowIdx = 1:length(windows)
        cVar = zeros(37,1);
        for pIdx = 1:size(movTypes,1)
            cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
            for x=1:size(dPCA_out{pIdx}.Z,2)
                %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:5),x,:))';
                %cVar(codes{pIdx,2}(x)) = sqrt(sum(var(tmp)));
                tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx,x,windows{windowIdx}));
                cVar(codes{pIdx,2}(x)) = (sum(tmp(:).^2));
            end
        end    

        movLegends = {{'HeadRight','HeadLeft','HeadUp','HeadDown','HeadTiltRight','HeadTiltLeft','HeadForward','HeadBackward'}
            {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
            {'Shrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','Index','Thumb'}
            {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
            {'EyesUp','EyesDown','EyesLeft','EyesRight'}
            {'TongueUp','TongueDown','TongueLeft','TongueRight'}};
        movLabels = horzcat(movLegends{:});
        colors = hsv(6)*0.8;
        plotIdx = 1;

        subtightplot(2,1,windowIdx,[0.05 0.05],[0.15 0.05],[0.05 0.01]);
        hold on
        for pIdx=1:size(movTypes,1)
            dat = sqrt(cVar(codes{pIdx,2}));
            bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
            plotIdx = plotIdx + length(dat);
        end
        title(windowNames{windowIdx});
        set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
        if windowIdx==2
            set(gca,'XTick',1:37,'XTickLabel',movLabels,'XTickLabelRotation',45);
        end

        ylim([0 60]);
    end
    saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.svg'],'svg');
end

%%
lineArgs = cell(length(trlCodeList),1);
colors = jet(length(lineArgs));
for l=1:length(lineArgs)
    lineArgs{l} = {'LineWidth',1,'Color',colors(l,:)};
end

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

psthOpts.prefix = 'all';
pOut = makePSTH_simple(psthOpts);
close all;

% %%
% nCon = length(trlCodeList);
% nChan = size(snippetMatrix,2);
% cSNR = zeros(nChan, nCon);
% 
% binWindow = [20:40];
% for t=1:length(trlCodeList)
%     trlIdx = find(trlCodes==trlCodeList(t));
%     binIdx = [];
%     for x=1:length(trlIdx)
%         binIdx = [binIdx, eventIdx(trlIdx(x)) + binWindow];
%     end
%     
%     mnMod = mean(snippetMatrix(binIdx,:));
%     sdMod = std(snippetMatrix(binIdx,:))+0.1;
%     cSNR(:,t) = abs(mnMod)./sdMod;
% end

%%
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