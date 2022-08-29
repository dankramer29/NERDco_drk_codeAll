function [ dec ] = buildMagDec_rnn( reachEpochs, posErr, cVecPop, magPop, fAlpha, csWeight )
    %population response SNR
    dist = matVecMag(posErr,2);
    errMat = zeros(length(fAlpha), length(csWeight));
    rescaleCoef = cell(length(fAlpha), length(csWeight));
    scaleFilt = cell(length(fAlpha), length(csWeight));
    rIdx = expandEpochIdx(reachEpochs);
    
    for a=1:length(fAlpha)
        for w=1:length(csWeight)
            decMag = filter(1-fAlpha(a),[1, -fAlpha(a)], magPop);
            decCVec = filter(1-fAlpha(a),[1, -fAlpha(a)], cVecPop);
            decCVecMag = matVecMag(decCVec,2);
            
            fTargModel = fitFTarg(posErr(rIdx,:), decCVec(rIdx,:), 1, 10);
            fScalModel = fitFScal(dist(rIdx), decMag(rIdx), 1, 10);
            rescaleCoef{a,w} = buildLinFilts(fTargModel(:,2), [ones(size(fScalModel,1),1), fScalModel(:,2)], 'standard');
            innerDecMag = decMag * rescaleCoef{a,w}(2) + rescaleCoef{a,w}(1);
            
            coef = [0, 1-csWeight(w), csWeight(w)];
            newMag = coef(1) + coef(2)*decCVecMag + coef(3)*innerDecMag;
            newMag(newMag<0)=0;
            newVec = bsxfun(@times, decCVec(rIdx,:), newMag(rIdx)./decCVecMag(rIdx));
            
            scaleFilt{a,w} = buildLinFilts(posErr(rIdx,:),newVec,'standard');
            scaleVec = newVec * scaleFilt{a,w};
            errMat(a,w) = mean(mean((scaleVec - posErr(rIdx,:)).^2));
        end
    end

    [minErr,minIdx] = min(errMat(:));
    [i,j] = ind2sub(size(errMat), minIdx);
    dec.fAlpha = fAlpha(i);
    dec.csWeight = csWeight(j);
    dec.rescaleCoef = rescaleCoef{i,j};
    dec.minErr = minErr;
    dec.scaleFilt = scaleFilt{i,j};
end

