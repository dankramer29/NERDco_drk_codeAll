function [ model ] = scaleHMMClickCovar( model, scalefactor, whichState)

covar = model.emisCovar(whichState,:,:);
covar = covar*scalefactor;
numDims = model.numDimensionsToUse;
model.emisCovar(whichState,:,:) = covar;
model.emisCovarInv(whichState,:,:) = pinv(squeeze(covar));
model.emisCovarDet(whichState) = det(squeeze(covar(1,1:numDims,1:numDims)));
