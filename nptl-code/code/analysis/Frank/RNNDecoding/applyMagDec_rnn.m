function [ decOutScale ] = applyMagDec_rnn( dec, cVecPop, magPop )
    decMag = filter(1-dec.fAlpha,[1, -dec.fAlpha], magPop);
    decCVec = filter(1-dec.fAlpha,[1, -dec.fAlpha], cVecPop);
    decCVecMag = matVecMag(decCVec,2);

    innerDecMag = decMag * dec.rescaleCoef(2) + dec.rescaleCoef(1);
    tmpMag = dec.csWeight*innerDecMag + (1-dec.csWeight)*decCVecMag;
    tmpMag(tmpMag<0)=0;
    decOut = bsxfun(@times, decCVec, tmpMag./decCVecMag);
    decOutScale = decOut * dec.scaleFilt;
end

