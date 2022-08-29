function [ targCode ] = getTargetCode( tPos, tPattern )
    targCode = zeros(size(tPos,1),1);
    for t=1:size(tPos,1)
        tmp = bsxfun(@plus, tPos(t,:), -tPattern);
        tmp = sqrt(sum(tmp.^2,2));
        [~,targCode(t)] = min(tmp);
    end
end

