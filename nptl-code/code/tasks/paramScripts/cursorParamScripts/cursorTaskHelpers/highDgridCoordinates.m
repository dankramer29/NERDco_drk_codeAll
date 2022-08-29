% Helper function that creates the coordinates of Gridlike task targets.
%
% INPUTS:
%        gridBounds  D x 2 matrix of the grid edges along each of D dimensions.
%                    e.g. [-300 300; -300 300; -300 300] for a 3D grid task.
%        N          how many voxels to divide each dimension into. e.g. 6
%                   for a 6x6x6 grid task. 
% OUTPUTS:
%       centers   (N^D) x D array with the center for each of the targets in
%                 the D dimensions.
%       edges     (N+1) x D array with the boundaries along each dimension for
%                 each of the tiles along the d'th dimension. Boundary for
%                 tile index i are [edges(i),edges(i+1)]
%
% Sergey Stavisky, 12 December 2016
function [centers, edges] = highDgridCoordinates( gridBounds, N )
    D = size( gridBounds, 1 ); % number of dimensions
    targInd = 0; % will count up
    
    % edges
    for iDim = 1 : D
        edges(1,iDim) = gridBounds(iDim,1);
        tileWidth = ( gridBounds(iDim,2)-gridBounds(iDim,1) ) / N;
        for iTile = 1 : N
            edges(iTile+1,iDim) =  edges(iTile,iDim) + tileWidth;
        end
    end
    
    % a bit cludgey but easier to interpret than using a dynamic number of
    % for loops...
    switch D
        case 1
            [g{1}] = ndgrid(1:N);
        case 2
            [g{1}, g{2}] = ndgrid(1:N);
        case 3
            [g{1}, g{2}, g{3}] = ndgrid(1:N);
        case 4
            [g{1}, g{2}, g{3}, g{4}] = ndgrid(1:N);
        case 5
            [g{1}, g{2}, g{3}, g{4}, g{5}] = ndgrid(1:N);
        case 6
            [g{1}, g{2}, g{3}, g{4}, g{5}, g{6}] = ndgrid(1:N);
        case 7
            [g{1}, g{2}, g{3}, g{4}, g{5}, g{6}, g{7}] = ndgrid(1:N);
            
        otherwise
            % just continue the pattern from above
            error('need to hard-code ndgrid call for dimensionality %i', D)
    end
    
    centers = nan( N^D, D );
    for iDim = 1 : D
        tileInd = reshape( g{iDim}, [], 1 );
        for iTarg = 1 : numel( tileInd )
            centers(iTarg,iDim) = mean( edges(tileInd(iTarg):tileInd(iTarg)+1,iDim) );
        end
    end
    
end