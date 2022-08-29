function dSize = derivSize(mPCA_cue, alignDat, trlIdx, trlCodes, binMS)
    %derivative size
    nDim = size(mPCA_cue.readoutZ,1);
    nCon = size(mPCA_cue.readoutZ,2);
    timeStep = binMS/1000;

    dSize = zeros(nDim, 1);
    for dimIdx=1:size(mPCA_cue.readoutZ,1)
        tmp = mPCA_cue.readoutZ_unroll(:,dimIdx);
        concatDat = triggeredAvg( tmp, alignDat.eventIdx(trlIdx), [-70,70] );

        allConSqrtMag = zeros(nCon,1);
        for conIdx=1:nCon
            conTrlIdx = find(trlCodes==conIdx);
            concatDat_con = concatDat(conTrlIdx,:);

            foldMag = zeros(size(concatDat_con,1),1);
            for testIdx=1:size(concatDat_con,1)
                trainTrl = [1:(testIdx-1), (testIdx+1):size(concatDat_con,1)];
                testTrl = testIdx;

                train_diff = diff(squeeze(mean(concatDat_con(trainTrl,:))))/timeStep;
                test_diff = diff(concatDat_con(testTrl,:))/timeStep;

                foldMag(testIdx) = train_diff*test_diff';
            end

            meanMag = mean(foldMag);
            sqrtDiffMag = sign(meanMag)*sqrt(abs(meanMag));
            allConSqrtMag(conIdx) = sqrtDiffMag;
        end

        trlCount = zeros(nCon,1);
        for conIdx=1:nCon
            trlCount(conIdx) = length(find(trlCodes==conIdx));
        end
        minCount = min(trlCount);

        unrollConDat = [];
        for conIdx=1:nCon
            conTrlIdx = find(trlCodes==conIdx);
            concatDat_con = concatDat(conTrlIdx,:);

            unrollConDat = [unrollConDat, concatDat_con(1:minCount,:)];
        end

        [ lessBiasedEstimate, meanOfSquares ] = lessBiasedDistance( unrollConDat, zeros(size(unrollConDat)));
        dSize(dimIdx) = mean(allConSqrtMag) / lessBiasedEstimate;
    end
end