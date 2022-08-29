function [ stats ] = simulMovePDStat( singleTrlAvg, singleMoveDir, dualTrlAvg, dualMoveDir )
    %compute tuning magnitude ratios and subspace angles
    coef_single = buildLinFilts(singleTrlAvg, [ones(length(singleMoveDir),1), singleMoveDir], 'standard')';

    pValSingle = zeros(size(singleTrlAvg,2),1);
    for x=1:size(singleTrlAvg,2)
        tmpMS = singleTrlAvg(:,x) - mean(singleTrlAvg(:,x));
        [B,BINT,R,RINT,STATS] = regress(tmpMS,singleMoveDir);
        pValSingle(x) = STATS(3);
    end

    %dual movement encoding
    coef_dual = buildLinFilts(dualTrlAvg, [ones(length(dualMoveDir),1), dualMoveDir], 'standard')';

    pValDual = zeros(size(dualTrlAvg,2),1);
    for x=1:size(dualTrlAvg,2)
        tmpMS = dualTrlAvg(:,x) - mean(dualTrlAvg(:,x));
        [B,BINT,R,RINT,STATS] = regress(tmpMS,dualMoveDir);
        pValDual(x) = STATS(3);
    end
    
    %consider significant units only
    sigUnits = find(pValSingle<0.001 | pValDual<0.001);

    %magnitude ratio, subspace angles
    coef_dual_norm = coef_dual(sigUnits,:);
    coef_dual_norm(:,2:end) = coef_dual_norm(:,2:end)./matVecMag(coef_dual_norm(:,2:end),1);

    coef_single_norm = coef_single(sigUnits,:);
    coef_single_norm(:,2:end) = coef_single_norm(:,2:end)./matVecMag(coef_single_norm(:,2:end),1);

    if size(coef_single_norm,2)==5
        subspaceDotEff1 = coef_single_norm(:,2:3)'*coef_dual_norm(:,2:3);
        subspaceDotEff2 = coef_single_norm(:,4:5)'*coef_dual_norm(:,4:5);
    else
        subspaceDotEff1 = coef_single_norm(:,2)'*coef_dual_norm(:,2);
        subspaceDotEff2 = coef_single_norm(:,3)'*coef_dual_norm(:,3);
    end
    
    subAngleEff1 = mean(acosd(diag(subspaceDotEff1)))';
    subAngleEff2 = mean(acosd(diag(subspaceDotEff2)))';
    
    if size(coef_single_norm,2)==5
        magRatioEff1 = mean(matVecMag(coef_dual(sigUnits,2:3),1)./matVecMag(coef_single(sigUnits,2:3),1));
        magRatioEff2 = mean(matVecMag(coef_dual(sigUnits,4:5),1)./matVecMag(coef_single(sigUnits,4:5),1));
    else
        magRatioEff1 = mean(matVecMag(coef_dual(sigUnits,2),1)./matVecMag(coef_single(sigUnits,2),1));
        magRatioEff2 = mean(matVecMag(coef_dual(sigUnits,3),1)./matVecMag(coef_single(sigUnits,3),1));
    end
    
    mnCorrSingle = corr(coef_single(:,2:end));
    mnCorrDual = corr(coef_dual(:,2:end));
    if size(coef_single,2)==3
        mnCorrSingle = mnCorrSingle(1,2);
        mnCorrDual = mnCorrDual(1,2);
    else
        mnCorrSingle = mean([abs(mnCorrSingle(1,3)), abs(mnCorrSingle(2,4))]);
        mnCorrDual = mean([abs(mnCorrDual(1,3)), abs(mnCorrDual(2,4))]);
    end
    
    stats = [magRatioEff1, magRatioEff2, magRatioEff2-magRatioEff1, magRatioEff2./magRatioEff1, subAngleEff1, subAngleEff2, subAngleEff2-subAngleEff1, subAngleEff2./subAngleEff1, ...
        mnCorrSingle, mnCorrDual];
end

