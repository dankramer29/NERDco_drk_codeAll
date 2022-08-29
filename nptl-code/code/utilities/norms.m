function cvx_optval = norms(x, p, dim)

%NORMS	Computation of multiple vector norms
%   NORMS( X ) provides a means to compute the norms of multiple vectors
%   packed into a matrix or N-D array. This is useful for performing
%   max-of-norms or sum-of-norms calculations.
%
%   All of the vector norms, including the false "-inf" norm, supported
%   by NORM() have been implemented in the NORMS() command.
%     NORMS(X,P)           = sum(abs(X).^P).^(1/P)
%     NORMS(X)             = NORMS(X,2).
%     NORMS(X,inf)         = max(abs(X)).
%     NORMS(X,-inf)        = min(abs(X)).
%   If X is a vector, these computations are completely identical to
%   their NORM equivalents. If X is a matrix, a row vector is returned
%   of the norms of each column of X. If X is an N-D matrix, the norms
%   are computed along the first non-singleton dimension.
%
%   NORMS( X, [], DIM ) or NORMS( X, 2, DIM ) computes Euclidean norms
%   along the dimension DIM. NORMS( X, P, DIM ) computes its norms
%   along the dimension DIM.
%
%	This function is (c) by Michael C. Grant and Stephen P. Boyd.
%	It has been slightly modified for use outside of the cvx_library.

narginchk( 1, 3 ) ;
if nargin < 2 || isempty( p ),
    p = 2;
elseif ~isnumeric( p ) || numel( p ) ~= 1 || ~isreal( p ),
    error( 'Second argument must be a real number.' );
elseif p < 1 || isnan( p ),
    error( 'Second argument must be between 1 and +Inf, inclusive.' );
end
    
%
% Check third argument
%

sx = size( x );
if nargin < 3 || isempty( dim ),
    dim = cvx_default_dimension( sx );
elseif ~cvx_check_dimension( dim, false ),
    error( 'Third argument must be a valid dimension.' );
elseif isempty( x ) || dim > length( sx ) || sx( dim ) == 1,
    p = 1;
end

%
% Compute the norms
%

switch p,
    case 1,
        cvx_optval = sum( abs( x ), dim );
    case 2,
        cvx_optval = sqrt( sum( x .* conj( x ), dim ) );
    case Inf,
        cvx_optval = max( abs( x ), [], dim );
    otherwise,
        cvx_optval = sum( abs( x ) .^ p, dim ) .^ ( 1 / p );
end

% Copyright 2012 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

end

function y = cvx_default_dimension( sx )

%CVX_DEFAULT_DIMENSION   Default dimension for SUM, MAX, etc. 
%   DIM = CVX_DEFAULT_DIMENSION( SX ), where SX is a size vector, returns
%   the
%   first index DIM such that SX(DIM)>1, if one exists; otherwise, DIM=1.
%   This
%   matches the behavior by functions like SUM, MAX, ANY, ALL, etc. in
%   selecting the dimension over which to operate if DIM is not supplied.
%
%   For example, suppose size(X) = [1,3,4]; then SUM(X) would sum over
%   dimension
%   2; and DIM=CVX_DEFAULT_DIMENSION([1,3,4]) returns DIM=2.
%
%   This is an internal CVX function, and as such no checking is performed
%   to
%   insure that the arguments are valid.

y = find( sx ~= 1 );
if isempty( y ), 
    y = 1; 
else
    y = y( 1 ); 
end

% Copyright 2012 Michael C. Grant and Stephen P. Boyd. 
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.


end

function y = cvx_check_dimension( x, zero_ok )

%CVX_CHECK_DIMENSION   Verifies that the input is valid dimension.
%   CVX_CHECK_DIMENSION( DIM ) verifies that the quantity DIM is valid for
%   use
%   in commands that call for a dimension; e.g., SUM( X, DIM ). In other
%   words,
%   it verifies that DIM is a positive integer scalar.
%
%   CVX_CHECK_DIMENSION( DIM, ZERO_OK ) allows DIM to be zero if ZERO_OK is
%   true. If ZERO_OK is false, the default behavior is used.

if isnumeric( x ) && length( x ) == 1 && isreal( x ) && x < Inf && x == floor( x ),
    if nargin < 2, zero_ok = false; end
    y = x > 0 | zero_ok;
else
    y = 0;
end

% Copyright 2012 Michael C. Grant and Stephen P. Boyd.
% See the file COPYING.txt for full copyright information.
% The command 'cvx_where' will show where this file is located.

end
