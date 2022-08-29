 %blocks = [3:8, 17:20]; %[3:8, 17:20];
 date = '2018.04.16';
 R_HM16 = makeRstructs(date, blocks); 
% flDir = 'Users/sharlene/CachedData/t5.2018.04.16/Data/FileLogger/';
% R = [];
% global modelConstants; 
% modelConstants.sessionRoot =  'Users/sharlene/CachedData/t5.2018.04.16/';
% modelConstants.streamDir = 'stream/';
% for blockNum = blocks 
%     stream = loadStream([flDir num2str(blockNum) '/'], blockNum);
%     [tempR, td, stream, smoothKernel] = onlineR(stream);
%     R = [R, tempR];
%     tempR = [];
%     clear stream
% end

%%
R = R_HM16;
%%
usedCoh = unique(abs([R.coherence]));
%usedCoh(usedCoh > 90) = nan; 
signedCoh = unique(([R.coherence]));
numCorr = zeros(1, length(usedCoh)); 
outOf = zeros(size(numCorr));
numCorrS = zeros(1, length(signedCoh)); 
outOfS = zeros(size(numCorr)); 
figure;
for cIdx = 1:length(usedCoh)
    numCorr(cIdx) = sum([R(abs([R.coherence]) == usedCoh(cIdx)).isSuccessful]); 
    outOf(cIdx) = sum(abs([R.coherence]) == usedCoh(cIdx)); 
    subplot(length(usedCoh), 1, cIdx)
    h = histogram([R(abs([R.coherence]) == usedCoh(cIdx)).timeGoCue] - [R(abs([R.coherence]) == usedCoh(cIdx)).timeStimulusOn])
    h.BinEdges = [450:25:3050];
end
for cIdx = 1:length(signedCoh)
     numCorrS(cIdx) = sum([R([R.coherence] == signedCoh(cIdx)).isSuccessful]); 
    outOfS(cIdx) = sum([R.coherence] == signedCoh(cIdx)); 
%   subplot(length(usedCoh), 1, cIdx)
%     h = histogram([R([R.coherence] == usedCoh(cIdx)).timeGoCue] - [R([R.coherence] == usedCoh(cIdx)).timeStimulusOn])
%     h.BinEdges = [450:50:3500];
end
    
%%
figure
%plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), '*-', 'MarkerSize', 6, 'LineWidth', 2);
plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), 'o', 'LineWidth', 2, 'MarkerSize', 5); 
[paramValues, LL, exitFlag, output] = PAL_PFML_Fit(usedCoh, numCorr, outOf,[0 .05 .5 .0], [1 1 0 0], @PAL_Weibull)
x = 0:.5:max(usedCoh);
y = PAL_Weibull(paramValues, x);
hold on;
plot(x, y, 'LineWidth', 2)
axis square;
axis([min(x), max(x)+0.5, paramValues(3), 1]);
line([paramValues(1), paramValues(1)], [0, paramValues(3) + ((1-paramValues(4))-paramValues(3))/2])
threshY = PAL_Weibull(paramValues, paramValues(1))
%%
figure
%plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), '*-', 'MarkerSize', 6, 'LineWidth', 2);
plot(signedCoh(signedCoh > 0), bsxfun(@rdivide, numCorrS(signedCoh > 0), outOfS(signedCoh > 0)), 'or', 'LineWidth', 2, 'MarkerSize', 5); 
hold on;
plot(fliplr(abs(signedCoh(signedCoh < 0))), fliplr(bsxfun(@rdivide, numCorrS(signedCoh < 0), outOfS(signedCoh < 0))), 'og', 'LineWidth', 2, 'MarkerSize', 5); 
xGreen = fliplr(abs(signedCoh(signedCoh < 0)));
xRed = signedCoh(signedCoh > 0);
[paramValuesR, LLR, exitFlagR, outputR] = PAL_PFML_Fit(xRed, numCorrS(signedCoh > 0), outOfS(signedCoh > 0),[0 0 .5 .01], [1 1 0 1], @PAL_Weibull)
[paramValuesG, LLG, exitFlagG, outputG] = PAL_PFML_Fit(xGreen, fliplr(numCorrS(signedCoh < 0)), fliplr(outOfS(signedCoh < 0)),[0 0 .6 0], [1 1 1 0], @PAL_Weibull)
x = 0:.5:max(signedCoh);
yR = PAL_Weibull(paramValuesR, x);
yG = PAL_Weibull(paramValuesG, x);
hold on;
plot(x, yR, 'r','LineWidth', 2);
plot(x, yG, 'g','LineWidth', 2);
axis square;
axis([min(x), max(x)+0.5, paramValues(3), 1]);
%line([paramValues(1), paramValues(1)], [0, paramValues(3) + ((1-paramValues(4))-paramValues(3))/2])
%threshY = PAL_Weibull(paramValues, paramValues(1))