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
    allLaunchDir = zeros(length(Ns(2).cond),2);
    
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
        
        allLaunchDir(x,:) = launchVec/norm(launchVec); 
        
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
    %decode velocity
    avgVel = zeros(2, nCon, nBins);
    for n=1:nCon
        avgVel(1,n,:) = [0; diff(Ns(2).cond(n).protoTrial.handX_SameTimesAsMove)*100];
        avgVel(2,n,:) = [0; diff(Ns(2).cond(n).protoTrial.handY_SameTimesAsMove)*100];
    end
    
    tmpX = squeeze(avgVel(1,:,:))';
    tmpY = squeeze(avgVel(2,:,:))';
    
    unrollVel = [tmpX(:), tmpY(:)];

    unrollNeural = zeros(size(unrollVel,1),size(avgNeural,1));
    for x=1:size(avgNeural,1)
        tmp = squeeze(avgNeural(x,:,:))';
        unrollNeural(:,x) = tmp(:);
    end
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(unrollNeural);
    reducedNeural = SCORE(:,1:20);
    
    velLag = 10;
    
    [ filts, featureMeans ] = buildLinFilts( unrollVel((velLag+1):end,:), [ones(length(reducedNeural)-velLag,1), reducedNeural(1:(end-velLag),:)], ...
        'standard' );
    predVel = [ones(length(reducedNeural),1), reducedNeural]*filts;
    
    figure;
    subplot(1,2,1);
    hold on;
    plot(predVel(:,1),'--');
    plot(unrollVel(:,1));
    
    subplot(1,2,2);
    hold on;
    plot(predVel(:,2),'--');
    plot(unrollVel(:,2));  
    
    %%
    %curvature decoder
    allNeural = [];
    allLabel = [];
    for x=1:size(avgVel,2)
        newLabel = zeros(121,1);
        if curveLabels(x)==1
            newLabel(:) = 1;
        elseif curveLabels(x)==2
            newLabel(:) = -1;
        end
        
        newNeural = squeeze(avgNeural(:,x,:))';
        
        allNeural = [allNeural; newNeural];
        allLabel = [allLabel; newLabel];
    end
       
    [ filts_curve, featureMeans ] = buildLinFilts( allLabel, [ones(length(reducedNeural),1), reducedNeural], ...
        'ridge', 1e3);
    predCurve = [ones(length(reducedNeural),1), reducedNeural]*filts_curve;
    
    %%
    %make prep decoder
    allNeural = [];
    allLabel = [];
    for x=1:length(nonMazeCon)
        traj = squeeze(avgVel(:,nonMazeCon(x),:))';
        dir = mean(traj);
        dir = dir/norm(dir);
        
        newlabel = zeros(80,2);
        newLabel(1:30,:) = repmat(dir,30,1);
        newLabel(31:80,:) = 0;
        
        newNeural = squeeze(avgNeural(:,nonMazeCon(x),1:80))';
        
        allNeural = [allNeural; newNeural];
        allLabel = [allLabel; newLabel];
    end
    
    [COEFF, SCORE_prep, LATENT, TSQUARED, EXPLAINED] = pca(allNeural);
    reducedNeural_prep = SCORE_prep(:,1:20);
    
    [ filts_prep, featureMeans ] = buildLinFilts( allLabel, [ones(length(reducedNeural_prep),1), reducedNeural_prep], ...
        'ridge', 1e3);
    predPrep_straight = [ones(length(reducedNeural_prep),1), reducedNeural_prep]*filts_prep;
    predPrep = [ones(length(reducedNeural),1), reducedNeural]*filts_prep;
    
    %%
    [COEFF, SCORE_prep, LATENT, TSQUARED, EXPLAINED, MU] = pca(prepVec);

    [ filts_prep, featureMeans ] = buildLinFilts( allLaunchDir, [ones(length(SCORE_prep),1), SCORE_prep(:,1:3)], ...
        'standard');

    tmp = [ones(length(SCORE_prep),1), SCORE_prep(:,1:3)]*filts_prep;
    predPrep = [ones(size(allNeural,1),1), (allNeural-MU)*COEFF(:,1:3)]*filts_prep;
    
    %%
    zVel = (unrollVel)./std(unrollVel);
    zPredVel = (predVel)./std(predVel);
    zPredCurve = (predCurve)./std(predCurve);
    zPredPrep = (predPrep)./std(predPrep);
    
    nPages = 18;
    plotIdx = 1;
    currIdx = 1;
    plotPerPage = 6;
    
    for pageIdx=1:nPages
        figure('Position',[680           1         514        1097]);
        for plotIdx=1:plotPerPage
            loopIdx = ((currIdx-1)*121+1):(currIdx*121);

            for dimIdx=1:3
                subplot(plotPerPage,3,(plotIdx-1)*3+dimIdx);
                hold on;
                
                if dimIdx==3
                    pos = cumsum(unrollVel(loopIdx,:));
                    plot(pos(:,1), pos(:,2), 'LineWidth',3);
                    plot(pos(1,1),pos(1,2),'o');
                    axis equal;
                else
                    %plot(zVel(loopIdx,dimIdx),'LineWidth',3);
                    plot(zPredVel(loopIdx,dimIdx),'LineWidth',3);
                    plot(zPredCurve(loopIdx,1),'LineWidth',3);
                    plot(zPredPrep(loopIdx,dimIdx),'LineWidth',3);
                    ylim([-3,3]);
                end
            end
            
            currIdx = currIdx + 1;
        end
    end
    
end