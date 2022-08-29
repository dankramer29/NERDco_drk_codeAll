blockNum = 26;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

xFactor = 1680/1050;

figure; 
plot(stream.continuous.windowsPC1LeftEye(:,1)*xFactor, stream.continuous.windowsPC1LeftEye(:,2), 'o');
axis equal;

tmp = diff(stream.continuous.windowsPC1Timestamp);
tmp(tmp==0) = [];
figure
plot(tmp,'o');