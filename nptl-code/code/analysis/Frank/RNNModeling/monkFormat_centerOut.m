%%
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
dataset = 'R_2016-02-02_1_arm';
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];

fileName = [dataDir filesep dataset '.mat'];
predata = load(fileName);
arraySets = {[1],[2]};

%mov start
alignIdx = 2;
arrayStack = cell(2,1);
for arraySetIdx = 1:length(arraySets)
    %file saving
    savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];

    %get binned rates
    tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
    tmpKin = predata.allKin{alignIdx};

    %smooth
    if isfield(predata,'neuralType') && ~strcmp(predata.neuralType,'LFADS')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    elseif ~isfield(predata,'neuralType')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    end

    %stack
    eventIdx = [];
    [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

    stackIdx = 1:size(tmp,2);
    neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
    kinStack = zeros(size(tmpKin,1)*size(tmpKin,2),size(tmpKin,3));
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        kinStack(stackIdx,:) = tmpKin(t,:,:);
        eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
        stackIdx = stackIdx + size(tmp,2);
    end

    %normalize
    neuralStack = zscore(neuralStack);
    arrayStack{arraySetIdx} = neuralStack;
end

%%
%save in RNN format
%'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'
%[data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx), data.targetPos(loopIdx,1:2)];
neural = zeros(2, size(neuralStack,1), size(neuralStack,2));
neural(1,:,:) = arrayStack{1};
neural(2,:,:) = arrayStack{2};

controllerOutputs = [];
unrollKin = [];

for t=1:size(predata.allKin{2},1)
    unrollKin = [unrollKin; squeeze(predata.allKin{2}(t,:,:))];
end
pos = unrollKin(:,1:2);
targ = unrollKin(:,6:7);
vel = unrollKin(:,3:4);

offset = round(-predata.timeAxis{2}(1)/0.01);
trialStartIdx = (1:length(predata.timeAxis{2}):size(unrollKin,1)) + offset;
targCodes = predata.allCon{2};

save(['/Users/frankwillett/Data/armControlNets/Jenkins/J_centerOut_packaged.mat'], 'neural','pos','targ','trialStartIdx','vel','targCodes');

%%
%3d reaching
load('/Users/frankwillett/Data/Monk/Jenkins_3D/R_2017-01-31_1.mat')
saveTagsToUse = [7 9];
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
mkdir(saveDir);
nDim = 3;

R = preprocessMonkR( R, saveTagsToUse, nDim );

for t=1:length(R)
    R(t).currentTarget = repmat(R(t).startTrialParams.posTarget(1:3),1,length(R(t).counter));
    R(t).saveTag = R(t).startTrialParams.saveTag;
    R(t).blockNum = R(t).saveTag;
    R(t).clock = R(t).counter;
end

R = R(ismember([R.saveTag], saveTagsToUse));

rtIdxAll = zeros(length(R),1);
[B,A] = butter(4, 5/500);
for t=1:length(R)
    %RT
    pos = double(R(t).cursorPos(1:2,:)');
    pos(21:end,:) = filtfilt(B,A,pos(21:end,:)); %reseed
    vel = [0 0; diff(pos)];
    vel(1:21,:) = 0;
    
    speed = matVecMag(vel,2)*1000;
    speed(speed>1000) = 0;
    R(t).speed = speed';
    R(t).maxSpeed = max(speed);
end

tPos = zeros(length(R),3);
for t=1:length(R)
    tPos(t,:) = R(t).startTrialParams.posTarget(1:3);
end

[targList,~,targCodes] = unique(tPos,'rows');
ms = [R.maxSpeed];
avgMS = zeros(length(targList),1);
for t=1:length(targList)
    tmp = ms(targCodes==t);
    tmp(tmp>1000)=[];
    avgMS(t) = mean(tmp);
end

for t=1:length(R)
    useThresh = max(avgMS(targCodes(t))*0.3,30);

    rtIdx = find(R(t).speed>useThresh,1,'first');
    if isempty(rtIdx)
        rtIdx = 150;
        rtIdxAll(t) = nan;
    else
        rtIdxAll(t) = rtIdx;
    end       
    R(t).rtTime = rtIdx;
end

trlIdx = 2000:2300;
tmpList = [-1,-1,-1];
colors = jet(27);

figure
hold on
for t=1:length(trlIdx)
    if all(tPos(trlIdx(t),:)==0)
        continue
    end
    
    %if ismember(tPos(trlIdx(t),:), tmpList, 'rows')
    %    continue
    %end
    
    tmpList = [tmpList; tPos(trlIdx(t),:)];
    
    cp = R(trlIdx(t)).cursorPos';
    %badIdx = any(cp>200,2);
    %cp(badIdx,:) = nan;
    
    plot3(cp(:,1), cp(:,2), cp(:,3), 'LineWidth', 2, 'Color', colors(targCodes(trlIdx(t),:),:));
end
for t=1:size(targList,1)
    plot3(targList(t,1), targList(t,2), targList(t,3), 'ro', 'MarkerSize', 12);
end
xlim([-100,100]);
ylim([-100,100]);
zlim([-100,100]);
xlabel('X');
ylabel('Y');
zlabel('Z');
axis equal;

OptionZ.FrameRate=15;OptionZ.Duration=5.5;OptionZ.Periodic=true;
CaptureFigVid([0,10;-360,10], 'Monk3D',OptionZ)

%%
rtTime = [R.rtTime];
goodRTTrials = find(rtTime > 200 & rtTime < 350);

for x=1:length(R)
    pos = R(x).cursorPos';
    vel = [0 0 0; diff(pos)];
    vel = gaussSmooth_fast(vel,10);
    R(x).cursorVel = vel';
end

afSet = {'timeTargetOn','rtTime'};
twSet = {[-400,1000],[-740,740]};
pfSet = {'goCue','moveOnset'};

for alignSetIdx=1:length(afSet)
    alignFields = afSet(alignSetIdx);
    smoothWidth = 0;
    datFields = {'cursorPos','currentTarget','cursorVel','speed'};
    timeWindow = twSet{alignSetIdx};
    binMS = 10;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,3);
    %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    %tooLow = meanRate < 0.5;
    %alignDat.zScoreSpikes(:,tooLow) = [];

    chanSet = {[1:96],[97:192]};
    arrayNames = {'M1','PMd'};
    for arrayIdx=1:length(chanSet)
        %all activity
        trlIdx = [R.isSuccessful]';
        trlIdx = find(trlIdx);
        %trlIdx = intersect(trlIdx, goodRTTrials);

        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,:);
        [targList, ~, targCodes] = unique(tPos,'rows');
        centerCode = find(all(targList==0,2));
        outerIdx = find(targCodes~=centerCode);
        
        speedProfile = triggeredAvg(alignDat.speed, alignDat.eventIdx(trlIdx(outerIdx)), timeWindow/binMS);
        speedProfile = nanmean(speedProfile)';

        %single-factor
        dPCA_out = apply_dPCA_simple( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
            targCodes(outerIdx), timeWindow/binMS, binMS/1000, {'CD','CI'} );
        lineArgs = cell(length(targList)-1,1);
        colors = jet(length(lineArgs))*0.8;
        for l=1:length(lineArgs)
            lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
        end
        oneFactor_dPCA_plot( dPCA_out,  (timeWindow(1)/binMS):(timeWindow(2)/binMS), ...
            lineArgs, {'CD','CI'}, 'zoom', speedProfile);
        exportPNGFigure(gcf, [outDir filesep saveDir filesep 'dPCA_' arrayNames{arrayIdx}])
    end
end
        
%%
%save in RNN format
%'rnnState','controllerOutputs','envState','distEnvState','controllerInputs'
%[data.cursorPos(loopIdx,1:2), data.cursorVel(loopIdx,1:2), data.cursorSpeed(loopIdx), data.targetPos(loopIdx,1:2)];
neural = zeros(2, size(alignDat.zScoreSpikes,1), 96);
neural(1,:,:) = alignDat.zScoreSpikes(:,1:96);
neural(2,:,:) = alignDat.zScoreSpikes(:,97:end);

controllerOutputs = [];

pos = alignDat.cursorPos;
targ = alignDat.currentTarget;
vel = alignDat.cursorVel;
speed = matVecMag(vel,2);
vel(speed>20,:) = 0;

offset = 0;
trialStartIdx = alignDat.eventIdx;

save(['/Users/frankwillett/Data/armControlNets/Jenkins/J_centerOut3d_packaged.mat'], 'neural','pos','targ','trialStartIdx',...
    'vel','targCodes','outerIdx','trlIdx');



        