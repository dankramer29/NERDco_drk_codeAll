function [ trlCodes ] = dirTrialBin_pattern( posErr, nDir )
    dir = bsxfun(@times, posErr, 1./matVecMag(posErr,2));
    theta = linspace(0,2*pi,nDir+1);
    theta = theta(1:nDir)';
    dirPattern = [cos(theta), sin(theta)];
    
    trlCodes = zeros(size(posErr,1),1);
    for t=1:length(trlCodes)
        tmp = matVecMag(bsxfun(@plus, dir(t,:), -dirPattern),2);
        [~,trlCodes(t)] = min(tmp);
    end
end

