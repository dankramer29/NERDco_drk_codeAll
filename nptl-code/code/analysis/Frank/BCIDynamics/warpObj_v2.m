function [ matchErr, warpCurve, h ] = warpObj_v2( curve, target, lambda, coefKnots, coef )
    
    tAxis = 1:length(curve);
    intW = interp1(coefKnots, coef, tAxis);
    dSquared = mean(diff(intW).^2);
    
    h = cumsum(exp(intW));
    h = h - h(1);
    h = h/h(end);
    
    warpCurve = interp1(tAxis, curve, (h*(length(tAxis)-1)+1));
    matchErr = mean((warpCurve(:) - target(:)).^2) + dSquared*lambda;
end

