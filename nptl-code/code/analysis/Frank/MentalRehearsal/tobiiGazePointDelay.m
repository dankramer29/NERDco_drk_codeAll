%measure difference in frame time between when the eye first moves and when
%it is detected by our system

%
% [TC, TCstr, E_per] = SMPTE_dec(smpte_video,SR,fps,debug)
%
% TC: 5 column matrix with hh mm ss ff video_time
% TCstr: Time Code and video time as string
% E_per: percentage of frames with errors
%
% smpte_video: video stream with SMPTE LTC code
% SR: sample rate of video stream
% fps: define frames per second (fps)
% debug: Option to print processing status (0:off,1:on) default:0 (faster)
%

%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.31/Data/_Lateral/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:100');
analogData = double(analogData.Data{end}');

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.31/Data/_Medial/NSP Data/2_cursorTask_Complete_t5_bld(002)003.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

%camera
[TC, TCstr, E_per] = SMPTE_dec_PR_v2(analogData,30000,30,1);

%%
datDir = '/Users/frankwillett/Data/BG Processed/t5.2018.01.31/';
bNums = [2];
allDat = cell(length(bNums),1);
for b=1:length(bNums)
    dataPath = [datDir 'RS_' strrep('t5.2018.01.31','.','_') '_block' num2str(bNums(b)) '.mat'];
    allDat{b} = load(dataPath);
end

eyePos = allDat{1}.stream.continuous.windowsPC1LeftEye;

frameNums = [1,06,34,20;
    1,06,36,21;
    1,06,38,20;
    1,06,40,21;
    1,06,42,24;
    ];
frameTimes = [];
for f=1:size(frameNums,1)
    tmpDiff = bsxfun(@plus,TC(:,1:4),-frameNums(f,:));
    tmpDiff = sum(abs(tmpDiff),2);
    [~,minIdx] = min(tmpDiff);
    frameTimes(f) = TC(minIdx,5);
end
frameTimeMS = uint32(round(frameTimes*1000));

frameIdx = (-allDat{1}.stream.continuous.clock(1) - uint32(offset_ms(end)) + frameTimeMS);

plotIdx = 42000:51000;

figure
hold on
plot(eyePos(plotIdx,:));
axis tight;
yLim = get(gca,'YLim');
for x=1:length(frameIdx)
    plot([frameIdx(x), frameIdx(x)]-plotIdx(1), yLim, '--k');
end

%200 ms until fully settled
%100ms for half way point

%%
%face tracker
dat=readtable('/Users/frankwillett/Data/Derived/faceAnalysis/eyeCalTest.csv');
hp = dat{:,{'pose_Tx','pose_Ty','pose_Tz','pose_Rx','pose_Ry','pose_Rz'}};
gaze = dat{:,{'gaze_0_x','gaze_0_y','gaze_0_z','gaze_1_x','gaze_1_y','gaze_1_z'}};

frameNums = [1,06,01,23];
frameTimes = [];
for f=1:size(frameNums,1)
    tmpDiff = bsxfun(@plus,TC(:,1:4),-frameNums(f,:));
    tmpDiff = sum(abs(tmpDiff),2);
    [~,minIdx] = min(tmpDiff);
    frameTimes(f) = TC(minIdx,5);
end
frameTimeMS = uint32(round(frameTimes*1000));

vidAxis = int32(round(1000*TC(:,5))) - int32(allDat{1}.stream.continuous.clock(1)) - int32(offset_ms(end));

figure
hold on
plot(vidAxis(minIdx:end), hp(1:length(vidAxis(minIdx:end)),4:5));
plot(allDat{1}.stream.continuous.windowsMousePosition);

%%
targPos = unique(allDat{1}.stream.discrete.currentTarget(:,1:2),'rows');
targPos(end,:) = [];

figure
hold on
plot(eyePos(:,1)*(1920/1680), eyePos(:,2)*(1080/1050), '.');
for t=1:size(targPos,1)
    plot(targPos(:,1)+960, targPos(:,2)+540, 'ro','MarkerFaceColor','r','MarkerSize',8);
end
axis equal;


calIdx = 10000:56455;

%%

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.02.09/Data/_Lateral/NSP Data/22_sequenceTask_Complete_t5_bld(022)022.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

%camera
[TC, TCstr, E_per] = SMPTE_dec_PR_v2(analogData,30000,30,1);