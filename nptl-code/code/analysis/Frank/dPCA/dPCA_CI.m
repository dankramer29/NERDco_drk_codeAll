function [ dimCI ] = dPCA_CI( dPCA_out, features, eventIdx, trlCodes, timeWindow )
    %returns a DIM x FACTOR1 x FACTOR2 X TIME x CI matrix containing 95%
    %confidence intervals for each dPCA dimension, factor, and time step
    nFactors = ndims(dPCA_out.featureAverages)-2;
    nDim = size(dPCA_out.W,2);
    
    if nFactors==1
        codeList = unique(trlCodes);
        dimCI = zeros(nDim,size(dPCA_out.featureAverages,2),size(dPCA_out.featureAverages,3),2);
        for dimIdx=1:nDim
            for conIdx=1:size(dPCA_out.featureAverages,2)
                innerTrlIdx = find(trlCodes==codeList(conIdx));
                concatDat = triggeredAvg( features * dPCA_out.W(:,dimIdx), eventIdx(innerTrlIdx), timeWindow );
                
                [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                dimCI(dimIdx,conIdx,:,:)=MUCI';
            end
        end
    elseif nFactors==2
        code1List = unique(trlCodes(:,1));
        code2List = unique(trlCodes(:,2));
        
        dimCI = zeros(nDim,size(dPCA_out.featureAverages,2),size(dPCA_out.featureAverages,3),size(dPCA_out.featureAverages,4),2);
        for dimIdx=1:nDim
            for conIdx_1=1:size(dPCA_out.featureAverages,2)
                for conIdx_2=1:size(dPCA_out.featureAverages,3)
                    innerTrlIdx = find(trlCodes(:,1)==code1List(conIdx_1) & trlCodes(:,2)==code2List(conIdx_2));
                    concatDat = triggeredAvg( features * dPCA_out.W(:,dimIdx), eventIdx(innerTrlIdx), timeWindow );
                    
                    [MUHAT,SIGMAHAT,MUCI,SIGMACI] = normfit(concatDat);
                    dimCI(dimIdx,conIdx_1,conIdx_2,:,:)=MUCI';
                end
            end
        end
    end
end

