%30 balanced path sequences, S
blockNum = 301;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

figure
plot(stream.continuous.windowsPC1GazePoint(:,1)*1680, stream.continuous.windowsPC1GazePoint(:,2)*1050, '.')
set(gca,'YDir','reverse');
axis equal;

figure
plot(stream.continuous.windowsPC1Timestamp)

comet(stream.continuous.windowsPC1GazePoint(:,1)*1680, stream.continuous.windowsPC1GazePoint(:,2)*1050);
set(gca,'YDir','reverse'); 