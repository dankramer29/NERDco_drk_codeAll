fid = fopen('/Users/frankwillett/Downloads/google-10000-english-master/google-10000-english-usa.txt','r');
dat = textscan(fid,'%s\n');
dat = dat{1};

letters = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};
wordBins = cell(length(letters),1);

for letterIdx=1:length(letters)
    wordBins{letterIdx} = [];
    
    for w=1:length(dat)
        if letters{letterIdx}==dat{w}(1)
            wordBins{letterIdx} = [wordBins{letterIdx}, w];
        end
    end
end

allWordLists = cell(length(letters),1);
for letterIdx=1:length(letters)
    possibleWords = dat(wordBins{letterIdx});
    numWords = 0;
    allWords = {};
    
    for w=1:length(possibleWords)
        nextWord = possibleWords{w};
        if length(nextWord)>2 && length(nextWord)<10
            numWords = numWords + 1;
            allWords = [allWords; nextWord];
        end
        
        if numWords>23
            break;
        end
    end
    
    allWordLists{letterIdx} = allWords;
end

%X
allWordLists{24} = {'xerox','xanax','xmen','xray','xylophone','xenial','xenophobe',...
    'xebec','xenia','xenic','xenon','xeric','xerus','xylan','xylem','xylol',...
    'xysti','xyloid','xylene','xenopus','xiphoid','xanthic','xyster','xeroses'}';

%Z
allWordLists{26} = {'zip','zone','zoom','zero','zoo','zambia','zen','zinc','zoloft','zenith',...
    'zerg','zoning','zephyr','zealot','zap','zebra','zigzag','zombie','zest','zodiac','zeal','zygote',...
    'ziplock','zipper'}';

%final shuffled word vector
finalVector = vertcat(allWordLists{:});
finalVector = finalVector(randperm(length(finalVector)));

save('/Users/frankwillett/Data/Derived/Handwriting/balancedWords.mat','finalVector');