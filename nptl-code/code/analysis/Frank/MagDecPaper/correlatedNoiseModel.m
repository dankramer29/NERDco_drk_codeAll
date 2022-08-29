nCells = 100;
nSteps = 10000;

E = randn(nCells, 3)*0.1;
E(:,3) = abs(E(:,3));
Q = eye(nCells);

cVec = randn(nSteps, 2);
cMag = matVecMag(cVec,2);
act = E*[cVec, cMag]' + randn(nCells, nSteps);
act = act';

filts = (E'/Q*E)\(E'/Q);
filts = filts';
decOut = act*filts;

corr(decOut, [cVec, cMag])

vecErr = cVec - decOut(:,1:2);
magErr = cMag - decOut(:,3);
magErrFromVec = cMag - matVecMag(decOut(:,1:2),2);
corr(magErrFromVec, magErr)