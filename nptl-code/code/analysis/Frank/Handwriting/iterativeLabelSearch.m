 function [currStart, currStretch] = iterativeLabelSearch(dat, templates, word, possibleStretch, letterStarts, letterStretches, cTimes, nReps)
    currStart = letterStarts;
    currStretch = letterStretches;

    for repIdx=1:nReps
        disp(repIdx);
        
        %first order
        for c=1:length(word)
            [cost, baseRecon] = reconCost( dat, templates, currStart, currStretch );

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
                pStart(pStart>(letterStarts(c+1)-30))=[];
            end
            if c>1 && repIdx==nReps
                pStart(pStart<(letterStarts(c-1)+30))=[];
            end
            
            tmpCost = zeros(length(possibleStretch), length(pStart));
            for stretchIdx=1:length(possibleStretch)
                for startIdx=1:length(pStart)
                    currStart(c) = pStart(startIdx);
                    currStretch(c) = possibleStretch(stretchIdx);

                    template = templates{c};
                    newX = linspace(0,1,round(size(template,1)*currStretch(c)));
                    stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);

                    loopIdx = currStart(c):(currStart(c)+size(stretchedTemplate,1)-1);
                    loopIdx(loopIdx>size(dat,1))=[];

                    newRecon = baseRecon;
                    newRecon(loopIdx,:) = stretchedTemplate(1:length(loopIdx),:);

                    cVal = sum(dat.*newRecon)./(matVecMag(dat,1).*matVecMag(newRecon,1));
                    cost = mean(cVal);
                    
                    %cVal = zeros(size(dat,2),1);
                    %for x=1:size(dat,2)
                    %    cVal(x) = corr(dat(:,x), newRecon(:,x));
                    %end
                    %cost = mean(cVal);
                    
                    %cost = corr(dat(:), newRecon(:));
                    
                    tmpCost(stretchIdx, startIdx) = cost;
                end
            end

            [minCost,minIdx] = max(tmpCost(:));
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
                    pStart(pStart>(letterStarts(c+2)-30))=[];
                end
                if c>1 && x==0
                    pStart(pStart<(letterStarts(c-1)+30))=[];
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
                    
                    newRecon = baseRecon;
                    choiceIdx = [x1 x2];
                    for x=0:1
                        startChoice = pairStart{x+1}(choiceIdx(x+1));
                        
                        template = templates{c+x};
                        newX = linspace(0,1,round(size(template,1)*currStretch(c+x)));
                        stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);

                        loopIdx = startChoice:(startChoice+size(stretchedTemplate,1)-1);
                        loopIdx(loopIdx>size(dat,1))=[];
                        newRecon(loopIdx,:) = stretchedTemplate(1:length(loopIdx),:);
                    end
                    
                    cVal = sum(dat.*newRecon)./(matVecMag(dat,1).*matVecMag(newRecon,1));
                    cost = mean(cVal);
                    tmpCost(x1, x2) = cost;
                end
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