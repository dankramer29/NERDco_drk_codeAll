function out = randomNDbasisVector(N)
%% take the default basis vector and rotate each plane by a random amount

in = NDbasisVector(N);

for ix = 1:N
    for iy = ix+1:N
        theta = rand()*pi/2;
        rot = NDrotationMatrix(N,ix,iy,theta);
        in = rot * in;
    end
end

out = in;