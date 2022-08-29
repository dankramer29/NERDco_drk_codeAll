 function [currStart, currStretch] = iterativeLabelSearch_additive(dat, templates, word, possibleStretch, letterStarts, letterStretches, cTimes, nReps)
    currStart = letterStarts;
    currStretch = letterStretches;

    for repIdx=1:nReps
        disp(repIdx);
        
        %first order
        for c=1:length(word)
            minSize = round(size(templates{c},1)*0.6);
            if repIdx==nReps
                pStart = round((cTimes(c)-0.35)*size(dat,1)):10:round((cTimes(c)+0.35)*size(dat,1));
            else
                pStart = round((cTimes(c)-0.2)*size(dat,1)):10:round((cTimes(c)+0.2)*size(dat,1));
            end
            pStart(pStart>(size(dat,1)-minSize-30))=[];
            pStart(pStart<1)=[];
            
            %enforce letter order
            if c<length(word) && repIdx==nReps
                pStart(pStart>(currStart(c+1)-30))=[];
            end
            if c>1 && repIdx==nReps
                pStart(pStart<(currStart(c-1)+30))=[];
            end
            
            tmpCost = zeros(length(possibleStretch), length(pStart));
            for stretchIdx=1:length(possibleStretch)
                for startIdx=1:length(pStart)
                    currStart(c) = pStart(startIdx);
                    currStretch(c) = possibleStretch(stretchIdx);

                    [ cost, reconDat ] = reconCost_additive( dat, templates, currStart, currStretch );
                    tmpCost(stretchIdx, startIdx) = cost;
                end
            end

            [minCost,minIdx] = max(tmpCost(:));
            if isempty(tmpCost)
                continue;
            end
            [minStretch, minStartIdx] = ind2sub(size(tmpCost),minIdx);
        
            currStart(c) = pStart(minStartIdx);
            currStretch(c) = possibleStretch(minStretch);
        end
        
        %%
        %second order adjacent pairings
        for c=1:(length(word)-1)
            [cost, baseRecon] = reconCost( dat, templates, currStart, currStretch );

            pairStart = cell(2,1);
            for x=0:1
                minSize = round(size(templates{c+x},1)*0.6);
                if repIdx==nReps
                    pStart = round((cTimes(c+x)-0.35)*size(dat,1)):10:round((cTimes(c+x)+0.35)*size(dat,1));
                else
                    pStart = round((cTimes(c+x)-0.2)*size(dat,1)):10:round((cTimes(c+x)+0.2)*size(dat,1));
                end
                pStart(pStart>(size(dat,1)-minSize-30))=[];
                pStart(pStart<1)=[];
                
                if c<(length(word)-1) && x==1
                    pStart(pStart>(currStart(c+2)-30))=[];
                end
                if c>1 && x==0
                    pStart(pStart<(currStart(c-1)+30))=[];
                end
            
                pairStart{x+1} = pStart;
            end
                  
            tmpCost = zeros(length(pairStart{1}), length(pairStart{2}));
            for x1=1:length(pairStart{1})
                for x2=1:length(pairStart{2})
                    if pairStart{1}(x1)>(pairStart{2}(x2)-30)
                        tmpCost(x1, x2) = -1000;
                        continue;
                    end
                    
                    newStart = currStart;
                    newStart([c,c+1]) = [pairStart{1}(x1), pairStart{2}(x2)];
                    
                    [ cost, reconDat ] = reconCost_additive( dat, templates, newStart, currStretch );
                    tmpCost(x1, x2) = cost;
                end
            end

            if isempty(tmpCost)
                continue;
            end
            
            [minCost,minIdx] = max(tmpCost(:));
            [minStart1, minStart2] = ind2sub(size(tmpCost),minIdx);

            currStart(c) = pairStart{1}(minStart1);
            currStart(c+1) = pairStart{2}(minStart2);
        end
        
        %%
        %swap letters
        maxSwaps = 5;
        swapNum = 0;
        
        while swapNum<maxSwaps
            possibleSwaps = [];
            for c1=1:length(word)
                for c2=(c1+1):length(word)
                    if currStart(c1)>currStart(c2)
                        possibleSwaps = [possibleSwaps; [c1 c2]];
                    end
                end
            end
            
            if isempty(possibleSwaps)
                break
            else
                swapIdx = randi(size(possibleSwaps,1));
                s1 = possibleSwaps(swapIdx,1);
                s2 = possibleSwaps(swapIdx,2);
                currStart([s1 s2]) = currStart([s2 s1]);
                currStretch([s1 s2]) = currStretch([s2 s1]);
                
                swapNum = swapNum + 1;
            end
        end
    end
end