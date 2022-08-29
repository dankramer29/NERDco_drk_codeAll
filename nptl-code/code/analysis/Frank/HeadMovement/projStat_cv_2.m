function [ meanDiff, rawProjPoints ] = projStat_cv_2( data, dataLabels )

    rawProjPoints = zeros(size(data,1),1);    
    for x=1:size(data,1)
        trainIdx = setdiff(1:size(data,1), x);
        class1 = data(intersect(trainIdx, find(dataLabels==1)),:);
        class2 = data(intersect(trainIdx, find(dataLabels==2)),:);

        interClassLine = mean(class2) - mean(class1);
        interClassLine = interClassLine/norm(interClassLine);
        rawProjPoints(x) = data(x,:) * interClassLine';
    end

    mnPoint = mean(rawProjPoints);
    rawProjPoints = rawProjPoints - mnPoint;

    meanDiff = mean(rawProjPoints(dataLabels==2,:)) - mean(rawProjPoints(dataLabels==1,:));
end

