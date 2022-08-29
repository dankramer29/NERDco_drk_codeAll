%simple script to plot the bias estimate for a block
%%
global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

%%
blockToPlot = 7;
sessionPath = modelConstants.sessionRoot;
flDir = [sessionPath modelConstants.dataDir 'FileLogger/'];
R = onlineR(loadStream([flDir num2str(blockToPlot) '/'], blockToPlot));

allBias_xkMod = [];
for t=1:length(R)
    allBias_xkMod = [allBias_xkMod; R(t).xkModBiasEst'];
end
movTime = vertcat(R.trialLength);
xkRaw = [R.xk]';

%%
figure
subplot(2,1,1);
plot((1:length(allBias_xkMod))/1000/60, allBias_xkMod*1000);

subplot(2,1,2);
plot((1:length(allBias_xkMod))/1000/60, matVecMag(allBias_xkMod,2)*1000);

figure
plot(movTime,'o');

%%
figure
subplot(2,1,1);
plot((1:length(allBias_xkMod))/1000/60, allBias_xkMod*1000);

subplot(2,1,2);
plot((1:length(allBias_xkMod))/1000/60, matVecMag(allBias_xkMod,2)*1000);

figure
plot(movTime,'o');