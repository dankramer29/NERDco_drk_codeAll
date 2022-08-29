function [A_hmm, B_hmm, diagVariance, stateLabels, stateLabelsSeq] = makeForcedAlignmentHMM(templates, sequenceIdx, templateBinSize, blankProb)

    %%
    %make hmm from templates
    %--each letter has a blank state at the end of it
    %--the sequence has a blank at the beginning
    %--at the very end, the HMM has a termination state that expresses the
    %termination symbol; only it can emit this symbol and it is the only
    %emitted symbol
    
    binSize = templateBinSize;
    stayProb = 0.20;
    skipProb = 0.20;

    nBins = 0;
    letterStartIdx = [];
    for x=1:length(sequenceIdx)
        letterStartIdx = [letterStartIdx; nBins+1];
        nBins = nBins + floor(size(templates{sequenceIdx(x)},1)/binSize) + 1;
    end

    nStates = nBins + 2; %+1 for blank at the beginning, +1 for termination state

    A_hmm = zeros(nStates, nStates);
    B_hmm = zeros(nStates, size(templates{1},2)+1);
    stateLabels = zeros(nStates,1);
    stateLabelsSeq = zeros(nStates,1);
    nLetters = length(templates);
    
    letterStartIdx = letterStartIdx + 1;
    
    for x=1:length(sequenceIdx)
        nBins = floor(size(templates{sequenceIdx(x)},1)/binSize);
        loopIdx = 1:binSize;
        currentIdx = letterStartIdx(x);

        for b=1:nBins
            neuralTemplate = mean(templates{sequenceIdx(x)}(loopIdx,:));
            B_hmm(currentIdx,1:(end-1)) = neuralTemplate;
            stateLabels(currentIdx) = sequenceIdx(x);
            stateLabelsSeq(currentIdx) = x;
            
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
                
                %optional transition to blank
                A_hmm(currentIdx,currentIdx+1) = (1-stayProb)*blankProb;
                A_hmm(currentIdx+1,currentIdx+1) = 0.5;
                
                stateLabels(currentIdx+1) = nLetters+1;
                stateLabelsSeq(currentIdx+1) = -1;
                
                if x<length(sequenceIdx)
                    %transition to next letter
                    A_hmm(currentIdx,letterStartIdx(x+1)) = (1-stayProb)*(1-blankProb); %last letter state
                    A_hmm(currentIdx+1,letterStartIdx(x+1)) = 0.5; %blank
                else
                    %transition to termination state
                    A_hmm(currentIdx,end) = (1-stayProb)*(1-blankProb); %last letter state
                    A_hmm(currentIdx+1,end) = 0.5; %blank
                end
            end

            currentIdx = currentIdx + 1;
            loopIdx = loopIdx + binSize;
        end
    end

    %fill in blank state emission probabilities
    letterStates = ismember(stateLabels, 1:nLetters);
    blankStates = stateLabels==nLetters+1;
    
    B_hmm(blankStates,1:(end-1)) = repmat(mean(B_hmm(letterStates,1:(end-1))), sum(blankStates), 1);
    
    %beginning blank state
    stateLabels(1) = nLetters + 1;
    A_hmm(1,1) = 0.5;
    A_hmm(1,2) = 0.5;
    
    %add termination state
    A_hmm(end,end) = 1;
    stateLabels(end) = nLetters + 2;
    stateLabelsSeq(end) = -2;
    B_hmm(end,end) = 1;
    
    %variance
    diagVariance = zeros(1,size(B_hmm,2));
    diagVariance(1:(end-1))=1;
    diagVariance(end)=0.000001; %low termination variance enforces sequence termination 
end
