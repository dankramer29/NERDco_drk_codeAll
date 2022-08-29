function [ stringCell ] = mat2stringCell( mat, prec )
    stringCell = cell(size(mat));
    if nargin<2
        prec = 4;
    end
    for n=1:numel(mat)
        stringCell{n} = num2str(mat(n), prec);
    end
end

