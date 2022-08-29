function [ CI ] = jackCI_full( trueS, dataFun, dataCell )
    N = size(dataCell{1},1);
    
    jackS = zeros(N,1);
    for j=1:N
        keepIdx = setdiff(1:N,j);
        
        deleteCell = dataCell;
        for x=1:length(deleteCell)
            deleteCell{x} = dataCell{x}(keepIdx,:);
        end
        
        jackS(j) = dataFun( deleteCell{:} );
    end
    
    ps = N*trueS - (N-1)*jackS;
    v = var(ps);
    
    CI = [mean(ps) - 1.96*sqrt(v/N); mean(ps) + 1.96*sqrt(v/N)];
end

