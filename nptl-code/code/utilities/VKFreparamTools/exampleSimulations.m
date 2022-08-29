%%
%Demonstrates how to use the simulator. The .mex file
%should be compiled first (compileSimBci.m)

%%
%Runs an alpha/beta sweep to find optimal gain and smoothing.

%Fills an options struct with defaults.
opts = makeBciSimOptions( );

%set some of the parameters to different values
opts.trial.dwellTime = 1.0;
opts.noiseMatrix = randn(10000,2)*1.5;
opts.forwardModel.delaySteps = 10;
opts.forwardModel.forwardSteps = 10;

%Specifies the alpha and beta values to test
alpha = fliplr(1-logspace(log10(0.005),log10(0.8),15));
beta = logspace(log10(0.3),log10(6.25),20);

%At each alpha and beta value, we do a sweep of fVel slopes and pick
%the best-performing one to report (this makes the assumption that the user
%will adapt their fVel, as shown in Willett et al., 2017). 
velSlopes = linspace(0,-2,10);

timeMat = zeros(length(alpha),length(beta),length(velSlopes));
nTrials = 50;

for a=1:length(alpha)
    disp([num2str(a) ' / ' num2str(length(alpha))]);
    for b=1:length(beta)
        for v=1:length(velSlopes)
            %specify the plant and control policy
            opts.plant.alpha = alpha(a);
            opts.plant.beta = beta(b);
            opts.control.fVelX = [0 1];
            opts.control.fVelY = [0 velSlopes(v)];
            
            %simulate a batch of movements
            startPos = repmat([0 0], nTrials, 1);
            targPos = repmat([1 0], nTrials, 1);
            [ out ] = simBatch( opts, targPos, startPos );
            timeMat(a,b,v) = mean(out.movTime);
        end
    end
end

bLabels = cell(length(beta),1);
for b=1:length(bLabels)
    bLabels{b} = num2str(beta(b),2);
end

aLabels = cell(length(alpha),1);
for b=1:length(aLabels)
    aLabels{b} = num2str(alpha(b),2);
end

figure
imagesc(squeeze(min(timeMat,[],3)),[0 10]); 
colormap(jet);
set(gca,'YDir','normal');
set(gca,'XTick',1:3:length(beta),'XTickLabel',bLabels(1:3:end));
set(gca,'YTick',1:3:length(alpha),'YTickLabel',aLabels(1:3:end));
xlabel('Beta (TD/s)');
ylabel('Alpha');
title('Average Movement Time (s)');
colorbar;

%%
%Computes the average movement time as a function of dwell time, target
%radius, noise STD, and feedback delay.
nTrials = 250;
startPos = repmat([0 0], nTrials, 1);
targPos = repmat([1 0], nTrials, 1);

meanMovTime = zeros(10,1);            
dwellTime = linspace(0.1,5,10);
targRad = linspace(0.05,0.25,10);
noiseStd = linspace(0.2,3,10);
visDelay = round(linspace(0,20,10));

defaultOpts = makeBciSimOptions( );
defaultOpts.trial.maxTrialTime = 15;
defaultOpts.trial.dwellTime = 1;
defaultOpts.trial.continuousHoldRule = 1;
defaultOpts.noiseMatrix = randn(1000000,2)*1.5;

figure
subplot(2,2,1);
opts = defaultOpts;
for x = 1:length(dwellTime)
    opts.trial.dwellTime = dwellTime(x);
    out = simBatch( opts, targPos, startPos );
    meanMovTime(x) = mean(out.movTime);
end
plot(dwellTime, meanMovTime, '-o');
xlabel('Dwell Time (s)');
ylabel('Mean Movement Time (s)');

subplot(2,2,2);
opts = defaultOpts;
for x = 1:length(targRad)
    opts.trial.targRad = targRad(x);
    out = simBatch( opts, targPos, startPos );
    meanMovTime(x) = mean(out.movTime);
end
plot(targRad, meanMovTime, '-o');
xlabel('Target Radius');
ylabel('Mean Movement Time (s)');

subplot(2,2,3);
opts = defaultOpts;
for x = 1:length(noiseStd)
    opts.noiseMatrix = randn(10000,2)*noiseStd(x);
    out = simBatch( opts, targPos, startPos );
    meanMovTime(x) = mean(out.movTime);
end
plot(noiseStd, meanMovTime, '-o');
xlabel('Noise STD');
ylabel('Mean Movement Time (s)');

subplot(2,2,4);
opts = defaultOpts;
for x = 1:length(visDelay)
    opts.forwardModel.delaySteps = visDelay(x);
    opts.forwardModel.forwardSteps = visDelay(x);
    out = simBatch( opts, targPos, startPos );
    meanMovTime(x) = mean(out.movTime);
end
plot(visDelay, meanMovTime, '-o');
xlabel('Feedback Delay (# of steps)');
ylabel('Mean Movement Time (s)');

