%%
%These first lines specify the file names to analyze, along with some extra information to
%inform model fitting (participant-specific feedback delay and reacion time;
%distance from the center to outer target in game-specific units). 
fileNames = {'T6.2015.02.02.mat','T7.2014.09.11.mat','T8.2015.03.24.mat'};
feedbackDelayTimeSteps = round([0.2, 0.26, 0.4]/0.02);
reactionTimeSteps = round([0.32, 0.4, 0.4]/0.02);
farDistance = [0.5, 0.5, 14];

%%
%Loop through each file specified above, fitting the model and plotting
%example data.
for f=1:length(fileNames)
    disp(fileNames{f});
    data = load(fileNames{f});
    
    %Fit the piecewise control policy model on each condition.
    conditionNumberByTrial = data.conditionNumber(data.trialEpochs(:,1));
    models = cell(length(data.alpha),1);
    
    for c=1:length(data.alpha)
        disp([num2str(c) ' / ' num2str(length(data.alpha))]);
        
        %Get trial epochs on which to fit the model, excluding a reaction
        %time interval.
        reachEpochs = data.trialEpochs(conditionNumberByTrial==c,:);
        reachEpochs(:,1) = reachEpochs(:,1) + reactionTimeSteps(f);
        
        %specify model fitting data and parameters
        opts.pos = data.cursorPos;
        opts.vel = data.cursorVel;
        opts.targPos = data.targetPos;
        opts.decoded_u = data.decodedControlVector;
        
        opts.modelOpts.noVel = false;
        opts.modelOpts.nKnots = 12;
        opts.modelOpts.noNegativeFTarg = false;
        
        opts.filtAlpha = data.alpha(c);
        opts.filtBeta = data.beta(c);

        opts.reachEpochsToFit = reachEpochs;
        opts.feedbackDelaySteps = feedbackDelayTimeSteps(f);
        opts.timeStep = 0.02;
        
        %fit the model
        models{c} = fitPiecewiseModel( opts );
        
        %find optimal gain & smoothing using the fit model
        dwellTime = data.dwellTimes(c);
        targetRad = data.cursorRadius + data.targetRadius;
        targetDist = farDistance(f);
        alpha = fliplr(1-logspace(log10(0.005),log10(0.8),15));
        beta = logspace(log10(0.3),log10(6.25),20);
        
        [optAlpha, optBeta, simResults] = alphaBetaSweep(models{c}.simOpts, alpha, beta, targetDist, targetRad, dwellTime);
    end
    
    %%
    %Plot the fTarg and fVel functions fit by the piecewise model, for each
    %condition.
    figure('Position',[34 585 944 393],'Name',[fileNames{f} ' Piecewise Model Fits']);
    subplot(1,2,1);
    hold on;
    for m=1:length(models)
        plot(models{m}.controlModel.fTargX / farDistance(f), models{m}.controlModel.fTargY, '-bo');
    end
    xlim([0 1]);
    ylim([0 2]);
    xlabel('Normalized Target Distance');
    ylabel('f_{targ}');

    subplot(1,2,2);
    hold on;
    for m=1:length(models)
        plot(models{m}.controlModel.fVelX * 50 / farDistance(f), models{m}.controlModel.fVelY, '-bo');
    end
    xlabel('Speed (target distances / sec)');
    ylabel('f_{vel}');

    %%
    %Plot the modeled control vector vs. the decoded control vector, and the IME of
    %cursor position vs. the actual cursor position, as an example.
    %(Plots the last three movements of the last condition).
    loopIdx = opts.reachEpochsToFit(end-2,1):opts.reachEpochsToFit(end,2);
    
    figure('Position',[19 254 1200 732],'Name',[fileNames{f} ' Example Data']);
    subplot(2,2,1);
    hold on;
    plot(data.secondsSinceSystemBoot(loopIdx), models{end}.modeledControlVector(loopIdx,1));
    plot(data.secondsSinceSystemBoot(loopIdx), data.decodedControlVector(loopIdx,1),'r');
    legend({'Modeled Control Vector c_x','Decoded Control Vector u_x'});
    xlabel('Time (s)');
    
    subplot(2,2,2);
    hold on;
    plot(data.secondsSinceSystemBoot(loopIdx), models{end}.modeledControlVector(loopIdx,2));
    plot(data.secondsSinceSystemBoot(loopIdx), data.decodedControlVector(loopIdx,2),'r');
    legend({'Modeled Control Vector c_y','Decoded Control Vector u_y'});
    xlabel('Time (s)');
    
    subplot(2,2,3);
    hold on;
    plot(data.secondsSinceSystemBoot(loopIdx), models{end}.internalModelEstimates(loopIdx,1));
    plot(data.secondsSinceSystemBoot(loopIdx), data.cursorPos(loopIdx,1),'r');
    legend({'IME of X Cursor Position','Actual X Cursor Position'});
    xlabel('Time (s)');
    
    subplot(2,2,4);
    hold on;
    plot(data.secondsSinceSystemBoot(loopIdx), models{end}.internalModelEstimates(loopIdx,2));
    plot(data.secondsSinceSystemBoot(loopIdx), data.cursorPos(loopIdx,2),'r');
    legend({'IME of Y Cursor Position','Actual Y Cursor Position'});
    xlabel('Time (s)');
end