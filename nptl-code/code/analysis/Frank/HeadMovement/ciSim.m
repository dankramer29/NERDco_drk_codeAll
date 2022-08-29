nTests = 1000;
allCI = zeros(nTests,6);
for testIdx=1:nTests
    disp(testIdx);
    
    c1 = 0.5*randn(20,100);
    c2 = 0.5*randn(20,100)+0.5;
    nSamples = size(c1,1);

    [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( c1, c2 );
    [allCI(testIdx,1:2), bootStats] = bootci(250,{@lessBiasedDistance, c1, c2},'type','percentile');
    
    allCI(testIdx,3:4) = jackCI_full( lessBiasedEstimate, @lessBiasedDistance, {c1, c2} );
    
    stdErrBoot = std(bootStats);
    allCI(testIdx,5:6) = [lessBiasedEstimate - 1.96*stdErrBoot, lessBiasedEstimate+1.96*stdErrBoot];
end

bad_1 = allCI(:,1)>5 | allCI(:,2)<5;
bad_2 = allCI(:,3)>5 | allCI(:,4)<5;
bad_3 = allCI(:,5)>5 | allCI(:,6)<5;

sum(bad_1)
sum(bad_2)
sum(bad_3)