function startContinuousMeansTracking(doReset, useFastAdapt)

if ~exist('doReset','var')
    doReset = true;
end

if ~exist('useFastAdapt','var')
    useFastAdapt = true;
end

global modelConstants

if useFastAdapt && ~doReset
    warning('startContinuousMeansTracking: no reason to do fast adapt but not reset means...?');
end

try
    % presumably meansTrackingInitial was loaded above. now reset the
    % meansTracker to take in those values
    setModelParam('meansTrackingEnable',true);
    switch modelConstants.rig
        case 't5'
            setModelParam('meansTrackingPeriodMS',90000);
        case 't6'
            setModelParam('meansTrackingPeriodMS',60000);
        case 't7'
            setModelParam('meansTrackingPeriodMS',30000);
    end
    if useFastAdapt
        setModelParam('meansTrackingUseFastAdapt', true);
    else
        setModelParam('meansTrackingUseFastAdapt', false);
        
    end
    if doReset
        setModelParam('meansTrackingResetToCurrent', true);
        pause(0.01);
        setModelParam('meansTrackingResetToCurrent', false);
    else
        setModelParam('meansTrackingResetToInitial', true);
        pause(0.01);
        setModelParam('meansTrackingResetToInitial', false);
    end
catch
    disp('startContinuousMeansTracking: warning: couldn''t set meansTrackingResetToInitial');
end