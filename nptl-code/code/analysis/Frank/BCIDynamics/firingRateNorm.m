encMatrix = randn(100,2);
command = [ones(1000,1), zeros(1000,1)];
command = [command; [zeros(1000,1), ones(1000,1)]];
command = [command; [ones(1000,2)]];

neural = encMatrix*command';
neural = neural';
neural = bsxfun(@times, neural, 1./matVecMag(neural,2));

decVec = neural * encMatrix;
