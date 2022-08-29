function [ data ] = formatRadial8( data )   
    data.outerTargCodes = [9 8 6 3 1 2 4 7];
    data.isOuterReach = ismember(data.targCodes, [1 2 3 4 6 7 8 9]);
end

