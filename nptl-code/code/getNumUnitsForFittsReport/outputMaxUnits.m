expPath = 'E:\t5';
yearsToGrab = {'2016', '2017'};
expDirs = grabDirs(expPath, yearsToGrab);
Ms = parseDirs(expDirs, expPath);

Ms = pullCX(Ms);

maxC = getMaxChannels(Ms);

saveOut(maxC);

clear expPath expDirs Ms;

