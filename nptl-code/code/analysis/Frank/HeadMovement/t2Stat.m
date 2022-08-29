function [ testStat ] = t2Stat( class1, class2 )
    class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
    class1 = class1(randi(size(class1,1), size(class1,1), 1),:);

    meanDiff = mean(class2) - mean(class1);
    sampleCov1 = cov(class1);
    sampleCov2 = cov(class2);
    pooledCov = (sampleCov1 + sampleCov2)/2;
    testStat = meanDiff*inv(pooledCov)*meanDiff';
end

