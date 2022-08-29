scriptDir = '/Users/frankwillett/Data/Derived/testLfadsManager/';
mkdir(scriptDir);

dataDir = '/remote/data';
outputDir = '/remote/output';
lfadsCodeDir = '/remote/lfadsCode';
datasetNames = {'day1','day1','day1','day1','day1','day2','day2','day2','day2','day2'};

opts = lfadsMakeOptsSimple();
paramStructs = repmat(opts,5,1);
kp = [0.9 0.92 0.94 0.96 0.98];
for k=1:5
    paramStructs(k).keep_prob = kp(k);
end
paramStructs = [paramStructs; paramStructs];

availableGPU = [0 1 2 3 5 6 7 8];
displayNum = 7;
mode = 'pairedSampleAndAverage';

lfadsMakeBatchScripts( scriptDir, dataDir, outputDir, lfadsCodeDir, ...
    datasetNames, paramStructs, availableGPU, displayNum, mode );