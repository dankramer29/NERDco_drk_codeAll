%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.17/Data/2_cursorTask_Complete_t5_bld(002)003.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:97:100');
analogData = double(analogData.Data{end}');

%try to get BNC sync
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.17/Data/2_cursorTask_Complete_t5_bld(002)003.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));

offset_ms = round((siTot(end).cbTimeMS)-siTot(end).xpcTime);

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

sessionName = 't5.2018.01.17';
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];

%load cued movement dataset
flDir = [sessionPath filesep 'Data' filesep 'FileLogger/'];
stream = parseDataDirectoryBlock([flDir num2str(2) '/'], 2);

headMouse = stream.continuous.windowsMousePosition;

headAccel = filtfilt(ones(30,1)/30,1,analogData);
headAccel = headAccel(1:30:end,:);
headAccel = headAccel((uint32(offset_ms(end))+stream.continuous.clock(1)):end,:);

figure
hold on
plot(zscore(headAccel(:,1:3)));
plot(zscore(headMouse),'LineWidth',3);
legend({'X','Y','Z','M1','M2'});

[B,A] = butter(6,10/500);
smoothAccel = filtfilt(B,A,headAccel);
figure
hold on
plot(-zscore(smoothAccel(:,1)));
plot(zscore(headMouse(:,2)),'LineWidth',3);
legend({'accel','mouse'});

%%
[c, lags] = xcorr(zscore(headAccel(:,1)), zscore(headMouse(:,2)));
[~,maxIdx] = max(abs(c));
lagSteps = lags(maxIdx);

figure
hold on
plot(-zscore(headAccel(:,1)));
plot(zscore(headMouse(:,2)));

figure
hold on
plot(-zscore(headAccel(:,1)));
plot(zscore(headMouse((-lagSteps):end,2)));


%HEAD MOUSE LOOKS TO HAVE 82 MS DELAY
%DOESNT APPEAR TO CAPTURE X AXIS BECAUSE THIS ROTATION IS IN THE DIRECTION
%OF GRAVITY?
%LOOKS TO BE JIGGLING AROUND BECAUSE IT IS NOT RIGIDLY ATTACHED TO HEAD
%BAND
%NS3 file syncs are only off by 4 ms for robot task october dataset between
%the NSPs
%%
ns3File = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.22/Data/13_cursorTask_Complete_t5_bld(013)007.ns3';
siTot = extractNS3BNCTimeStamps(ns3File(1:(end-4)));

ns3File_med = '/Users/frankwillett/Data/BG Datasets/t5.2018.01.22/Data/med/14_robotTask_Complete_t5_bld(014)015.ns3';
siTot_med = extractNS3BNCTimeStamps(ns3File_med(1:(end-4)));

median(round(siTot(end).cbTimeMS-siTot(end).xpcTime))
median(round(siTot_med(end).cbTimeMS-siTot_med(end).xpcTime))