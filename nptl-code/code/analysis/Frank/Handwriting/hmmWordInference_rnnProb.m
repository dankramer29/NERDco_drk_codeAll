%%
googleWords = importdata('/Users/frankwillett/Downloads/google-10000-english-master/google-10000-english-usa.txt');
headwords = importdata('/Users/frankwillett/Downloads/10000-headwords/headwords 1st 1000.txt');
headwords = lower(headwords);

wordsTested = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesData/t5.2019.06.26.mat','mappedText');

wordList = [googleWords; headwords; wordsTested.mappedText];
wordList = unique(wordList);
save('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/wordListForInference','wordList');

empErr = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/confusionMatrix_train.mat');
cMatReorder = [1 2 3 4 8 9 10 11 12 13 14 15 6 16 7 17 18 19 20 5 21 22 23 24 25 26];
empErr.cMat = empErr.cMat(cMatReorder, cMatReorder);

rnnData=load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/rnnDecoderOutput.mat');
for t=1:length(rnnData.rnnProb)
    rnnData.rnnProb{t} = [rnnData.rnnProb{t}; zeros(40,27)];
    rnnData.rnnProb{t}(1:(end-40),27) = 0;
    rnnData.rnnProb{t}(1:(end-40),:) = rnnData.rnnProb{t}(1:(end-40),:)./sum(rnnData.rnnProb{t}(1:(end-40),:),2);
    rnnData.rnnProb{t}((end-39):end,27) = 1;
    rnnData.rnnProb{t}(:,1:26) = rnnData.rnnProb{t}(:,cMatReorder);
end

%%
charEmissions = zeros(26,26);
for x=1:26
    cProb = 0.90;
    oProb = (1-cProb)/25;

    charEmissions(x,:) = oProb;
    charEmissions(x,x) = cProb;
end

charEmissions = (charEmissions + empErr.cMat(1:26,1:26))/2;
for x=1:size(charEmissions,1)
    charEmissions(x,:) = charEmissions(x,:)/sum(charEmissions(x,:));
end

%%
A_hmm = cell(length(wordList),1);
B_hmm = cell(length(wordList),1);
eProbIdx_hmm = cell(length(wordList),1);
for w=1:length(wordList)
    %if mod(w,100)==0
    %    disp(w);
    %end
    word = wordList{w};
    nChar = length(word);

    nStates = nChar*2*26 + 1;
    tProb = 0.5;

    A = zeros(nStates, nStates);
    B = zeros(nStates, 26+1);
    eProbIdx = zeros(nStates, 1);
    for x=1:nChar
        for y=1:26
            %augmented state propagation
            currIdx = (x-1)*26*2 + y;

            A(currIdx,currIdx) = 1-tProb;
            A(currIdx,currIdx+26) = tProb;
            A(currIdx+26,currIdx+26) = 1-tProb;

            if x==nChar
                %transition to end of word state
                A(currIdx+26,end) = tProb;
            else
                %transition to next letter
                nextBlockStart = x*26*2+1;
                nextLetterIdx = word(x+1)-96;
                A(currIdx+26,nextBlockStart:(nextBlockStart+25)) = charEmissions(nextLetterIdx,:)*tProb;
            end

            %emissions in this state and augmented state
            B(currIdx,:) = [charEmissions(y,:), 0];
            B(currIdx+26,:) = [charEmissions(y,:), 0];
            
            %mark which letter these states belong to
            eProbIdx(currIdx) = y;
            eProbIdx(currIdx+26) = y;
        end
    end

    A(end,end) = 1.0;
    B(end,27) = 1.0;
    eProbIdx(end) = 27;
    
    A_hmm{w} = sparse(A);
    B_hmm{w} = B;
    eProbIdx_hmm{w} = eProbIdx;
end

%%
results = cell(size(rnnData.rnnText,1),1);
for trialIdx = 1:size(rnnData.rnnText,1)
    rnnOutput = strtrim(rnnData.rnnText(trialIdx,:));
    rnnOutput(rnnOutput=='-')=[];

    emProb = zeros(length(wordList),1)-1000000;
    for w=1:length(wordList)
        %if mod(w,100)==0
        %    disp(w);
        %end
        nStates = size(A_hmm{w},1);
        word = wordList{w};
        
        firstLetterIdx = word(1)-96;
        startProb = zeros(nStates,1);
        startProb(1:26) = charEmissions(firstLetterIdx,:)';

        %[seq,states] = hmmgenerate(100,A,B);
        %disp(char(seq+96));

        %figure;
        %imagesc(log(A+0.00001)); 
        %colormap(jet)

        %figure;
        %imagesc(log(B+0.00001)); 
        %colormap(jet);

        %compute probability of observations
        LOGPSEQ = hmmprob_softmax_frw(rnnData.rnnProb{trialIdx},A_hmm{w},eProbIdx_hmm{w},startProb);
        emProb(w) = LOGPSEQ;

        %pForward = zeros(nChar,1);
        %pForward(1) = 1;

        %logProb = 0;
        %for x=1:length(wordStr)
        %    logProb = logProb + p
        %end

        %[seq,states] = hmmgenerate(100,A,B);
    end

    emProb(isnan(emProb)) = -1000000;
    [~,sortIdx] = sort(emProb,'descend');
    %for w=1:5
    %    disp(wordList{sortIdx(w)});
    %end
    %disp(emProb(sortIdx(1:5)));
    
    disp(['RNN: ' rnnOutput ', HMM: ' wordList{sortIdx(1)} ', True: ' strtrim(rnnData.trueText(trialIdx,:))]);
    results{trialIdx} = wordList(sortIdx(1:5));
end

%%
correct = zeros(length(results),2);
for t=1:length(results)
    rnnText = strtrim(rnnData.trueText(t,:));
    correct(t,1) = length(results{t}{1})==length(rnnText) && all(results{t}{1}==rnnText);
    
    topFive = false;
    for x=1:5
        topFive = topFive | (length(results{t}{x})==length(rnnText) && all(results{t}{x}==rnnText));
    end
    correct(t,2) = topFive;
end

%%
nRep = 10000;
allEmits = zeros(nRep,1);
pStop = 0.05;

for repIdx=1:nRep    
    stop = false;
    nEmit = 0;
    while ~stop
        nEmit = nEmit+1;
        stop = rand(1)<pStop;
    end
    
    allEmits(repIdx) = nEmit;
end

%%
nTokens = 2;
A = zeros(nTokens+1);

tProb = 0.6;
for x=1:nTokens
    A(x,x) = (1-tProb);
    A(x,x+1) = tProb;
end
A(end,end) = 1.0;

B = zeros(nTokens+1, nTokens);
for x=1:nTokens
    B(x,:) = 0.1;
    B(x,x) = 1-(nTokens-1)*0.1;
end
B(end,:) = 1/nTokens;

%%
nRep = 10000;
allEmits = zeros(nRep,1);

for repIdx=1:nRep   
    nEmit = 1;
    state = 1;
    while state~=(nTokens+1)
        transProb = A(state,:);
        cs = cumsum(transProb);
        r = rand(1);
        for x=1:length(cs)
            if r<=cs(x)
                state = x;
                break;
            end
        end
        nEmit = nEmit + 1;
    end
    
    
    allEmits(repIdx) = nEmit-1;
end