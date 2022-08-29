function [ cVar, cVar_proj, rawProjPoints ] = singleTrialModulationSize( dPCA_out, movWindow, movCodes )
    %modulation size
    cdIdx = find(dPCA_out.cval.whichMarg==1);
    cdIdx = cdIdx(1:3);
    nTrials = size(dPCA_out.cval.Z_singleTrial,1);

    mov1Activity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,1,movWindow));
    mov2Activity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,2,movWindow));

    dataMatrix = [nanmean(mov1Activity,3); nanmean(mov2Activity,3)];
    dataLabels = zeros(nTrials*2,1);
    dataLabels(1:nTrials) = 1;
    dataLabels((nTrials+1):end) = 2;

    badIdx = find(any(isnan(dataMatrix),2));
    dataMatrix(badIdx,:) = [];
    dataLabels(badIdx,:) = [];

    dm1 = dataMatrix(dataLabels==1,:);
    dm2 = dataMatrix(dataLabels==2,:);
    minLen = min(size(dm1,1), size(dm2,1));
    dm1 = dm1(1:minLen,:);
    dm2 = dm2(1:minLen,:);

    %single trial projection metric       
    dataMatrix_to = squeeze(dPCA_out.cval.Z_trialOrder(:,cdIdx,movWindow));
    dataMatrix_to = nanmean(dataMatrix_to,3);
    [~,~,dataLabels_to] = unique(movCodes);
    [cVar_proj(1), rpp] = projStat_cv_2(dataMatrix_to, dataLabels_to);
    
    rawProjPoints = cell(2,1);
    rawProjPoints{1} = rpp(dataLabels_to==1);
    rawProjPoints{2} = rpp(dataLabels_to==2);

    nResample = 10000;

    [D,P,STATS] = manova1(dataMatrix_to, dataLabels_to);
    cVar_proj(8) = P;

    resampleVec = zeros(nResample,1);
    for resampleIdx=1:nResample
        shuffLabels = dataLabels_to(randperm(length(dataLabels_to)));
        resampleVec(resampleIdx) = projStat_cv_2(dataMatrix_to, shuffLabels);
    end

    ci = bootci(nResample, {@projStat_cv, dm1, dm2}, 'type','per');
    cVar_proj(2) = prctile(resampleVec,99);
    cVar_proj(3) = mean(resampleVec);
    cVar_proj(4:5) = ci;    

    [H,P,CI] = ttest2(rawProjPoints{2}, rawProjPoints{1});
    cVar_proj(6:7) = CI;

    %population norm metric
    testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));

    resampleVec = zeros(nResample,1);
    for resampleIdx=1:nResample
        shuffLabels = dataLabels(randperm(length(dataLabels)));
        resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
    end

    resampleVec_mvn = zeros(nResample,1);
    mn = mean(dataMatrix);
    cv = cov(dataMatrix);
    for resampleIdx=1:nResample
        resampleData = mvnrnd(mn, cv, size(dataMatrix,1));
        resampleVec_mvn(resampleIdx) = norm(mean(resampleData(dataLabels==2,:)) - mean(resampleData(dataLabels==1,:)));
    end

    cVar(1) = testStat;
    cVar(2) = prctile(resampleVec,99);
    cVar(3) = prctile(resampleVec_mvn,99);

    ci = bootci(nResample, {@normStat, dm1, dm2}, 'type','per');
    cVar(4:5) = ci;    
end

