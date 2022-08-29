function [ cVar, rawProjPoints ] = modulationMagnitude_v5( trlCodes, snippetMatrix, eventIdx, trlBaselineMatrix, ...
    movWindow, binMS, timeWindow, codeSets )

    %single trial projection bars
    trlCodeList = unique(trlCodes);
    cVar = zeros(max(trlCodeList),1);
    rawProjPoints = cell(max(trlCodeList),2);
    
    baselineWindowActivity = permute(trlBaselineMatrix,[3 2 1]);
    ba = squeeze(nanmean(baselineWindowActivity,2));
    ba = ba(all(~isnan(ba),2),:)';
    
    for pIdx = 1:length(codeSets)
        setTrl = find(ismember(trlCodes, codeSets{pIdx}));
        
        ortho_dpca = apply_dPCA_simple( snippetMatrix, eventIdx(setTrl), ...
            trlCodes(setTrl), [0, 1000]/binMS, binMS/1000, {'CD','CI'}, [length(codeSets{pIdx}), length(codeSets{pIdx})], 'standard', 'ortho' );
        close(gcf);
        
        cdIdx = find(ortho_dpca.whichMarg==1);
        cdDim = ortho_dpca.W(:,cdIdx);
        cdRates = (snippetMatrix * cdDim) * cdDim';
        cdBaseline = (ba * cdDim) * cdDim';

        for codeIdx=1:length(codeSets{pIdx})
            disp(codeIdx);
            
            trlIdx = find(trlCodes==codeSets{pIdx}(codeIdx));
            movWindowActivity = triggeredAvg(cdRates, eventIdx(trlIdx), [movWindow(1), movWindow(end)]);

            ma = squeeze(mean(movWindowActivity,2));
            
            minLen = min(size(cdBaseline,1),size(ma,1));
            ba_r = cdBaseline(1:minLen,:);
            ma = ma(1:minLen,:);

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

            [ci,bootstats] = bootci(nResample, {@lessBiasedDistance, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
            cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    

            %cross-validated projection     
            [~, rawProjPoints{codeSets{pIdx}(codeIdx),1}, rawProjPoints{codeSets{pIdx}(codeIdx),2}] = projStat_cv_paper(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:), testStat);
        end
    end    
end

