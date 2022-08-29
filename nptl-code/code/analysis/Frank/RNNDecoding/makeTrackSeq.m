angles = linspace(0,2*pi,9);
angles = angles(1:(end-1));
targList = [cos(angles)', sin(angles)'];
targList = [targList*0.5; targList*1.0; targList*2.0];

nCursorDim = 2;
nOutputFactors = 20;
nSteps = 250;

targSeq = zeros(nCursorDim, nSteps, size(targList,1));
for t=1:size(targList,1)
    targSeq(:,50:end,t) = repmat(targList(t,:), nSteps-49, 1)';
end

noiseSeq = randn(nOutputFactors, nSteps, size(targList,1));
save('/Users/frankwillett/Data/Derived/gruCLTest_free/trackSeq.mat','targSeq','noiseSeq');