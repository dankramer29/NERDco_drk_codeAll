%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.24/Data/_Lateral/NSP Data/28_cursorTask_Complete_t5_bld(028)029.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:100');
analogData = double(analogData.Data{end}');

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.24/Data/_Medial/NSP Data/28_cursorTask_Complete_t5_bld(028)029.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));
offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

%camera
[TC, TCstr, E_per] = SMPTE_dec_PR_v2(analogData,30000,30,1);
vidStart = [4,9,36,29];
vidEnd = [4,14,50,07];

%cursor movement
flDir = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.24/Data/FileLogger/';
blockNum = 28;
stream = parseDataDirectoryBlock([flDir num2str(blockNum) '/'], blockNum);

%%
vidFile = '/Users/frankwillett/Data/faceWithBCI.mp4';
vidObj = VideoReader(vidFile);
vidWriteObj = VideoWriter('faceWithTaskOverlap.avi');
open(vidWriteObj)

vidObj.CurrentTime = 30;

% Read video frames until available
figure('Units','pixels','Position',[1 1 1280 720]);
currAxes = axes('Units','pixels','Position',[1 1 1280 720]);

while hasFrame(vidObj)
  disp(vidObj.CurrentTime);
  
  cerebusTime = vidObj.CurrentTime + frameToSeconds(vidStart, 29.97) - frameToSeconds(TC(1,:), 29.97) + TC(1,end);
  frameIdx = (-int32(stream.continuous.clock(1)) - int32(offset_ms(end)) + int32(round(cerebusTime*1000)));
  frameIdx(frameIdx<1) = 1;
  frameIdx(frameIdx>length(stream.continuous.clock)) = length(stream.continuous.clock);
  
  vidFrame = readFrame(vidObj);
  
  cla;
  image(vidFrame, 'Parent', currAxes);
  hold on;
  
  mp = [200, 500];
  wkSize = [400, 400];
  
  scaleFactor = wkSize(1)/1080;
  cp = squeeze(stream.continuous.cursorPosition(frameIdx,:,1:2));
  cRad = scaleFactor*45/2;
  tp = squeeze(stream.continuous.currentTarget(frameIdx,1:2));
  tRad = scaleFactor*100/2;
  
  cp(1) = -cp(1);
  tp(1) = -tp(1);
  
  rectangle('Position',[mp(1)-wkSize(1)/2, mp(2)-wkSize(2)/2, wkSize(1), wkSize(2)], 'FaceColor', 'k');
  rectangle('Position',[scaleFactor*tp(1)+mp(1)-tRad, scaleFactor*tp(2)+mp(2)-tRad, tRad*2, tRad*2], 'Curvature', [1 1], 'FaceColor', [0.5 0.5 0.5]);
  rectangle('Position',[scaleFactor*cp(1)+mp(1)-cRad, scaleFactor*cp(2)+mp(2)-cRad, cRad*2, cRad*2], 'Curvature', [1 1], 'FaceColor', 'w');
  
  M = getframe;
  writeVideo(vidWriteObj, M);
end

close(vidWriteObj);
