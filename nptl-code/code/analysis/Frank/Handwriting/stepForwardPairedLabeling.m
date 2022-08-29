 function [letterStart, letterStretch] = stepForwardPairedLabeling(dat, templates, word, letters, timeScaleFactor)
    letterStart = zeros(length(word),1);
    letterStretch = zeros(length(word),1);

    possibleStretch = linspace(0.66,1.5,10);
    currIdx = 1;
    if nargin<5
        timeScaleFactor = 1;
    end
    
    for c=1:(length(word)-1)
    %for c=1:2
        template1 = templates{strcmp(word(c), letters)};
        template2 = templates{strcmp(word(c+1), letters)};
        startTimes1 = 1:(10*timeScaleFactor):(250*timeScaleFactor);
        
        tmpCost = zeros(length(possibleStretch), length(startTimes1), length(startTimes1))-1000;
        tmpLen = zeros(length(possibleStretch), length(startTimes1), length(startTimes1));
        for stretchIdx=1:length(possibleStretch)
            newX = linspace(0,1,round(size(template1,1)*possibleStretch(stretchIdx)));
            stretchedTemplate1 = interp1(linspace(0,1,size(template1,1)), template1, newX);
            
            newX = linspace(0,1,round(size(template2,1)*possibleStretch(stretchIdx)));
            stretchedTemplate2 = interp1(linspace(0,1,size(template2,1)), template2, newX);
            
            for startIdx1=1:length(startTimes1)
                startTimes2 = 1:(10*timeScaleFactor):(250*timeScaleFactor);
                for startIdx2=1:length(startTimes2)
                    fullPair = [stretchedTemplate1; zeros(startTimes2(startIdx2),size(dat,2)); stretchedTemplate2];
                    
                    stIdx = (startTimes1(startIdx1)+currIdx-1);
                    loopIdx = stIdx:(stIdx+size(fullPair,1)-1);
                    if loopIdx(end)>(size(dat,1)-40)
                        continue;
                    end
                    loopIdx(loopIdx>size(dat,1))=[];
                    
                    redPair = fullPair(1:length(loopIdx),:);
                    redDat = dat(loopIdx,:);
                    %redDat = dat;
                    %redPair = zeros(size(dat));
                    %redPair(loopIdx,:) = fullPair(1:length(loopIdx),:);
                    
                    tmpCost(stretchIdx, startIdx1, startIdx2) = mean(sum(redDat.*redPair)./(matVecMag(redDat,1).*matVecMag(redPair,1)));
                    tmpLen(stretchIdx, startIdx1, startIdx2) = size(stretchedTemplate1,1);
                end
            end
        end
        
        [maxVal,maxIdx] = max(tmpCost(:));
        [maxStretch, maxStartIdx1, maxStartIdx2] = ind2sub(size(tmpCost), maxIdx);
        
        letterStart(c) = currIdx+startTimes1(maxStartIdx1);
        letterStretch(c) = possibleStretch(maxStretch);
        
        if c==(length(word)-1)
            letterStart(c+1) = currIdx+startTimes1(maxStartIdx1)+tmpLen(maxIdx)+startTimes2(maxStartIdx2);
            letterStretch(c+1) = possibleStretch(maxStretch);
        end
        
        currIdx = currIdx+startTimes1(maxStartIdx1)+tmpLen(maxIdx);
    end
end