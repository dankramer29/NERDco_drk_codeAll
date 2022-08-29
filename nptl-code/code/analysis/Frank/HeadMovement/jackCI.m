function [ CI ] = jackCI( trueS, jackS )
    N = size(jackS,1);
    ps = N*trueS - (N-1)*jackS;
    v = var(ps);
    
    CI = [mean(ps) - 1.96*sqrt(v/N); mean(ps) + 1.96*sqrt(v/N)];
end

