function [ matchErr, warpCurve, h ] = warpObj( curve, target, coefKnots, coef )
    
    tAxis = 1:length(curve);
    intW = interp1(coefKnots, coef, tAxis);
    h = cumsum(exp(intW));
    h = h - h(1);
    h = h/h(end);
    
    warpCurve = interp1(tAxis, curve, (h*(length(tAxis)-1)+1));
    matchErr = sum((warpCurve(:) - target(:)).^2);
end

