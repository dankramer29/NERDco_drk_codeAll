function [ diffNorm, rawProjPoints_1, rawProjPoints_2 ] = cvMeanDiffMagnitude_unbiased( class1, class2 )
    
    allSquareEst = zeros(size(class1,1),1);
    rawProjPoints_1 = zeros(size(class1,1),1);
    rawProjPoints_2 = zeros(size(class1,1),1);
    
    for x=1:size(class1,1)
        trainIdx = setdiff(1:size(class1,1), x);
        classDiff = mean(class2(trainIdx,:)) - mean(class1(trainIdx,:));
        allSquareEst(x) = (class2(x,:)-class1(x,:))*classDiff';
    end
    
    mnSquare = mean(allSquareEst);
    diffNorm = sign(mnSquare)*sqrt(abs(mnSquare));

    for x=1:size(class1,1)
        trainIdx = setdiff(1:size(class1,1), x);
        interClassLine = mean(class2(trainIdx,:)) - mean(class1(trainIdx,:));
        interClassLine = interClassLine/diffNorm;
        rawProjPoints_1(x) = class1(x,:) * interClassLine';
        rawProjPoints_2(x) = class2(x,:) * interClassLine';
    end

    mnPoint = mean([rawProjPoints_1; rawProjPoints_2]);
    rawProjPoints_1 = rawProjPoints_1 - mnPoint;
    rawProjPoints_2 = rawProjPoints_2 - mnPoint;
end

