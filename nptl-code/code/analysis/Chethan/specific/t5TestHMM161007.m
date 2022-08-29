setupRigForPreviousSession('t5161007');

% block 2 was a retraining block in which HMM was not performing
% particularly well

[D, R] = decodeBlockWithDiscreteFilter(2);