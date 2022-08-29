% calculate preferred directions based on movement period- for comparison to
% delayed reach task. Potentially compare differences pre-move and post-MO
load('/Users/sharlene/CachedData/processed/allHM_TF.mat')
%%
targDirs = [90, 270, 0, 180]; %up/down is 1/2, left/right is 4/3
for sesh = 1:length(aggR)
temppsth = aggR(sesh).HM.psth; 
binsBefore = aggR(sesh).HM.psthBefore; 

psth = nanmean(temppsth,3);
%filter out non-firing units: channels are 1st D

%% decide which target elicits the highest FR: targets are 2nd D
DM(sesh).dirFR = nan(size(psth,1), size(psth,2)); 
DM(sesh).prefDir = nan(size(dirFR,1),1); 
for unit = 1:size(psth,1)
    for target = 1:4
        DM(sesh).dirFR(unit,target) = nanmax(psth(unit, target, 1, (binsBefore-15):(binsBefore+15)));
    end
    [~, tempIdx] = max(DM(sesh).dirFR(unit,:));
    DM(sesh).prefDir(unit) = targDirs(tempIdx); %prefDir in degrees
end
end
%% load c4 and repeat 
load('/Users/sharlene/CachedData/processed/all_HM_C4.mat')
%%
targDirs = [90, 270, 0, 180]; %up/down is 1/2, left/right is 4/3
for sesh = 1:length(aggR)
temppsth = aggR(sesh).HM_C4.psth; %not split by target whaaat
binsBefore = aggR(sesh).HM_C4.psthBefore; 
% make our own PSTHes here: 

%psth = nanmean(temppsth,3);
%filter out non-firing units: channels are 1st D

%% decide which target elicits the highest FR: targets are 2nd D
C4(sesh).dirFR = nan(size(psth,1), size(psth,2)); 
C4(sesh).prefDir = nan(size(dirFR,1),1); 
for unit = 1:size(psth,1)
    for target = 1:4
        C4(sesh).dirFR(unit,target) = nanmax(psth(unit, target, 1, (binsBefore-15):(binsBefore+15)));
    end
    [~, tempIdx] = max(DM(sesh).dirFR(unit,:));
    C4(sesh).prefDir(unit) = targDirs(tempIdx); %prefDir in degrees
end
end
