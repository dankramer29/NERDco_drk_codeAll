setModelParam('clickPercentage', 1); % 0 to 1, something to do with dwell vs click
% setModelParam('clickHoldTime', uint16(30)); %number of ms it needs to be clicking to send a click
setModelParam('clickSource', uint16(clickConstants.CLICK_TYPE_NEURAL));

% setModelParam('hmmClickSpeedMax', 0.6); % above this speed, it cannot click. 
                                        % Needs to be adjusted for new
                                        % coordinate systems.
                                        % currently the t5 scripts just
                                        % overwrite this.
% the hmmResetOnFast is causing bad behavior. just cut it.
setModelParam('hmmResetOnFast',false)
