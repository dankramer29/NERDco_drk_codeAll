function in =  fit4DimModel_RNN_simple( in )

    %get reaction time
    inForRT = in;
    if isfield(in,'isOuter')
        inForRT.reachEpochs = inForRT.reachEpochs(in.isOuter,:);
        inForRT.reachEpochs_fit = inForRT.reachEpochs_fit(in.isOuter,:);
    end

    possibleRT = 12;
    meanR2 = zeros(length(possibleRT),1);
    for rtIdx = 1:length(possibleRT)
        disp(possibleRT(rtIdx));
        inForRT.rtSteps = possibleRT(rtIdx);

        [inForRT.kin.posErrForFit, inForRT.kin.unitVec, inForRT.kin.targDist, inForRT.kin.timePostGo] = prepKinForModel( inForRT );
        inForRT.modelType = 'FMP';

        fullModel = fitPhasicAndFB_6(inForRT);
        [~,sortIdx] = sort(fullModel.R2Vals,'descend');
        meanR2(rtIdx) = nanmean(fullModel.R2Vals(sortIdx(1:96)));
    end

    [~,maxIdx] = max(meanR2);
    in.rtSteps = possibleRT(maxIdx);
    [in.kin.posErrForFit, in.kin.unitVec, in.kin.targDist, in.kin.timePostGo] = prepKinForModel( in );
    
    in.rt_meanR2 = meanR2;
end

