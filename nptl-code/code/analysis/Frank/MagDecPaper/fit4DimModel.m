function [ popResponse, sfResponse, fullModel, in, modelVectors, Q] =  fit4DimModel( saveDir, in )
    %model fitting
    fileName = [saveDir filesep 'modelOutput.mat'];
    if ~exist(fileName,'file')
        %get reaction time
        inForRT = in;
        if isfield(in,'isOuter')
            inForRT.reachEpochs = inForRT.reachEpochs(in.isOuter,:);
            inForRT.reachEpochs_fit = inForRT.reachEpochs_fit(in.isOuter,:);
        end
        
        possibleRT = 0:25;
        meanR2 = zeros(length(possibleRT),1);
        for rtIdx = 1:length(possibleRT)
            disp(possibleRT(rtIdx));
            inForRT.rtSteps = possibleRT(rtIdx);
            
            [inForRT.kin.posErrForFit, inForRT.kin.unitVec, inForRT.kin.targDist, inForRT.kin.timePostGo] = prepKinForModel( inForRT );
            inForRT.modelType = 'FMP';

            fullModel = fitPhasicAndFB_6(inForRT);
            [~,sortIdx] = sort(fullModel.R2Vals,'descend');
            meanR2(rtIdx) = mean(fullModel.R2Vals(sortIdx(1:96)));
        end

        [~,maxIdx] = max(meanR2);
        in.rtSteps = possibleRT(maxIdx);
        [in.kin.posErrForFit, in.kin.unitVec, in.kin.targDist, in.kin.timePostGo] = prepKinForModel( in );

        modelTypes = {'FMP','FP','FM','MP','F','P','M'};
        fullModel = cell(length(modelTypes),1);
        sfResponse = cell(length(modelTypes),1);
        popResponse = cell(length(modelTypes),1);
        modelVectors = cell(length(modelTypes),1);
        R2Vals = zeros(size(in.features,2), length(modelTypes));
        Q = cell(length(modelTypes),1);

        nFolds = 6;
        C = cvpartition(size(in.reachEpochs,1),'KFold',nFolds);
        evalIdx = expandEpochIdx(in.reachEpochs);

        for m=1:length(modelTypes)
            disp(modelTypes{m});

            in.modelType = modelTypes{m};
            fullModel{m} = fitPhasicAndFB_6(in);

            sfResponse{m} = zeros(size(in.features));
            popResponse{m} = zeros(size(in.features,1),4);
            modelVectors{m} = zeros(size(in.features,1),4);
            foldModels = cell(nFolds, 1);
            for n=1:nFolds
                disp([' -- Fold ' num2str(n)]);
                inFold = in;
                inFold.reachEpochs = in.reachEpochs(C.training(n),:);
                if isfield(inFold,'speedCode')
                    inFold.speedCode = inFold.speedCode(C.training(n));
                end
                foldModels{n} = fitPhasicAndFB_6(inFold);

                inFold.reachEpochs = in.reachEpochs(C.test(n),:);
                out = applyPhasicAndFB(inFold, foldModels{n});

                testIdx = expandEpochIdx(inFold.reachEpochs);
                sfResponse{m}(testIdx,:) = out.all(testIdx,:);  
                popResponse{m}(testIdx, foldModels{n}.popIdx) = out.popResponse(testIdx,:);
                modelVectors{m}(testIdx, :) = out.modelVectors(testIdx, :);
            end

            R2Vals(:,m) = getDecoderPerformance(sfResponse{m}(evalIdx,:),in.features(evalIdx,:),'R2');

            %fill in the gaps with full model
            out = applyPhasicAndFB(in, fullModel{m});
            gapIdx = setdiff(1:size(in.cursorPos,1), evalIdx);
            sfResponse{m}(gapIdx, :) = out.all(gapIdx,:);
            popResponse{m}(gapIdx, fullModel{m}.popIdx) = out.popResponse(gapIdx,:);
            modelVectors{m}(gapIdx, :) = out.modelVectors(gapIdx,:);

            %noise
            Q{m} = cov(in.features(evalIdx,:) - sfResponse{m}(evalIdx,:));
        end 
        sfResponse = sfResponse{1};
        popResponse = popResponse{1};
        save(fileName,'popResponse','R2Vals','fullModel','foldModels','in','modelVectors','Q');
    else
       load(fileName,'popResponse','R2Vals','fullModel','in','modelVectors','Q');
       out = applyPhasicAndFB(in, fullModel{1});
       sfResponse = out.all;
    end
end

