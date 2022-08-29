function [ err, projPoints ] = rbFitObjective( observedPoints, focalLen, centerPoint, bodyPoints, T, R )

    K = [focalLen(1), 0;
            0, focalLen(2);
            centerPoint(1), centerPoint(2)];

    nPointsPerBody = size(bodyPoints,1);
    pointIdx = 1:nPointsPerBody;
    projPoints = zeros(size(R,1)*nPointsPerBody, 2);
    for r=1:size(R,1)
        rotMat = angle2dcm(R(r,1), R(r,2), 0);
        projPoints(pointIdx,:) = (bodyPoints*rotMat + T)*K;
        pointIdx = pointIdx + nPointsPerBody;
    end
    
    err = mean(mean(sqrt((observedPoints - projPoints).^2)));
end

