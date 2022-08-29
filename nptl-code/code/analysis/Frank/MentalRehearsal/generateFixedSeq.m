targPath = generateTargPath(8, 120);

paths = cell(5,1);
for x=1:length(paths)
    paths{x} = zeros(2,20);
end
paths{1}(:,1:8) = [344  -269   412   222  -179     9   128   -57
                  496   334  -383   -74   112   269  -316   494];
paths{2}(:,1:8) = [ -475    80    91  -419   383  -305   345   -19
                    429   -73  -357  -299  -175   181    18   115];              
paths{3}(:,1:8) = [ -15   324   -32   289   139   426  -165  -475    
                    -106   391   406  -209    37    83  -382   433    ];            
paths{4}(:,1:8) = [   -458   240   307  -444   -94  -185   272   428    
                     -248    27   200   348    36   397  -260   341    ];
paths{5}(:,1:8) = [   338   141   234  -366  -243  -403  -347   -28    
                     259   416  -342  -174  -398   450    12   315    ];
                 
sequenceMatrix = single(zeros(50, 2, sequenceConstants.MAX_TARG_IN_SEQ));
for x=1:length(paths)
    sequenceMatrix(x,:,:) = paths{x};
end


