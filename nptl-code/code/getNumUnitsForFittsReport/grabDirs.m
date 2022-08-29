function expDirs = grabDirs(expPath, yearsToGrab)
% returns dir output of experiments

expDirs = [];
for yearIdx = 1:length(yearsToGrab),
    year = yearsToGrab{yearIdx};
    
	expDirs = [expDirs; dir([expPath filesep '*' year '*'])];

end


