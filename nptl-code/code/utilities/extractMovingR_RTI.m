function R_mtt = extractMovingR_RTI(R)
% extract the parts of R during which cursor is moving closer to target; 
% i.e. those that are relevant for kin decoder build; for creating T in
% onlineTfromR. (Keeping the bigger R with both move and click so can 
% reuse it for click decoder build, rather than re-extracting everything 
% from stream via relabelDataUsingRTI, onlineTfromR, etc.) 

%SELF: most of the code in onlineTfromR is a hairy combination of extracting the relevant data,
%mixed up with downsampling everything by dt. Trying to use it anyway after first creating a
%version of R that *only* contains the moving-toward-target inds so the
%subsampling only occurs for the relevant bits of each trial, and then only extract
%indices the way it's done in onlineTfromR if ~useRTI (like I've done for
%clickState). Only a few of the fields are relevant to the build
%anyway, like Z, X, dt, and maybe T (btw, figure out what T.T is...
%recursive self-reference for sweeping other params or something??)

Rfieldnames = fieldnames(R(1));

for trialIdx = 1:length(R),
    mtt = R(trialIdx).movingTowardTarget;  %moving toward target (logical) inds for this trial
    for fieldIdx = 1:length(Rfieldnames), 
        thisFieldName = Rfieldnames{fieldIdx};
        try
            R_mtt(trialIdx).(thisFieldName) = R(trialIdx).(thisFieldName)(:,mtt);
        catch  %if not of length mtt (e.g. posTarget, trialNum, etc.)
            R_mtt(trialIdx).(thisFieldName) = R(trialIdx).(thisFieldName);
        end
    end
end

