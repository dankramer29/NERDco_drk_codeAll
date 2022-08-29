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
%a,g,q
templateIdx = [183, 273;
    3978, 4078;
    2682, 2774;
    ];

templates = cell(size(templateIdx,1),1);
for t=1:size(templateIdx,1)
    loopIdx = templateIdx(t,1):templateIdx(t,2);
    templates{t} = [filtVel(loopIdx,:), zeros(length(loopIdx),1)]/1000;
end

figure;
for t=1:length(templates)
    subplot(2,2,t);
    hold on;
    plot(cumsum(templates{t}(:,1)), cumsum(templates{t}(:,2)));
end
axis equal;

%%
letterCodes = [400:406, 412:432];
templateCodes = letterCodes([1 10 18]) ;

save('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_fixedAGQ.mat','templates','templateCodes');