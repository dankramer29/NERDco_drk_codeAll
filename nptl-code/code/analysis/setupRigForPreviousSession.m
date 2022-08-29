function setupRigForPreviousSession(runID)
% function analyzePreviousSession(runID)
%   run ID can be full or trimmed runID
%   (i.e., both
%     analyzePreviousSession('t5161007')
%   or
%     analyzePreviousSession('t5.2016.10.07')
%   are acceptable

[runID runIDtrim] = parseRunID(runID);

global modelConstants
participant = runID(1:2);
modelConstants.sessionRoot = sprintf('/net/experiments/%s/%s/', ...
                                     participant, runID);
