function [ cVec ] = applyPiecewiseModel( model, posHat, velHat, targPos )
    dist = matVecMag(targPos - posHat, 2);
    speed = matVecMag(velHat, 2);
    
    toTargVec = bsxfun(@times, (targPos - posHat), 1./dist);
    velVec = bsxfun(@times, velHat, 1./speed);
    toTargVec(dist==0,:) = 0;
    velVec(speed==0,:)=0;

    distWeight = interp1([-0.01 model.fTargX 10*model.fTargX(end)], [model.fTargY(1) model.fTargY model.fTargY(end)], dist,'linear','extrap');
    distWeight(distWeight<0) = 0;
    if ~isempty(model.fVelX)
        speedWeight = interp1([-0.01 model.fVelX 10*model.fVelX(end)], [model.fVelY(1) model.fVelY model.fVelY(end)], speed,'linear','extrap');
        speedWeight(speedWeight>0) = 0;
    end
    
    cVec = zeros(size(posHat));
    cVec = cVec + bsxfun(@times, toTargVec, distWeight);
    if ~isempty(model.fVelX)
        cVec = cVec + bsxfun(@times, velVec, speedWeight);
    end
    cVec = bsxfun(@plus, cVec, model.bias(1,:));
end

function [ mag ] = matVecMag( mat, dim )
    if length(size(mat))>2
        error('Cannot use on matrices bigger than 2 dimensions');
    end
    mag = sqrt(sum(mat.^2,dim));
end
