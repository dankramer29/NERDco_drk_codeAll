function out = applyQuickProj(Z,ld);
% APPLYQUICKPROJ    
% 
% out = applyQuickProj(Z,ld);



Z=double(Z);
Znorm = bsxfun(@times,Z,ld.invSoftNormVals(:));
ZnormMS = bsxfun(@minus,Znorm,ld.pcaMeans(:));

out.Znorm = Znorm;
out.ZnormMS = ZnormMS;
