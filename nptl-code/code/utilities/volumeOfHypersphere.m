function V = volumeOfHypersphere( r, D )
    % volume of a sphere of radius r and dimensionality D. See Wikipedia Volume_of_an_n-ball
    % article
    % SDS March 6 2017
    switch D
        case 1
            V = 2*r;
        case 2
            V = pi*r^2;
        case 3
            V = ((4*pi)/3)*r^3;
        case 4
            V = 0.5*(pi^2)*r^4;
        case 5
            V = ((8*pi^2)/15)*r^5;
        case 6
            V = ((pi^3)/6)*r^6;
        otherwise
            error('not implemented for this dimensionality > 6')
    end
end