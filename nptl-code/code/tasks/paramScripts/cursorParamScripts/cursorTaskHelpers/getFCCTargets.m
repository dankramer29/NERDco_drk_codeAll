function [ X ] = getFCCTargets( nTargets, r )
% Return a set of optimal FCC keyboard targets in the radi
%   Input:  nTargets - number of targets (more sets will be added in the future)
%           r - targets size (sphere radius)
%   Output: X - matrix of targets' coordinate (x,y,z) [nTargets X 3]
showLocations = true; % whether to throw up a figure showing target centers.        
switch nTargets
    case 13
      X = r * [-1.0000    0.5774   -1.6330;
                0.0000   -1.1547   -1.6330;
                1.0000    0.5774   -1.6330;
               -1.0000   -1.7321   -0.0000;
               -2.0000    0.0000   -0.0000;
               -1.0000    1.7321   -0.0000;
                1.0000   -1.7321   -0.0000;
                0.0000    0.0000   -0.0000;
                1.0000    1.7321   -0.0000;
                2.0000    0.0000   -0.0000;
               -1.0000   -0.5774    1.6330;
                0.0000    1.1547    1.6330;
                1.0000   -0.5774    1.6330;];
    otherwise
        disp(['Choose a number of target from the list: 13'])
end
   
if showLocations
    figure; hold on;
    theta = 0:0.01:2*pi;
    rTrg = 1.1;
    for i=1:size(X,1)
        x = X(i,:);
        plot3(x(1) + sin(theta)*rTrg, x(2) + cos(theta)*rTrg, x(3)+zeros(size(theta)),'k');
    end
end

end

