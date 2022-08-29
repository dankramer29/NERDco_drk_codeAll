function [ CI ] = jackCI_raw( trueS, jackS )
    N = size(jackS,1);
    %ps = N*trueS - (N-1)*jackS;
    ps = jackS;
    v = var(ps);
    
    CI = [mean(ps) - 1.96*sqrt(v); mean(ps) + 1.96*sqrt(v)];
end

