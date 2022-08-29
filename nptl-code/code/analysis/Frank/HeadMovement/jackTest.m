nTests = 200;
allCI = zeros(nTests,4);
for testIdx=1:nTests
    dat = randn(20,1)+1;
    
    jackS = zeros(length(dat),1);
    for j=1:length(dat)
        keepIdx = setdiff(1:length(dat),j);
        jackS(j) = mean(dat(keepIdx));
    end
    
    allCI(testIdx,1:2) = jackCI( mean(dat), jackS );
    allCI(testIdx,3:4) = jackCI_raw( mean(dat), jackS );
end

bad_1 = allCI(:,1)>1 | allCI(:,2)<1;
bad_2 = allCI(:,3)>1 | allCI(:,4)<1;
