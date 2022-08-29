%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));
resultsDir = '/Users/frankwillett/Data/CaseDerived/';
sessions = defineAllSessions();

%%
gainSmoothSessions = strcmp(vertcat(sessions.conditionTypes),'gainSmoothing');
fittsSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'fittsLaw'));
fittsSessions = fittsSessions(1:12);

vPlans = defineValidationPlans_v3(fittsSessions, resultsDir, 'predictive');
validateModels_vPred_sciRep(fittsSessions, vPlans, resultsDir, 6, 'fittsPredict');
makePerformanceTable_v2(resultsDir, fittsSessions, 6, 'fittsPredict');

%%
%new sci rep predictions based on different training conditions
vPlans = defineValidationPlans_v3(sessions(gainSmoothSessions), resultsDir, 'predictive_fast');
validateModels_vPred_sciRep(sessions(gainSmoothSessions), vPlans, resultsDir, 6, 'gsPredict_fast');

vPlans = defineValidationPlans_v3(sessions(gainSmoothSessions), resultsDir, 'predictive_slow');
validateModels_vPred_sciRep(sessions(gainSmoothSessions), vPlans, resultsDir, 6, 'gsPredict_slow');

vPlans = defineValidationPlans_v3(sessions(gainSmoothSessions), resultsDir, 'predictive_medium');
validateModels_vPred_sciRep(sessions(gainSmoothSessions), vPlans, resultsDir, 6, 'gsPredict_medium');

makePerformanceTable_v2(resultsDir, sessions(gainSmoothSessions), [6], 'gsPredict_fast');
makePerformanceTable_v2(resultsDir, sessions(gainSmoothSessions), [6], 'gsPredict_medium');
makePerformanceTable_v2(resultsDir, sessions(gainSmoothSessions), [6], 'gsPredict_slow');

modelValPlots_zoomedAxes_v2(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_fast'});
modelValPlots_zoomedAxes_v2(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_medium'});
modelValPlots_zoomedAxes_v2(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_slow'});

summarizeLineStats(resultsDir,{'gsPredict_slow','gsPredict_medium','gsPredict_fast'});

%%
%predictive, fitts & gain/smooth
vPlans = defineValidationPlans_v3(sessions(gainSmoothSessions), resultsDir, 'predictive');
validateModels_vPred_sciRep(sessions(gainSmoothSessions), vPlans, resultsDir, 6, 'gsPredict_sciRep');
makePerformanceTable_v2(resultsDir, sessions(gainSmoothSessions), [6], 'gsPredict_sciRep');
modelValPlots_zoomedAxes_v2(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_sciRep'});

makePerformanceTable_v2(resultsDir, sessions(gainSmoothSessions), [6], 'gsPredict');
overallAccuracyPlots_v2(resultsDir, 'gsPredict');

modelDotPlots_v2(sessions(gainSmoothSessions), resultsDir, {6, 'gsPredict'});
modelValPlots(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict'});

vPlans = defineValidationPlans_v3(fittsSessions, resultsDir, 'predictive');
validateModels_vPred(fittsSessions, vPlans, resultsDir, 6, 'fittsPredict');

makePerformanceTable_v2(resultsDir, fittsSessions, 6, 'fittsPredict');
fittsModelDotPlots(fittsSessions, resultsDir, {6, 'fittsPredict'});
fittsLawFunc(resultsDir, sessions, {6, 'fittsPredict'});
fittsLawFunc(resultsDir, sessions, {NaN, NaN});
fittsModelComparisonPlots(resultsDir, sessions);
optiPaperFigures(sessions, resultsDir);

modelValPlots(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict'});
optimalParamSweep( resultsDir, {6, 'gsPredict'} );

modelValPlots(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_fast'});
modelValPlots(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_medium'});
modelValPlots(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict_slow'});

%%
gainSmoothSessions = strcmp(vertcat(sessions.conditionTypes),'gainSmoothing');
trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {NaN,NaN});

systemDynamicsPlot(resultsDir, sessions(gainSmoothSessions));
paperStats(resultsDir, sessions(gainSmoothSessions));

feedbackCorrections(resultsDir, sessions(gainSmoothSessions), 'xVal', 'rtFB', 'iterNoise');
feedbackCorrections(resultsDir, sessions(gainSmoothSessions), 'xVal', 'rtFB', 'noIterNoise');
plotFeedbackCorrections(resultsDir, sessions(gainSmoothSessions));

modelNums = setdiff(1:18,[5 6]);
for m=modelNums
    magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {m,'gsExplain'});
    trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {m,'gsExplain'});
end

magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {2, 'gsExplain'}); %constant
magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {7, 'gsExplain'}); %piecewise
magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {4, 'gsExplain'}); %linear
magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {8, 'gsExplain'}); %deadzone
magVsDistance_v2(resultsDir, sessions(gainSmoothSessions), {12, 'gsExplain'}); %no vel

trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {2,'gsExplain'});
trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {7,'gsExplain'});
trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {4,'gsExplain'});
trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {8,'gsExplain'});
trajectoryPlots_v2(resultsDir, sessions(gainSmoothSessions), {12,'gsExplain'});

magVsDistanceBiases(resultsDir, sessions(gainSmoothSessions), {7, 'gsExplain'});
magVsDistanceBiases(resultsDir, sessions(gainSmoothSessions), {2, 'gsExplain'});
magVsDistanceBiases(resultsDir, sessions(gainSmoothSessions), {4, 'gsExplain'});
magVsDistanceBiases(resultsDir, sessions(gainSmoothSessions), {8, 'gsExplain'});
magVsDistanceBiases(resultsDir, sessions(gainSmoothSessions), {12, 'gsExplain'});

for x=setdiff(1:16,[5 6])
    compareSimControlStrat(resultsDir, sessions(gainSmoothSessions), {x,'gsExplain'})
end

for m=setdiff(1:16,[5 6])
    modelDotPlots_v2(sessions(gainSmoothSessions), resultsDir, {m, 'gsExplain'});
    close all;
end

modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {7,'gsExplain'});
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {12,'gsExplain'});
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {18,'gsExplain'}, 'outer');
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {2,'gsExplain'});
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {2,'gsExplain'});
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {4,'gsExplain'});
modelTrajectoryPlots_v2(sessions(gainSmoothSessions), resultsDir, {8,'gsExplain'});

modelDotPlots_v2(sessions, resultsDir, {7, 'gsPredict'});
%%
summarizePerformance_v2(resultsDir, sessions(gainSmoothSessions), {nan, 'gsPredict'});
summarizePerformance_v2(resultsDir, sessions(gainSmoothSessions), {6, 'gsPredict'});

gainSmoothSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'gainSmoothing'));
summarizePerformance_v2(resultsDir, gainSmoothSessions, {nan, 'gsExplain'});

makeMovies(resultsDir, gainSmoothSessions, {NaN,NaN});
makeMovies(resultsDir, gainSmoothSessions, {7,'gsExplain'});
prepareArmMovies(resultsDir, sourceFileDirs, gainSmoothSessions, {7,'gsExplain'});

makeCVecMovies(resultsDir, gainSmoothSessions, {NaN,NaN});

%bias killing methods
biasKillingMethods_v2( gainSmoothSessions, resultsDir );
plotTrajGradients( gainSmoothSessions, resultsDir);
%%
%fitts sessions
fittsSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'fittsLaw'));
vPlans = defineValidationPlans_v3(fittsSessions, resultsDir, 'explanatory');
validateModels_v3(fittsSessions, vPlans, resultsDir, 7, 'fittsExplain');
validateModels_v3(fittsSessions, vPlans, resultsDir, 19, 'fittsExplain');

makePerformanceTable_v2(resultsDir, sessions(fittsSessions), 7, 'fittsExplain');
makePerformanceTable_v2(resultsDir, sessions(fittsSessions), 19, 'fittsExplain');
fittsModelDotPlots(sessions(fittsSessions), resultsDir, {7, 'fittsExplain'});
fittsModelDotPlots(sessions(fittsSessions), resultsDir, {19, 'fittsExplain'});

fittsLawFunc(resultsDir, sessions, {nan, nan});
fittsLawFunc(resultsDir, sessions, {7, 'fittsExplain'});

magVsDistance_v2(resultsDir, sessions(fittsSessions), {nan, nan});
plotFittsLawControlStrats( resultsDir, sessions, {nan, nan} );

gainSmoothSessions = strcmp(vertcat(sessions.conditionTypes),'gainSmoothing');
gainPerformancePlots(resultsDir, sessions(gainSmoothSessions), {nan, nan});
gainPerformancePlots(resultsDir, sessions(gainSmoothSessions), {7, 'gsExplain'});

fittsLawFitting(resultsDir, sessions, {nan, nan});
fittsLawCrossValPlots(resultsDir, sessions, {nan, nan});

fittsModelComparisonPlots(resultsDir, sessions);

fittsDynamics( resultsDir, sessions );

fittsModelSweep( resultsDir, sessions );
plotFittsSweep( resultsDir, sessions );
fittsSweepValidation( resultsDir, sessions );
plotFittsSweepValidation( resultsDir, sessions );

T6fittsSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'fittsLaw') & strcmp(vertcat(sessions.subject),'T6'));
makeMovies(resultsDir, T6fittsSessions(3:end), {NaN,NaN});

T8fittsSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'fittsLaw') & strcmp(vertcat(sessions.subject),'T8'));
prepareArmMovies(resultsDir, sourceFileDirs, T8fittsSessions, {NaN,NaN});

exponentFitts(resultsDir, sessions);

fittsLawPaperFigures_v4( resultsDir, sessions )
%%
%neural tuning and raster plots
singleVsMultiEncoding_realData_v2(resultsDir, sessions(strcmp(vertcat(sessions.conditionTypes),'gainSmoothing')));

topNSearch(resultsDir, sessions);
plotTopNSearch(resultsDir, sessions);

topNSearch_crossBlock(resultsDir, sessions);
plotTopNSearch_crossBlock(resultsDir, sessions);

channelDropCurves(resultsDir, sessions);
channelDropCurvesMag(resultsDir, sessions);
channelDropCurvesSimple(resultsDir, sessions(strcmp(vertcat(sessions.conditionTypes),'fittsLaw')));
plotChannelDropCurves(resultsDir, sessions);
simulatedDroppingCurves(resultsDir);

noiseCorrMat(resultsDir, sessions);

makeBCSimTuningSummaries(resultsDir, sessions);
vectorAndScalarTuning(resultsDir, sessions);
plotVectorAndScalarTuning(resultsDir, sessions);
residualTargDistTuning(resultsDir, sessions);
neuronHeatMaps(resultsDir, sessions, 'predictSubtract');
neuronHeatMaps(resultsDir, sessions, 'model');
neuronHeatMaps(resultsDir, sessions, 'modelVectorOnly');
neuronHeatMaps(resultsDir, sessions, 'normal');
plotHeatMaps(resultsDir, sessions);

atTargetEncoding(resultsDir, sessions);
plotAtTargetEncoding(resultsDir, sessions);
plotBCSimTuning(resultsDir, sessions);
plotGoalEncoding(resultsDir, sessions);
plotBCSimRasters(resultsDir, sessions);

gainSmoothSessions = strcmp(vertcat(sessions.conditionTypes),'gainSmoothing');
cVecDecoderBuilding(resultsDir, sessions(gainSmoothSessions));
cVecDecoderEval(resultsDir, sessions(gainSmoothSessions));

crossBlockSquares(resultsDir, sessions);
plotCrossBlockSquares(resultsDir, sessions);

magnitudeDecoding(resultsDir, sessions);
magnitudeDecoding_3(resultsDir, sessions);

nonlinearDecodingSimpler_v2(resultsDir, sessions);
nonlinearDecodingMaxLik(resultsDir, sessions);
nonlinearDecodingAll(resultsDir, sessions, 'noSmooth');
nonlinearDecodingAll(resultsDir, sessions, 'postSmooth');
nonlinearDecodingAll(resultsDir, sessions, 'preSmooth');

nonlinearDecodingResSimp_v2(resultsDir, sessions, 'noSmooth');
nonlinearDecodingResSimp_v2(resultsDir, sessions, 'postSmooth');
nonlinearDecodingResSimp_v2(resultsDir, sessions, 'preSmooth');

nonlinearDecoding(resultsDir, sessions(~gainSmoothSessions));
nonlinearDecodingResults(resultsDir, sessions(gainSmoothSessions));
nonlinearDecodingSim(resultsDir);
%%
%plot noise models
plotARModels_v2( sessions, resultsDir, {9,'explain'} );
plotSplineModels_v2( sessions, resultsDir, {9,'explain'} );
plotPointModels_v2( sessions, resultsDir, {7,'gsExplain'} );
noiseTypeAnalysis_v2( resultsDir, sessions, vPlans, {NaN, NaN}, {9,'explain'} );

%illustrate the fitting process
exampleFittingFigures( resultsDir, sessions, vPlans, {NaN, NaN}, {9,'explain'} );

%example feedback delay and noise setting changes
exampleDelayAndNoiseTraj(sessions, resultsDir, {7,'gsExplain'});

modelTrajectoryPlots_v2(sessions, resultsDir, {12,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {9,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {1,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {5,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {11,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {16,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {20,'explain'});
modelTrajectoryPlots_v2(sessions, resultsDir, {15,'explain'});


trajectoryPlots_v2(resultsDir, sessions(19), {nan,nan});


%%
%paper figures
modelPaperFigures_v7(sessions, resultsDir);
optiPaperFigures_SciRep(sessions, resultsDir);
