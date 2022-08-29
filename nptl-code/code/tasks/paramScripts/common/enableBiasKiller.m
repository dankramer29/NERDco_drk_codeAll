function enableBiasKiller(BKthresh, BKtau, frwMode, beta)

%% enable bias killer, with optional input of BK threshold
% setModelParam('biasCorrectionVelocityThreshold',0.1);
% setModelParam('biasCorrectionTau',30000);
% setModelParam('biasCorrectionEnable',true);


% setModelParam('biasCorrectionType', uint16(DecoderConstants.BIAS_CORRECTION_FRANK));
% setModelParam('biasCorrectionVelocityThreshold',0.35);
% setModelParam('biasCorrectionTau',30000);

%% enable bias killer
% Important: if using meters as meters/second units, as we do in SCL, then
% Frank's method, which squares the numbers, makes small numbers *really*
% small and thus it seems like Bias Killer is doing almost nothing. So,
% unless runnign in pixel units or something else where velocity > 1, use
% Beata's method or create some new method that treats higher speeds as
% more MORE influencial but doesn't use square.
% BJ & SDS Feb 2017

% set defaults for inputs:
if ~exist('frwMode', 'var') || isempty(frwMode), 
    frwMode = false; 
end

if ~exist('BKthresh', 'var') || isempty(BKthresh),
    % SDS April 5 2017:trying for roughly 66th percentile
    if exist('beta','var')
        BKthresh = (beta/1000)*0.4;
    else
        BKthresh = 4e-5;
    end
    % This threshold is checked against PRE-GAIN speed.
end

if ~exist('BKtau', 'var') || isempty(BKtau),
    BKtau = 30000;  %in ms
end


if frwMode, %Scale-corrected version of Frank's bias killer 
    %adds a scale factor so that the max speed (defined by beta) maps to 
    %itself when passed through the squaring function.
    setModelParam('biasCorrectionType', uint16(DecoderConstants.BIAS_CORRECTION_FRANK));
    setModelParam('biasCorrectionVelocityThreshold', 0);    
    setModelParam('biasCorrectionTau', 7500*(beta/1000))
else        %Beata's bias killer
    setModelParam('biasCorrectionType', uint16(DecoderConstants.BIAS_CORRECTION_BEATA));
    % setModelParam('biasCorrectionType', uint16(DecoderConstants.BIAS_CORRECTION_SERGEY));
    % setModelParam('biasCorrectionPower', 1.3); %power used for BIAS_CORRECTION_SERGEY
    setModelParam('biasCorrectionVelocityThreshold', BKthresh);    
    setModelParam('biasCorrectionTau', BKtau);  %SDS Apparently this really is in ms, the previous /15 was wrong. Did something change?!
end

setModelParam('biasCorrectionInitial',zeros(double(xkConstants.NUM_STATE_DIMENSIONS),1)); % SDS July 2016
% setModelParam('biasCorrectionInitial',[0; 0]);

% setModelParam('biasCorrectionMeansTau',1000);  %BJ: What is this? Doesn't seem to do anything??
 
% bi = [-1 1 -1 1] .*0.25;
% setModelParam('biasCorrectionInitialMeans',bi);

setModelParam('biasCorrectionResetToInitial',true);
pause(0.1);
setModelParam('biasCorrectionResetToInitial',false);

setModelParam('biasCorrectionEnable',true);