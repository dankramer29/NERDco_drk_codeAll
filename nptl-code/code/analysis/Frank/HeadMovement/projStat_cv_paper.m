function [ meanDiff, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv_paper( class1, class2, normSize )
    
    rawProjPoints_1 = zeros(size(class1,1),1);
    rawProjPoints_2 = zeros(size(class1,1),1);
    
    for x=1:size(class1,1)
        trainIdx = setdiff(1:size(class1,1), x);
        interClassLine = mean(class2(trainIdx,:)) - mean(class1(trainIdx,:));
        interClassLine = interClassLine/normSize;
        rawProjPoints_1(x) = class1(x,:) * interClassLine';
        rawProjPoints_2(x) = class2(x,:) * interClassLine';
    end

    mnPoint = mean([rawProjPoints_1; rawProjPoints_2]);
    rawProjPoints_1 = rawProjPoints_1 - mnPoint;
    rawProjPoints_2 = rawProjPoints_2 - mnPoint;

    meanDiff = mean(rawProjPoints_2) - mean(rawProjPoints_1);
end

