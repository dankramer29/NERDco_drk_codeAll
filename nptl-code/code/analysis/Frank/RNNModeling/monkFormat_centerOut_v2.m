%%
%2d reaching split
load('/Users/frankwillett/Data/Monk/JenkinsData/R_2016-02-02_1.mat')
saveTagsToUse = [1];
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
mkdir(saveDir);
nDim = 2;

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
    if t>1 && t<length(R)
        concatPos = double([R(t-1).cursorPos, R(t).cursorPos, R(t+1).cursorPos]');
        concatPos = filtfilt(B,A,concatPos); %reseed
        pos = concatPos((length(R(t-1).cursorPos)+1):(length(R(t-1).cursorPos)+length(R(t).cursorPos)),:);
        pos = pos(:,1:2);
    else   
        pos = double(R(t).cursorPos(1:2,:)');
        pos(21:end,:) = filtfilt(B,A,pos(21:end,:)); %reseed
    end
    
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
    avgMS(t) = median(tmp);
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

%%
%get return to center RT time
for t=1:length(R)
    if all(R(t).currentTarget(1:2,50)==0)
        concatPos = double([R(t-1).cursorPos, R(t).cursorPos]');

        cTrialStart = size(R(t-1).cursorPos,2);

        concatPos = concatPos(:,1:2);
        concatPos(21:end,:) = filtfilt(B,A,concatPos(21:end,:)); %reseed
        vel = [0 0; diff(concatPos)];
        vel(1:21,:) = 0;

        speed = matVecMag(vel,2)*1000;
        speed(speed>1000) = 0;
        useThresh = max(avgMS(targCodes(t-1))*0.3,30);

        rtIdx = find(speed((cTrialStart-400):end)>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 0;
        else
            rtIdx = rtIdx - 400;
        end       
        R(t).rtTime = rtIdx;
    end
end

%%
rtTime = [R.rtTime];
for x=1:length(R)
    pos = R(x).cursorPos';
    vel = [0 0 0; diff(pos)];
    vel = gaussSmooth_fast(vel,10);
    R(x).cursorVel = vel';
end

afSet = {'timeTargetOn_a','rtTime_a','timeFirstTargetAcquire_a','trialStart'};
twSet = {[-400,1000],[-740,740],[-1000,2000],[-500,1000]};
pfSet = {'goCue','moveOnset','targEnter','tStart'};

tto = [R.timeTargetOn];
delayTime = [R.timeTargetOn];
fta = [R.timeFirstTargetAcquire];
rtTime_use = rtTime;

validTrl = cell(length(afSet),1);
validTrl{1} = find(~isnan(tto) & delayTime>300);
validTrl{2} = find(~isnan(rtTime) & delayTime>300);
validTrl{3} = find(~isnan(fta) & delayTime>300);

tto(isnan(tto)) = 300;
rtTime_use(isnan(rtTime_use)) = 300;
fta(isnan(fta)) = 300;

for t=1:length(R)
    R(t).timeTargetOn_a = tto(t);
    R(t).rtTime_a = rtTime_use(t);
    R(t).timeFirstTargetAcquire_a = fta(t);
    R(t).trialStart = 1;
end

for alignSetIdx=1:length(afSet)
    alignFields = afSet(alignSetIdx);
    smoothWidth = 0;
    datFields = {'cursorPos','currentTarget','cursorVel','speed'};
    timeWindow = twSet{alignSetIdx};
    binMS = 10;

    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    vt = validTrl{alignSetIdx};
    alignDat.eventIdx = alignDat.eventIdx(vt);
    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,3);
    %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    %tooLow = meanRate < 0.5;
    %alignDat.zScoreSpikes(:,tooLow) = [];

    chanSet = {[1:96],[97:192]};
    arrayNames = {'M1','PMd'};
    for arrayIdx=1:length(chanSet)
        %all activity
        trlIdx = [R(vt).isSuccessful]';
        trlIdx = find(trlIdx);
        %trlIdx = intersect(trlIdx, goodRTTrials);

        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,:);
        [targList, ~, targCodes] = unique(tPos,'rows');
        centerCode = find(all(targList(:,1:2)==0,2));
        targDist = matVecMag(tPos(:,1:2),2);
        
        if isempty(centerCode)
            outerIdx = find(targDist>100);
        else
            outerIdx = find(targCodes~=centerCode & targDist>100);
        end
        
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
%splice outer and center aligned trials together
afSet = {'timeTargetOn_a','rtTime_a','timeFirstTargetAcquire_a','trialStart'};
twSet = {[-400,1000],[-740,740],[-1000,2000],[-500,1000]};
pfSet = {'goCue','moveOnset','targEnter','tStart'};

smoothWidth = 0;
datFields = {'cursorPos','currentTarget','cursorVel','speed'};
binMS = 10;

alignFields = afSet(2);
timeWindow = twSet{2};
alignDat_rt = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

tPos = alignDat_rt.currentTarget(alignDat_rt.eventIdx+10,:);
targDist = matVecMag(tPos(:,1:2),2);
[targList, ~, targCodes] = unique(tPos,'rows');
centerCode = find(all(targList(:,1:2)==0,2));
        
vt = validTrl{2};
totalTrialTime = 73+75+50+100;
spliceAlignDat.zScoreSpikes = zeros(totalTrialTime*length(vt),192);
spliceAlignDat.speed = zeros(totalTrialTime*length(vt),1);
spliceAlignDat.targCodes = zeros(length(vt),1);
spliceAlignDat.eventIdx = zeros(length(vt),1);
spliceAlignDat.targDist = zeros(length(vt),1);

globalIdx = 74;
for t=1:length(vt)
    rtDataIdx = (alignDat_rt.eventIdx(vt(t))-73):(alignDat_rt.eventIdx(vt(t))+74);
    tStartDataIdx = (alignDat_rt.eventIdx(vt(t)+1)-49):(alignDat_rt.eventIdx(vt(t)+1)+100);
    
    loopIdx = (globalIdx-73):(globalIdx+75+50+100-1);
    spliceAlignDat.zScoreSpikes(loopIdx,:) = [alignDat_rt.zScoreSpikes(rtDataIdx,:); alignDat_rt.zScoreSpikes(tStartDataIdx,:)];
    spliceAlignDat.speed(loopIdx,:) = [alignDat_rt.speed(rtDataIdx,:); alignDat_rt.speed(tStartDataIdx,:)];
    spliceAlignDat.pos(loopIdx,:) = [alignDat_rt.cursorPos(rtDataIdx,:); alignDat_rt.cursorPos(tStartDataIdx,:)];
    spliceAlignDat.currentTarget(loopIdx,:) = [alignDat_rt.currentTarget(rtDataIdx,:); alignDat_rt.currentTarget(tStartDataIdx,:)];
    
    spliceAlignDat.eventIdx(t) = globalIdx;
    spliceAlignDat.targCodes(t) = targCodes(vt(t));
    spliceAlignDat.targDist(t) = targDist(vt(t));

    globalIdx = globalIdx + totalTrialTime;
end

%%
trlIdx = [R(vt).isSuccessful]' & [R(vt+1).isSuccessful]';
trlIdx = find(trlIdx);
outerIdx = find(spliceAlignDat.targDist(trlIdx)>100);

twSplice = [-740, 740+500+1000];
speedProfile = triggeredAvg(spliceAlignDat.speed, spliceAlignDat.eventIdx(trlIdx(outerIdx)), twSplice/binMS);
speedProfile = nanmean(speedProfile)';
smoothSpikes = gaussSmooth_fast(spliceAlignDat.zScoreSpikes,3);

%single-factor
chanSet = {[1:96],[97:192]};
arrayNames = {'M1','PMd'};
for arrayIdx=1:length(chanSet)
    dPCA_out = apply_dPCA_simple( smoothSpikes(:,chanSet{arrayIdx}), spliceAlignDat.eventIdx(trlIdx(outerIdx)), ...
        spliceAlignDat.targCodes(trlIdx(outerIdx)), twSplice/binMS, binMS/1000, {'CD','CI'} );
    lineArgs = cell(length(targList)-1,1);
    colors = jet(length(lineArgs))*0.8;
    for l=1:length(lineArgs)
        lineArgs{l} = {'Color',colors(l,:),'LineWidth',2};
    end
    oneFactor_dPCA_plot( dPCA_out,  (twSplice(1)/binMS):(twSplice(2)/binMS), ...
        lineArgs, {'CD','CI'}, 'sameAxes', speedProfile);
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



        