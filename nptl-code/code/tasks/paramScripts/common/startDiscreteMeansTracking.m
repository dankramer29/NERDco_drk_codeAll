function startDiscreteMeansTracking(doReset, useFastAdapt)

if ~exist('doReset','var')
    doReset = true;
end

if ~exist('useFastAdapt','var')
    useFastAdapt = true;
end

global modelConstants

if useFastAdapt && ~doReset
    warning('startDiscreteMeansTracking: no reason to do fast adapt but not reset means...?');
end

try
    % presumably meansTrackingInitial was loaded above. now reset the
    % meansTracker to take in those values
    setModelParam('discreteMeansTrackingEnable',true);
    switch modelConstants.rig
        case 't6'
            setModelParam('discreteMeansTrackingPeriodMS',120000);
        case 't7'
            setModelParam('discreteMeansTrackingPeriodMS',30000);
    end
    if useFastAdapt
        setModelParam('discreteMeansTrackingUseFastAdapt', true);
    else
        setModelParam('discreteMeansTrackingUseFastAdapt', false);
    end
    if doReset
        setModelParam('discreteMeansTrackingResetToCurrent', true);
        pause(0.01);
        setModelParam('discreteMeansTrackingResetToCurrent', false);
    else
        setModelParam('discreteMeansTrackingResetToInitial', true);
        pause(0.01);
        setModelParam('discreteMeansTrackingResetToInitial', false);        
    end
catch
    disp('startDiscreteMeansTracking: warning: couldn''t set meansTrackingResetToInitial');
end
