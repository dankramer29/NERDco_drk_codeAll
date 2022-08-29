% PrependAndUpdateFields.m
%
% Gives a list of cmoon NPTL R struct continuous fields and time fields that
% can then be fed into PrependPrevTrialRastersAndKin.m to prepend (or append, with a
% different function) the R struct trial with data from the immediatley preceding/next
% trial. This allows to e.g. make smoothed firing rates or estimate LFP power using data
% outside the immediate border of this trial.
%
% USAGE: [ prependFields, updateFields ] = PrependAndUpdateFields(  )
%
% EXAMPLE:
%
% INPUTS:
%
% OUTPUTS:
%     prependFields             
%     updateFields              
%
% Created by Sergey Stavisky on 03 Mar 2019 using MATLAB version 9.3.0.713579 (R2017b)

 function [ prependFields, updateFields ] = PrependAndUpdateFields(  )
    
    % 3 March 2019: Adding just the bare minimum for what I need for the speaking during BCI
    % data. Add more to these later if needed.
    % these are the continuous fields, e.g. neural data or kinematics.
    prependFields = {...
        'minAcausSpikeBand';
        'clock';
        'cursorPosition';
        'state';
    };

    updateFields = {...
        'timeFirstTargetAcquire';
        'timeLastTargetAcquire';
    };
end