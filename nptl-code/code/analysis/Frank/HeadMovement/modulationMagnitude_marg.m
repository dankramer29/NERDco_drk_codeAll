function [ cVar, rawProjPoints, example_plane ] = modulationMagnitude_marg( trlCodes, snippetMatrix, eventIdx, trlBaselineMatrix, ...
    movWindow, binMS, timeWindow, codeSets, mode )

    %single trial projection bars
    trlCodeList = unique(trlCodes);
    cVar = zeros(max(trlCodeList),1);
    rawProjPoints = cell(max(trlCodeList),2);
    example_plane = cell(max(trlCodeList),2);
    
    baselineWindowActivity = permute(trlBaselineMatrix,[3 2 1]);
    ba = squeeze(nanmean(baselineWindowActivity,2));
    ba = ba(all(~isnan(ba),2),:)';
    
    for pIdx = 1:length(codeSets)
        setTrl = find(ismember(trlCodes, codeSets{pIdx}));
               
        setRates = triggeredAvg(snippetMatrix, eventIdx(setTrl), movWindow);
        setRates = squeeze(mean(setRates,2));
            
        baselineMean = mean(ba,1);
        setRates_minusBase = setRates - baselineMean;
        setGrandMean = mean(setRates_minusBase);
    
        for codeIdx=1:length(codeSets{pIdx})
            disp(codeIdx);
            
            trlIdx = find(trlCodes==codeSets{pIdx}(codeIdx));
            movWindowActivity = triggeredAvg(snippetMatrix, eventIdx(trlIdx), movWindow);

            ma = squeeze(mean(movWindowActivity,2));
            if strcmp(mode,'subtractMean') || strcmp(mode,'subtractMean_norm')
                ma = ma - setGrandMean;
            end
            
            minLen = min(size(ba,1),size(ma,1));
            ba_r = ba(1:minLen,:);
            ma = ma(1:minLen,:);
            
            if strcmp(mode,'subtractMean_norm') || strcmp(mode,'raw_norm')
                ma = ma ./ std(ma);
                ba_r = ba_r ./ std(ba_r);
            end

            dataMatrix = [ba_r; ma];
            dataLabels = [ones(size(ba_r,1),1); ones(size(ma,1),1)+1];

            nResample = 1000;

            %population distance metric
            testStat = lessBiasedDistance( ma, ba_r );
            resampleVec = zeros(nResample,1);
            for resampleIdx=1:nResample
                shuffLabels = dataLabels(randperm(length(dataLabels)));
                resampleVec(resampleIdx) = lessBiasedDistance(dataMatrix(shuffLabels==2,:), dataMatrix(shuffLabels==1,:)); 
            end

            cVar(codeSets{pIdx}(codeIdx),1) = testStat;
            cVar(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);

            %[ci,bootstats] = bootci(nResample, {@lessBiasedDistance, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
            ci = jackCI_full( testStat, @lessBiasedDistance, {dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)} );
            cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    

            %cross-validated projection     
            [~, rawProjPoints{codeSets{pIdx}(codeIdx),1}, rawProjPoints{codeSets{pIdx}(codeIdx),2}] = projStat_cv_paper(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:), testStat);
        
            %example points
            [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca([ma; ba_r]);
            example_plane{codeSets{pIdx}(codeIdx),1} = (ma-MU) * COEFF(:,1:2);
            example_plane{codeSets{pIdx}(codeIdx),2} = (ba_r-MU) * COEFF(:,1:2);
            
            %raw firing rate
            cVar(codeSets{pIdx}(codeIdx),5) = mean(mean(ma)-mean(ba_r));
        end
    end    
end

