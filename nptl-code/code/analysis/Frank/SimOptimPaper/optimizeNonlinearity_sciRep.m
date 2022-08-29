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

simOpts.forwardModel.delaySteps = 15;
simOpts.forwardModel.forwardSteps = 15;
simOpts.control.rtSteps = 0;

gameOpts = makeBciSimFastGameOpts( );
gameOpts.targList = [1 0];
gameOpts.targRad = 3;
gameOpts.returnToCenter = false;
gameOpts.nReaches = 200;

fOpts.rapidRepeat = true;
fOpts.rapidFitts = false;
fOpts.returnTraj = false;

alphaOpt = fliplr(1-(logspace(-1,0,39)-0.09));
betaOpt = linspace(0.1,5.0,39);

powValues = linspace(1.0,4.0,16);
factorNames = {'Dwell Time','Target Radius','Decoding Noise'};
factorValues = {linspace(0.5,4,20), linspace(0,0.4,20), linspace(0.33,2.0,20)};
finalResults = cell(length(factorNames),1);
    
%%
for factorIdx = 1:length(factorNames)
    finalResults{factorIdx} = zeros(length(factorValues{factorIdx}),4);
    for valueIdx = 1:length(factorValues{factorIdx})
        simOpts.trial.dwellTime = 1.0;
        gameOpts.targRad = 0.2;
        noiseModel.cov = eye(2);
        
        if factorIdx==1
            simOpts.trial.dwellTime = factorValues{factorIdx}(valueIdx);
        elseif factorIdx==2
            gameOpts.targRad = factorValues{factorIdx}(valueIdx);
        elseif factorIdx==3
            noiseModel.cov = eye(2)*factorValues{factorIdx}(valueIdx).^2;
        end

        %new noise
        simOpts.noiseMatrix = genTimeSeriesFromARModel_multi( 100000, noiseModel.coef, noiseModel.cov );

%         %optimize
%         optFunStatic = @(coef)tttOptFunc_expNonlin(simOpts, gameOpts, fOpts, coef(1), coef(2), coef(3));
%         
%         validValues = false;
%         while ~validValues
%             startCoef = [0.90, 1.5, 0.0];
%             startCoef(1) = startCoef(1)+randn(1)*0.01;
%             startCoef(2) = startCoef(2)+randn(1)*0.3;
%             startCoef(3) = startCoef(3)+randn(1);
%             validValues = startCoef(1)>0 & startCoef(1)<1 & startCoef(2)>0 & startCoef(3)>0;
%         end
%         
%         options = psoptimset('Display','off','MaxFunEvals',2000,'TolMesh',10^-4);
%         
%         [X, fval] = patternsearch(optFunStatic,startCoef,[],[],[],[],...
%             [0,0,0],...
%             [1.0,Inf,Inf],[],options); 
    
        %first optimize alpha/beta  
        results = zeros(length(powValues),3);
        parfor powIdx=1:length(powValues)
            tmpOpts = simOpts;
            tmpOpts.plant.nonlinType = 1;
            tmpOpts.plant.n1 = powValues(powIdx)-1;
            [ bestAlpha, bestBeta, minTime ] = alphaBetaSweep( tmpOpts, gameOpts, fOpts, alphaOpt, betaOpt );
            
            optFunStatic = @(coef)tttOptFunc_expNonlin(tmpOpts, gameOpts, fOpts, coef(1), coef(2), powValues(powIdx));
        
            options = psoptimset('Display','off','MaxFunEvals',2000,'TolMesh',10^-4);
            [X, fval] = patternsearch(optFunStatic,[bestAlpha, bestBeta],[],[],[],[],...
                [0,0],...
                [1.0,Inf],[],options); 

            results(powIdx,:) = [X(1), X(2), fval];
        end

        [~,bestResult] = min(results(:,3));
        finalResults{factorIdx}(valueIdx,:) = [results(bestResult,1:2), powValues(bestResult), results(bestResult,3)];
    end
end

%%
save([figDir filesep 'optResults'],'finalResults','factorNames','factorValues','powValues','alphaOpt','betaOpt');

%%
%comparison to jenkins reaching, jenkins cursor jump
%prep dimensions - are they orthogonal to movement dimensions?
%try CIS bump input & pos err inputs again
%try longer output delays to match real data; revisit long delay issue
