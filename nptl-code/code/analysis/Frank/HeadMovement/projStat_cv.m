function [ meanDiff, rawProjPoints_1, rawProjPoints_2 ] = projStat_cv( class1, class2 )

    rp1 = randperm(size(class1,1));
    class1 = class1(rp1,:);
    
    rp2 = randperm(size(class2,1));
    class2 = class2(rp2,:);
    
    rawProjPoints_1 = zeros(size(class1,1),1);
    rawProjPoints_2 = zeros(size(class1,1),1);
    
    for x=1:size(class1,1)
        trainIdx = setdiff(1:size(class1,1), x);
        interClassLine = mean(class2(trainIdx,:)) - mean(class1(trainIdx,:));
        interClassLine = interClassLine/norm(interClassLine);
        rawProjPoints_1(x) = class1(x,:) * interClassLine';
        rawProjPoints_2(x) = class2(x,:) * interClassLine';
    end

    mnPoint = mean([rawProjPoints_1; rawProjPoints_2]);
    rawProjPoints_1 = rawProjPoints_1 - mnPoint;
    rawProjPoints_2 = rawProjPoints_2 - mnPoint;

    meanDiff = mean(rawProjPoints_2) - mean(rawProjPoints_1);
end

