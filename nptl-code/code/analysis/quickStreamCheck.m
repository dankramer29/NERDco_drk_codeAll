function [R stream]  = quickStreamCheck(blockNum)
global modelConstants 

flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
%blockNum = 215;
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);

figure
plot(stream.continuous.xk(:,[2 4]));
[R, td, stream, smoothKernel] = onlineR(stream);
