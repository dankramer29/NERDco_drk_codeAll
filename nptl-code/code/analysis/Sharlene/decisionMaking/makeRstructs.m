function [R, stream] = makeRstructs(date, blocks) 
 flDir1 = 'Users/sharlene/CachedData/t5.';
 flDir2 = '/Data/FileLogger/';
 flDir = [flDir1, date, flDir2];
R = [];
stream = [];
global modelConstants; 
modelConstants.sessionRoot =  ['Users/sharlene/CachedData/t5.', date, '/'];
modelConstants.streamDir = 'stream/';
for blockNum = blocks 
    streamtemp = loadStream([flDir num2str(blockNum) '/'], blockNum);
    [tempR, ~, streamtemp, ~] = onlineR(streamtemp);
    R = [R, tempR];
    stream = [stream, streamtemp];
    tempR = [];
    streamtempp = [];
   % clear stream
end