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
unigram_logP = log(words.data)-log(totalCounts);

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
endOfWordStates = zeros(length(words.data),1);
endOfWordTransProb = zeros(length(words.data),1);
newWordStates = zeros(length(words.data),1);
newWordStayProb_logP = zeros(length(words.data),1);
stateWordIdx = zeros(nStates,1);

stateTransP = cell(length(words.data),1);
currIdx = 1;

for w=1:length(words.data)
    word = words.textdata{w};
    newWordStates(w) = currIdx;
    newWordStayProb_logP(w) = log(charStayProb(unicodeToLetterIdx(word(1))));
    
    for c=1:length(word)
        letterIdx = unicodeToLetterIdx(word(c));
        
        for augIdx=1:2
            stateLabels(currIdx) = letterIdx;
            stateWordIdx(currIdx) = w;
            
            if c==1 && augIdx==1
                %special word-start acceptor - accepts from space and from other
                %words (low probability)
                stateTransP{currIdx} = -1;
            else
                %accepts from current state or previous state
                if augIdx==1
                    prevLetterIdx = unicodeToLetterIdx(word(c-1));
                    stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(prevLetterIdx)];
                else
                    stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(letterIdx)];
                end
            end

            currIdx = currIdx + 1;
        end
        
        endOfWordStates(w) = currIdx-1;
        endOfWordTransProb(w) = 1-charStayProb(letterIdx);
    end
end

endOfWordTransProb_logP = log(endOfWordTransProb);

%special state: space
spaceStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('>');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        %accepts from all end-of-words
        stateTransP{currIdx} = -2;
    else
        %accepts from previous space state
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end
spaceEndStateIdx = currIdx-1;

%special state: comma
commaStateIdx = currIdx;
letterIdx = unicodeToLetterIdx(',');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = -2;
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end
commaEndStateIdx = currIdx-1;

%special state: 's
pluralStateIdx = currIdx;
for augIdx=1:2
    stateLabels(currIdx) = unicodeToLetterIdx('''');
    if augIdx==1
        stateTransP{currIdx} = -2;
    else
        stateTransP{currIdx} = [currIdx, charStayProb(unicodeToLetterIdx('''')); currIdx-1, 1-charStayProb(unicodeToLetterIdx(''''))];
    end

    currIdx = currIdx + 1;
end

for augIdx=1:2
    stateLabels(currIdx) = unicodeToLetterIdx('s');
    if augIdx==1
        stateTransP{currIdx} = [currIdx, charStayProb(unicodeToLetterIdx('s')); currIdx-1, 1-charStayProb(unicodeToLetterIdx(''''))];
    else
        stateTransP{currIdx} = [currIdx, charStayProb(unicodeToLetterIdx('s')); currIdx-1, 1-charStayProb(unicodeToLetterIdx('s'))];
    end

    currIdx = currIdx + 1;
end
pluralEndStateIdx = currIdx-1;

%special state: period
periodStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('~');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = -2;
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end
periodLastStateIdx = currIdx-1;

%special state: question
questionStateIdx = currIdx;
letterIdx = unicodeToLetterIdx('?');
for augIdx=1:2
    stateLabels(currIdx) = letterIdx;
    if augIdx==1
        stateTransP{currIdx} = -2;
    else
        stateTransP{currIdx} = [currIdx, charStayProb(letterIdx); currIdx-1, 1-charStayProb(letterIdx)];
    end
    
    currIdx = currIdx + 1;
end
questionLastStateIdx = currIdx-1;

%special state: termination
terminationStateIdx = nStates;
stateLabels(currIdx) = length(letters)+1;
stateTransP{currIdx} = [currIdx, 1; questionLastStateIdx, 1-charStayProb(unicodeToLetterIdx('?')); periodLastStateIdx, 1-charStayProb(unicodeToLetterIdx('~'))];

for x=1:length(stateTransP)
    if length(stateTransP{x})>1
        stateTransP{x}(:,2) = log(stateTransP{x}(:,2));
    end
end

%%
%end of word -> space, comma, plural, question, period, skip words
%comma -> space
%plural -> comma, space
%skip words, space -> new word

spaceProb = 0.86;
commaProb = 0.03;
pluralProb = 0.02;
spaceSkipProb = 0.03;
periodProb = 0.03;
questionProb = 0.03;

spaceAcceptor_logP = zeros(length(words.data),2);
spaceAcceptor_logP(:,1) = endOfWordStates;
spaceAcceptor_logP(:,2) = endOfWordTransProb*spaceProb;
spaceAcceptor_logP = [spaceAcceptor_logP; commaEndStateIdx, 1-charStayProb(unicodeToLetterIdx(','))];
spaceAcceptor_logP = [spaceAcceptor_logP; pluralEndStateIdx, (1-charStayProb(unicodeToLetterIdx('s'))*(1-commaProb))];
spaceAcceptor_logP = [spaceAcceptor_logP; spaceStateIdx, 1-charStayProb(unicodeToLetterIdx('>'))];
spaceAcceptor_logP(:,2) = log(spaceAcceptor_logP(:,2));

commaAcceptor_logP = zeros(length(words.data),2);
commaAcceptor_logP(:,1) = endOfWordStates;
commaAcceptor_logP(:,2) = endOfWordTransProb*commaProb;
commaAcceptor_logP = [commaAcceptor_logP; pluralEndStateIdx, (1-charStayProb(unicodeToLetterIdx('s'))*commaProb)];
commaAcceptor_logP = [commaAcceptor_logP; commaStateIdx, 1-charStayProb(unicodeToLetterIdx(','))];
commaAcceptor_logP(:,2) = log(commaAcceptor_logP(:,2));

pluralAcceptor_logP = zeros(length(words.data),2);
pluralAcceptor_logP(:,1) = endOfWordStates;
pluralAcceptor_logP(:,2) = endOfWordTransProb*pluralProb;
pluralAcceptor_logP = [pluralAcceptor_logP; pluralStateIdx, 1-charStayProb(unicodeToLetterIdx(''''))];
pluralAcceptor_logP(:,2) = log(pluralAcceptor_logP(:,2));

periodAcceptor_logP = zeros(length(words.data),2);
periodAcceptor_logP(:,1) = endOfWordStates;
periodAcceptor_logP(:,2) = endOfWordTransProb*periodProb;
periodAcceptor_logP = [periodAcceptor_logP; periodStateIdx, 1-charStayProb(unicodeToLetterIdx('~'))];
periodAcceptor_logP(:,2) = log(periodAcceptor_logP(:,2));

questionAcceptor_logP = zeros(length(words.data),2);
questionAcceptor_logP(:,1) = endOfWordStates;
questionAcceptor_logP(:,2) = endOfWordTransProb*questionProb;
questionAcceptor_logP = [questionAcceptor_logP; questionStateIdx, 1-charStayProb(unicodeToLetterIdx('?'))];
questionAcceptor_logP(:,2) = log(questionAcceptor_logP(:,2));

stateTransP{spaceStateIdx} = spaceAcceptor_logP;
stateTransP{commaStateIdx} = commaAcceptor_logP;
stateTransP{pluralStateIdx} = pluralAcceptor_logP;
stateTransP{periodStateIdx} = periodAcceptor_logP;
stateTransP{questionStateIdx} = questionAcceptor_logP;

startProb = -inf(length(stateLabels),1);
startProb(newWordStates) = unigram_logP;

spaceLeaveProb_logP = log(1-charStayProb(unicodeToLetterIdx('>')));

newWordAcceptor = [endOfWordStates, endOfWordTransProb_logP + log(spaceSkipProb);
    spaceEndStateIdx, spaceLeaveProb_logP;
    0, 0];

%%
rnnOut = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/rnnSentenceOutput_87.mat');
%rnnOut = load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/rnnSentenceOutput_86.mat');

%%
decStatePaths = cell(length(rnnOut.rnnProb), 1);

%%
parfor sentenceIdx=1:10
    oProb = rnnOut.rnnProb{sentenceIdx};
    oProb = oProb(3:end,:);
    oProb(:,32) = 0;
    oProb = [oProb; zeros(10,size(oProb,2))];
    oProb((end-9):end,32) = 1;
    oProb = log(oProb);

    statePath = hmmViterbiLanguageModel(oProb,startProb,stateLabels,stateTransP,spaceEndStateIdx,...
        stateWordIdx,unigram_logP,newWordStayProb_logP);
    
    disp(horzcat(decLetters{stateLabels(statePath)}))
    decStatePaths{sentenceIdx} = statePath;
end

decLetters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z',...
    ' ',',','''','.','?',''};

sp = decStatePaths{5};
disp(horzcat(decLetters{stateLabels(sp)}))

%%
allCleanText = cell(length(rnnOut.rnnProb), 1);

for sentenceIdx=1:length(rnnOut.rnnProb)
    if isempty(decStatePaths{sentenceIdx})
        continue
    end
    
    sp = decStatePaths{sentenceIdx};
    slPath = stateLabels(sp);
    wPath = stateWordIdx(sp);

    cleanText = '';
    currIdx = 1;
    while currIdx>0
        if wPath(currIdx)>0
            cleanText = [cleanText, words.textdata{wPath(currIdx)}];
            currIdx = currIdx+find(wPath(currIdx:end)~=wPath(currIdx),1,'first')-1;
            if isempty(currIdx)
                currIdx = -1;
            end
        else
            cleanText = [cleanText, decLetters{slPath(currIdx)}];
            currIdx = currIdx+find(slPath(currIdx:end)~=slPath(currIdx),1,'first')-1;
            if isempty(currIdx)
                currIdx = -1;
            end
        end
    end
    
    allCleanText{sentenceIdx} = cleanText;
end

%%
wordErrCount = zeros(length(rnnOut.rnnProb), 1);
wordCount = zeros(length(rnnOut.rnnProb), 1);
charCount = zeros(length(rnnOut.rnnProb), 1);

for sentenceIdx=1:length(rnnOut.rnnProb)
    trueText = strrep(rnnOut.trueText(sentenceIdx,:),' ','');
    trueText = strrep(trueText,'>',' ');
    trueText = strrep(trueText,'~','.');
    
    C = strsplit(trueText); 
    w = WER(allCleanText{sentenceIdx}, trueText);

    wordCount(sentenceIdx) = length(C);
    wordErrCount(sentenceIdx) = w(1)*length(C);
    
    tmp = strrep(rnnOut.trueText(sentenceIdx,:),' ','');
    charCount(sentenceIdx) = length(tmp);
end

disp(100*sum(wordErrCount(1:10))/sum(wordCount(1:10)));

valIdx = [99   40    22    34    92    91    35     6    55     3];
cpmTrials = (charCount(1:10)./(numBinsPerTrial(valIdx)/100))*60;

disp(60*sum(charCount)/(sum(numBinsPerTrial(valIdx))/100));

%%
load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/timeSeriesData/t5.2019.05.08.mat');
load('/Users/frankwillett/Data/Derived/Handwriting/rnnDecoding/cvPartitions/t5.2019.05.08_cvPartitions.mat')

%%
charPerTrial = zeros(length(mappedText),1);
timePerTrial = numBinsPerTrial/100;
for t=1:length(charPerTrial)
    tmp = strrep(mappedText{t},' ','');
    charPerTrial(t) = length(tmp);
end

badTrials = [18, 32, 62];
useTrl = setdiff(1:length(mappedText), badTrials);

cpm = 60*(sum(charPerTrial)/sum(timePerTrial));
%cpm = 67.1731

%%
%exampleTrl = 1;
%exampleSnippet = [234, 265];

exampleTrl = 5;
exampleSnippet = [234, 278];

timeAxis = (exampleSnippet(1):exampleSnippet(2))/5;

figure('Position',[ 680   800   443   298]);
plot(timeAxis, rnnOut.rnnProb{exampleTrl}(exampleSnippet(1):exampleSnippet(2),1:31),'LineWidth',3);
xlabel('Time (s)');
set(gca,'FontSize',24,'LineWidth',2);
ylabel('Grapheme Probability');
axis tight;
saveas(gcf,'/Users/frankwillett/Data/Derived/Handwriting/systemFigure/graphemeProbabilities.svg','svg');

disp(rnnOut.rnnText(exampleTrl, exampleSnippet(1):exampleSnippet(2)));

exampleSnippetRaw = (1000 + exampleSnippet*200)/10;
exData = squeeze(fullData(valIdx(exampleTrl),:,:));
exData = gaussSmooth_fast(exData, 4.0);
exData = exData(exampleSnippetRaw(1):exampleSnippetRaw(2),:)';

ta2 = linspace(timeAxis(1), timeAxis(end), size(exData,2));

figure('Position',[ 680   800   443   298]);
imagesc(ta2, 1:size(exData,1), exData,[-1 1.5]);
colormap(gray);
xlabel('Time (s)');
set(gca,'FontSize',24,'LineWidth',2,'YDir','normal');
ylabel('Channel #');
axis tight;
saveas(gcf,'/Users/frankwillett/Data/Derived/Handwriting/systemFigure/neuralRaster.svg','svg');

%%
%exampleTrl = 1;
%exampleSnippet = [234, 265];

exampleTrl = 2;
exampleSnippet = [1, 389];

timeAxis = (exampleSnippet(1):exampleSnippet(2))/5;

figure('Position',[ -81         740        2002         278]);
plot(timeAxis, rnnOut.rnnProb{exampleTrl}(exampleSnippet(1):exampleSnippet(2),1:31),'LineWidth',3);
xlabel('Time (s)');
set(gca,'FontSize',24,'LineWidth',2);
ylabel('Grapheme Probability');
axis tight;
saveas(gcf,'/Users/frankwillett/Data/Derived/Handwriting/systemFigure/graphemeProbabilities_long2.svg','svg');

disp(rnnOut.rnnText(exampleTrl, exampleSnippet(1):exampleSnippet(2)));

exampleSnippetRaw = (1000 + exampleSnippet*200)/10;
exData = squeeze(fullData(valIdx(exampleTrl),:,:));
exData = gaussSmooth_fast(exData, 4.0);
exData = exData(exampleSnippetRaw(1):exampleSnippetRaw(2),:)';

ta2 = linspace(timeAxis(1), timeAxis(end), size(exData,2));

figure('Position',[ -81         740        2002         278]);
imagesc(ta2, 1:size(exData,1), exData,[-1 1.5]);
colormap(gray);
xlabel('Time (s)');
set(gca,'FontSize',24,'LineWidth',2,'YDir','normal');
ylabel('Channel #');
axis tight;
saveas(gcf,'/Users/frankwillett/Data/Derived/Handwriting/systemFigure/neuralRaster_long2.svg','svg');

figure; 
imagesc(rnnOut.rnnProb{2}');
set(gca,'YTick',1:31,'YTickLabel',letters,'FontSize',16);

%%
save('/Users/frankwillett/Data/Derived/Handwriting/sentence_lm_output_87','allCleanText','decStatePaths','cpmTrials','wordErrCount','wordCount');