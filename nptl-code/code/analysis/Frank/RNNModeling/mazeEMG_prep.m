datasets = {'2009-09-12','2009-09-16'};
fileDir = '/Users/frankwillett/Data/Derived/armControlNets/MazeDataset/';

for datasetIdx=1:length(datasets)
    load([fileDir 'Mjs.mat']);
    load([fileDir 'N,' datasets{datasetIdx} ',1-2,quicky-ss.mat']);
    load([fileDir 'RC,' datasets{datasetIdx} ',1-2,quicky-ss.mat']);
    saveDir = ['/Users/frankwillett/Data/Derived/armControlNets/MazeResults/' datasets{datasetIdx} '/'];
    mkdir(saveDir);
    
    nCon = length(Ns(1).cond);
    numBarriers = zeros(nCon,1);
    for x=1:nCon
        numBarriers(x) = Ns(1).cond(x).protoTrial.numBarriers;
    end

    nonMazeCon = find(numBarriers==0);
    figure
    hold on
    for x=1:length(nonMazeCon)
        handX = Ns(2).cond(nonMazeCon(x)).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(nonMazeCon(x)).protoTrial.handY_SameTimesAsMove;
        plot(handX, handY);
        text(handX(end), handY(end), num2str(nonMazeCon(x)));
    end
    axis equal;

    %%
    allVel = cell(length(Ns(2).cond),1);
    colors = hsv(256)*0.8;
    colorLaunch = zeros(length(Ns(2).cond),3);
    
    figure
    hold on
    for x=1:length(Ns(2).cond)
        handX = Ns(2).cond(x).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(x).protoTrial.handY_SameTimesAsMove;
        
        allVel{x} = diff([handX, handY]);
        launchVec = allVel{x}(50,:);
        launchAngle = atan2(launchVec(2), launchVec(1));
        colorIdx = round(256*(launchAngle+pi)/(2*pi));
        colorLaunch(x,:) = colors(colorIdx,:);
        
        plot(handX, handY, 'Color', colorLaunch(x,:), 'LineWidth', 3);
        text(handX(end), handY(end), num2str(x), 'FontSize',18,'FontWeight','bold');
    end
    axis equal;
    
    %%
    if strcmp(datasets{datasetIdx},'2009-09-16')
        curveLabels = [0, -1, -1, 0, -1, -1, 0, 1, ...
            1, 0, 1, 1, 0, 1, 1, 0, ...
            -1, -1, 0, -1, -1, 0, -1, -1, ...
            0, -1, -1];
        curveLabels(curveLabels==-1) = 2;
    elseif strcmp(datasets{datasetIdx},'2009-09-12')
        curveLabels = [0, -1, -1, 0, 0, 0, ...
            0, -1, -1, 0, -1, -1, ...
            0, 1, 1, 0, 1, 1, ...
            0, -1, -1, 0, -1, -1, ...
            0, 1, 1];
        curveLabels(curveLabels==-1) = 2;
    end
    
    %%
    nCon = length(Ns(2).cond);
    nEMG = length(Mjs);
    nBins = 121;
    
    nNeural = length(Ns);
    avgNeural = zeros(nNeural, nCon, nBins);
    for n=1:nCon
        for neuralIdx=1:length(Ns)
            tmp = Ns(neuralIdx).cond(n).MoveLocked.meanFR';
            %tmp = gaussSmooth_fast(tmp, 3);
            avgNeural(neuralIdx,n,:) = tmp;
        end
    end
    areaIdx = [Ns.oneForPMdtwoforM1];

    prepIdx = 1:20;
    prepVec = zeros(nCon, nNeural);
    for n=1:nCon
        prepVec(n,:) = squeeze(mean(avgNeural(:,n,prepIdx),3));
    end
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);
    SCORE = SCORE(:,1:3);
    
    figure; 
    hold on;
    for s=1:size(SCORE,1)
        if ismember(s, nonMazeCon)
            mType = 'o';
        else
            mType = 's';
        end
        
        plot3(SCORE(s,1), SCORE(s,2), SCORE(s,3), mType, 'Color', colorLaunch(s,:), ...
            'MarkerFaceColor', colorLaunch(s,:), 'MarkerSize',16)
        text(SCORE(s,1), SCORE(s,2), SCORE(s,3), num2str(s), 'FontSize',14);
    end
    
    colorCW = hsv(2)*0.8;
    figure; 
    hold on;
    for s=1:size(SCORE,1)
        if curveLabels(s)==0
            mType = 'o';
            cToUse = colorLaunch(s,:);
        else
            mType = 's';
            cToUse = colorCW(curveLabels(s),:);
        end
        
        plot3(SCORE(s,1), SCORE(s,2), SCORE(s,3), mType, 'Color', cToUse, ...
            'MarkerFaceColor', cToUse, 'MarkerSize',16)
        text(SCORE(s,1), SCORE(s,2), SCORE(s,3), num2str(s), 'FontSize',14);
    end
end