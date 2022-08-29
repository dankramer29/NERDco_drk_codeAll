datasets = {'Jenkins_array_MATstructs_N_N,2009-09-18,1-2,good-ss',...
    'Nitschke_array_MATstructs_N_N,2010-09-23,1-2-3-4-5,decent-ss'};
sessionNames = {'Jenkins.2019.09.18',...
    'Nitschke.2010.09.23'};
fileDir = '/Users/frankwillett/Data/Monk/Maze/';

for datasetIdx=1:length(datasets)
    load([fileDir datasets{datasetIdx}]);
    saveDir = ['/Users/frankwillett/Data/Derived/Handwriting/MonkMaze/' sessionNames{datasetIdx} '/'];
    mkdir(saveDir);
    
    nCon = length(Ns(1).cond);
    numBarriers = zeros(nCon,1);
    for x=1:nCon
        numBarriers(x) = Ns(1).cond(x).protoTrial.numBarriers;
    end

    %%
    nonMazeCon = find(numBarriers==0);
    mazeCon = find(numBarriers>0);
    
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
        if ismember(x, mazeCon)
            launchVec = allVel{x}(50,:);
        else
            launchVec = mean(allVel{x});
        end
        
        launchAngle = atan2(launchVec(2), launchVec(1));
        colorIdx = round(256*(launchAngle+pi)/(2*pi));
        colorLaunch(x,:) = colors(colorIdx,:);
        
        %if ismember(x, mazeCon)
            plot(handX, handY, 'Color', colorLaunch(x,:), 'LineWidth', 3);
            text(handX(end), handY(end), num2str(x), 'FontSize',18,'FontWeight','bold');
        %end
    end
    axis equal;
    
    %%
    %find curvature axis
    allCurveDir = zeros(length(Ns(1).cond),2);
    allCurveMag = zeros(length(Ns(1).cond),1);
    for x=1:length(Ns(2).cond)
        traj = [Ns(2).cond(x).protoTrial.handX_SameTimesAsMove, Ns(2).cond(x).protoTrial.handY_SameTimesAsMove];
        traj = traj-traj(1,:);
        
        trajEnd = traj(end,:);
        trajStart = traj(1,:);
        
        totalDir = trajEnd-trajStart;
        totalDir = totalDir/norm(totalDir);
        
        orthoDir = [1,0];
        orthoDir(2) = -orthoDir(1)*totalDir(1)/totalDir(2);
        orthoDir = orthoDir / norm(orthoDir);
        
        proj = traj*orthoDir';
        [~,maxIdx] = max(abs(proj));
        curveSign = sign(proj(maxIdx));
        
        curveDir = orthoDir*curveSign;
        allCurveDir(x,:) = curveDir;
        allCurveMag(x) = max(abs(proj));
    end
       
    figure
    hold on
    for x=1:length(Ns(2).cond)
        handX = Ns(2).cond(x).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(x).protoTrial.handY_SameTimesAsMove;
        
        launchAngle = atan2(allCurveDir(x,2), allCurveDir(x,1));
        colorIdx = round(256*(launchAngle+pi)/(2*pi));
        
        if ismember(x, mazeCon)
            plot(handX, handY, 'Color', colors(colorIdx,:), 'LineWidth', 3);
            text(handX(end), handY(end), num2str(x), 'FontSize',18,'FontWeight','bold');
        end
    end
    axis equal;
    
    curveMagColor = zeros(length(allCurveMag),3);
    colors = jet(256);
    
    figure
    hold on
    for x=1:length(Ns(2).cond)
        handX = Ns(2).cond(x).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(x).protoTrial.handY_SameTimesAsMove;
        
        launchAngle = atan2(allCurveDir(x,2), allCurveDir(x,1));
        colorIdx = round(256*allCurveMag(x)/max(allCurveMag));
        curveMagColor(x,:) = colors(colorIdx,:);
        
        plot(handX, handY, 'Color', curveMagColor(x,:), 'LineWidth', 3);
        text(handX(end), handY(end), num2str(x), 'FontSize',18,'FontWeight','bold');
    end
    axis equal;
    
    %%
    if strcmp(sessionNames{datasetIdx},'Jenkins.2019.09.18')
        %0 = straight, 1 = clockwise, -1 = counter-clockwise
        curveLabels = zeros(length(Ns(1).cond),1);
        curveLabels(8) = -1;
        curveLabels(62) = -1;
        curveLabels(63) = -1;
        curveLabels(21) = -1;
        curveLabels(20) = -1;
        curveLabels(108) = 1;
        curveLabels(107) = 1;
        curveLabels(9) = -1;
        curveLabels(95) = -1;
        curveLabels(96) = -1;
        curveLabels(74) = 1;
        curveLabels(75) = 1;
        curveLabels(72) = -1;
        curveLabels(42) = -1;
        curveLabels(71) = -1;
        curveLabels(41) = -1;
        curveLabels(54) = -1;
        curveLabels(53) = -1;
        curveLabels(18) = 1;
        curveLabels(17) = 1;
        curveLabels(86) = -1;
        curveLabels(105) = -1;
        curveLabels(104) = -1;
        curveLabels(87) = -1;
        curveLabels(29) = -1;
        curveLabels(30) = -1;
        curveLabels(2) = -1;
        curveLabels(3) = -1;
        curveLabels(60) = -1;
        curveLabels(59) = -1;
        curveLabels(92) = 1;
        curveLabels(93) = 1;
        curveLabels(26) = 1;
        curveLabels(27) = 1;
        curveLabels(69) = -1;
        curveLabels(86) = -1;
        curveLabels(38) = -1;
        curveLabels(39) = -1;
        curveLabels(11) = -1;
        curveLabels(12) = -1;
        curveLabels(98) = -1;
        curveLabels(99) = -1;
        curveLabels(84) = 1;
        curveLabels(83) = 1;
        curveLabels(47) = 1;
        curveLabels(6) = 1;
        curveLabels(5) = 1;
        curveLabels(48) = 1;
        curveLabels(24) = -1;
        curveLabels(23) = -1;
        curveLabels(80) = -1;
        curveLabels(57) = -1;
        curveLabels(56) = -1;
        curveLabels(81) = -1;
        curveLabels(102) = -1;
        curveLabels(101) = -1;
        curveLabels(44) = 1;
        curveLabels(45) = 1;
        curveLabels(15) = 1;
        curveLabels(51) = 1;
        curveLabels(14) = 1;
        curveLabels(50) = 1;
        curveLabels(66) = -1;
        curveLabels(89) = 1;
        curveLabels(90) = 1;
        curveLabels(65) = -1;
        curveLabels(32) = -1;
        curveLabels(33) = -1;
        curveLabels(108) = 1;
        curveLabels(107) = 1;
        curveLabels(35) = 1;
        curveLabels(36) = 1;
        curveLabels(77) = 1;
        curveLabels(78) = 1;
        curveLabels(68) = -1;
        curveLabels(curveLabels==-1) = 2;
        
    elseif strcmp(sessionNames{datasetIdx},'Nitschke.2010.09.23')
        curveLabels = zeros(length(Ns(1).cond),1);
        curveLabels(68) = -1;
        curveLabels(69) = -1;
        curveLabels(84) = -1;
        curveLabels(99) = -1;
        curveLabels(38) = -1;
        curveLabels(83) = -1;
        curveLabels(39) = -1;
        curveLabels(98) = -1;
        curveLabels(50) = 1;
        curveLabels(29) = 1;
        curveLabels(30) = 1;
        curveLabels(51) = 1;
        curveLabels(59) = 1;
        curveLabels(60) = 1;
        curveLabels(77) = 1;
        curveLabels(78) = 1;
        curveLabels(12) = 1;
        curveLabels(11) = 1;
        curveLabels(21) = -1;
        curveLabels(20) = -1;
        curveLabels(56) = -1;
        curveLabels(57) = -1;
        curveLabels(42) = -1;
        curveLabels(41) = -1;
        curveLabels(14) = -1;
        curveLabels(15) = -1;
        curveLabels(75) = -1;
        curveLabels(74) = -1;
        curveLabels(2) = 1;
        curveLabels(3) = 1;
        curveLabels(101) = 1;
        curveLabels(66) = 1;
        curveLabels(102) = 1;
        curveLabels(65) = 1;
        curveLabels(96) = 1;
        curveLabels(32) = 1;
        curveLabels(95) = 1;
        curveLabels(33) = 1;
        curveLabels(47) = -1;
        curveLabels(48) = -1;
        curveLabels(8) = -1;
        curveLabels(9) = -1;
        curveLabels(90) = -1;
        curveLabels(89) = -1;
        curveLabels(80) = 1;
        curveLabels(81) = 1;
        curveLabels(105) = 1;
        curveLabels(104) = 1;
        curveLabels(23) = 1;
        curveLabels(24) = 1;
        curveLabels(45) = 1;
        curveLabels(44) = 1;
        curveLabels(62) = -1;
        curveLabels(92) = -1;
        curveLabels(93) = -1;
        curveLabels(63) = -1;
        
        curveLabels(108) = -1;
        curveLabels(107) = -1;
        curveLabels(72) = 1;
        curveLabels(71) = 1;
        curveLabels(87) = 1;
        curveLabels(35) = 1;
        curveLabels(86) = 1;
        curveLabels(36) = 1;
        curveLabels(18) = -1;
        curveLabels(17) = -1;
        curveLabels(53) = -1;
        curveLabels(54) = -1;
        curveLabels(27) = 1;
        curveLabels(26) = 1;
        curveLabels(5) = -1;
        curveLabels(6) = -1;
        
        curveLabels(curveLabels==-1) = 2;
    end
    
    figure
    hold on
    for x=1:length(Ns(2).cond)
        handX = Ns(2).cond(x).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(x).protoTrial.handY_SameTimesAsMove;
        
        if curveLabels(x)==2
            cToUse = [0.8 0 0];
        elseif curveLabels(x)==1
            cToUse = [0 0 0.8];
        end
        
        if ismember(x, mazeCon)
            plot(handX, handY, 'Color', cToUse, 'LineWidth', 3);
            text(handX(end), handY(end), num2str(x), 'FontSize',18,'FontWeight','bold');
        end
    end
    axis equal;
    
    %%
    nCon = length(Ns(2).cond);
    nBins = 121;
    
    nNeural = length(Ns);
    avgNeural = zeros(nNeural, nCon, nBins);
    for n=1:nCon
        for neuralIdx=1:length(Ns)
            tmp = Ns(neuralIdx).cond(n).MoveLocked.meanFR';
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
        
        if curveLabels(s)~=0
            plot3(SCORE(s,4), SCORE(s,5), SCORE(s,6), mType, 'Color', cToUse, ...
                'MarkerFaceColor', cToUse, 'MarkerSize',16)
            text(SCORE(s,4), SCORE(s,5), SCORE(s,6), num2str(s), 'FontSize',14);
        end
    end
    
    %%
    %get radial subspace
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec(nonMazeCon,:));
    SCORE = (prepVec-MU)*COEFF;

    %get non-radial subspace
    [COEFF, SCORE_nonRadial, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec - SCORE(:,1:3)*COEFF(:,1:3)');

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
        
        if curveLabels(s)~=0
            plot3(SCORE_nonRadial(s,1), SCORE_nonRadial(s,2), SCORE_nonRadial(s,3), mType, 'Color', cToUse, ...
                'MarkerFaceColor', cToUse, 'MarkerSize',16)
            text(SCORE_nonRadial(s,1), SCORE_nonRadial(s,2), SCORE_nonRadial(s,3), num2str(s), 'FontSize',14);
        end
    end
    
    %%
    %color by curve mag
     [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);
    figure; 
    hold on;
    for s=1:size(SCORE,1)
        cToUse = curveMagColor(s,:);
        
        if curveLabels(s)~=0
            plot3(SCORE(s,4), SCORE(s,5), SCORE(s,6), mType, 'Color', cToUse, ...
                'MarkerFaceColor', cToUse, 'MarkerSize',16)
            text(SCORE(s,4), SCORE(s,5), SCORE(s,6), num2str(s), 'FontSize',14);
        end
    end    
    
    %%
    %color by curve direction angle
    colors = hsv(256)*0.8;
    figure; 
    hold on;
    for s=1:size(SCORE,1)
        curveAngle = atan2(allCurveDir(s,2), allCurveDir(s,1));
        colorIdx = round(256*(curveAngle+pi)/(2*pi));
        cToUse = colors(colorIdx,:);
        
        if curveLabels(s)~=0
            plot3(SCORE_nonRadial(s,1), SCORE_nonRadial(s,2), SCORE_nonRadial(s,3), mType, 'Color', cToUse, ...
                'MarkerFaceColor', cToUse, 'MarkerSize',16)
            text(SCORE_nonRadial(s,1), SCORE_nonRadial(s,2), SCORE_nonRadial(s,3), num2str(s), 'FontSize',14);
        end
    end
    
    %%
    clusters = {[77 78 92 93 26 27 18 17], ...
        [50 89 14 90 51 15 107 75], ...
        [57 80 98 24 102 101 23 99 81 69 68 12 11], ...
        [20 21 72 71 95 9 6 96 8 63 53 42 29 54 104 105 86 87 41 59 3 30 65 32 47 38 45 44 33 39 84 66 48 2 83 36 35 6 60 5]};
    
    figure
    hold on
    colors = hsv(4)*0.8;
    for clusterIdx=1:length(clusters)
        conIdx = clusters{clusterIdx};
        for x=1:length(conIdx)
            handX = Ns(2).cond(conIdx(x)).protoTrial.handX_SameTimesAsMove;
            handY = Ns(2).cond(conIdx(x)).protoTrial.handY_SameTimesAsMove;

            plot(handX, handY, 'Color', colors(clusterIdx,:), 'LineWidth', 3);
            text(handX(end), handY(end), num2str(conIdx(x)), 'FontSize',18,'FontWeight','bold');
        end
    end
end