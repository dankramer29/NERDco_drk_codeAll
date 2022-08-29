% CAN DELETE THIS, THIS IS EXTERNAL TEST FOR WHAT WILL BE A SUBFUNCTION

function eachDimTile = whichGridlikeTile( effectorPos, gridEdges, tilesEachDim )
    % This function is used during the 'gridlike' mode of the cursorTask.
    % It computes, based on the position of the effector, which 'tile' that
    % the high-dimensional 'grid' has been partitioned into the effector is
    % currently in. This is returned as <eachDimTime>, a set of tile coodinates, one for
    % each (active) dimension of the task. Tile coordinates correspond to
    % edges (again in each active dimension) of each tile, which is in
    % <gridEdges>.
    % returning all zeros means effector is not in any of the tiles.
    % Sergey Stavisky Dec 13 2016
    
    eachDimTile = uint16( zeros( size( tilesEachDim ) ) );
    for iDim = 1 : numel( tilesEachDim ) % loop across dimensions
        if tilesEachDim(iDim) > 0
            
            % Which tile am I in?            
            myTile = find( ( effectorPos(iDim) > gridEdges(1:tilesEachDim(iDim),iDim) ) & ...
                ( effectorPos(iDim) <= gridEdges(2:tilesEachDim(iDim)+1,iDim) ) );
            if isempty( myTile )
                % not in any tile for this dimension, which means not in
                % any tiles
                eachDimTile = uint16( zeros( size( tilesEachDim ) ) );
                break                
            else
                eachDimTile(iDim) = myTile;
            end
        else
            % do nothing, nextTarget(iDim) stays how it
            % was initialized, presumably 0
        end
    end
end