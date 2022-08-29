function [ cVar, rawProjPoints, example_plane ] = modulationMagnitude_mpca( trlCodes, smoothSnippetMatrix, snippetMatrix, eventIdx, trlBaselineMatrix, ...
    movWindow, binMS, codeSets )

    %mPCA set up
    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Condition-dependent', 'Condition-independent'};

    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 10;
    opts_m.makePlots = false;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'pcaAxes';
    opts_m.alignMode = 'none';

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
        
        mpca = apply_mPCA_general( smoothSnippetMatrix, eventIdx(setTrl), trlCodes(setTrl), [0, 1000]/binMS, binMS/1000, opts_m);

        cdIdx = find(mpca.whichMarg==1);
        cdRates = mpca.readoutZ_unroll(:,cdIdx);
        %cdRates = mpca.readout_xval.Z_unroll(:,cdIdx);
        
        cdDim = mpca.readouts(:,cdIdx);
        cdBaseline = (ba * cdDim);

        for codeIdx=1:length(codeSets{pIdx})
            disp(codeIdx);
            
            trlIdx = find(trlCodes==codeSets{pIdx}(codeIdx));
            movWindowActivity = triggeredAvg(cdRates, eventIdx(trlIdx), movWindow);

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
        
            %example points
            example_plane{codeSets{pIdx}(codeIdx),1} = ma;
            example_plane{codeSets{pIdx}(codeIdx),2} = ba_r;
        end
    end    
end

