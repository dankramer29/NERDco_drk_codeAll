function ang = findAngle(A,B,want_sign)
% findAngle Finds angle between vectors in A and B.
%
% ANG = findAngle(A,B,WANT_SIGN) A and B are the vectors to be compared. 
% Must both be MxN, where N is the dimension of the vectors (e.g. for 
% pd's, M is the number of cells, and N is the number of movement 
% dimensions). If one or both vectors is the zero vector, the angle 
% returned is zero. Returns angle in degrees.
%
% If WANT_SIGN = 1 (default = 0), adds a sign to each angle,  
% + for clockwise, - for counterclockwise going from A to B. 
%
% BJ, 2004

if ~exist('want_sign', 'var') || isempty(want_sign),
    want_sign = 0;
end
    
M_A = length(A(:,1));
M_B = length(B(:,1));

N_A = length(A(1,:));
N_B = length(B(1,:));

if (M_A ~= M_B) || (N_A ~= N_B),
    error('A and B must be the same size.')
end

ang = [];
for i = 1:M_A,
	a = A(i,:);
	b = B(i,:);
	dp=dot(a,b);
	mag_a = sqrt( sum( a.^2));
	mag_b = sqrt( sum( b.^2));
	magnitudes = mag_a * mag_b;
    if magnitudes == 0,
        ang_rad = NaN;
    else
		ang_rad = acos(dp/magnitudes);
        ang_rad = real(ang_rad);
        if ang_rad < 10^-5, %sometimes happens for zero angles because all the mathematical computations keep increasing rounding error 
            ang_rad = 0;
        end
    end
    ang = [ang; rad2deg(ang_rad)];
    
    if want_sign, 
        %use cross product to get sign. only works in R3; if 2D, augment 
        %with a column of 0's; if > 3D, use only first 3D:
        if size(a,2) == 2,
            a = [0 a];
            b = [0 b];
        end
        %use first 3 dims otherwise:
        cab = cross(a(1:3), b(1:3)'); 
        if cab(1) < 0,  %if 1st element of cross-product is negative, define angle as being negative
            ang(end) = 0 - ang(end);
        end
    end        
end

