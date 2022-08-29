function [ posErrForFit, unitVec, targDist, timePostGo ] = prepKinForModel_v2( in )
    timePostGo = zeros(size(in.cursorPos,1),2);
    for t=1:size(in.reachEpochs,1)
        loopIdx = in.reachEpochs(t,1):in.reachEpochs(t,2);
        timePostGo(loopIdx,1) = (0:(length(loopIdx)-1));
    end
    timePostGo(:,2) = timePostGo(:,1)*0.02;
    
    targPosForFit = in.targetPos;
    targChangeIdx = find(any(abs(diff(in.targetPos))>0,2));
    

    %apply model to all time periods
    targDist = double(matVecMag(posErrForFit,2));
    unitVec = double(bsxfun(@times, posErrForFit, 1./targDist));
    unitVec(isnan(unitVec)) = 0;
    unitVec(isinf(unitVec)) = 0;
    posErrForFit = double(posErrForFit);
end

