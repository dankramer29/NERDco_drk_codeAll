function [ A_hmm, B_hmm, stateLabels, letterStartIdx ] = makeHMMLetterDecoder( templates, binSize, stayProb, skipProb, blankStayProb )
    %letter sequence decoder
    nBins = 0;
    letterStartIdx = [];
    for x=1:length(templates)
        letterStartIdx = [letterStartIdx; nBins+1];
        nBins = nBins + floor(size(templates{x},1)/binSize);
    end

    nStates = nBins+1; %+1 for blank
    letterStartIdx = [letterStartIdx; nStates];

    nLetters = length(templates);
    A_hmm = zeros(nStates, nStates);
    B_hmm = zeros(nStates, size(templates{1},2));

    stateLabels = [];
    for x=1:length(templates)
        nBins = floor(size(templates{x},1)/binSize);
        loopIdx = 1:binSize;
        currentIdx = letterStartIdx(x);

        for b=1:nBins
            neuralTemplate = mean(templates{x}(loopIdx,:));
            B_hmm(currentIdx,:) = neuralTemplate;

            if b<nBins
                A_hmm(currentIdx,currentIdx) = stayProb;
                if b==(nBins-1)
                    %second to last, no skipping
                    A_hmm(currentIdx,currentIdx+1) = 1-stayProb;
                else
                    A_hmm(currentIdx,currentIdx+1) = 1-stayProb-skipProb;
                    A_hmm(currentIdx,currentIdx+2) = skipProb;
                end
            else
                %last bin
                A_hmm(currentIdx,currentIdx) = stayProb;
                A_hmm(currentIdx,letterStartIdx) = (1-stayProb)/(nLetters+1);
            end

            currentIdx = currentIdx + 1;
            loopIdx = loopIdx + binSize;
            stateLabels = [stateLabels; x];
        end
    end

    %add blank state?
    A_hmm(end,end) = blankStayProb;
    A_hmm(end,letterStartIdx(1:(end-1))) = (1-blankStayProb)/nLetters;
    stateLabels(end+1) = (nLetters+1);
    B_hmm(end,:) = mean(B_hmm(1:(end-1),:));
end

