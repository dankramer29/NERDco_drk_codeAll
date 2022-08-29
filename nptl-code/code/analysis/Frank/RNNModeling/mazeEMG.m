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

    %balancedCon = [22, 16, 13, 10];
    balancedCon = [22, 13, 4, 1];
    colors = hsv(length(balancedCon))*0.8;
    
    figure
    hold on
    for x=1:length(balancedCon)
        handX = Ns(2).cond(balancedCon(x)).protoTrial.handX_SameTimesAsMove;
        handY = Ns(2).cond(balancedCon(x)).protoTrial.handY_SameTimesAsMove;
        plot(handX, handY,'LineWidth',4,'Color',colors(x,:));
        %text(handX(end), handY(end), num2str(nonMazeCon(x)));
    end
    axis equal;
    axis off;
    exportPNGFigure(gcf, [saveDir 'movLegend']);
    
    nCon = length(balancedCon);
    nEMG = length(Mjs);
    nBins = 121;
    avgEMG = zeros(nEMG, nCon, nBins);
    for n=1:nCon
        for emgIdx=1:length(Mjs)
            avgEMG(emgIdx,n,:) = Mjs(emgIdx).cond(balancedCon(n)).MoveLocked.meanFR;
        end
    end

    nNeural = length(Ns);
    avgNeural = zeros(nNeural, nCon, nBins);
    for n=1:nCon
        for neuralIdx=1:length(Ns)
            tmp = Ns(neuralIdx).cond(balancedCon(n)).MoveLocked.meanFR';
            %tmp = gaussSmooth_fast(tmp, 3);
            avgNeural(neuralIdx,n,:) = tmp;
        end
    end
    areaIdx = [Ns.oneForPMdtwoforM1];

    speedProfiles = [];
    for n=1:nCon
        speedProfiles = [speedProfiles, Mjs(1).cond(balancedCon(n)).protoTrial.handVel_SameTimesAsMove];
    end

    figure
    plot(speedProfiles,'LineWidth',2);
    legend({'1','2','3','4'});

    %70 from EMG to kin
    %150 from M1 to kin
    useUnits = [Ns.initialUnitRating]>=0;
    vars = {avgEMG, squeeze(avgNeural(useUnits & areaIdx==1,:,:)), squeeze(avgNeural(useUnits & areaIdx==2,:,:))};
    varNames = {'EMG','PMd','M1'};
    
    for varIdx = 1:length(vars)
        time = 0:(nBins-1);
        time = time - time(1);
        timeEvents = 0;

        combinedParams = {{1, [1 2]}, {2}};
        margNames = {'CD', 'CI'};
        margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

        var = vars{varIdx};

        [W,V,whichMarg] = dpca(var, size(var,1), ...
            'combinedParams', combinedParams);

        explVar = dpca_explainedVariance(var, W, V, ...
            'combinedParams', combinedParams, ...
            'numOfTrials', ones(size(var,1), size(var,2)));

        out.W = W;
        out.whichMarg = whichMarg;
        out.V = V;
        out.explVar = explVar;

        Z = dpca_plot(var, W, V, @dpca_plot_default, ...
            'explainedVar', explVar, ...
            'marginalizationNames', margNames, ...
            'marginalizationColours', margColours, ...
            'whichMarg', whichMarg,                 ...
            'time', time,                        ...
            'timeEvents', timeEvents,               ...
            'timeMarginalization', 3,           ...
            'legendSubplot', 16);
        out.Z = Z;
        close(gcf);

        nCon = 4;
        lineArgs = cell(nCon,1);
        targColors = hsv(nCon)*0.8;
        for t=1:length(targColors)
            lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
        end
        time = time * 0.01;

        yAxesFinal = oneFactor_dPCA_plot( out, time, lineArgs, margNames, 'zoom', speedProfiles);
        exportPNGFigure(gcf, [saveDir varNames{varIdx}]);
    end
    
    %%
    %align to go
    condNum = [R.primaryCondNum];
    
    balancedCon = [22, 16, 13, 10];
    for n=1:nCon
        trlIdx = find(condNum==balancedCon(n));
    end
    
    figure
    for n=1:nCon
        subplot(1,nCon,n);
        hold on;
        for m=1:length(Mjs)
            plot(Mjs(m).cond(balancedCon(n)).MoveLocked.meanFR)
        end
    end
end