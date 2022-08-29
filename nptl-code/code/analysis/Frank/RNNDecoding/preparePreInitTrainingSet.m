%prepare dataset for training pre-initialized networks for the CL
%optimization

%%
%control network
pwX = [         0
    0.0909
    0.1818
    0.2727
    0.3636
    0.4545
    0.5455
    0.6364
    0.7273
    0.8182
    0.9091
    1.0000
    1.01];
pwY = [       0
    0.3999
    0.6842
    0.7434
    0.8041
    0.8646
    0.9088
    0.9455
    0.9668
    0.9913
    1.0101
    1.0101
    1.0101];

controlNetInput = randn(3000,4);
posErrMag = matVecMag(controlNetInput(:,1:2),2);
controlMag = interp1(pwX, pwY, posErrMag, 'linear','extrap');
controlNetOutput = bsxfun(@times, controlNetInput(:,1:2), controlMag./matVecMag(controlNetInput,2));

%%
%forward model network

%%
%decoder network
