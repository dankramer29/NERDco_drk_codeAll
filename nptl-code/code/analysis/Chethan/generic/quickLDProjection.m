function out = quickLDProjection(Z,softNorm);
% QUICKLDPROJECTION    
% 
% out = quickLDProjection(Z,softNorm);

if ~exist('softNorm','var')
    softNorm = 0.00001;
end

Z=double(Z);
ranges = [min(Z');max(Z')];
isnv = 1./(diff(ranges)+softNorm);
Znorm = bsxfun(@times,Z,isnv(:));
Zmean = mean(Znorm,2);
ZnormMS = bsxfun(@minus,Znorm,Zmean(:));
[pcs, a,b] = pca(ZnormMS');

out.invSoftNormVals = isnv;
out.Znorm = Znorm;
out.pcaMeans = Zmean;
out.ZnormMS = ZnormMS;
out.projector = pcs(:,1:20);
out.varCaptEachPC = b(1:20);