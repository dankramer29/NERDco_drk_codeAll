addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));
resultsDir = '/Users/frankwillett/Data/CaseDerived/';
sessions = defineAllSessions();

%%
gainSmoothSessions = sessions(strcmp(vertcat(sessions.conditionTypes),'gainSmoothing'));

%%
%try to find the bad channels in T8 we should be excluding
psthSweepForNoise(resultsDir, gainSmoothSessions(10:15));

%%
%block 11 1.27
cVecDecoderBuilding_revision(resultsDir, gainSmoothSessions);
cVecDecoderBuilding(resultsDir, gainSmoothSessions);
cVecDecoderBuilding_GP(resultsDir, gainSmoothSessions);

cVecDecoderEval_revision(resultsDir, gainSmoothSessions, 'Kalman', 'PE_OFC_Separate');
cVecDecoderEval_revision(resultsDir, gainSmoothSessions, 'Kalman', 'PE_OFC_Group_Vis');

cVecDecoderEval_v2(resultsDir, gainSmoothSessions, 'Kalman_oScale', 'PE_OFC_Group_oScale'); %11.5 cm (T6), 11 cm (T8)
cVecDecoderEval_v2(resultsDir, gainSmoothSessions, 'Kalman', 'PE_OFC_Group');
cVecDecoderEval_v2(resultsDir, gainSmoothSessions, 'Kalman', 'PE_OFC_Separate');
cVecDecoderEval_v2(resultsDir, gainSmoothSessions, 'Kalman', 'UnitVec');


cVecDecoderEval(resultsDir, gainSmoothSessions, 'KalmanFixedA', 'PE_OFC_Group');
cVecDecoderEval(resultsDir, gainSmoothSessions, 'KalmanFixedA', 'PE_OFC_Separate');
cVecDecoderEval(resultsDir, gainSmoothSessions, 'GLS', 'PE_OFC_Separate');

decAsmEffectOnOutput(resultsDir, gainSmoothSessions);

%%
decAssumptionsSim_v6;
decSimWithBias;

plotDecAsmSim;

%%
recalibrationRoutineSim;
taskSpecificParamsExample;