% Helper function that returns a list of <N> target diameters that scale by
% <scaleEachStep> in hypervolume relative to <smallestDiameter>'s
% hypervolume.
%
% INPUTS:
%        smallestDiameter   Diameter of the smallest target
%        N                  How many "steps" up in size to go.
%        numDims            Dimensionality (e.g. 3 for 3D, 4 for 4D).
%
% OUTPUTS:
%       diameters      Nx1 list of target diameters.
%       hypervolumes   Nx1 list of hypervolumes
% Sergey Stavisky, 6 March 2017
function [diameters, hypervolumes] = targetDiameterListByHypervolume( smallestDiameter, N, numDims, scaleEachStep )
    if nargin < 4
        scaleEachStep = 2; % double each time
    end
    
    initialVolume = volumeOfHypersphere( (smallestDiameter/2), numDims );
    hypervolumes(1) = initialVolume;
    diameters(1) = smallestDiameter;
    
    for i = 2 : N
        hypervolumes(i) = initialVolume* (scaleEachStep^(i-1));
        diameters(i) = 2*radiusOfHypervolume( hypervolumes(i), numDims );
    end

end

