function curveFitParams = fitPCurves_Rstruct(R, curveFxn, fitParams)
switch curveFxn %first letter of the string
    case 'W'
        PALfxn = @PAL_Weibull;
    case 'C'
        PALfxn = @PAL_CumulativeNormal; 
    case 'G'
        PALfxn =@PAL_Gumbel;
    case 'L'
        PALfxn =@PAL_Logistic;
end
usedCoh = unique(abs([R.coherence]));
signedCoh = unique(([R.coherence]));
numCorr = zeros(1, length(usedCoh)); 
outOf = zeros(size(numCorr));
numCorrS = zeros(1, length(signedCoh)); 
outOfS = zeros(size(numCorr)); 

for cIdx = 1:length(usedCoh)
    if length(abs([R.coherence]) == usedCoh(cIdx)) > 1
        numCorr(cIdx) = sum([R(abs([R.coherence]) == usedCoh(cIdx)).isSuccessful]); 
        outOf(cIdx) = sum(abs([R.coherence]) == usedCoh(cIdx)); 
    end
end

for cIdx = 1:length(signedCoh)
    if length(([R.coherence]) == signedCoh(cIdx)) > 1
        numCorrS(cIdx) = sum([R([R.coherence] == signedCoh(cIdx)).isSuccessful]); 
        outOfS(cIdx) = sum([R.coherence] == signedCoh(cIdx)); 
    end
end
    
%%
figure
%plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), '*-', 'MarkerSize', 6, 'LineWidth', 2);
plot(usedCoh, bsxfun(@rdivide, numCorr, outOf), 'o', 'LineWidth', 2, 'MarkerSize', 5); 
%[paramValues, LL, exitFlag, output] = PAL_PFML_Fit(usedCoh, numCorr, outOf, fitParams.searchGrid, fitParams.paramsFree, PALfxn);
[paramValues, LL, exitFlag, output] = PAL_PFML_Fit(usedCoh, numCorr, outOf, fitParams, [1 1 0 1] , PALfxn);
x = 0:.5:max(usedCoh);
y = PALfxn(paramValues, x);
hold on;
plot(x, y, 'LineWidth', 2)
axis square;
axis([min(x), max(x)+0.5, paramValues(3), 1]);
line([paramValues(1), paramValues(1)], [0, paramValues(3) + ((1-paramValues(4))-paramValues(3))/2])
title('Unsigned Coherence Curves')
xlabel('Coherence')
ylabel('Proportion Correct')
legend({'Raw Data', 'Curve Fit'})
%threshY = PAL_Weibull(paramValues, paramValues(1))
curveFitParams.unsigned.paramVals = paramValues; 
curveFitParams.unsigned.LL = LL; 
curveFitParams.unsigned.exitFlag = exitFlag;
curveFitParams.unsigned.output = output;
%%
figure
plot(signedCoh(signedCoh > 0), bsxfun(@rdivide, numCorrS(signedCoh > 0), outOfS(signedCoh > 0)), 'or', 'LineWidth', 2, 'MarkerSize', 5); 
hold on;
plot(fliplr(abs(signedCoh(signedCoh < 0))), fliplr(bsxfun(@rdivide, numCorrS(signedCoh < 0), outOfS(signedCoh < 0))), 'og', 'LineWidth', 2, 'MarkerSize', 5); 
xGreen = fliplr(abs(signedCoh(signedCoh < 0)));
xRed = signedCoh(signedCoh > 0);
%[paramValuesR, LLR, exitFlagR, outputR] = PAL_PFML_Fit(xRed, numCorrS(signedCoh > 0), outOfS(signedCoh > 0),fitParams.searchGrid, fitParams.paramsFree, PALfxn);
%[paramValuesG, LLG, exitFlagG, outputG] = PAL_PFML_Fit(xGreen, fliplr(numCorrS(signedCoh < 0)), fliplr(outOfS(signedCoh < 0)),fitParams.searchGrid, fitParams.paramsFree, PALfxn);
[paramValuesR, LLR, exitFlagR, outputR] = PAL_PFML_Fit(xRed, numCorrS(signedCoh > 0), outOfS(signedCoh > 0), fitParams, [1 1 1 1], PALfxn);
[paramValuesG, LLG, exitFlagG, outputG] = PAL_PFML_Fit(xGreen, fliplr(numCorrS(signedCoh < 0)), fliplr(outOfS(signedCoh < 0)), fitParams, [1 1 1 1], PALfxn);

x = 0:.5:max(signedCoh);
yR = PALfxn(paramValuesR, x);
yG = PALfxn(paramValuesG, x);
hold on;
plot(x, yR, 'r','LineWidth', 2);
plot(x, yG, 'g','LineWidth', 2);
axis square;
axis([min(x), max(x)+0.5, paramValues(3), 1]);
title('Signed Coherence Curves')
xlabel('Coherence')
ylabel('Proportion Correct')
legend({'more red', 'more green'})

curveFitParams.signedR.paramVals = paramValuesR; 
curveFitParams.signedR.LL = LLR; 
curveFitParams.signedR.exitFlag = exitFlagR;
curveFitParams.signedR.output = outputR;

curveFitParams.signedG.paramVals = paramValuesG; 
curveFitParams.signedG.LL = LLG; 
curveFitParams.signedG.exitFlag = exitFlagG;
curveFitParams.signedR.output = outputG;