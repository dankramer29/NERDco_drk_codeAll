%%
datasets = {'randomDelay%2FopenSimTraj',8,4;
    'randomDelay_2comp%2FopenSimTraj',8,4;
    'randomDelay_longInterval%2FopenSimTraj',8,4;
    '3comp%2FopenSimTraj',8,4
    '3comp%2FopenSimTraj_stagger',8,4;
    'mpc_rings_fbDelay_smallSpine%2FopenSimTraj',8,4;
    'mpc_rings_fbDelay_smallSpine_l2%2FopenSimTraj',8,4;
    'mpc_rings_fbDelay_smallSpine_sNoise%2FopenSimTraj',8,4;
    'mpc_smallSpine_vdistort%2FopenSimTraj',8,4;
    'mpc_smallSpine_vdistort_posErr%2FopenSimTraj',8,4;
    'mpc_smallSpine_vdistort_dualTarg%2FopenSimTraj',8,4
    'sheet_net%2FopenSimTraj',8,4;
    'sheet_net_2%2FopenSimTraj',8,4
    'sheet_net_3%2FopenSimTraj',8,4
    '3comp_vmr_musLenVel%2FopenSimTraj',8,4
    '3comp_vmr_musLenVel_posture%2FopenSimTraj',8,4
    '3comp_vmr_musLenVel_2%2FopenSimTraj',8,4
    '2comp_vmr_musLenVel%2FopenSimTraj (2)',8,4
    '2comp_vmr_musLenVel_bump%2FopenSimTraj',8,4
    '3comp_vmr_musLenVel_bump%2FopenSimTraj',8,4
    '3comp_musLenForceVel_sigmoid%2FopenSimTraj',8,4
    '2comp_musLenForceVel_rigid_vmr%2FopenSimTraj_oneShot',8,4};

for datasetIdx=1:size(datasets,1)
    dat = load(['/Users/frankwillett/Data/Derived/armControlNets/' datasets{datasetIdx,1} '.mat']);
    saveDir = ['/Users/frankwillett/Data/Derived/armControlNets/dPCA/' datasets{datasetIdx,1} filesep];
    mkdir(saveDir);

    nAngles = datasets{datasetIdx,2};
    nDist = datasets{datasetIdx,3};
    nTargs = size(dat.asPerTarg,1);
    nSteps = size(dat.excPerTarg,2);
    targColors = repmat(hsv(nAngles)*0.8,nDist,1);
    
    if isfield(dat,'rsPerTarg')
        nCompartments = size(dat.rsPerTarg,2)-1;
        for n=1:nCompartments
            dat.(['units' num2str(n-1)]) = zeros(nTargs, nSteps, size(dat.rsPerTarg{1,n},2));
            for t=1:nTargs
                dat.(['units' num2str(n-1)])(t,:,:) = dat.rsPerTarg{t,n};
            end
        end
    else
        fNames = fieldnames(dat);
        nCompartments = 0;
        for n=1:length(fNames)
            if ~isempty(strfind(fNames{n},'units'))
                nCompartments = nCompartments+1;
            end
        end
    end
    
    if isfield(dat,'targOnset')
        plotIdx = (50+dat.targOnset-30):(50+dat.targOnset+70);
        timeAxis = (single(plotIdx)/100.0 - single(plotIdx(1))/100.0)+0.7;
    else
        plotIdx = 70:170;
        timeAxis = plotIdx/100;
    end
    nSteps = length(plotIdx);
    
    dat.excPerTarg = dat.excPerTarg(:,plotIdx,:);
    for n = 0:(nCompartments-1)
        dat.(['units' num2str(n)]) = dat.(['units' num2str(n)])(:,plotIdx+1,:);
    end
    dat.asPerTarg = dat.asPerTarg(:,plotIdx+1,:);
    dat.inpPerTarg = dat.inpPerTarg(:,plotIdx,:);
    
    if strcmp(datasets{datasetIdx,1}(1:9),'sheet_net')
        sheetUnits = dat.units0;
        
        nSplits = 4;
        nCompartments = nSplits;
        nPerSplit = floor(size(sheetUnits,3)/nSplits);
        splitIdx = 1:nPerSplit;
        for n=1:nSplits
            dat.(['units' num2str(n-1)]) = sheetUnits(:,:,splitIdx);
            splitIdx = splitIdx + nPerSplit;
        end
    end
    
    %%
    %kinematics
    figure('Position',[209         636        1443         452]);
    subplot(1,3,1);
    hold on;
    for x=1:nTargs
        xVals = squeeze(dat.asPerTarg(x,:,47));
        yVals = squeeze(dat.asPerTarg(x,:,48));
        plot(xVals, yVals, 'Color',targColors(x,:),'LineWidth',2);
        %tR = 0.005;
        %rectangle('Position',[squeeze(dat.inpPerTarg(x,end,1))-tR, squeeze(dat.inpPerTarg(x,end,2))-tR, tR*2, tR*2],...
        %    'Curvature',[1 1],'EdgeColor',targColors(x,:),'LineWidth',2);
    end
    axis equal;
    
    for dimIdx=1:2
        subplot(1,3,dimIdx+1);
        hold on;
        for x=1:nTargs
            armPos = squeeze(dat.asPerTarg(x,:,46+dimIdx));
            plot(timeAxis, armPos,'Color',targColors(x,:),'LineWidth',2,'LineStyle','-');
            plot(timeAxis, squeeze(dat.inpPerTarg(x,:,dimIdx)),'Color',targColors(x,:),'LineWidth',2);
        end
        axis tight;
        plot([1,1],get(gca,'YLim'),'--k','LineWidth',2);
    end
    
    saveas(gcf, [saveDir 'kinematics.png'],'png');
    
    %%
    %muscle activity
    globalIdx = 1;
    figure('Position',[209          68        1495        1020]);
    for distIdx = 1:nDist
        for angleIdx = 1:nAngles
            subplot(nDist,nAngles,(distIdx-1)*nAngles + angleIdx);
            hold on;
            
            plot(timeAxis, squeeze(dat.excPerTarg(globalIdx,:,:)),'LineWidth',2);
            globalIdx = globalIdx+1;
            axis tight;
            ylim([0,1]);
        end
    end
    saveas(gcf, [saveDir 'musExc.png'],'png');
    
    %%
    %speed profile
    speedTraj = [];
    for x=1:nTargs
        speedTraj = [speedTraj; 100*[0; matVecMag(diff(squeeze(dat.asPerTarg(x,:,47:48))),2)]'];
    end
    
    targIdx = 1:nAngles;
    colors = jet(nDist)*0.8;
    
    figure
    hold on
    for x=1:nDist
        plot(timeAxis, speedTraj(targIdx,:)','Color', colors(x,:),'LineWidth',2);
        targIdx = targIdx + nAngles;
    end
    plot(timeAxis, mean(speedTraj),'Color','k','LineWidth',4);
    axis tight;
    
    meanSpeed = mean(speedTraj);
    saveas(gcf, [saveDir 'meanSpeed.png'],'png');
    %close all;
    %%
    %neural activity
    musFeedbackIdx = [6,7,8,9,10,11,17,21,25,29,33,37]+1;
    kinFeedbackIdx = [1,2,3,4,47,48];
    
    stackedDat = [];
    stackedDat.mus = reshape(permute(dat.excPerTarg,[2 1 3]), [nTargs*nSteps, size(dat.excPerTarg,3)]);
    stackedDat.musFeedback = reshape(permute(squeeze(dat.asPerTarg(:,:,musFeedbackIdx)),[2 1 3]), [nTargs*nSteps, length(musFeedbackIdx)]);
    stackedDat.kinFeedback = reshape(permute(squeeze(dat.asPerTarg(:,:,kinFeedbackIdx)),[2 1 3]), [nTargs*nSteps, length(kinFeedbackIdx)]);
    stackedDat.musFeedback = zscore(stackedDat.musFeedback);
    stackedDat.kinFeedback = zscore(stackedDat.kinFeedback);
    for y=1:nCompartments
        unitField = ['units' num2str(y-1)];
        stackedDat.(unitField) = reshape(permute(dat.(unitField),[2 1 3]), [nTargs*nSteps, size(dat.(unitField),3)]);
    end
    
    setNames = {};
    for y=1:nCompartments
        setNames{end+1} = ['units' num2str(y-1)];
    end
    setNames{end+1} = 'mus';
    setNames{end+1} = 'musFeedback';
    setNames{end+1} = 'kinFeedback';
        
    for setIdx = 1:length(setNames)
        features = stackedDat.(setNames{setIdx});
        originalFeatures = features;
        nTrials = size(features,1)/nSteps;

        if size(features,2)<50
            features = repmat(features, 1, 5);
        end

        margNames = {'Dir', 'CI'};
        nReps = 10;
        features = repmat(features, nReps, 1);
        features = features + randn(size(features))*0.01;

        targSets = {(nTargs-nAngles+1):nTargs, 1:nTargs};
        targSetNames = {'radial8','rings'};
        dPCA_results = cell(length(targSets),1);
        for targSetIdx=1:length(targSets)
            %single factor
            trialIdx = 1:nSteps:size(features,1);
            useTrialIdx = [];
            globalIdx = 0;
            for repIdx=1:nReps
                useTrialIdx = [useTrialIdx; targSets{targSetIdx}'+globalIdx];
                globalIdx = globalIdx + nTargs;
            end
            
            out = apply_dPCA_simple( features, trialIdx(useTrialIdx), repmat(targSets{targSetIdx}', nReps, 1), [0,nSteps-1], 0.01, margNames );
            close(gcf);
            dPCA_results{targSetIdx} = out;

            lineArgs = cell(nTrials,1);
            targColors = repmat(hsv(nAngles)*0.8,nDist,1);
            for t=1:length(targColors)
                lineArgs{t} = {'Color',targColors(t,:),'LineWidth',2};
            end

            yAxesFinal = oneFactor_dPCA_plot( out, timeAxis-timeAxis(1), lineArgs, margNames, 'zoom', meanSpeed' );
            saveas(gcf, [saveDir setNames{setIdx} '_1fac_' targSetNames{targSetIdx} '.png'],'png');
            save([saveDir setNames{setIdx} '_1fac_' targSetNames{targSetIdx} '.mat'],'out');
            
            %SFA-rotated dPCA
            sfaOut = sfaRot_dPCA( out );
            oneFactor_dPCA_plot( sfaOut, timeAxis-timeAxis(1), lineArgs, margNames, 'zoomedAxes', meanSpeed' );
            saveas(gcf,[saveDir setNames{setIdx} '_sfa_' targSetNames{targSetIdx} '.png'],'png');
        end
        
        %%
        areas = {'M1','PMd'};
        
        for areaIdx = 1:length(areas)
            %canon corr
            jenkinsDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
            jData = load([jenkinsDir filesep 'J_dPCA__MovStart_' areas{areaIdx} '.mat']);

            jData = jData.dPCA_out.featureAverages;
            modelData = dPCA_results{1}.featureAverages;

            jData_unroll = jData(:,:)';
            modelData_unroll = modelData(:,:)';

            [j_COEFF, j_SCORE, LATENT, TSQUARED, j_EXPLAINED, MU] = pca(jData_unroll);
            [m_COEFF, m_SCORE, LATENT, TSQUARED, m_EXPLAINED, MU] = pca(modelData_unroll);

            [A,B,R,U,V,STATS] = canoncorr(j_SCORE(:,1:10),m_SCORE(:,1:10));

            var_J = j_SCORE(:,1:10)*A;

            U = U';
            U = reshape(U, [10,8,101]);

            V = V';
            V = reshape(V,  [10,8,101]);

            figure('Position',[680           1         504        1099]);
            for dimIdx=1:10
                subplot(10,2,dimIdx*2-1);
                hold on;
                for x=1:8
                    plot(squeeze(U(dimIdx,x,:)),lineArgs{x}{:});
                end
                axis tight;

                subplot(10,2,dimIdx*2);
                hold on;
                for x=1:8
                    plot(squeeze(V(dimIdx,x,:)),lineArgs{x}{:});
                end
                axis tight;
            end
            title(mean(R));
            saveas(gcf, [saveDir setNames{setIdx} '_CC_' areas{areaIdx} '.png'],'png');
        end
        
        %%
        %prep activity
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(squeeze(dPCA_results{2}.featureAverages(:,:,1))');
        
        figure
        hold on
        for targIdx=1:size(SCORE,1)
            plot3(SCORE(targIdx,1), SCORE(targIdx,2), SCORE(targIdx,3),'o',lineArgs{targIdx}{:});
        end
        xlabel('Dim 1');
        ylabel('Dim 2');
        zlabel('Dim 3');

        %%
        %two factor dir x dist
        trialIdx = 1:nSteps:size(features,1);
        dirFactor = repmat((1:nAngles)', nReps*nDist, 1);
        distFactor = repmat(1:nDist,  nAngles, 1);
        distFactor = repmat(distFactor(:), nReps, 1);
        margNames = {'Dir', 'Dist', 'CI', 'Dir x Dist'};

        out = apply_dPCA_simple( features, trialIdx, [dirFactor, distFactor], [0,nSteps-1], 0.01, margNames );
        close(gcf);
        
        lineArgs = cell(nAngles, nDist);
        lStyles = {':','--','-.','-'};
        dirColors = hsv(nAngles)*0.8;
        for dirIdx=1:nAngles
            for distIdx=1:nDist
                lineArgs{dirIdx, distIdx} = {'Color',dirColors(dirIdx,:),'LineWidth',2,'LineStyle',lStyles{distIdx}};
            end
        end

        yAxesFinal = twoFactor_dPCA_plot( out, timeAxis-timeAxis(1), lineArgs, margNames, 'zoom', meanSpeed' );
        saveas(gcf, [saveDir setNames{setIdx} '_2fac.png'],'png');
        
        %%
        %two factor single line
        dirSets = {[1,5],[3,7]};
        dirSetNames = {'horz','vert'};
        for dirSetIdx=1:length(dirSets)
            factors = [];
            for n=1:nDist
                tmp = [(1:nAngles)', zeros(nAngles,1)+n];
                factors = [factors; tmp];
            end
            factors = repmat(factors, nReps,1 );
            useTrl = find(factors(:,1)==dirSets{dirSetIdx}(1) | factors(:,1)==dirSets{dirSetIdx}(2));

            trialIdx = 1:nSteps:size(features,1);
            margNames = {'Dir', 'Dist', 'CI', 'Dir x Dist'};

            out = apply_dPCA_simple( features, trialIdx(useTrl), factors(useTrl,:), [0,nSteps-1], 0.01, margNames );
            close(gcf);

            lineArgs = cell(nAngles, nDist);
            lStyles = {'-',':'};
            distColors = jet(nDist)*0.8;
            for dirIdx=1:2
                for distIdx=1:nDist
                    lineArgs{dirIdx, distIdx} = {'Color',distColors(distIdx,:),'LineWidth',2,'LineStyle',lStyles{dirIdx}};
                end
            end

            yAxesFinal = twoFactor_dPCA_plot( out, timeAxis-timeAxis(1), lineArgs, margNames, 'zoom', meanSpeed' );
            saveas(gcf, [saveDir setNames{setIdx} '_2fac_' dirSetNames{dirSetIdx} '.png'],'png');
        end
        
        %%
        %jPCA
        Data = struct();
        trlIdx = 1:length(timeAxis);
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

        windowIdx = [1000, 1200];
        
        %short window
        jPCATimes = windowIdx(1):10:windowIdx(2);
        for x = 1:length(jPCATimes)
            [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
            jPCATimes(x) = Data(1).times(minIdx);
        end

        [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
        phaseSpace(Projections, jPCA_Summary);  % makes the plot
        saveas(gcf, [saveDir setNames{setIdx} 'jPCA.png'],'png');
        close all;
    end
end

%%
saveDir = '/Users/frankwillett/Data/Derived/armControlNets/Jenkins/';
dataset = 'R_2016-02-02_1_arm';
paths = getFRWPaths();

addpath(genpath([paths.codePath filesep 'code/analysis/Frank']));
dataDir = [paths.dataPath filesep 'Derived' filesep 'BCIDynamicsPredata'];

fileName = [dataDir filesep dataset '.mat'];
predata = load(fileName);
arraySets = {[1],[2]};

%mov start
alignIdx = 2;

for arraySetIdx = 1:length(arraySets)
    %file saving
    savePostfix = ['_' predata.alignTypes{alignIdx} '_' horzcat(predata.metaData.arrayNames{arraySets{arraySetIdx}})];

    %get binned rates
    tmp = cat(3,predata.allNeural{alignIdx, arraySets{arraySetIdx}});
    tmpKin = predata.allKin{alignIdx};

    %smooth
    if isfield(predata,'neuralType') && ~strcmp(predata.neuralType,'LFADS')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    elseif ~isfield(predata,'neuralType')
        for t=1:size(tmp,1)
            tmp(t,:,:) = gaussSmooth_fast(squeeze(tmp(t,:,:)),2.5);
        end
    end

    %stack
    eventIdx = [];
    [~,eventOffset] = min(abs(predata.timeAxis{alignIdx}));

    stackIdx = 1:size(tmp,2);
    neuralStack = zeros(size(tmp,1)*size(tmp,2),size(tmp,3));
    kinStack = zeros(size(tmpKin,1)*size(tmpKin,2),size(tmpKin,3));
    for t = 1:size(tmp,1)
        neuralStack(stackIdx,:) = tmp(t,:,:);
        kinStack(stackIdx,:) = tmpKin(t,:,:);
        eventIdx = [eventIdx; stackIdx(1)+eventOffset-1];
        stackIdx = stackIdx + size(tmp,2);
    end

    %normalize
    neuralStack = zscore(neuralStack);

    %information needed for unrolling functions
    %timeWindow = [-eventOffset+1, length(predata.timeAxis{alignIdx})-eventOffset];
    timeWindow = [-50, 50];
    trialCodes = predata.allCon{alignIdx};
    timeStep = predata.binMS/1000;
    margNames = {'CD', 'CI'};

    %simple dPCA
    dPCA_out = apply_dPCA_simple( neuralStack, eventIdx, trialCodes, timeWindow, timeStep, margNames );

    nCon = length(unique(trialCodes));
    lineArgs = cell(8,1);
    colors = hsv(nCon)*0.8;
    for c=1:nCon
        lineArgs{c} = {'LineWidth',2,'Color',colors(c,:)};
    end

    timeAxis = (timeWindow(1):timeWindow(2))*timeStep;
    margNamesShort = {'Dir','CI'};
    avgSpeed = mean(squeeze(predata.kinAvg{alignIdx}(:,:,5))',2);
    avgSpeed = avgSpeed(20:(end-60));

    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_dPCA_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_dPCA_' savePostfix '.svg'],'svg');
    save([saveDir filesep 'J_dPCA_' savePostfix '.mat'], 'dPCA_out');
    
    %SFA-rotated dPCA
    sfaOut = sfaRot_dPCA( dPCA_out );
    oneFactor_dPCA_plot( sfaOut, timeAxis, lineArgs, margNames, 'zoomedAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_sfa_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_sfa_' savePostfix '.svg'],'svg');
    
    oneFactor_dPCA_plot( dPCA_out, timeAxis, lineArgs, margNames, 'sameAxes', avgSpeed );
    saveas(gcf,[saveDir filesep 'J_dPCA_sameAx_' savePostfix '.png'],'png');
    saveas(gcf,[saveDir filesep 'J_dPCA_sameAx_' savePostfix '.svg'],'svg');
end

%%


        