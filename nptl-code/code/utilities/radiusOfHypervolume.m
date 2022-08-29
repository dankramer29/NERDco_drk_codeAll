function r = radiusOfHypervolume( V, D )
    % radius of a sphere of volume V and dimensionality D. See Wikipedia Volume_of_an_n-ball
    % article
    % SDS March 6 2017
    switch D
        case 1
            r = V/2;
        case 2
            r = V^(1/2)/sqrt(pi);
        case 3
            r = ( (3*V)/(4*pi) )^(1/3);
        case 4
            r = ( (2*V)^0.25 ) / sqrt( pi );
        case 5
            r = ( (15*V)/(8*pi^2) )^(1/5);
        case 6
            r = ( (6*V)^(1/6) ) / sqrt(pi);
        otherwise
            error('not implemented for dimensionality > 6')
    end
end