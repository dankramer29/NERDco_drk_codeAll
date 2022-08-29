function [ meanDiff ] = normStat( class1, class2 )
    meanDiff = norm(mean(class2) - mean(class1));
end

