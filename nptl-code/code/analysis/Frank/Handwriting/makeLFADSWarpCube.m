lfads = load('/Users/frankwillett/Data/Derived/Handwriting/lfads/t5.2019.05.08_inferredInputs.mat');
warpCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.05.08_warpedCube.mat');
unwarpedCube = load('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.05.08_unwarpedCube.mat');

warpCubeLfads = warpCube;
fNames = fieldnames(warpCube);

lfadsLabelCell = cell(size(lfads.conLabels,1),1);
for c=1:length(lfadsLabelCell)
    lfadsLabelCell{c} = strtrim(lfads.conLabels(c,:));
end

unshuffledInputs = zeros(size(lfads.inferredInputs));
unshuffledInputs(lfads.shuffIdx+1,:,:) = lfads.inferredInputs;

unshuffledLabels = zeros(size(lfads.labels));
unshuffledLabels(lfads.shuffIdx+1) = lfads.labels+1;

for f=1:length(fNames)
    labelIdx = find(strcmp(fNames{f},lfadsLabelCell));
    lfadsTrlIdx = find(unshuffledLabels==labelIdx);

    warpCubeLfads.(fNames{f}) = unshuffledInputs(lfadsTrlIdx,:,:);
    
    for t=1:size(warpCubeLfads.(fNames{f}),1)
        warpClock = squeeze(warpCube.([fNames{f} '_T'])(:,t));
        dat = squeeze(warpCubeLfads.(fNames{f})(t,:,:));
        warpCubeLfads.(fNames{f})(t,:,:) = interp1(warpClock, dat, 1:size(dat,1),'linear', 0);
    end
end

save('/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.05.08_lfads_warpedCube.mat','-struct','warpCubeLfads');