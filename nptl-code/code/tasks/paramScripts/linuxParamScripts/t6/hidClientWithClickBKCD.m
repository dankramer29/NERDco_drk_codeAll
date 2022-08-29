setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_DECODE_V));


setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetDevice', uint16(linuxConstants.DEVICE_HIDCLIENT));
setModelParam('screenUpdateRate', 10);


setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));
setHMMThreshold();
setModelParam('hmmClickSpeedMax', 0.2);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('stopOnClick', true);

%% change velScaling to scale gain on touchpad cursor
velScaling = 0.85;

%% CP: scaleXk DOES NOT play nicely with bias estimate, use new "outputVelocityScaling" parameter instead
%setModelParam('scaleXk', [1 1 velScaling velScaling 1]);
setModelParam('outputVelocityScaling',zeros(1,2)+velScaling);


%% neural decode
loadFilterParams;

% neural click
loadDiscreteFilterParams;


%updateHMMThreshold(0.92, 0);
%setModelParam('clickHoldTime', uint16(8));
setModelParam('clickHoldTime', uint16(30));
updateHMMThreshold(0.80, 0); % set HMM threshold, no prompt for new likelihoods (use last built from buildHMM)


enableBiasKiller();
setBiasFromPrevBlock();

disp('press any key to unpauseExpt');
pause();
resetBiasKiller();

unpauseExpt();

