function NF=calcNormFactors(Zp, softNorm)
%% soft norm neural data - taken from jcyk pca code
%rangePerNeuron = range(Zp);
    rangePerNeuron = diff(quantile(Zp,[0.1 0.9]));
    NF = rangePerNeuron + softNorm;
    NF = 1./NF;
