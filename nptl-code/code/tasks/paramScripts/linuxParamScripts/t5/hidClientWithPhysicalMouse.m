setModelParam('pause', true)
setModelParam('taskType', uint32(linuxConstants.TASK_FREE_RUN));

setModelParam('inputType', uint32(cursorConstants.INPUT_TYPE_MOUSE_RELATIVE));


setModelParam('mouseOffset', [0 0]);
setModelParam('workspaceY', double([-540 540]));
setModelParam('workspaceX', double([-960 960]));

setModelParam('targetDevice', uint16(linuxConstants.DEVICE_HIDCLIENT));
setModelParam('screenUpdateRate', 10);


setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_MOUSE));

setModelParam('hmmClickSpeedMax', 0.2);
setModelParam('clickRefractoryPeriod', 1000);
setModelParam('stopOnClick', true);

%% change velScaling to scale gain on touchpad cursor
velScaling = 1;

%% CP: scaleXk DOES NOT play nicely with bias estimate, use new "outputVelocityScaling" parameter instead
%setModelParam('scaleXk', [1 1 velScaling velScaling 1]);
%setModelParam('outputVelocityScaling',zeros(1,2)+velScaling);
setModelParam('outputVelocityScaling',velScaling);



%updateHMMThreshold(0.92, 0);
setModelParam('clickHoldTime', uint16(8));


enableBiasKiller();
%setModelParam('biasCorrectionVelocityThreshold',0.01);
setModelParam('biasCorrectionVelocityThreshold',0.2);

setBiasFromPrevBlock();


disp('press any key to unpauseExpt');
pause();

resetBiasKiller();
biasKillerPauseUpdate();

unpauseExpt();
