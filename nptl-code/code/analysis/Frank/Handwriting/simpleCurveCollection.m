nPoints = 10000;
mousePos = zeros(nPoints,2);
times = zeros(nPoints,1);

tic;
for t=1:size(mousePos,1)
    mousePos(t,:) = get(0, 'PointerLocation');
    times(t) = toc;
    pause(0.01);
end

cutIdx = find(all(mousePos==0,2));
mousePos = mousePos(1:(cutIdx-1),:);
times = times(1:(cutIdx-1),:);

interpPos = interp1(times, mousePos, 0:0.01:times(end));
[B,A] = butter(2,10/50);

interpPos(isnan(interpPos))=0;
filtPos = filtfilt(B,A,interpPos);
filtVel = diff(filtPos);

%%
%tilde, question mark, apostrophe, comma
templateIdx = [196, 288;
    1099, 1209;
    2073, 2132;
    2903, 2974;];

templates = cell(size(templateIdx,1),1);
for t=1:size(templateIdx,1)
    loopIdx = templateIdx(t,1):templateIdx(t,2);
    templates{t} = [filtVel(loopIdx,:), zeros(length(loopIdx),1)];
end

%fix my bad apostrophe
templates{3}(42:60,1) = -templates{3}(42:60,1);

%add off-the-page information
zBump = -templates{4}(1:30,2);
zIdx = [0,0;
    90,111;
    1,30;
    1,30;];

for t=1:length(templates)
    if zIdx(t,2)~=0
        loopIdx = zIdx(t,1):zIdx(t,2);
        warpBump = interp1(1:length(zBump),zBump,linspace(1,length(zBump),length(loopIdx)));
        templates{t}(loopIdx,3) = warpBump;
    end
end

punctuationCodes = [580 581 582 583];
templateCodes = punctuationCodes;

save('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_punctuation.mat','templates','templateCodes');