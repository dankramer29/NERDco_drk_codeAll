setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));


%setModelParam('mouseOffset', [0 0 0 0]);  % why did this change?
setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetDevice', uint16(linuxConstants.DEVICE_HIDCLIENT));
setModelParam('screenUpdateRate', uint16(10));  %every 10 ms


setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setModelParam('hmmClickSpeedMax', 0.6);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('stopOnClick', true);

setModelParam('xpcVelocityOutputPeriodMS', 1);
% setModelParam('gain', [1 -1 0 0 0]);  %probably not needed - autobot &
% vcs seem to be inverted
setModelParam('gain', [1 1 0 0 0]);

%% change velScaling to scale gain on touchpad cursor
% velScaling = 5000;  %BJ: this needed to be made higher for new decoder vel units! 
                    %was: 0.85; 
velScaling = 4000;     %BJ: this needed to be made higher for new decoder vel units! 
%                     %was: 0.85; 

% doResetBK = true;
% unpauseOnAny(doResetBK);    %SELF: does this being 'true' not undo getting 
%                             %initial bias estimate from previous block?
% 
% CP: scaleXk DOES NOT play nicely with bias estimate, use new "outputVelocityScaling" parameter instead
% setModelParam('outputVelocityScaling',zeros(1,2)+velScaling);
setModelParam('outputVelocityScaling',velScaling);

% %% BJ: our param "gain" appears to make gain feed back on itself, causing 
% %infinite speeds rapidly! don't touch this for linux -> tablet! 
% (SELF: but can I use nonlinear gain??)
% % Linear gain?
% gain_x = 1; %0.7;
% gain_y = gain_x;
% gain_z = gain_x;
% gain_r = gain_x;
% gain = getModelParam('gain');
% % gain(1:4) = [gain_x gain_y gain_z gain_r];
% gain(1:4) = [gain_x gain_y gain_z gain_r]; 
% setModelParam('gain', gain);
% 
% % Exponetial gain? (SELF: not working yet here; does "game" need to accommodate this?)
% setModelParam('powerGain', 2)
% % setModelParam('powerGainUnityCrossing', 4.50e-05)
% setModelParam('powerGainUnityCrossing', 2e-05)
% 

%% neural decode
loadFilterParams;

% neural click
loadDiscreteFilterParams;


setModelParam('clickHoldTime', uint16(30));

% updateHMMThreshold(0.95, 0, loadedModel);  %set threshold to 95th percentile
% BJ: This would normally happen inside updateHMMThreshold: 
% modelConstants.sessionParams.hmmQ = hmmQ; % set gobal hmmQ (do I have to?)
% curThresh = quantile(likelihoods, hmmQ);
% fprintf(1, 'Setting HMM quantile to q%01.2f ...', hmmQ);
% modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
% setHMMThreshold(curThresh); % push variables
%but instead I want to set absolute LL threshold itself so can stay
%constant across blocks in which I'm comparing different state decoders:
curThresh = 0.89;
fprintf(1, 'Setting absolute HMM likelihood threshold to %01.2f ...', curThresh);
modelConstants.sessionParams.hmmClickLikelihoodThreshold = curThresh;
setHMMThreshold(curThresh); % push variables
%SELF: do I need to set modelConstants.sessionParams.hmmQ for anything?
%(maybe for purpose of consistency and not making analysis confusing, could 
%figure out the quantile corresponding to LL = curThresh and set that too.) 

enableBiasKiller(1.5e-04);  %now takes threshold as input (in case speeds for different games can be in different units)
setBiasFromPrevBlock();

doResetBK = true;
unpauseOnAny(doResetBK);    %SELF: does this being 'true' not undo getting 
                            %initial bias estimate from previous block?

