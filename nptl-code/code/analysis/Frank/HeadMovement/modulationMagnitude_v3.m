function [ cVar, rawProjPoints ] = modulationMagnitude_v3( trlCodes, snippetMatrix, eventIdx, trlBaselineMatrix, ...
    movWindow, binMS, timeWindow, codeSets )

    %single trial projection bars
    trlCodeList = unique(trlCodes);
    cVar = zeros(max(trlCodeList),1);
    rawProjPoints = cell(max(trlCodeList),2);
    timeOffset = (-timeWindow(1)/binMS);

    dPCA_out_all = cell(length(codeSets),1);
    
    for pIdx = 1:length(codeSets)
        trlIdx = ismember(trlCodes, codeSets{pIdx});
        trlIdx = find(trlIdx);

        dPCA_out = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
            trlCodes(trlIdx), timeWindow/binMS, binMS/1000, {'CI','CD'}, [20 1], 'none', 'ortho' );
        close(gcf);

        cdIdx = find(dPCA_out.whichMarg==1);
        cdIdx = cdIdx(1:10);
        dPCA_out_all{pIdx} = dPCA_out;
        
        nothingDat_reduced = zeros(size(trlBaselineMatrix,1),size(trlBaselineMatrix,2),10);
        for t=1:size(trlBaselineMatrix,1)
            nothingDat_reduced(t,:,:) = squeeze(trlBaselineMatrix(t,:,:)) * dPCA_out.W(:,cdIdx);
        end
        
        baselineWindowActivity = nothingDat_reduced(:,timeOffset+movWindow,:);
        baselineWindowActivity = permute(baselineWindowActivity,[3 2 1]);
        ba = squeeze(nanmean(baselineWindowActivity,2));
        ba = ba(all(~isnan(ba),2),:)';
    
        for codeIdx=1:length(codeSets{pIdx})
            disp(codeIdx);
            
            trlIdx = find(trlCodes==codeSets{pIdx}(codeIdx));
            timeOffset = (-timeWindow(1)/binMS);
            movWindowMatrix = triggeredAvg(snippetMatrix, eventIdx(trlIdx), [movWindow(1), movWindow(end)]+timeOffset);
            
            movWindowActivity = zeros(size(movWindowMatrix,1),size(movWindowMatrix,2),10);
            for t=1:size(movWindowActivity,1)
                movWindowActivity(t,:,:) = squeeze(movWindowMatrix(t,:,:)) * dPCA_out.W(:,cdIdx);
            end
        
            ma = squeeze(mean(movWindowActivity,2));
            
            minLen = min(size(ba,1),size(ma,1));
            ba_r = ba(1:minLen,:);
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

