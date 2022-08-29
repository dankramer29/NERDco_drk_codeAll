function [fHandles, out] = apply_dPCA( features, reachEpochs, codes1, codes2, timeWindow, ...
    doJPCA, margNames, plotFun, popModel, tuningCoef )
    %%
    if isempty(codes2)
        maxRep = max(hist(codes1));
    else
        [~,~,muxCodes] = unique([codes1, codes2],'rows');
        maxRep = max(hist(muxCodes));
    end
    
    if isempty(doJPCA)
        doJPCA = true;
    end
    
    codes1List = unique(codes1);
    nCodes1 = length(codes1List);
    nCodes2 = length(unique(codes2));
    time = (timeWindow(1):timeWindow(2))*0.02;

    if isempty(codes2)
        N = size(features,2);%100;   % number of neurons
        T = length(time);%20;     % number of time points
        S = nCodes1;%7;       % number of stimuli (dir)
        E = maxRep;%20;     % maximal number of trial repetitions

        trialNum = zeros(N, S);
        firingRates = nan(N, S, T, E);
        popRates = nan(4, S, T, E);
        for s = 1:nCodes1
            trlIdx = find(codes1==codes1List(s));
            trialNum(:,s) = length(trlIdx);
            for e = 1:length(trlIdx)
                loopIdx = (reachEpochs(trlIdx(e))+timeWindow(1)):(reachEpochs(trlIdx(e))+timeWindow(2));
                if loopIdx(end)>size(features,1) || loopIdx(1)<1
                    trialNum(:,s) = trialNum(:,s) - 1;
                    continue;
                end
                firingRates(:,s,:,e) = features(loopIdx,:)';
                if ~isempty(popModel)
                    popRates(:,s,:,e) = popModel(loopIdx,:)';
                end
            end
        end
    else
        N = size(features,2);%100;   % number of neurons
        T = length(time);%20;     % number of time points
        S = nCodes1;%7;       % number of stimuli (dir)
        D = nCodes2;          % number of decisions (dist)
        E = maxRep;%20;     % maximal number of trial repetitions

        trialNum = zeros(N, S, D);
        firingRates = nan(N, S, D, T, E);
        popRates = nan(4, S, D, T, E);
        for s = 1:S
            for d = 1:D
                trlIdx = find(codes1==s & codes2==d);
                trialNum(:,s,d) = length(trlIdx);
                for e = 1:length(trlIdx)
                    loopIdx = (reachEpochs(trlIdx(e))+timeWindow(1)):(reachEpochs(trlIdx(e))+timeWindow(2));
                    if loopIdx(end)>size(features,1)
                        trialNum(:,s) = trialNum(:,s) - 1;
                        continue;
                    end
                    firingRates(:,s,d,:,e) = features(loopIdx,:)';
                    if ~isempty(popModel)
                        popRates(:,s,d,:,e) = popModel(loopIdx,:)';
                    end
                end
            end
        end
    end
    
    % computing PSTHs
    firingRatesAverage = nanmean(firingRates, ndims(firingRates));
    popAverage = nanmean(popRates, ndims(popRates));

    % parameter groupings
    % 1 - stimulus
    % 2 - decision
    % 3 - time
    % [1 3] - stimulus/time interaction
    % [2 3] - decision/time interaction
    % [1 2] - stimulus/decision interaction
    % [1 2 3] - rest
    % Here we group stimulus with stimulus/time interaction etc. Don't change
    % that if you don't know what you are doing

    if isempty(codes2)
        combinedParams = {{1, [1 2]}, {2}};
        if isempty(margNames)
            margNames = {'Dir', 'Condition-independent'};
        end
    else
        combinedParams = {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}};
        if isempty(margNames)
            margNames = {'Dir', 'Dist', 'Condition-independent', 'Dir/Dist Interaction'};
        end
    end
    margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;

    % Time events of interest (e.g. stimulus onset/offset, cues etc.)
    % They are marked on the plots with vertical lines
    %time = (-40:99)*0.02 - 0.02;
    timeEvents = 0;
    
    %%
    if isempty(plotFun)
        plotFun = @dpca_plot_default;
    end
    
    %%
    %PCA
    X = firingRatesAverage(:,:);
    X = bsxfun(@minus, X, mean(X,2));

    [W,~,~] = svd(X, 'econ');
    W = W(:,1:20);
    out.W_pca = W;
    
    % minimal plotting
    %dpca_plot(firingRatesAverage, W, W, @dpca_plot_default);
    %fHandles(1) = gcf;
    
    % computing explained variance
    explVar = dpca_explainedVariance(firingRatesAverage, W, W, ...
        'combinedParams', combinedParams);
    out.explVar_pca = explVar;
    
    % a bit more informative plotting
    Z_pca = dpca_plot(firingRatesAverage, W, W, plotFun, ...
        'explainedVar', explVar, ...
        'time', time,                        ...
        'timeEvents', timeEvents,               ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours);
    fHandles(1) = gcf;
    out.Z_pca = Z_pca;
    %% Step 2: PCA in each marginalization separately
    dpca_perMarginalization(firingRatesAverage, @dpca_plot_default, ...
       'combinedParams', combinedParams);
    fHandles(2) = gcf;
    
    %%
    %jPCA
    if doJPCA
        Data = struct();
        for n=1:size(firingRatesAverage,2)
            Data(n).A = squeeze(firingRatesAverage(:,n,:))';
            Data(n).times = (20*timeWindow(1)):20:(20*timeWindow(2));
        end

        jPCA_params.normalize = false;
        jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
        jPCA_params.meanSubtract = true;
        jPCA_params.numPCs = 6;  % default anyway, but best to be specific

        startTimes = 100:20:600;
        Projection = cell(length(startTimes),2);
        jPCA_Summary = cell(length(startTimes),2);
        for s=1:length(startTimes)
            times = startTimes(s):20:(startTimes(s)+250);
            [Projection{s,1}, jPCA_Summary{s,1}] = jPCA(Data, times, jPCA_params);
            
            times = startTimes(s):20:(startTimes(s)+1000);
            [Projection{s,2}, jPCA_Summary{s,2}] = jPCA(Data, times, jPCA_params);
        end

        jPCA_Small = [jPCA_Summary{:,1}];
        R2 = [jPCA_Small.R2_Mskew_kD];
        [~, bestIdx] = max(R2);

        figure('Position',[624          52        1210         932]);
        for plotIdx=1:26
            jPCA_inner = jPCA_Small(plotIdx);
            Projection_Small = Projection{plotIdx,1};
            jPCA_inner.startTime = startTimes(plotIdx);
            
            subtightplot(5,6,plotIdx);
            params.planes2plot = 1;
            params.reusePlot = 1;
            phaseSpace(Projection_Small, jPCA_inner, params);  % makes the plot
            set(gca,'XTickLabel',[],'YTickLabel',[]);
        end
        fHandles(4)=gcf;
        
        colors = hsv(length(Projection_Small))*0.8;
        Projection_Small = Projection{bestIdx,1};
        
        fHandles(3)=figure('Position',[680   688   958   290]);
        subplot(1,2,1);
        hold on
        for p=1:length(Projection_Small)
            plot(Projection_Small(p).allTimes, Projection_Small(p).projAllTimes(:,1),'Color',colors(p,:),'LineWidth',1);
        end
        xlabel('Time (s)');
        ylabel('jPC1');

        subplot(1,2,2);
        hold on
        for p=1:length(Projection_Small)
            plot(Projection_Small(p).allTimes, Projection_Small(p).projAllTimes(:,2),'Color',colors(p,:),'LineWidth',1);
        end
        xlabel('Time (s)');
        ylabel('jPC2');
        
        out.eig = (abs(eig(jPCA_Small(bestIdx).Mskew))*50)/(2*pi);
        out.bestIdx = bestIdx;
        out.jPCA_Summary = jPCA_Summary;
    end
    %%
    %with cross-validated plot
    ifSimultaneousRecording = 1;
    optimalLambda = dpca_optimizeLambda(firingRatesAverage, firingRates, trialNum, ...
        'combinedParams', combinedParams, ...
        'simultaneous', ifSimultaneousRecording, ...
        'numRep', 10, ...  % increase this number to ~10 for better accuracy
        'filename', 'tmp_optimalLambdas.mat',...
        'lambdas', 1e-05 * 1.5.^[0:25]);
    close(gcf);

    Cnoise = dpca_getNoiseCovariance(firingRatesAverage, ...
        firingRates, trialNum, 'simultaneous', ifSimultaneousRecording);

    [W,V,whichMarg] = dpca(firingRatesAverage, 20, ...
        'combinedParams', combinedParams, ...
        'lambda', 0, ...
        'Cnoise', Cnoise);
    out.W = W;
    out.whichMarg = whichMarg;
    out.V = V;

    explVar = dpca_explainedVariance(firingRatesAverage, W, V, ...
        'combinedParams', combinedParams, ...
        'Cnoise', Cnoise, ...
        'numOfTrials', trialNum);
    out.explVar = explVar;
    
    Z = dpca_plot(firingRatesAverage, W, V, plotFun, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', time,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
    out.Z = Z;
    fHandles(5) = gcf;
    
    %%
    if ~isempty(popModel)
        expFRA = firingRatesAverage(:,:);
        expFRA = bsxfun(@plus, expFRA', -mean(expFRA'))';
        expPop = popAverage(:,:);
        expPop = bsxfun(@plus, expPop', -mean(expPop'))';

        totalVar = sum(sum(expFRA.^2));

        dimFVAF = zeros(size(expPop,1),1);
        for dim=1:size(expPop,1)
            filt = buildLinFilts(expFRA', expPop(dim,:)', 'standard');
            predFRA = ((expPop(dim,:)')*filt)';
            dimFVAF(dim) = 100 - sum(sum((expFRA - predFRA).^2)) / totalVar * 100;    
        end
        
        dimFVAF_2 = zeros(2,1);
        dimGroups = {[1 2],[3 4]};
        if size(expPop,1) == 4
            for dim=1:2
                filt = buildLinFilts(expFRA', expPop(dimGroups{dim},:)', 'standard');
                predFRA = ((expPop(dimGroups{dim},:)')*filt)';
                dimFVAF_2(dim) = 100 - sum(sum((expFRA - predFRA).^2)) / totalVar * 100;    
            end
        end
        
        filt = buildLinFilts(expFRA', expPop', 'standard');
        predFRA = ((expPop')*filt)';
        fvafAll = 100 - sum(sum((expFRA - predFRA).^2)) / totalVar * 100;   
        if ~isempty(tuningCoef)
            fvafAll2 = 100 - sum(sum((expFRA - (tuningCoef*expPop)).^2)) / totalVar * 100;  
        else
            fvafAll2 = [];
        end
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(expFRA,'centered','off');

        disp(['Var: ' num2str(fvafAll)]);
        disp(['% of PCA: ' num2str(100*fvafAll/sum(EXPLAINED(1:10)))]);
        disp(['Angle: ' num2str(subspace(COEFF(:,1:4), expPop')*180/pi)]);

        subAngle = subspace(COEFF(:,1:4), expPop')*180/pi;
        percentVAFModel = 100*fvafAll/sum(EXPLAINED(1:10));

        figure; 
        hold on
        plot(0:length(EXPLAINED),[0; cumsum(EXPLAINED)],'-o');
        plot(4, fvafAll, 'rx');
        xlim([0 10]);
        title(num2str(percentVAFModel));
        fHandles(6) = gcf;
        
        modelCompareSummary.fvafAll = fvafAll;
        modelCompareSummary.fvafAll2 = fvafAll2;
        modelCompareSummary.dimFVAF = dimFVAF;
        modelCompareSummary.EXPLAINED = EXPLAINED;
        modelCompareSummary.fractionFVAF = percentVAFModel;
        modelCompareSummary.dimFVAF_2 = dimFVAF_2;
        
        %post-go 
        cut_FRA = firingRatesAverage(:,:,51:end);
        expFRA = cut_FRA(:,:);
        expFRA = bsxfun(@plus, expFRA', -mean(expFRA'))';
        
        cut_pop = popAverage(:,:,51:end);
        expPop = cut_pop(:,:);
        expPop = bsxfun(@plus, expPop', -mean(expPop'))';
        
        totalVar = sum(sum(expFRA.^2));
        
        if ~isempty(tuningCoef)
            fvafAll2_post = 100 - sum(sum((expFRA - (tuningCoef*expPop)).^2)) / totalVar * 100;  
        else
            fvafAll2_post = [];
        end
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED_post, MU] = pca(expFRA','centered','off');
        modelCompareSummary.fvafAll2_post = fvafAll2_post;
        modelCompareSummary.EXPLAINED_post = EXPLAINED_post;
        
        out.modelCompareSummary = modelCompareSummary;
    end

    out.firingRatesAverage = firingRatesAverage;
    out.popAverage = popAverage;
end

