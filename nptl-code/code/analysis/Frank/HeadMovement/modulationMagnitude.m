function [ cVar, cVar_proj, rawProjPoints, dPCA_out_all ] = modulationMagnitude( trlCodes, snippetMatrix, eventIdx, trlBaselineMatrix, ...
    movWindow, baselineWindow, binMS, timeWindow, codeSets, mode )

    %single trial projection bars
    trlCodeList = unique(trlCodes);
    cVar = zeros(max(trlCodeList),1);
    cVar_proj = zeros(max(trlCodeList),1);
    rawProjPoints = cell(max(trlCodeList),2);
    dPCA_out_all = cell(length(codeSets),1);
    
    for pIdx = 1:length(codeSets)
        trlIdx = ismember(trlCodes, codeSets{pIdx});
        trlIdx = find(trlIdx);

        dPCA_out = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
            trlCodes(trlIdx), timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'xval' );
        close(gcf);

        cdIdx = find(dPCA_out.cval.whichMarg==1);
        cdIdx = cdIdx(1:6);
        dPCA_out_all{pIdx} = dPCA_out;
        
        if strcmp(mode,'nothing_control')
            nothingDat_reduced = zeros(size(trlBaselineMatrix,1),size(trlBaselineMatrix,2),6);
            for t=1:size(trlBaselineMatrix,1)
                nothingDat_reduced(t,:,:) = squeeze(trlBaselineMatrix(t,:,:)) * dPCA_out.cval.resortW{1}(:,cdIdx);
            end
        end

        for codeIdx=1:length(codeSets{pIdx})
            disp(codeIdx);
            
            trlIdx = find(trlCodes==codeSets{pIdx}(codeIdx));
            timeOffset = (-timeWindow(1)/binMS);

            movWindowActivity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+movWindow));
            
            if strcmp(mode,'baseline_Z')
                baselineWindowActivity = squeeze(dPCA_out.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+baselineWindow));
                ba = squeeze(nanmean(baselineWindowActivity,3));
                ba = ba(all(~isnan(ba),2),:);
            elseif strcmp(mode,'baseline_Mn')
                fm = dPCA_out.featureMeansFromTrlAvg;
                baselineWindowActivity = zeros(length(trlIdx), length(cdIdx));
                for t=1:length(trlIdx)
                    baselineWindowActivity(t,:) = squeeze(trlBaselineMatrix(trlIdx(t),:)-fm) * dPCA_out.cval.resortW{1}(:,cdIdx);
                end
                ba = baselineWindowActivity;
            elseif strcmp(mode,'nothing_control')
                baselineWindowActivity = nothingDat_reduced(:,timeOffset+movWindow,:);
                baselineWindowActivity = permute(baselineWindowActivity,[3 2 1]);
                ba = squeeze(nanmean(baselineWindowActivity,2));
                ba = ba(all(~isnan(ba),2),:)';
            end
            
            ma = squeeze(nanmean(movWindowActivity,3));
            ma = ma(all(~isnan(ma),2),:);
 
            minLen = min(size(ba,1),size(ma,1));
            ba = ba(1:minLen,:);
            ma = ma(1:minLen,:);

            dataMatrix = [ba; ma];
            dataLabels = [ones(size(ba,1),1); ones(size(ma,1),1)+1];

            badIdx = find(any(isnan(dataMatrix),2));
            dataMatrix(badIdx,:) = [];
            dataLabels(badIdx,:) = [];

            nResample = 10000;

            %population distance metric
            testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
            resampleVec = zeros(nResample,1);
            for resampleIdx=1:nResample
                shuffLabels = dataLabels(randperm(length(dataLabels)));
                resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
            end

            cVar(codeSets{pIdx}(codeIdx),1) = testStat;
            cVar(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);

            ci = bootci(nResample, {@normStat, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
            cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    

            %single trial projection metric       
            [cVar_proj(codeSets{pIdx}(codeIdx),1), rawProjPoints{codeSets{pIdx}(codeIdx),1}, ...
                rawProjPoints{codeSets{pIdx}(codeIdx),2}] = projStat_cv(dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:));

            nResample = 10000;
            resampleVec = zeros(nResample,1);
            for resampleIdx=1:nResample
                shuffLabels = dataLabels(randperm(length(dataLabels)));
                resampleVec(resampleIdx) = projStat_cv(dataMatrix(shuffLabels==1,:), dataMatrix(shuffLabels==2,:));
            end

            ci = bootci(nResample, {@projStat_cv, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)}, 'type','per');
            cVar_proj(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
            cVar_proj(codeSets{pIdx}(codeIdx),3) = mean(resampleVec);
            cVar_proj(codeSets{pIdx}(codeIdx),4:5) = ci;    

            [H,P,CI] = ttest2(rawProjPoints{codeSets{pIdx}(codeIdx),2}, rawProjPoints{codeSets{pIdx}(codeIdx),1});
            cVar_proj(codeSets{pIdx}(codeIdx),6:7) = CI;
        end
    end    
end

