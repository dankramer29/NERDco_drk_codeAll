function enableRapidBiasKiller()

%% enable bias killer
setModelParam('biasCorrectionType', uint16(DecoderConstants.BIAS_CORRECTION_FRANK));
% 80% quantile of t7.2014.12.04 - 005 = 0.28
% 80% quantile of t7.2014.12.08 - 005 = 0.34
setModelParam('biasCorrectionVelocityThreshold',0.25);
setModelParam('biasCorrectionTau',10000);

setModelParam('biasCorrectionInitial',[0; 0]);

setModelParam('biasCorrectionMeansTau',1000);

%bi = [-1 1 -1 1] .*0.25;
bi = nan(4,1);
setModelParam('biasCorrectionInitialMeans',bi);
setModelParam('biasCorrectionResetToInitial',true);
pause(0.1);
setModelParam('biasCorrectionResetToInitial',false);

setModelParam('biasCorrectionEnable',true);
