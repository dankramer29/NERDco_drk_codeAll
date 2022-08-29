function convertPrefitToShareable( sessions, resultsDir )
    mkdir([resultsDir filesep 'shareableFiles']);
    for s=1:length(sessions)
        load([resultsDir '\prefitFiles\prefit_' sessions(s).name{1} '.mat']);
        
        share.subjectCode = sessions(s).subject{1};
        share.date = sessions(s).name{1}(4:13);
        
        %give only the test blocks, not the calibration blocks
        testBlocks = prefitFile.blockList(strcmp(prefitFile.calCodes,'closed loop'));
        testBlockIdx = find(strcmp(prefitFile.calCodes,'closed loop'));
        testIdx = find(ismember(prefitFile.loopMat.blockNum, testBlocks));
        
        share.cursorRadius = median(prefitFile.loopMat.cursorRad(testIdx));
        share.targetRadius = median(prefitFile.loopMat.targetRad(testIdx)) - share.cursorRadius;
        
        share.alpha = prefitFile.alpha(testBlockIdx);
        share.beta = prefitFile.beta(testBlockIdx)*50;
        share.dwellTimes = zeros(size(share.alpha));
        for b=1:length(testBlocks)
            share.dwellTimes(b) = prefitFile.tmOpts{testBlockIdx(b)}.holdTime;
        end        
        
        share.secondsSinceSystemBoot = prefitFile.loopMat.timenow(testIdx);

        share.conditionNumber = prefitFile.loopMat.blockNum;
        for b=1:length(testBlocks)
            share.conditionNumber(prefitFile.loopMat.blockNum==testBlocks(b)) = b;
        end
        
        share.conditionNumber = share.conditionNumber(testIdx);
        share.cursorPos = double(prefitFile.loopMat.positions(testIdx,:));
        share.cursorVel = double(prefitFile.loopMat.vel(testIdx,:));
        share.targetPos = double(prefitFile.loopMat.targetPos(testIdx,:));
        share.decodedControlVector = prefitFile.loopMat.cVecNorm(testIdx,:);
        
        reaches = prefitFile.trl.reaches;
        reaches(reaches(:,1) < testIdx(1),:) = [];
        reaches = reaches - testIdx(1) + 1;
        share.trialEpochs = reaches;
        
        if any(strcmp(sessions(s).subject{1},{'T6','T7'}))
            interTrialPeriods = share.trialEpochs(2:end,1) - share.trialEpochs(1:(end-1),2);
            tmp = interTrialPeriods;
            tmp(tmp>40) = [];
            longPeriod = max(tmp);
            
            share.trialEpochs(find(interTrialPeriods==1)+1,1) = share.trialEpochs(find(interTrialPeriods==1)+1,1) + longPeriod - 1;
        end
        for t=1:size(share.trialEpochs,1)
            loopIdx = share.trialEpochs(t,1):share.trialEpochs(t,2);
            share.targetPos(loopIdx,:) = repmat(median(share.targetPos(loopIdx,:)),length(loopIdx),1);
        end
        
        save([resultsDir filesep 'shareableFiles' filesep share.subjectCode '.' share.date '.mat'],'-struct','share');
%         for c=1:10
%             cIdx = find(share.conditionNumber==c);
%             filtDec = filter((1-share.alpha(c))*share.beta(c), [1, -share.alpha(c)], share.decodedControlVector);
%             
%             figure
%             hold on
%             plot(share.cursorVel(cIdx,1));
%             plot(filtDec(cIdx,1),'r');
%         end
    end
end

