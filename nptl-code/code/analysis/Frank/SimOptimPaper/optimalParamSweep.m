function optimalParamSweep( resultsDir, visModelType )
    %start with a base dataset, sweep gain/smoothing as we vary:
    %noise, feedback delay, target radius, dwell time
    testResultsCell = load([resultsDir filesep 'testFiles' filesep 'testCell_' num2str(visModelType{1}) '_' visModelType{2} '.mat']);
    load([resultsDir filesep 'prefitFiles' filesep 'prefit_t8.2015.03.24_HighSpeed.mat']);
    base = testResultsCell.testResultsCell{12}.simOpts{2};
    base.plant.fStaticX = 0:10;
    base.plant.fStaticY = 0:10;
    base.plant.fOmegaX = 0:10;
    base.plant.fOmegaY = ones(1,11);
    base.plant.omegaAlpha = 0.8;
    arModel = testResultsCell.testResultsCell{12}.fit.fitModel.bestARModel;
    
    gameOpts = prefitFile.conditions.tmOpts{2};
    gameOpts.nReaches = 50;
    gameOpts.resetOnSuccess = 1;
    gameOpts.holdTime = 1;
    gameOpts.resetPos = gameOpts.centerTargPos;
    gameOpts.returnToCenter = 0;
     
    fOpts.rapidRepeat = false;
    fOpts.returnTraj = true;
    fOpts.rapidFitts = false;
    
    %%
    %initial overview with trajectories
    beta = linspace(2,35,19);
    alpha = fliplr(1-(logspace(-1,0,19)-0.09));
    trajBeta = beta(2:5:18);
    trajAlpha = alpha(2:5:18);
    velMultipliers = linspace(0,-1.4,10);
    
    base.control.fTimeX = linspace(0,1,10);
    base.control.fTimeY = linspace(0,0,10);
    
    res = cell(length(trajAlpha), length(trajBeta));
    for a=1:length(trajAlpha)
        for b=1:length(trajBeta)
            simOpts = base;
            simOpts.plant.beta = trajBeta(b);
            simOpts.plant.alpha = trajAlpha(a);
            simOpts.trial.dwellTime = 1;
            
            tmpPerf = zeros(length(velMultipliers),4);
            for v=1:length(velMultipliers)
                simOpts.control.fVelY = linspace(0,velMultipliers(v),12);
                tmpRes = bciSimFast(gameOpts, simOpts, fOpts);
                tmpPerf(v,:) = [mean(tmpRes.translateTime), mean(tmpRes.exDialTime), mean(tmpRes.ttt), ...
                    mean(tmpRes.pathEff)];
            end
            [~,minIdx] = min(tmpPerf(:,3));
            
            simOpts.control.fVelY = linspace(0,velMultipliers(minIdx),12);
            tmpGameOpts = gameOpts;
            tmpGameOpts.nReaches = 25;
            res{a,b} = bciSimFast(tmpGameOpts, simOpts, fOpts);
        end
    end
    
    figure('Position',[304   201   666   710]);
    for a=1:length(trajAlpha)
        for b=1:length(trajBeta)
            subtightplot(4,4,(4-a)*length(trajAlpha) + b);
            plotColoredTrajectories2D( res{a,b}.pos, ones(length(res{a,b}.isOuterReach),1), ...
                res{a,b}.reachEpochs(res{a,b}.isOuterReach,:), 0, unique(res{a,b}.targPos,'rows'), mean(res{a,b}.targRad), true );
            xlim([-18 18]);
            ylim([-18 18]+40.5);
            set(gca,'XTick',[]);
            set(gca,'YTick',[]);
            
            if b==1
                ylabel(['\alpha=' num2str(trajAlpha(a),2)],'FontWeight','bold','FontSize',16);
            end
            if a==4
                title(['\beta=' num2str(trajBeta(b),2)],'FontWeight','bold','FontSize',16);
            end
        end
    end
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4b'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4b'],'fig');
    
    %%
    %optimizations
    baseOpts = gameOpts;
    baseOpts.targList = [14 40.5];
    baseOpts.nReaches = 250;
    
    fOpts.rapidRepeat = true;
    fOpts.returnTraj = false;    
    %%
    %example optimization surface
    velMultipliers = linspace(0,-1.4,10);
    perfMat = zeros(length(alpha), length(beta), 4);
    
    tic;
    for b=1:length(beta)
        disp(b);
        for a=1:length(alpha)
            simOpts = base;
            simOpts.control.fVelX = linspace(0,simOpts.control.fVelX(end),12);
            simOpts.plant.beta = beta(b);
            simOpts.plant.alpha = alpha(a);
            simOpts.trial.dwellTime = 1;
            
            tmpPerf = zeros(length(velMultipliers),4);
            for v=1:length(velMultipliers)
                simOpts.control.fVelY = linspace(0,velMultipliers(v),12);
                res = bciSimFast(baseOpts, simOpts, fOpts);
                tmpPerf(v,:) = [mean(res.translateTime), mean(res.exDialTime), mean(res.ttt), ...
                    mean(res.pathEff)];
            end
            [~,minIdx] = min(tmpPerf(:,3));
            perfMat(a,b,:) = tmpPerf(minIdx,:);
        end
    end
    totalTime = toc;
    
    figure('Position',[80   331   879   655]);
    pTitles = {'Translate Time (s)','Dial-in Time (s)','Movement Time (s)','Path Efficiency'};
    for p=1:4
        subtightplot(2,2,p,[0.16 0.08],[0.09 0.05],[0.08 0.02]);
        hold on;
        imgData = squeeze(perfMat(:,:,p));
        imgDataSmooth = robustSmooth( imgData, [.05 .1 .05; .1 .4 .1; .05 .1 .05] );
        if strcmp(pTitles{p},'Path Efficiency')
            imgDataSmooth(imgDataSmooth>1)=1;
        end
        imagesc(1:length(beta), 1:length(alpha), imgDataSmooth);
        set(gca,'XTick',1:3:length(beta),'XTickLabel',mat2stringCell(beta(1:3:end),2));
        set(gca,'YTick',1:4:length(alpha),'YTickLabel',mat2stringCell(alpha(1:4:end),2));
        colormap(parula);
        
        [Xdot Ydot] = meshgrid(2:5:18, 2:5:18);
        plot(Xdot,Ydot, 'wo', 'LineWidth', 2);
        
        xlim([1, length(beta)]);
        ylim([1, length(alpha)]);
        colorbar;
        xlabel('Gain (\beta)');
        ylabel('Smoothing (\alpha)');
        set(gca,'FontSize',10);
        set(get(gca,'XLabel'),'FontSize',12);
        set(get(gca,'YLabel'),'FontSize',12);
        title(pTitles{p},'FontSize',12);
    end
    
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4a'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4a'],'fig');
    
    %%
    %time simulation
    nReps = 100;
    allTimes = zeros(nReps,1);
    for x=1:nReps
        tic;
        res = bciSimFast(baseOpts, simOpts, fOpts);
        allTimes(x) = toc;
    end
    
    figure
    plot(allTimes,'o');
    
    disp(100*50*mean(allTimes)/(sum(res.ttt)*50));
    
    %%
    %time iterative search
    simOpts = base;
    optFun = @(coef)(innerAlphaBetaSweep( simOpts, baseOpts, fOpts, [coef(1)*0.19 + 0.8, coef(2)*20 + 0.2, coef(3)] ));

    allTimes = zeros(100,1);
    for n=1:100
        tic;
        options = psoptimset('Display','iter','MaxFunEvals',2000,'TolMesh',10^-2);
        startCoef = [rand(1), rand(1)*20, -rand(1)];
        startValues = [(startCoef(1)-0.8)/0.19, (startCoef(2)-0.2)/20, startCoef(3)];
        [X, fval] = patternsearch(optFun,startValues,[],[],[],[],...
            [0, 0, -2],[1,1, 0],[],options); 
        finalX = [X(1)*0.19 + 0.8, X(2)*20 + 0.2, X(3)];
        allTimes(n) = toc;
    end
    
    %%
    %optimal params as a function of noise, delay, radius
    outerFactors = {'noise','delay','radius'};
    factorLevels = {linspace(0.5,2,10), 1:3:25, linspace(1,5,10)};
    velMultipliers = 0;
    optVals = cell(length(outerFactors),1);
    nRep = 10;
    
    for fIdx = 1:length(outerFactors)
        optVals{fIdx} = zeros(length(factorLevels{fIdx}),nRep,2);
        for n=1:length(factorLevels{fIdx})
            disp(['N=' num2str(n)]);
            for repIdx=1:nRep
                disp(['  R=' num2str(repIdx)]);
                noiseMat = genTimeSeriesFromARModel_multi( 100000, arModel.coef, arModel.cov );
                perfMat = zeros(length(alpha), length(beta), 4);
                for b=1:length(beta)
                    for a=1:length(alpha)
                        simOpts = base;
                        gameOpts = baseOpts;
                        simOpts.noiseMatrix = noiseMat;
                        if strcmp(outerFactors{fIdx},'noise')
                            simOpts.noiseMatrix = simOpts.noiseMatrix * factorLevels{fIdx}(n);
                        elseif strcmp(outerFactors{fIdx},'delay')
                            simOpts.forwardModel.delaySteps = factorLevels{fIdx}(n);
                            simOpts.forwardModel.forwardSteps = factorLevels{fIdx}(n);
                        elseif strcmp(outerFactors{fIdx},'radius')
                            gameOpts.targRad = factorLevels{fIdx}(n);
                        end

                        simOpts.control.fVelX = linspace(0,simOpts.control.fVelX(end),12);
                        simOpts.plant.beta = beta(b);
                        simOpts.plant.alpha = alpha(a);
                        simOpts.trial.dwellTime = 1;

                        tmpPerf = zeros(length(velMultipliers),4);
                        for v=1:length(velMultipliers)
                            simOpts.control.fVelY = linspace(0,velMultipliers(v),12);
                            res = bciSimFast(gameOpts, simOpts, fOpts);
                            tmpPerf(v,:) = [mean(res.translateTime), mean(res.exDialTime), mean(res.ttt), ...
                                mean(res.pathEff)];
                        end
                        [~,minIdx] = min(tmpPerf(:,3));
                        perfMat(a,b,:) = tmpPerf(minIdx,:);
                    end
                end

                %save optimal values
                ttt = squeeze(perfMat(:,:,3));
                tttSmooth = robustSmooth( ttt, [.05 .1 .05; .1 .4 .1; .05 .1 .05] );
                [~,minIdx] = min(tttSmooth(:));
                [aIdx, bIdx] = ind2sub([length(alpha), length(beta)],minIdx);

                optVals{fIdx}(n,repIdx,1) = alpha(aIdx);
                optVals{fIdx}(n,repIdx,2) = beta(bIdx);
            end %repetitions
        end %factor levels
    end %factor 
    
    %%
    %optimal params as a function of noise, delay, radius
    outerFactors = {'noise','delay','radius'};
    factorLevels = {linspace(0.5,2,10), 1:3:25, linspace(1,5,10)};
    optVals = cell(length(outerFactors),1);
    nRep = 10;
    
    for fIdx = 1:length(outerFactors)
        optVals{fIdx} = zeros(length(factorLevels{fIdx}),nRep,2);
        for n=1:length(factorLevels{fIdx})
            disp(['N=' num2str(n)]);
            for repIdx=1:nRep
                disp(['  R=' num2str(repIdx)]);
                
                noiseMat = genTimeSeriesFromARModel_multi( 100000, arModel.coef, arModel.cov );
                simOpts = base;
                gameOpts = baseOpts;
                simOpts.noiseMatrix = noiseMat;
                if strcmp(outerFactors{fIdx},'noise')
                    simOpts.noiseMatrix = simOpts.noiseMatrix * factorLevels{fIdx}(n);
                elseif strcmp(outerFactors{fIdx},'delay')
                    simOpts.forwardModel.delaySteps = factorLevels{fIdx}(n);
                    simOpts.forwardModel.forwardSteps = factorLevels{fIdx}(n);
                elseif strcmp(outerFactors{fIdx},'radius')
                    gameOpts.targRad = factorLevels{fIdx}(n);
                end
                simOpts.trial.dwellTime = 1;

                [ bestAlpha, bestBeta ] = alphaBetaSweep( simOpts, gameOpts, fOpts, alpha, beta );
                
                myFun = @(coef)(alphaBetaOptFunc( simOpts, gameOpts, fOpts, coef ));
                X = patternsearch(myFun, [bestAlpha bestBeta]);
                
%                 newAlpha = linspace(bestAlpha-0.05,bestAlpha+0.05,20);
%                 newAlpha(newAlpha>=1)=[];
%                 newAlpha(newAlpha<0)=[];
%                 newBeta = linspace(bestBeta-2.5, bestBeta+2.5, 20);
%                 [ bestAlpha2, bestBeta2 ] = alphaBetaSweep( simOpts, gameOpts, fOpts, newAlpha, newBeta );
                
                optVals{fIdx}(n,repIdx,1) = X(1);
                optVals{fIdx}(n,repIdx,2) = X(2);
            end %repetitions
        end %factor levels
    end %factor 
    
    mkdir([resultsDir filesep 'gsOpt']);
    save([resultsDir filesep 'gsOpt' filesep 'optVals'],'optVals','outerFactors','factorLevels','alpha','beta');
    
    %%
    %optimal params as a function of noise, delay, radius
    outerFactors = {'noise','delay','radius'};
    factorLevels = {linspace(0.5,2,10), 1:3:25, linspace(1,5,10)};
    
    optVals = cell(length(outerFactors),1);
    nRep = 10;
    
    for fIdx = 1:length(outerFactors)
        optVals{fIdx} = zeros(length(factorLevels{fIdx}),nRep,2);
        for n=1:length(factorLevels{fIdx})
            disp(['N=' num2str(n)]);
            for repIdx=1:nRep
                disp(['  R=' num2str(repIdx)]);
                noiseMat = genTimeSeriesFromARModel_multi( 100000, arModel.coef, arModel.cov );
                
                simOpts = base;
                gameOpts = baseOpts;
                simOpts.noiseMatrix = noiseMat;
                if strcmp(outerFactors{fIdx},'noise')
                    simOpts.noiseMatrix = simOpts.noiseMatrix * factorLevels{fIdx}(n);
                elseif strcmp(outerFactors{fIdx},'delay')
                    simOpts.forwardModel.delaySteps = factorLevels{fIdx}(n);
                    simOpts.forwardModel.forwardSteps = factorLevels{fIdx}(n);
                elseif strcmp(outerFactors{fIdx},'radius')
                    gameOpts.targRad = factorLevels{fIdx}(n);
                end
                
                myFun = @(coef)(alphaBetaOptFunc( simOpts, gameOpts, fOpts, coef ));
                X = patternsearch(myFun, [0.5 25]);
                
                optVals{fIdx}(n,repIdx,1) = X(1);
                optVals{fIdx}(n,repIdx,2) = X(2);
            end %repetitions
        end %factor levels
    end %factor 
    
        
    %%
    %plot result of optimization search
    colors = [0 0 0; 0.8 0 0];
    
    outerFactorNames = {'Noise','Feedback Delay (s)','Target Radius'};
    figure('Position',[624         690        1199         288]);
    for fIdx = 1:length(outerFactors)
        axH(fIdx,1)=subtightplot(1,3,fIdx,[0 0.1],[0.20 0.05],[0.06 0.06]);
        hold on
        
        meanSmooth = mean(optVals{fIdx}(:,:,1),2);
        [~,~,smoothCI] = normfit(optVals{fIdx}(:,:,1)');
        meanGain = mean(optVals{fIdx}(:,:,2),2);
        [~,~,gainCI] = normfit(optVals{fIdx}(:,:,2)');
        
        if fIdx==2
            fLevels = factorLevels{fIdx}*0.02;
        else
            fLevels = factorLevels{fIdx};
        end

        errorbar(fLevels, meanSmooth, meanSmooth - smoothCI(1,:)', smoothCI(2,:)'-meanSmooth, 'LineWidth', 2,'Color',colors(1,:));
        xlabel(outerFactorNames{fIdx});
        if fIdx==1
            ylabel('Smoothing (\alpha)');
        end
        xlim([fLevels(1), fLevels(end)]);
        set(gca,'FontSize',12);
        
        axH(fIdx,2)=axes('position',get(gca,'position'),'YAxisLocation','right','Color','none','XTick',[],'ycolor',colors(2,:));
        hold on;
        errorbar(fLevels, meanGain, meanGain - gainCI(1,:)', gainCI(2,:)'-meanGain, 'LineWidth', 2,'Color',colors(2,:));
        if fIdx==1
            ylabel('Gain (\beta)');
        end
        xlim([fLevels(1), fLevels(end)]);
        set(gca,'FontSize',12);
    end
    set(gcf,'PaperPositionMode','auto');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4c'],'svg');
    saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'fig4c'],'fig');
end

