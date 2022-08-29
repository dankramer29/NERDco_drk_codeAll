blockNum = 200;
flDir = [modelConstants.sessionRoot modelConstants.dataDir 'FileLogger/'];
stream = loadStream([flDir num2str(blockNum) '/'], blockNum);
[R, td, stream, smoothKernel] = onlineR(stream);

speedCodes = zeros(length(R),1);
for t=1:length(R)
    speedCodes(t) = R(t).startTrialParams.speedCode;
end

posTarget = [R.posTarget];
outerIdx = find(~all(posTarget==0));
colors = jet(4)*0.8;
alpha = 0.96;
B = 1-alpha;
A = [1, -alpha];

maxSpeeds = zeros(length(outerIdx),2);
tableIdx = 1;

figure;
hold on
for t=1:4
    trlIdx = find(speedCodes(outerIdx)==t);
    for x=1:length(trlIdx)
        pos = R(outerIdx(trlIdx(x))).cursorPosition';
        speed = matVecMag(diff(pos),2);
        speed = filtfilt(B,A,double(speed));
        plot(speed,'Color',colors(t,:));
        
        maxSpeeds(tableIdx,:) = [t, max(speed)];
        tableIdx = tableIdx + 1;
    end
end

figure
plot(maxSpeeds(:,1), maxSpeeds(:,2),'o');
 
