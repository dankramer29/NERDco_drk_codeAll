function [movLabelSets, codeSets, fullCodes, allLabels, allTemplates, allTemplateCodes, allTimeWindows] = allAlphabetCodePreamble()
    %define codes of interest and matching templates
    letterCodes = [400:406, 412:432];
    curveCodes = [486:525]; 
    wordCodes = [2092 2256 2272 2282 2291];
    punctuationCodes = [580 581 582 583];
    bezierCodes = 540:579;
    prepArrowCodes = [526:537];
    speedSizeCodes = [439 441 445 447 448 450 454 456 457 459 463 464 465 467 471 473];
    bezierCodes2 = (581:636)+1000; %to avoid overlap with punctuation codes
    bezierCodes3 = 741:796;
    bezierCodes4 = 797:844;
    bezierCodes5 = 637:692;
    
    letterLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
    curveLabels = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
        'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
        'cv37','cv38','cv39','cv40'};
    wordLabels = {'word1','word2','word3','word4','word5'};
    punctuationLabels = {'comma','apos','tilde','question'};
    bezierLabels = {'right1a','right2a','right3a','right4a','right5a','right6a',...
        'up1a','up2a','up3a','up4a','up5a','up6a',...
        'left1a','left2a','left3a','left4a','left5a','left6a',...
        'down1a','down2a','down3a','down4a','down5a','down6a',...
        'rd1a','rd2a','rd3a','rd4a','rd5a','rd6a','rd7a','rd8a','rd9a','rd10a','rd11a','rd12a','rd13a','rd14a','rd15a','r1d6a'};
    speedSizeLabels = {'aSmallSlow','aBigSlow','aSmallFast','aBigFast',...
        'mSmallSlow','mBigSlow','mSmallFast','mBigFast',...
        'zSmallSlow','zBigSlow','zSmallFast','zBigFast',...
        'tSmallSlow','tBigSlow','tSmallFast','tBigFast'};
    prepArrowLabels = {'fastRight','fastRightDown','fastRightUp','fastRightUpLeft','fastRightUpRight','fastRightUpRightSlash', ...
        'slowRight','slowRightDown','slowRightUp','slowRightUpLeft','slowRightUpRight','slowRightUpRightSlash'};
    bezierLabels2 = {'right1h','right2h','right3h','right4h','right5h','right6h','right7h','right8h','right9h','right10h',...
        'up1h','up2h','up3h','up4h','up5h','up6h','up7h','up8h','up9h','up10h',...
        'left1h','left2h','left3h','left4h','left5h','left6h','left7h','left8h','left9h','left10h'...
        'down1h','down2h','down3h','down4h','down5h','down6h','down7h','down8h','down9h','down10h',...
        'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
         };
   betterBezierLabels = {'rightCW1','rightCW2','rightCW3','rightCCW1','rightCCW2','rightCCW3',...
        'upCW1','upCW2','upCW3','upCCW1','upCCW2','upCCW3',...
        'leftCW1','leftCW2','leftCW3','leftCCW1','leftCCW2','leftCCW3',...
        'downCW1','downCW2','downCW3','downCCW1','downCCW2','downCCW3',...
        'straight1','straight2','straight3','straight4','straight5','straight6','straight7','straight8',...
        'straight9','straight10','straight11','straight12','straight13','straight14','straight15','straight16'};
    bezierLabels3 = {'rightCW1','rightCW2','rightCW3','rightCCW1','rightCCW2','rightCCW3',...
        'upCW1','upCW2','upCW3','upCCW1','upCCW2','upCCW3',...
        'leftCW1','leftCW2','leftCW3','leftCCW1','leftCCW2','leftCCW3',...
        'downCW1','downCW2','downCW3','downCCW1','downCCW2','downCCW3',...
        'straight1','straight2','straight3','straight4','straight5','straight6','straight7','straight8',...
        'straight9','straight10','straight11','straight12','straight13','straight14','straight15','straight16',...
        'bendRightCW','bendRightCCW','bendUpCW','bendUpCCW','bendLeftCW','bendLeftCCW','bendDownCW','bendDownCCW',...
        'stopRightCW','stopRightCCW','stopUpCW','stopUpCCW','stopLeftCW','stopLeftCCW','stopDownCW','stopDownCCW',...
         };
    bezierLabels4 = {'single1CW','double1CCW','single1CCW','double1CW',...
        'single2CW','double2CCW','single2CCW','double2CW',...
        'single3CW','double3CCW','single3CCW','double3CW',...
        'single4CW','double4CCW','single4CCW','double4CW',...
        'single5CW','double5CCW','single5CCW','double5CW',...
        'single6CW','double6CCW','single6CCW','double6CW',...
        'single7CW','double7CCW','single7CCW','double7CW',...
        'single8CW','double8CCW','single8CCW','double8CW',...
        'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
         };
     bezierLabels5 = {'right3CW','right2CW','right1CW','right4CW','right5CW',...
        'right3CCW','right2CCW','right1CCW','right4CCW','right5CCW',...
        'up3CW','up2CW','up1CW','up4CW','up5CW',...
        'up3CCW','up2CCW','up1CCW','up4CCW','up5CCW',...
        'left3CW','left2CW','left1CW','left4CW','left5CW',...
        'left3CCW','left2CCW','left1CCW','left4CCW','left5CCW',...
        'down3CW','down2CW','down1CW','down4CW','down5CW',...
        'down3CCW','down2CCW','down1CCW','down4CCW','down5CCW',...    
        'rd1h','rd2h','rd3h','rd4h','rd5h','rd6h','rd7h','rd8h','rd9h','rd10h','rd11h','rd12h','rd13h','rd14h','rd15h','r1d6h',...
         };
     
    movLabelSets = {letterLabels, curveLabels, wordLabels, prepArrowLabels, speedSizeLabels, bezierLabels, bezierLabels2, bezierLabels3, bezierLabels4, bezierLabels5};
    codeSets = {letterCodes, curveCodes, wordCodes, prepArrowCodes, speedSizeCodes, bezierCodes, bezierCodes2, bezierCodes3, bezierCodes4, bezierCodes5};
    
    fullCodes = [letterCodes, curveCodes, wordCodes, punctuationCodes, bezierCodes, prepArrowCodes, speedSizeCodes, bezierCodes2, bezierCodes3, bezierCodes4, bezierCodes5];
    allLabels = [letterLabels, curveLabels, wordLabels, punctuationLabels, bezierLabels, prepArrowLabels, speedSizeLabels, bezierLabels2, bezierLabels3, bezierLabels4, bezierLabels5];
    
    tempAlphabetCurve = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_sp.mat');
    tempPunctuation = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_punctuation.mat');
    tempPrepArrow = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_prepArrowSeries.mat');
    tempBezier = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates/templates.mat');
    tempBezier2 = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates2/templates.mat');
    tempBezier3 = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates4/templates.mat');
    tempBezier4 = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates5/templates.mat');
    tempBezier5 = load('/Users/frankwillett/Data/Derived/Handwriting/BezierTemplates6/templates.mat');
    tempAGQ = load('/Users/frankwillett/Data/Derived/Handwriting/MouseTemplates/templates_fixedAGQ.mat');
    tempAlphabetCurve.templates([1 10 18]) = tempAGQ.templates;
    
    allTemplateCodes = [letterCodes, curveCodes, tempPunctuation.templateCodes, tempPrepArrow.templateCodes, ...
        bezierCodes, speedSizeCodes, bezierCodes2, bezierCodes3, bezierCodes4, bezierCodes5];
    
    %add zero Z to bezier templates
    for t=1:length(tempBezier.templates)
        tempBezier.templates{t} = [tempBezier.templates{t}, zeros(length(tempBezier.templates{t}),1)];
    end
    for t=1:length(tempBezier2.templates)
        tempBezier2.templates{t} = [tempBezier2.templates{t}, zeros(length(tempBezier2.templates{t}),1)];
    end
    for t=1:length(tempBezier3.templates)
        tempBezier3.templates{t} = [tempBezier3.templates{t}, zeros(length(tempBezier3.templates{t}),1)];
    end
    for t=1:length(tempBezier4.templates)
        tempBezier4.templates{t} = [tempBezier4.templates{t}, zeros(length(tempBezier4.templates{t}),1)];
    end
    for t=1:length(tempBezier5.templates)
        tempBezier5.templates{t} = [tempBezier5.templates{t}, zeros(length(tempBezier5.templates{t}),1)];
    end
    
    %fix template units
    for t=1:length(tempPunctuation.templates)
        tempPunctuation.templates{t} = tempPunctuation.templates{t}/1000;
    end
    for t=1:length(tempPrepArrow.templates)
        tempPrepArrow.templates{t} = tempPrepArrow.templates{t}/1000;
    end
    for t=1:length(tempBezier.templates)
        tempBezier.templates{t} = tempBezier.templates{t}/10;
    end
    for t=1:length(tempBezier2.templates)
        tempBezier2.templates{t} = tempBezier2.templates{t}/10;
    end
    for t=1:length(tempBezier3.templates)
        tempBezier3.templates{t} = tempBezier3.templates{t}/10;
    end
    for t=1:length(tempBezier4.templates)
        tempBezier4.templates{t} = tempBezier4.templates{t}/10;
    end
    for t=1:length(tempBezier5.templates)
        tempBezier5.templates{t} = tempBezier5.templates{t}/10;
    end

    %reorder punctuation template
    tempPunctuation.templates = tempPunctuation.templates([4 3 1 2]);
    
    speedSizeLetterIdx = [1 1 1 1 6 6 6 6 26 26 26 26 5 5 5 5];
    allTemplates = [tempAlphabetCurve.templates; tempPunctuation.templates; tempPrepArrow.templates; ...
        tempBezier.templates; tempAlphabetCurve.templates(speedSizeLetterIdx); tempBezier2.templates; tempBezier3.templates; tempBezier4.templates; tempBezier5.templates];
    
    allTimeWindows = zeros(length(fullCodes),2);
    allTimeWindows(:,1) = -50;
    allTimeWindows(ismember(fullCodes, letterCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, curveCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, wordCodes),2) = 400; 
    allTimeWindows(ismember(fullCodes, punctuationCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes2),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes3),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes4),2) = 150; 
    allTimeWindows(ismember(fullCodes, bezierCodes5),2) = 150; 
    allTimeWindows(ismember(fullCodes, prepArrowCodes),2) = 250; 
    allTimeWindows(ismember(fullCodes, speedSizeCodes),2) = 250;
    
    %annotate curvature
    for t=1:length(allTemplates)
        allTemplates{t} = [allTemplates{t}, zeros(size(allTemplates{t},1),1)];
    end
    
    curveWindows = {'a',[1 50 -1; 66 81 -1];
        'b',[31 71 1];
        'c',[1 51 -1];
        'd',[1 41 -1];
        't',[11 26 -1];
        'm',[31 47 1; 61 81 1;];
        'o',[1 61 -1];
        'e',[11 66 -1];
        'f',[1 26 -1];
        'g',[1 41 -1; 66 86 1];
        'h',[36 56 1];
        'i',[];
        'j',[1 26 1];
        'k',[];
        'l',[];
        'n',[36 61 1];
        'p',[46 76 1]
        'q',[1 46 -1; 71 91 1];
        'r',[46 71 1];
        's',[1 31 -1; 31 56 1];
        'u',[1 31 -1];
        'v',[];
        'w',[];
        'x',[];
        'y',[];
        'z',[];
        'dash',[];
        'gt',[];
        'cv1',[];
        'cv2',[];
        'cv3',[];
        'cv4',[];
        'cv5',[];
        'cv6',[];
        'cv7',[];
        'cv8',[];
        'cv9',[];
        'cv10',[];
        'cv11',[];
        'cv12',[];
        'cv13',[1 41 1];
        'cv14',[1 41 -1];
        'cv15',[1 41 -1];
        'cv16',[1 41 1];
        'cv17',[1 41 -1];
        'cv18',[1 41 1];
        'cv19',[1 41 -1];
        'cv20',[1 41 1];
        'cv21',[1 36 1];
        'cv22',[1 36 -1];
        'cv23',[1 36 1];
        'cv24',[1 36 -1];
        'cv25',[1 36 -1];
        'cv26',[1 36 1];
        'cv27',[1 36 -1];
        'cv28',[1 36 1];
        'cv29',[];
        'cv30',[];
        'cv31',[];
        'cv32',[];
        'cv33',[];
        'cv34',[];
        'cv35',[];
        'cv36',[];
        'cv37',[26 46 1];
        'cv38',[26 46 -1];
        'cv39',[26 46 -1];
        'cv40',[26 46 1];
        'right1a',[1 70 1];
        'right2a',[1 70 1];
        'right3a',[1 70 1];
        'right4a',[1 70 -1];
        'right5a',[1 70 -1];
        'right6a',[1 70 -1];
        'up1a',[1 70 1];
        'up2a',[1 70 1];
        'up3a',[1 70 1];
        'up4a',[1 70 -1];
        'up5a',[1 70 -1];
        'up6a',[1 70 -1];
        'left1a',[1 70 1];
        'left2a',[1 70 1];
        'left3a',[1 70 1];
        'left4a',[1 70 -1];
        'left5a',[1 70 -1];
        'left6a',[1 70 -1];
        'down1a',[1 70 1];
        'down2a',[1 70 1];
        'down3a',[1 70 1];
        'down4a',[1 70 -1];
        'down5a',[1 70 -1];
        'down6a',[1 70 -1];
        'rd1a',[];
        'rd2a',[];
        'rd3a',[];
        'rd4a',[];
        'rd5a',[];
        'rd6a',[];
        'rd7a',[];
        'rd8a',[];
        'rd9a',[];
        'rd10a',[];
        'rd11a',[];
        'rd12a',[];
        'rd13a',[];
        'rd14a',[];
        'rd15a',[];
        'rd16a',[];
        
        'right1h',[1 70 1];
        'right2h',[1 70 1];
        'right3h',[1 70 1];
        'right4h',[1 70 1];
        'right5h',[1 70 1];
        'right6h',[1 70 -1];
        'right7h',[1 70 -1];
        'right8h',[1 70 -1];
        'right9h',[1 70 -1];
        'right10h',[1 70 -1];
        'up1h',[1 70 1];
        'up2h',[1 70 1];
        'up3h',[1 70 1];
        'up4h',[1 70 1];
        'up5h',[1 70 1];
        'up6h',[1 70 -1];
        'up7h',[1 70 -1];
        'up8h',[1 70 -1];
        'up9h',[1 70 -1];
        'up10h',[1 70 -1];
        'left1h',[1 70 1];
        'left2h',[1 70 1];
        'left3h',[1 70 1];
        'left4h',[1 70 1];
        'left5h',[1 70 1];
        'left6h',[1 70 -1];
        'left7h',[1 70 -1];
        'left8h',[1 70 -1];
        'left9h',[1 70 -1];
        'left10h',[1 70 -1];
        'down1h',[1 70 1];
        'down2h',[1 70 1];
        'down3h',[1 70 1];
        'down4h',[1 70 1];
        'down5h',[1 70 1];
        'down6h',[1 70 -1];
        'down7h',[1 70 -1];
        'down8h',[1 70 -1];
        'down9h',[1 70 -1];
        'down10h',[1 70 -1];
        };
    
    for t=1:length(fullCodes)
        tempIdx = find(allTemplateCodes==fullCodes(t));        
        curveIdx = find(strcmp(curveWindows(:,1),allLabels{t}));
        if isempty(tempIdx) || isempty(curveIdx)
            continue;
        end
        
        cWin = curveWindows{curveIdx,2};
        for x=1:size(cWin,1)
            loopIdx = cWin(x,1):cWin(x,2);
            allTemplates{tempIdx}(loopIdx,end) = cWin(x,3);
        end
    end
    
end