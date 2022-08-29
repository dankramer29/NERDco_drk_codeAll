function [ letterSnippets ] = extractLetterSnippets( zScoreSpikes, allLetterStarts, allEventIdx, allLabeling, skipTrlIdx, letterNames, mode )
    letterSnippets = struct();

    %0 = low, 1 = high
    penStart = [0.25, 1, 0.5, 0.5, 1, 0.5, ...
                0.25, 0.25, 1, 0.25, 1, 0.5, ...
                0.5, 1, 1, 0.5, 0.5, 0.25, ...
                0.5, 0.5, 0.5, 0.5, 0.5, 0.5, ...
                0.5, 0.5, 0.5, 0.25, 1, 0.5, 1];

    penEnd = [0.0, 0.0, 0.0, 1.0, 1.0, 0.0, ...
         0.50, 0.0, 1.0, -0.5, 0.0, 1.0, ...
         1.0, 0.0, 0.0, 0.0, 0.0, -0.5, ...
         0.5, 0.0, 0.5, 0.5, 0.5, 0.0, ...
         -0.5, 0.0, 0.0, 0.0, 1.0, 0.5, 0.0];

    for c=1:length(letterNames)
        letterSnippets.(letterNames{c}) = {};
        letterSnippets.([letterNames{c} '_long']) = {};
        letterSnippets.([letterNames{c} '_penEndState']) = [];
        letterSnippets.([letterNames{c} '_penLetterEndState']) = [];
        letterSnippets.([letterNames{c} '_isFirstLetter']) = [];
        letterSnippets.([letterNames{c} '_isLastLetter']) = [];
        letterSnippets.([letterNames{c} '_trlIdx']) = [];
    end
    
    letterSnippets.blank = {};
    letterSnippets.blank_trlIdx = [];

    for t=1:length(allLabeling)
        if ismember(t, skipTrlIdx)
            continue;
        end
        labels = allLabeling{t}(:,1);
        labelsWithBlanks = allLabeling{t}(:,2);
        blankIdx = find(labelsWithBlanks==(length(letterNames)+1));
        
        for x=1:length(allLetterStarts{t})
            if strcmp(mode,'includeBlanks')
                if x==length(allLetterStarts{t})
                    loopIdx = allEventIdx(t) + (allLetterStarts{t}(x):length(allLabeling{t}));
                else
                    loopIdx = allEventIdx(t) + (allLetterStarts{t}(x):allLetterStarts{t}(x+1));
                end
            elseif strcmp(mode,'extractBlanks')
                if x==length(allLetterStarts{t})
                    endOfLetter = min([blankIdx(blankIdx>allLetterStarts{t}(x)); length(allLabeling{t})]);
                    loopIdx = allEventIdx(t) + (allLetterStarts{t}(x):endOfLetter);
                else
                    endOfLetter = min([blankIdx(blankIdx>allLetterStarts{t}(x)); allLetterStarts{t}(x+1)]);
                    loopIdx = allEventIdx(t) + (allLetterStarts{t}(x):endOfLetter);
                end
            end

            loopIdx(loopIdx<1) = [];
            loopIdxLong = [(loopIdx(1)-10):(loopIdx(1)-1), loopIdx];
            loopIdxLong(loopIdxLong<1) = [];

            newLetterLong = zScoreSpikes(loopIdxLong,:);
            newLetter = zScoreSpikes(loopIdx,:);

            charName = letterNames{labels(allLetterStarts{t}(x)+2)};
            letterSnippets.(charName){end+1} = newLetter;
            letterSnippets.([charName '_long']){end+1} = newLetterLong;

            isFirstLetter = (x==1);
            isLastLetter = (x==length(allLetterStarts{t}));

            if x<length(allLetterStarts{t})
                nextLetter = labels(allLetterStarts{t}(x+1)+2);
                penEndState = penStart(nextLetter);
            else
                penEndState = -1;
            end

            letterSnippets.([charName '_isFirstLetter'])(end+1) = isFirstLetter;
            letterSnippets.([charName '_isLastLetter'])(end+1) = isLastLetter;
            letterSnippets.([charName '_penLetterEndState'])(end+1) = penEnd(labels(allLetterStarts{t}(x)+2));
            letterSnippets.([charName '_penEndState'])(end+1) = penEndState;
            letterSnippets.([charName '_trlIdx'])(end+1) = t;
        end
        
        blankEpochs = logicalToEpochs(labelsWithBlanks==(length(letterNames)+1));
        for b=1:size(blankEpochs,1)
            loopIdx = allEventIdx(t) + (blankEpochs(b,1):blankEpochs(b,2));
            letterSnippets.blank{end+1} = zScoreSpikes(loopIdx,:);
            letterSnippets.blank_trlIdx(end+1) = t;
        end
    end
end

