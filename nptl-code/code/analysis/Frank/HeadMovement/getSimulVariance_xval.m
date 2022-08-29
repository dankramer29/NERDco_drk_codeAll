function [ meanVar, varCI ] = getSimulVariance_xval( eventIdx, movCues, neuralActivity, W, movWindow, nResamples, constraintSpace )
    codeList = unique(movCues);
    varCI = nan(2,1);
    
    if nargin<7
        constraintSpace = {};
    end
    if ~isempty(constraintSpace)
        neuralActivity = neuralActivity*constraintSpace{1}*constraintSpace{2}';
    end
    nDim = size(W{1},2);
    
    %bootsrap CI
    if nResamples>0
        resampleVar = zeros(nResamples,1);
        for resampleIdx=1:nResamples
            trlAvgActivity = zeros(length(codeList),nDim);
            for codeIdx=1:length(codeList)
                trlIdxForThisCode = find(movCues==codeList(codeIdx));
                
                %resample trials
                trlIdxForThisCode = trlIdxForThisCode(randi(length(trlIdxForThisCode), length(trlIdxForThisCode), 1));
                
                %get average activity
                dataMatrix = zeros(length(trlIdxForThisCode),nDim);
                for x=1:length(trlIdxForThisCode)
                    loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
                    dataMatrix(x,:) = mean(neuralActivity(loopIdxWindow,:)*W{trlIdxForThisCode(x)});
                end
                trlAvgActivity(codeIdx,:) = mean(dataMatrix);
            end
            
            %compute mean-subtracted variance in these dimensions
            trlAvgActivity = trlAvgActivity - mean(trlAvgActivity);
            resampleVar(resampleIdx) = mean(sqrt(sum(trlAvgActivity.^2,2)));
        end
        varCI = prctile(resampleVar,[2.5,97.5]);
    end
    
    %mean
    trlAvgActivity = zeros(length(codeList),nDim);
    for codeIdx=1:length(codeList)
        trlIdxForThisCode = find(movCues==codeList(codeIdx));
        
        %get average activity
        dataMatrix = zeros(length(trlIdxForThisCode),nDim);
        for x=1:length(trlIdxForThisCode)
            loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
            dataMatrix(x,:) = mean(neuralActivity(loopIdxWindow,:)*W{trlIdxForThisCode(x)});
        end
        trlAvgActivity(codeIdx,:) = mean(dataMatrix);
    end

    %compute mean-subtracted variance in these dimensions
    trlAvgActivity = trlAvgActivity - mean(trlAvgActivity);
    meanVar = mean(sqrt(sum(trlAvgActivity.^2,2)));
end

