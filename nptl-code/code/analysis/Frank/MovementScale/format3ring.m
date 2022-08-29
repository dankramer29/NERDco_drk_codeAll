function [ data ] = format3ring( data )
    
    data.targCodes(data.targCodes==25) = 0;
    data.targCodes(data.targCodes>25) = data.targCodes(data.targCodes>25)-1;
    data.targList(25,:) = [];
    
    theta = linspace(0,2*pi,17);
    theta = theta(1:16);
    dirVectors = [cos(theta)', sin(theta)'];
    dirVectors = [dirVectors*120; dirVectors*80; dirVectors*40];
    orderedIdx = zeros(48,1);
    for d=1:size(dirVectors,1)
        tmp = bsxfun(@plus, dirVectors(d,:), -data.targList(:,1:2));
        [~,minIdx] = min(sqrt(sum(tmp.^2,2)));
        orderedIdx(d) = minIdx;
    end
    
    data.outerRingCodes = orderedIdx(1:16);
    data.middleRingCodes = orderedIdx(17:32);
    data.innerRingCodes = orderedIdx(33:48);
    
    data.dirGroups = cell(16,1);
    for d=1:16
        data.dirGroups{d} = [data.innerRingCodes(d), data.middleRingCodes(d), data.outerRingCodes(d)];
    end
    
    data.dirTheta = theta;
    data.withinDirDist = [40,80,120];
    data.isOuterReach = data.targCodes ~= 0;  
    
end

