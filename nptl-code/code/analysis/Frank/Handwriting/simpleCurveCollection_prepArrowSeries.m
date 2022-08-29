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
%straight right, bend down, bend up, bend up-left, bend up-right, bend
%up-right-slashback

templateIdx = [144, 163;
    1500, 1550;
    2251, 2295;
    3242, 3307;
    3763, 3839;
    4950, 5042;
    ];

templates = cell(size(templateIdx,1),1);
for t=1:size(templateIdx,1)
    loopIdx = templateIdx(t,1):templateIdx(t,2);
    templates{t} = [filtVel(loopIdx,:), zeros(length(loopIdx),1)];
end

templateCodes = 526:537;
templates = [templates; templates];

save('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_prepArrowSeries.mat','templates','templateCodes');