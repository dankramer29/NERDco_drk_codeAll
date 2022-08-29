%load('/Users/frankwillett/Data/Monk/Jenkins_3D/R_2017-01-26_1.mat')
%saveTagsToUse = 5;

load('/Users/frankwillett/Data/Monk/Jenkins_3D/R_2017-01-31_1.mat')
saveTagsToUse = [7 9];
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins3d';
mkdir(saveDir);

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
    R(t).speed = speed;
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
smoothWidth = 0;
datFields = {'cursorPos','currentTarget'};
binMS = 20;
unrollDat = binAndUnrollR( R, binMS, smoothWidth, datFields );

afSet = {'timeTargetOn','rtTime'};
twSet = {[-240,1500],[-740,740]};
pfSet = {'goCue','moveOnset'};

for alignSetIdx=1:length(afSet)
    alignFields = afSet(alignSetIdx);
    smoothWidth = 0;
    datFields = {'cursorPos','currentTarget'};
    timeWindow = twSet{alignSetIdx};
    binMS = 20;
    alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

    alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
    alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,1.5);
    %meanRate = mean(alignDat.rawSpikes)*1000/binMS;
    %tooLow = meanRate < 0.5;
    %alignDat.zScoreSpikes(:,tooLow) = [];

    chanSet = {[1:96],[97:192],[1:192]};
    arrayNames = {'M1','PMd','All'};
    for arrayIdx=1:length(chanSet)
        %all activity
        trlIdx = [R.isSuccessful]';
        trlIdx = find(trlIdx);

        tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,:);
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
            lineArgs, {'CD','CI'}, 'zoom');
        saveas(gcf,[outDir filesep saveDir filesep 'dPCA_' arrayNames{arrayIdx} '.png'],'png');
        saveas(gcf,[outDir filesep saveDir filesep 'dPCA_' arrayNames{arrayIdx} '.svg'],'svg');
    end
end
        