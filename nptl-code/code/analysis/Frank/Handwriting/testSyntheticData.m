load('/Users/frankwillett/Data/Derived/Handwriting/bat1.mat');

%get aligned cube
warpCube = load(['/Users/frankwillett/Data/Derived/Handwriting/Cubes/t5.2019.06.26_valFold10_warpedCube.mat']);

%get a reduced template for each letter
letterCutoff = [151, 121, 95, 131, 121, 181, 121, 111, 171, 171, 111, 131, 91, 171, 51, 101, 121, ...
        171, 61, 131, 61, 51, 111, 111, 131, 121] + 60;
letters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z'};
templates = cell(length(letters),1);

for x=1:length(letters)
    tmp = warpCube.(letters{x});
    avg = squeeze(nanmean(tmp,1));
    smoothAvg = gaussSmooth_fast(avg,4.0);
    smoothAvg = smoothAvg(60:letterCutoff(x),:);

    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(smoothAvg);
    templates{x} = MU + (SCORE(:,1:10)*COEFF(:,1:10)');
end

%get text from labels
lbLetters = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','-'};
mappedText = cell(size(synthLabels,1),1);
for t=1:length(mappedText)
    sl = squeeze(synthLabels(t,:,:));
    
    slMax = zeros(size(sl,1),1);
    slChar = zeros(size(sl,1),1);
    for x=1:length(slMax)
        [~,slMax(x)] = max(sl(x,:));
        slChar(x) = char(lbLetters{slMax(x)});
    end
    
    diffPoint = [1; find(diff(slChar)~=0)+3];
    word = slChar(diffPoint);
    word(word=='-')=[];
    mappedText{t} = char(word)';
end
        
%estimated time per letter
charTimes = [1.8873    1.7251    1.4460    2.3449    1.3471    2.1174    2.3284, ...
    1.6697    1.7366    2.0320    2.0605    0.9188    2.2624    1.4814, ...
    1.7359    1.7486    2.5387    1.4503    1.4332    2.0136    1.1858, ...
    1.8473    1.6225    1.7308    1.7821    1.8579]';

for t=1:size(synthDat,1)
    dat = gaussianSmooth(squeeze(synthDat(t,:,:)), 4.0);    
    word = mappedText{t};
    datLabel = zeros(size(dat,1),1);

    %naive ballpark times
    allTempIdx = zeros(length(word),1);
    for c=1:length(word)
        allTempIdx(c) = find(strcmp(word(c), letters));
    end
    cTimes = charTimes(allTempIdx);
    cTimes = cumsum(cTimes);
    cTimes = [0; cTimes(1:(end-1))]/cTimes(end);

    heatmapCell = cell(length(word),1);

    %make heatmaps
    possibleStart = 1:10:(size(dat,1)-50);
    possibleStretch = linspace(0.66,1.5,10);

    for c=1:length(word)
        templateIdx = find(strcmp(word(c), letters));
        template = templates{templateIdx};
        allCorr = nan(length(possibleStretch), length(possibleStart));

        for stretchIdx=1:length(possibleStretch)
            newX = linspace(0,1,round(size(template,1)*possibleStretch(stretchIdx)));
            stretchedTemplate = interp1(linspace(0,1,size(template,1)), template, newX);
            for startIdx=1:length(possibleStart)
                loopIdx = possibleStart(startIdx):(possibleStart(startIdx)+size(stretchedTemplate,1)-1);
                if loopIdx(end)>size(dat,1)
                    continue;
                end
                cVal = nanmean(diag(corr(stretchedTemplate, dat(loopIdx,:))));
                allCorr(stretchIdx, startIdx) = cVal;
            end
        end
        heatmapCell{c} = allCorr;
    end

    %initial guess (pairwise stepping)
    [letterStarts, letterStretches] = stepForwardPairedLabeling(dat, templates, word, letters);
    heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, letterStarts/100, letterStretches );

    %iterative refinement
    allTempIdx = zeros(length(word),1);
    for c=1:length(word)
        allTempIdx(c) = find(strcmp(word(c), letters));
    end

    nReps = 3;
    [currStart, currStretch] = iterativeLabelSearch_additive(dat, templates(allTempIdx), word, possibleStretch, letterStarts, letterStretches, cTimes, nReps);
    heatmapWordPlot( heatmapCell, possibleStart/100, possibleStretch, word, currStart/100, currStretch );
end

