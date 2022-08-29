load('/Users/frankwillett/Downloads/t5.2016.10.10.mat');

trainIdx = 1:90000;
testIdx = 90000:size(dataset.targetPos,1);

tVec = dataset.targetPos - dataset.cursorPos;
smoothFeatures = zscore(gaussSmooth_fast(dataset.TX, 3.0));

decCoef = buildLinFilts(tVec(trainIdx,:), smoothFeatures(trainIdx,:), 'inverseLinear');
decOnTest = smoothFeatures(testIdx,:)*decCoef;

figure
hold on;
plot(tVec(testIdx,1),'LineWidth',2);
plot(decOnTest(:,1),'LineWidth',2);
xlabel('Time Step');
legend({'TargetPos - CursorPos','Decoded'});
set(gca,'FontSize',14);