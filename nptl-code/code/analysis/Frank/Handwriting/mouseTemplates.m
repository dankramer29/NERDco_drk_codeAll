%%
blockList = [0 1 2 3];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'MouseTemplates' filesep];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 'mouseHandWriting' filesep 'handDrawing' filesep];

%%       
bNums = horzcat(blockList);
movField = 'windowsMousePosition';
filtOpts.filtFields = {'windowsMousePosition'};
filtOpts.filtCutoff = 10/500;
R = getStanfordRAndStream( sessionPath, horzcat(blockList), 4.5, blockList(1), filtOpts );

allR = []; 
for x=1:length(R)
    for t=1:length(R{x})
        R{x}(t).blockNum=bNums(x);
        R{x}(t).currentMovement = repmat(R{x}(t).startTrialParams.currentMovement,1,length(R{x}(t).clock));
    end
    allR = [allR, R{x}];
end

for t=1:length(allR)
    allR(t).headVel = [0 0 0; diff(allR(t).rigidBodyPosXYZ')]';
end

alignFields = {'goCue'};
smoothWidth = 0;
datFields = {'rigidBodyPosXYZ','currentMovement','headVel','windowsMousePosition'};
timeWindow = [-1000,4000];
binMS = 10;
alignDat = binAndAlignR( allR, timeWindow, binMS, smoothWidth, alignFields, datFields );

meanRate = mean(alignDat.rawSpikes)*1000/binMS;
tooLow = meanRate < 1.0;
alignDat.rawSpikes(:,tooLow) = [];
alignDat.meanSubtractSpikes(:,tooLow) = [];
alignDat.zScoreSpikes(:,tooLow) = [];

alignDat.zScoreSpikes_allBlocks = zscore(alignDat.rawSpikes);
alignDat.zScoreSpikes_blockMean = alignDat.zScoreSpikes;

smoothSpikes_allBlocks = gaussSmooth_fast(zscore(alignDat.rawSpikes),3);
smoothSpikes_blockMean = gaussSmooth_fast(alignDat.zScoreSpikes,3);

trlCodes = alignDat.currentMovement(alignDat.eventIdx);
nothingTrl = trlCodes==218;

uniqueCodes = unique(trlCodes);
letterCodes = uniqueCodes(2:29);
curveCodes = uniqueCodes(30:end);
codeSets = {letterCodes, curveCodes};
movLabels = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt',...
    'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};

movLabels1 = {'a','b','c','d','t','m','o','e','f','g','h','i','j','k','l','n','p','q','r','s','u','v','w','x','y','z','dash','gt'};
movLabels2 = {'cv1','cv2','cv3','cv4','cv5','cv6','cv7','cv8','cv9','cv10','cv11','cv12','cv13','cv14','cv15','cv16','cv17','cv18','cv19',...
    'cv20','cv21','cv22','cv23','cv24','cv25','cv26','cv27','cv28','cv29','cv30','cv31','cv32','cv33','cv34','cv35','cv36',...
    'cv37','cv38','cv39','cv40'};
movLabelSets = {movLabels1, movLabels2};

%%
uc = uniqueCodes(2:end);
timeEnd = zeros(length(uc),1)+110;

timeEnd(1) = 110; 
timeEnd(2) = 120; 
timeEnd(3) = 100;
timeEnd(4) = 110;
timeEnd(5) = 110;
timeEnd(6) = 140;
timeEnd(10) = 120;
timeEnd(14) = 130;
timeEnd(15) = 80;
timeEnd(17) = 120;
timeEnd(18) = 120;
timeEnd(19) = 130;
timeEnd(21) = 100;
timeEnd(22) = 80;
timeEnd(26) = 100;
timeEnd(27) = 80;

timeEnd(29) = 60;
timeEnd(30) = 60;
timeEnd(31) = 60;
timeEnd(32) = 60;
timeEnd(33) = 60;
timeEnd(34) = 60;
timeEnd(35) = 60;
timeEnd(36) = 60;

templates = cell(length(uc),1);
for t=1:length(uc)
    trlIdx = find(trlCodes==uc(t));
    trlIdx = trlIdx(end);
    loopIdx = (alignDat.eventIdx(trlIdx)):(alignDat.eventIdx(trlIdx)+timeEnd(t));
    
    vel = diff(alignDat.windowsMousePosition(loopIdx,1:2));
    templates{t} = vel;
end

%use 44 as 90-degree bend template
rot90 = [[cosd(-90), cosd(0)]; [sind(-90), sind(0)]];
rotNeg90 = [[cosd(90), cosd(180)]; [sind(90), sind(180)]];
rotNeg180 = [[cosd(180), cosd(270)]; [sind(180), sind(270)]];

templates{43} = templates{44}.*[-1, 1];
templates{41} = (rot90*templates{44}')';
templates{42} = (rot90*templates{43}')';
templates{45} = (rotNeg90*templates{43}')';
templates{46} = (rotNeg90*templates{44}')';
templates{47} = (rotNeg180*templates{43}')';
templates{48} = (rotNeg180*templates{44}')';

%use 51 as c-curve template
templates{52} = templates{51}.*[-1, 1];
templates{49} = (rot90*templates{51}')';
templates{50} = (rot90*templates{52}')';
templates{53} = (rotNeg90*templates{52}')';
templates{54} = (rotNeg90*templates{51}')';
templates{55} = (rotNeg180*templates{52}')';
templates{56} = (rotNeg180*templates{51}')';

%use 66 as hook template
templates{65} = templates{66}.*[1, -1];
templates{67} = (rotNeg90*templates{66}')';
templates{68} = (rotNeg90*templates{65}')';

%identify start and end of each template
speedThresh = 0.001;
for t=1:length(templates)
    spd = matVecMag(templates{t},2);
    startIdx = find(spd>speedThresh,1,'first');
    endIdx = find(spd>speedThresh,1,'last');
    
    templates{t} = templates{t}(startIdx:endIdx,:);
end

%add blank z
for t=1:length(templates)
    templates{t} = [templates{t}, zeros(size(templates{t},1),1)];
end

%fix noise in f at the end
templates{9}(72:76,2) = 0;

%Add z dimension describing lift-off and re-placement of the pencil on the
%page. First, pull a pulse template from "a"; then, apply it wherever it is
%needed manually.

%biphasicPulse = -templates{1}(1:36,1);
biphasicPulse = templates{27}(9:23,1);

pulsePlacement = {64, 1:27;
    63, 4:23;
    62, 1:30;
    61, 3:19;
    60, 6:21;
    59, 2:32;
    58, 7:23;
    57, 8:25;
    25, 25:50;
    24, 20:45;
    14, 30:52;
    13, 43:66;
    12, 37:57;
    9, 48:66;
    5, 33:54;};

for p=1:size(pulsePlacement,1)
    warpPulse = interp1(linspace(0,1,length(biphasicPulse)),biphasicPulse,linspace(0,1,length(pulsePlacement{p,2})));
    templates{pulsePlacement{p,1}}(pulsePlacement{p,2},3) = warpPulse;
end

%%
figure('Position',[680          57        1148        1041]);
for t=1:length(movLabels)
    subtightplot(9,9,t);
    
    trlIdx = find(trlCodes==uc(t));
    trlIdx = trlIdx(end);
    loopIdx = (alignDat.eventIdx(trlIdx)):(alignDat.eventIdx(trlIdx)+timeEnd(t));
    
    hold on;
    pos = cumsum( templates{t});
    plot(pos(:,1), pos(:,2), 'LineWidth', 2);
    
    posRaw = alignDat.windowsMousePosition(loopIdx,:);
    posRaw = posRaw - posRaw(1,:);
    plot(posRaw(:,1), posRaw(:,2), '--', 'LineWidth', 2);
    
    xLim = get(gca,'XLim');
    xAxis = linspace(xLim(1), xLim(2), length(templates{t}));
    %plot(xAxis(1:(end-1)), diff(alignDat.windowsMousePosition(loopIdx,1:2))*10, 'LineWidth', 2);
    plot(xAxis, templates{t}*10, 'LineWidth', 2);
    
    axis off;
    axis equal;
    
    title(t);
end

%%
figure('Position',[680          57        1148        1041]);
for t=1:length(movLabels)
    subtightplot(9,9,t);
    
    trlIdx = find(trlCodes==uc(t));
    trlIdx = trlIdx(end);
    loopIdx = (alignDat.eventIdx(trlIdx)):(alignDat.eventIdx(trlIdx)+timeEnd(t));
    
    hold on;
    
    xLim = get(gca,'XLim');
    %plot(xAxis(1:(end-1)), diff(alignDat.windowsMousePosition(loopIdx,1:2))*10, 'LineWidth', 2);
    plot(templates{t}*10, 'LineWidth', 2);
    
    axis off;
    
    title(t);
end

%%
save([outDir 'templates_sp.mat'], 'templates');

