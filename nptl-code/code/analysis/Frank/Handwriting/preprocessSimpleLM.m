words = importdata('/Users/frankwillett/Data/Derived/Handwriting/wordLists/vocab_50000','\t');

letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
    '>',',','''','~','?'};
charTimes = [99 91 70 104 110 132 84 98 125 110 104 79 92 127 68 90 113 104 74 86 86 83 110 103 115 100 ...
    82 77 116 71 110]/100;

unicodeToLetterIdx = zeros(256,1);
for l=1:length(letters)
    unicodeToLetterIdx(letters{l}) = l;
end

totalCounts = sum(words.data);
logP = log(words.data)-log(totalCounts);

%%
stayProb = linspace(0.3,0.8,20);
allMeanTimes = zeros(length(stayProb),1);
for x=1:length(stayProb)
    nReps = 1000;
    repTimes = zeros(nReps,1);
    for n=1:nReps
        state = 0;
        totalTime = 0;
        while state<2
            if rand(1)>stayProb(x)
                state = state + 1;
            end
            totalTime = totalTime + 1;
        end
        repTimes(n) = totalTime;
    end
    allMeanTimes(x) = mean(repTimes);
end

binSize = 0.2;
charStayProb = zeros(length(charTimes),1);
for c=1:length(charTimes)
    [~,minIdx] = min(abs(charTimes(c)-allMeanTimes*binSize));
    charStayProb(c) = stayProb(minIdx);
end

%%
nStates = 0;
for w=1:length(words.data)
    %characters in the word
    newStates = length(words.textdata{w})*2;
    nStates = nStates + newStates;
end

%special states: space, comma->space, 's->space, period->termination,
%question->termination, termination
nSpecialStates = 2 + 2 + 4 + 2 + 2 + 1;
nStates = nStates + nSpecialStates;

stateLabels = zeros(nStates, 1);

%%
stateTransP = cell(length(words.data),1);
currIdx = 1;

for w=1:length(words.data)
    word = words.textdata{w};
    for c=1:length(word)
        letterIdx = unicodeToLetterIdx(word(c));
        
        for augIdx=1:2
            stateLabels(currIdx) = letterIdx;
            
            if c==length(word) && augIdx==2
                %special transitioning out of a word state (most likely
                %goes to space, comma, etc. but can skip to a next word
                %with low probability)
                stateTransP{currIdx} = -1;
            else
                %transition to next augmented state or next letter
                stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
            end

            currIdx = currIdx + 1;
        end
    end
end

%special state: space
spaceStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('>');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
    else
        %transitioning to a word state
        stateTransP{currIdx} = -2;
    end
    
    currIdx = currIdx + 1;
end

%special state: comma
commaStateIdx = currIdx;
letterIdx = unicodeToLetterIdx(',');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); spaceStateIdx, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end

%special state: 's
pluralStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('''');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];

    currIdx = currIdx + 1;
end

letterIdx = unicodeToLetterIdx('s');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); spaceStateIdx, 1-charStayProb(letterIdx)];
    end

    currIdx = currIdx + 1;
end

%special state: period
periodStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('~');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); nStates, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end

%special state: question
questionStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('?');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx+1, 1-charStayProb(letterIdx)];
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); nStates, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end

%special state: termination
terminationStateIdx = nStates;
stateLabels(currIdx) = length(letters)+1;

%%



