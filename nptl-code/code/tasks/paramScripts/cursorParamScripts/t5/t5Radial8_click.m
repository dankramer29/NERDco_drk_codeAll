radial8Task();

%make hold time longer (make it more difficult to acquire target using
%'hold backstop'):
setModelParam('holdTime', 5000);


% forces it to be 2D and also makes SCL cursor task decoders work with a
% high enough gain in pixel land that it's controllable.

% number of trials
setModelParam('numTrials', 220);

% max task duration
setModelParam('maxTaskTime',1000*60*5.1);

%% neural decode
loadFilterParams;

loadDiscreteFilterParams;

enableBiasKiller;
setBiasFromPrevBlock;

doResetBK = true;

gainCorrectDim =  getModelParam('gain');
gainCorrectDim(1) = 4000;
gainCorrectDim(2) = 4000;
% setModelParam('gain', gainCorrectDim); % unlocks cursor
setModelParam('gain', gainCorrectDim); % unlocks cursor

% unpauseOnAny(doResetBK);


%% Click parameters
cursor_click_enable;

% Click Fails
setModelParam('selectionRefractoryMS', uint16( 500 ) ); % grace period. Used for both click and dwell

setModelParam('stopOnClick', double( true ) );
setModelParam('hmmClickSpeedMax', double( inf ) ); % no max speed
% setModelParam('hmmClickSpeedMax', double( 1e-3 ) ); % 

% neural click
% to set threshold to a LL centile:
% updateHMMThreshold(0.89, 0, loadedModel); % open loop training params, prompt for block for recalc of likelihoods
% % % a bit brittle, will fail if hmm wasn't trained this time
% to set threshold to an actual LL value:
curThresh = 0.95;
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables

setModelParam('clickHoldTime', uint16(45)); %number of ms it needs to be clicking to send a click
% setModelParam('hmmClickSpeedMax', double( 5e-5 ) ); 

unpauseOnAny(doResetBK);
