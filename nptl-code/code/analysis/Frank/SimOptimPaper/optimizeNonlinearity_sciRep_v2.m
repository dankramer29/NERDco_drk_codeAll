%%
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects'));
addpath(genpath('/Users/frankwillett/Documents/AjiboyeLab/Projects/Velocity BCI Simulator/'));

bg2FileDir = '/Users/frankwillett/Data/BG Datasets/optimPaperDatasets';
figDir = '/Users/frankwillett/Data/Derived/nonlinearGainOptFigure/';
mkdir(figDir);

%%
load('/Users/frankwillett/Data/CaseDerived/testFiles/testCell_7_gsExplain.mat')
controlModel = testResultsCell{99}.fit.fitModel.bestMRule.piecewisePointModel;
noiseModel = testResultsCell{99}.fit.fitModel.bestARModel;
clear testResultsCell;

%%
simOpts = makeFastBciSimOptions( );

simOpts.control.fTargX  = [linspace(0,1,10) 1.1 1.2 1.3];
simOpts.control.fTargY = [0, 0.4, 0.6, 0.7, 0.78, 0.85, 0.9, 0.93, 0.96, 1, 1.02 1.03 1.03];

simOpts.trial.maxTrialTime = 12;
simOpts.trial.targRad = 0.1;
simOpts.trial.dwellTime = 2.0;

simOpts.forwardModel.delaySteps = 15;
simOpts.forwardModel.forwardSteps = 15;
simOpts.control.rtSteps = 0;

%%
betaValues = logspace(log10(0.25), log10(1.5), 30);

maxAlpha = 0.97;
minAlpha = 0.84;
alphaValues = fliplr(maxAlpha-(logspace(log10(0.01),log10(1),30)-0.01)*(maxAlpha-minAlpha)/0.99);

powValues = linspace(1.0,4.0,16);
nReps = 50;
allAcqTimes = zeros(nReps,length(alphaValues),length(betaValues),length(powValues));

targetPos = repmat([1.0,0],250,1);
startPos = zeros(250,2);

for repIdx=6:nReps
    disp(['Rep ' num2str(repIdx) '/' num2str(nReps) ' ...']);
    newNoiseMatrix = genTimeSeriesFromARModel_multi( 100000, noiseModel.coef, noiseModel.cov );
    for a=1:length(alphaValues)
        disp(['   Alpha value ' num2str(a) '/' num2str(length(alphaValues)) ' ...']);
        for b=1:length(betaValues)
            disp(['      Gain value ' num2str(b) '/' num2str(length(betaValues)) ' ...']);
            
            for powIdx=1:length(powValues)
                newOpts = simOpts;
                newOpts.noiseMatrix = newNoiseMatrix;
                newOpts.plant.beta = betaValues(b);
                newOpts.plant.alpha = alphaValues(a);
                newOpts.plant.nonlinType = 1;
                newOpts.plant.n1 = powValues(powIdx)-1;

                out = simBatch( newOpts, targetPos, startPos );
                allAcqTimes(repIdx, a, b, powIdx) = mean(out.movTime);
            end %power
        end %beta
    end %alpha
end %reps

resultsDir = '/Users/frankwillett/Data/CaseDerived/';
save([resultsDir filesep 'figures' filesep 'optiPaper' filesep 'powSim']);

%%
resultsDir = '/Users/frankwillett/Data/CaseDerived/';

optValues = zeros(nReps, length(powValues), 3);
for repIdx=1:nReps
    for d=1:length(powValues)
        tmp = squeeze(allAcqTimes(repIdx,:,:,d));
        [bestTime, minIdx] = min(tmp(:));
        [i,j] = ind2sub(size(tmp),minIdx);
        
        optValues(repIdx,d,:) = [alphaValues(i), betaValues(j), allAcqTimes(repIdx,i,j,d)];
    end  
end

optValues = optValues(1:30,:,:);

aIdx = 11;
bIdx = 12;
tmp = squeeze(allAcqTimes(1:30,aIdx,bIdx,:));
[mn,~,CI] = normfit(tmp);
    
figure('Position',[430   862   272   228]);
hold on;
plot(powValues, mn, '-k', 'LineWidth', 1);
plot(get(gca,'XLim'),[4.844 4.844],'--k','LineWidth',2);
text(2,5.2,'Optimal','FontSize',14);
errorPatch(powValues', CI', [0 0 0],0.2);
xlabel('Exponent');
ylabel('Total Movement Time (s)');
set(gca,'FontSize',14,'LineWidth',1);
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'nonlinOptExample1'],'svg');
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'nonlinOptExample1'],'fig');

figure('Position',[680   867   775   231]);
metricLabels = {'Optimal Smoothing (\alpha)','Optimal Gain (\beta)','Total Movement Time (s)'};
for m=1:3
    subplot(1,3,m);
    hold on;
    
    [mn,~,CI] = normfit(squeeze(optValues(:,:,m)));
    plot(powValues, mn, '-k','LineWidth',1);
    errorPatch(powValues', CI', [0 0 0],0.2);
    %errorbar(dtAxis, mn, mn-CI(1,:), CI(2,:)-mn, 'k', 'LineWidth',2);
    set(gca,'FontSize',14,'LineWidth',1);
    xlabel('Exponent');
    ylabel(metricLabels{m});
    axis tight;
end
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'nonlinOptExample2'],'svg');
saveas(gcf, [resultsDir filesep 'figures' filesep 'optiPaper' filesep 'nonlinOptExample2'],'fig');


