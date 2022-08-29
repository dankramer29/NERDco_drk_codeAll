function [ tPattern ] = ringPattern( nRings, nDirs )
    theta = linspace(0,2*pi,nDirs+1);
    theta = theta(1:(end-1))';
    tPattern = [];
    for n=1:nRings
        tmp = [cos(theta), sin(theta)];
        tPattern = [tPattern; tmp];
    end
end

