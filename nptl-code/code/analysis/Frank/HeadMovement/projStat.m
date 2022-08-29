function [ meanDiff ] = projStat( class1, class2 )
    interClassLine = mean(class2) - mean(class1);
    interClassLine = interClassLine/norm(interClassLine);
    rawProjPoints_1 = class1 * interClassLine';
    rawProjPoints_2 = class2 * interClassLine';

    mnPoint = mean([rawProjPoints_1; rawProjPoints_2]);
    rawProjPoints_1 = rawProjPoints_1 - mnPoint;
    rawProjPoints_2 = rawProjPoints_2 - mnPoint;

    meanDiff = mean(rawProjPoints_2) - mean(rawProjPoints_1);
end

