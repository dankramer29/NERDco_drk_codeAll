load('/Users/frankwillett/Downloads/radial8Controller%2FfinalOutput.mat')
finalOutputs = permute(finalOutputs, [2 1 3]);

nUnits = 256;
outputSets = {1:nUnits, (nUnits+1):(nUnits+6)};
setNames = {'Units','Mus'};

for setIdx = 1:length(outputSets)
    features = reshape(finalOutputs(:,:,outputSets{setIdx}),[],length(outputSets{setIdx}));
    
    if setIdx==2
        features = repmat(features, 1, 5);
    end
    
    nPerTrial = size(finalOutputs,1);
    margNames = {'Dir', 'CI'};
    nReps = 10;
    features = repmat(features, nReps, 1);
    features = features + randn(size(features))*0.0001;
    
    out = apply_dPCA_simple( features, 1:nPerTrial:size(features,1), repmat((1:8)', nReps, 1), [40,120], 0.01, margNames );

    lineArgs = cell(8,1);
    targColors = hsv(8)*0.8;
    for t=1:length(targColors)
        lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
    end
    timeAxis = (40:120)*0.01 - 0.5;

    yAxesFinal = oneFactor_dPCA_plot( out, timeAxis, lineArgs, margNames, 'zoom' );
end

%%
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/dPCA/';
mkdir(saveDir);

datasets = {'ringsControllerCLOpenSimTraj (1)', 16, 4;
    'ringDelayOpenSimTraj (3)', 8, 4;
    'ringDelayOpenSimTraj_slow', 8, 4;
    'openSimTraj_delayRings_3ew_stacked', 8, 4;
    'musLenForce_ringsDelay_OS', 8, 4;
    'mpc_delayRings_bmAbs%2FopenSim_stacked', 8, 4;
    'mpc_delayRings_baselineCost%2FopenSim_stacked', 8, 4;
    'mpc_delayRings_baselineCost%2FopenSim_stacked (1)', 8, 4;
    '2layer_posErr%2FopenSim_stacked',8,4;
    'randomDelay%2FopenSim_stacked',8,4;
    'randomDelay_2comp%2FopenSim_stacked',8,1;};

for datasetIdx=1:size(datasets,1)
    dat = load(['/Users/frankwillett/Data/Derived/armControlNets/' datasets{datasetIdx,1} '.mat']);
    nAngles = datasets{datasetIdx,2};
    nDist = datasets{datasetIdx,3};
    
    dat.musFeedback = dat.as(:,[6,7,8,9,10,11,17,21,25,29,33,37]+1);
    dat.posErr = dat.inp(:,1:2)-dat.as(:,47:48);
    if datasetIdx>=9
        setNames = {'units0','units1','mus','musFeedback','posErr'};
    else
        setNames = {'units','mus'};
    end
    
    for setIdx = 1:length(setNames)
        features = dat.(setNames{setIdx});
        originalFeatures = features;
        nTrials = size(features,1)/100;

        if setIdx>2
            features = repmat(features, 1, 5);
        end

        nPerTrial = 100;
        margNames = {'Dir', 'CI'};
        nReps = 10;
        features = repmat(features, nReps, 1);
        features = features + randn(size(features))*0.01;

        %single factor
        out = apply_dPCA_simple( features, 1:nPerTrial:size(features,1), repmat((1:nTrials)', nReps, 1), [0,99], 0.01, margNames );
        close(gcf);
        
        lineArgs = cell(nTrials,1);
        targColors = repmat(hsv(nAngles)*0.8,nDist,1);
        for t=1:length(targColors)
            lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
        end
        timeAxis = (0:99)*0.01 - 0.25;

        yAxesFinal = oneFactor_dPCA_plot( out, timeAxis, lineArgs, margNames, 'zoom', dat.meanSpeed' );
        saveas(gcf, [saveDir datasets{datasetIdx,1} '_' setNames{setIdx} '_1fac.png'],'png');
        
        %two factor
        dirFactor = repmat((1:nAngles)', nReps*nDist, 1);
        distFactor = repmat(1:nDist,  nAngles, 1);
        distFactor = repmat(distFactor(:), nReps, 1);
        margNames = {'Dir', 'Dist', 'CI', 'Dir x Dist'};

        out = apply_dPCA_simple( features, 1:nPerTrial:size(features,1), [dirFactor, distFactor], [0,99], 0.01, margNames );
        close(gcf);
        
        lineArgs = cell(nAngles, nDist);
        lStyles = {':','--','-.','-'};
        dirColors = hsv(nAngles)*0.8;
        for dirIdx=1:nAngles
            for distIdx=1:nDist
                lineArgs{dirIdx, distIdx} = {'Color',dirColors(dirIdx,:),'LineWidth',2,'LineStyle',lStyles{distIdx}};
            end
        end
        timeAxis = (0:99)*0.01 - 0.25;

        yAxesFinal = twoFactor_dPCA_plot( out, timeAxis, lineArgs, margNames, 'zoom', dat.meanSpeed' );
        saveas(gcf, [saveDir datasets{datasetIdx,1} '_' setNames{setIdx} '_2fac.png'],'png');
        
        %%
        %jPCA
        Data = struct();
        trlIdx = 1:100;
        timeMS = round(timeAxis*1000);
        for n=1:nTrials
            Data(n).A = originalFeatures(trlIdx, :);
            Data(n).times = timeMS;
            trlIdx = trlIdx + length(trlIdx);
        end

        jPCA_params.normalize = true;
        jPCA_params.softenNorm = 0;
        jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.meanSubtract = true;
        jPCA_params.numPCs = 6;  % default anyway, but best to be specific

        windowIdx = [0, 150];
        
        %short window
        jPCATimes = windowIdx(1):10:windowIdx(2);
        for x = 1:length(jPCATimes)
            [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
            jPCATimes(x) = Data(1).times(minIdx);
        end

        [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
        phaseSpace(Projections, jPCA_Summary);  % makes the plot
        
        %%
        ofByTrl = reshape(originalFeatures, 100, nTrials, []);
        ofByTrl = permute(ofByTrl, [2 1 3]);
        mn = mean(ofByTrl,1);
        meanSubtractByTrl = ofByTrl - mn;
        
        msFeatures = reshape(permute(meanSubtractByTrl, [2 1 3]), nTrials*100, []);
        
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(msFeatures);
        
        colors = repmat(hsv(8)*0.8, 4, 1);
        trlIdx = 1:100;
        figure
        hold on;
        for t=1:nTrials
            plot3(SCORE(trlIdx,1), SCORE(trlIdx,2), SCORE(trlIdx,3), 'Color', colors(t,:), 'LineWidth', 2);
            plot3(SCORE(trlIdx(1),1), SCORE(trlIdx(1),2), SCORE(trlIdx(1),3), 'o', 'Color', 'k', 'LineWidth', 5);
            plot3(SCORE(trlIdx(end),1), SCORE(trlIdx(end),2), SCORE(trlIdx(end),3), 'o', 'Color', 'r', 'LineWidth', 5);
            trlIdx = trlIdx + length(trlIdx);
        end
        
        colors = repmat(hsv(8)*0.8, 4, 1);
        trlIdx = 1:100;
        figure
        hold on;
        for t=1:nTrials
            plot3(SCORE(trlIdx,4), SCORE(trlIdx,5), SCORE(trlIdx,6), 'Color', colors(t,:), 'LineWidth', 2);
            plot3(SCORE(trlIdx(1),4), SCORE(trlIdx(1),5), SCORE(trlIdx(1),6), 'o', 'Color', 'k', 'LineWidth', 5);
            plot3(SCORE(trlIdx(end),4), SCORE(trlIdx(end),5), SCORE(trlIdx(end),6), 'o', 'Color', 'r', 'LineWidth', 5);
            trlIdx = trlIdx + length(trlIdx);
        end
    end
    close all;
end
