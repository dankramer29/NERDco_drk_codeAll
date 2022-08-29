function [ mag ] = matVecMag( mat, dim )
    if length(size(mat))>2
        error('Cannot use on matrices bigger than 2 dimensions');
    end
    
    mag = sqrt(sum(mat.^2,dim));
end

