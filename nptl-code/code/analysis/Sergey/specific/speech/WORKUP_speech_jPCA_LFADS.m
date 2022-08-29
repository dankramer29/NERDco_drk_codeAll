% Performs jPCA analysis using the 
% Based off of WORKUP_speech_jPCA.m
%
% Performs jPCA analysis on speech production data using Mark Churchland's code
% package, i.e., describes how well rotatory neural dynamics capture the (low-dimensional) 
% neural data. See Churchland et al 2012 Nature as the primary reference, and Pandarinath
% et al. 2015 eLife for the jPCA method applied to human motor cortex data.
% Also performs Performs statistical testing of whether these rotations are statistically
% significance versus a null hypothesis of data that has similar covariance across time
% (T), neurons (N), and conditions (C), but otherwise lacks higher-order statistics of the
% real data. See Elsayed and Cunningham Nature Neuroscience 2017 for this method (I use their
% published code-pack).
% 
% This code works better in slightly older MATLAB (e.g. R2015a) because some of the
% function calls (e.g. princomps) are deprecated by 2017).
%
% Sergey Stavisky, January 9 2018
% Stanford Neural Prosthetics Translational Laboratory
function WORKUP_speech_jPCA_LFADS

clear
% add TME code to path
% TMEstartup; % maybe not necessary if it's already on path.
rng(1)

saveFiguresDir = [FiguresRootNPTL '/speech/jPCA/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end

% I save the caterpillar projections here, so that I can render them as a
% video on my laptop later.
saveResultsDir = [ResultsRootNPTL '/speech/LFADS/caterpillar/'];
if ~isdir( saveResultsDir )
    mkdir( saveResultsDir )
end


%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted.3 The RESPONSE label ('ga' in above example) is used as the label for this trial.


%% t5.2017.10.23 Phonemes
participant = 't5';
Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.23-phonemes.mat'];
originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.23-phonemes_5ae60c61a42dca423cd4ab54034528cc.mat';

% t5.2017.10.23 Caterpillar
datasetNameCater = 't5.2017.10.23-caterpillar-overlap';
originalDataPathCater = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.23-caterpillar_6d87e2b2dea9d0fd01a4dab770229c1b.mat';


%% t5.2017.10.25 Words
% participant = 't5';
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t5.2017.10.25-words.mat'];
% originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t5.2017.10.25-words_82c2626e58be7297f50c2fe82ad705f5.mat';


%% t8.2017.10.28 Words
% participant = 't8';
% Rfile = [ResultsRootNPTL '/speech/Rstructs/R_t8.2017.10.18-words.mat'];

% originalDataPath = '/net/derivative/user/sstavisk/Results/speech/dataForLFADS/t8.2017.10.18-words_8addfbbee389070374096973486f884a.mat';

% LFADS SPECIFICATIONS

runID = 1; % which LFADS run to perform analysis on
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');

lfadsPreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetName filesep]; %contains the input files for LFADS
lfadsPostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetName filesep]; %contains the results of each LFADS run
runParams = load([lfadsPreDir 'runParams.mat'],'paramFields','paramPossibilities','runTable','paramVec','datasetNames');


%% Load data fed into LFADS (speech trial data)
originalDat = load(originalDataPath);


%%
includeLabels = labelLists( Rfile ); % lookup;
% Don't analyze silence / stayStill 
includeLabels(strcmp( includeLabels,{'silence'})) = [];
includeLabels(strcmp( includeLabels,{'stayStill'})) = [];
uniqueLabels = unique( includeLabels );

% It's nice to see some PSTHs, with the same color scheme as jPCA 
% These are chosen based on which channels were interesting from earlier PSTH analysis
% Should be an even number for a nicer plot
switch participant
    case 't5' % T5 Example channels (high ANOVA scores):
        plotTheseElecs = {...
            'chan_1.6';
            'chan_1.9';
            'chan_1.20';
            'chan_1.37';
            'chan_2.1';
            'chan_2.2';
            'chan_2.3';
            'chan_2.4';
            'chan_2.7';
            'chan_2.34';
            'chan_2.41';
            'chan_2.85';
            };
        
    case 't8'        % T8 Example channels (high ANOVA scores)
        plotTheseElecs = {...
            'chan_1.7';
            'chan_1.33';
            'chan_1.1';
            'chan_2.68';
            'chan_2.41';
            'chan_1.71';
            'chan_1.34';
            'chan_2.75';
            'chan_2.71';
            'chan_2.73';
            'chan_2.69';
            'chan_2.63';
            };
end



% The alignment window is set in the data that was provided to LFADS. Here
% let's pull it out so I have a record of it.
% Align to audible start of response speech (VOT)
params.alignEvent = originalDat.datInfo.params.alignEvent;
params.startEvent = originalDat.datInfo.params.startEvent;
params.endEvent = originalDat.datInfo.params.endEvent;


% The exact JPCA epoch used is defined below for now to make it faster for me to try different
% windows.
params.downSampleEveryNms = originalDat.datInfo.params.sampleEveryNms; % Note that data was already downsampled, don't do it again
params.gaussianSmoothStdMS = 30; % the neural data is smoothed with a gaussian kenrel of this many ms 1 standard deviation before jPCA

% jPCA specific parameters
params.jPCA_params.softenNorm = 10;
params.jPCA_params.suppressBWrosettes = true;
params.jPCA_params.suppressHistograms = true;
params.jPCA_params.meanSubtract = true;
params.jPCA_params.numPCs = 6;

% what timestamps (from the Data structure) to use.
switch params.alignEvent
    case 'handResponseEvent' % SPEECH ALIGNMENT
        params.dataTimestamps =  -151:params.downSampleEveryNms :99;        
    case 'handPreResponseBeep'  % GO CUE ALIGNMENT
        params.dataTimestamps = 899:params.downSampleEveryNms :1399; % T5 % 
%         params.dataTimestamps = 1200:params.downSampleEveryNms :1450; % T8
end

% Add jPCA code (from Churchland et al 2012, obtained from Chuchland lab website)
addpath( genpath( [CodeRootNPTL '/code/analysis/Sergey/generic/jPCA/'] ) );

% SURROGATE DATA TESTING PARAMETERS
params.surrogate_type = 'surrogate-TNC';
params.numSurrogates = 100; % how many surrogate datasets to compare to



%% Load the LFADS firing rates for this run
datasetNumStr = num2str( runID );
fileTrain = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_train_posterior_sample_and_average'];
fileValid = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_valid_posterior_sample_and_average'];
fileMat = [lfadsPreDir 'matlabDataset.mat'];

resultTrain = hdf5load(fileTrain);
resultValid = hdf5load(fileValid);
matInput = load(fileMat);

smoothRates = zeros(size(matInput.all_data)); % chan x time x trial
smoothRates(:,:,matInput.trainIdx) = resultTrain.output_dist_params;
smoothRates(:,:,matInput.validIdx) = resultValid.output_dist_params;


%% Format the data for jPCA
% dataTensor = permute( originalDat.datTensor, [2 3 1]); % If I want to use original data. Permute so it's chan x time x trial
dataTensor = smoothRates; %  % chan x time x trial

% prepare the smoothing kernel
numSTD = 3; % will make the kernel out to this many standard deviations
gaussSD = params.gaussianSmoothStdMS/params.downSampleEveryNms; % divide by bin size since data is not 1 ms resolution 
x = -numSTD*gaussSD:1:numSTD*gaussSD;
gkern = normpdf( x, 0, gaussSD );
gkern = gkern ./ sum( gkern );


% smooth all the single-trial data first, so that if I want to I can also
% plot single-trial jPCA.
filteredT = round( 1000.*originalDat.datInfo.t ); % converted to ms
% trim off not suitably filtered parts
filteredT(1:numSTD*gaussSD) = [];
filteredT(end-numSTD*gaussSD+1:end) = [];
datTensorSmoothed = dataTensor;
for iTrial = 1 : size( datTensorSmoothed,  3 )
    datTensorSmoothed(:,:,iTrial) = filter( gkern, 1, squeeze( datTensorSmoothed(:,:,iTrial) )' )';
end
% cut off the not-to-be-trusted-due-to-filtering portions
datTensorSmoothed(:,1:2*numSTD*gaussSD,:) = []; % 2 x because only taking from front, to shift everything back


% This involves the key trial-averaging operation.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrials = strcmp( originalDat.datInfo.label, myLabel );
    
    % trial-average within this condition    
    trialAvgDat = squeeze( mean( datTensorSmoothed(:,:,myTrials), 3) )'; % time x chan
    Data(iLabel).A = trialAvgDat; % time x channel
    Data(iLabel).times = filteredT;  
end

%% Make jPCA Plots
[Projection, Summary] = jPCA( Data, params.dataTimestamps, params.jPCA_params );
fprintf('%i PCs used capture %.4f overall variance (%s)\n', ...
    params.jPCA_params.numPCs, sum(Summary.varCaptEachPC(1:end)), mat2str( Summary.varCaptEachPC , 4 ) )

% Make the jPCA plot
plotParams.planes2plot = [1]; % PLOT
[figh, cmap] = makeJPCAplot(  Projection, Summary, plotParams, uniqueLabels );
titlestr = sprintf('jPCA trajectories %s', datasetName );
figh.Name = titlestr;

% Make a movie of trial-averaged data
% switch params.alignEvent
%     case 'handResponseEvent'
%         movParams.times = -999:10:999; % SPEECH ALIGNMENT        
%     case 'handPreResponseBeep'
%         movParams.times = 9:10:2499; % GO ALIGNMENT
% end
% 
% 
% movParams.pixelsToGet = [600 500 560 420]; % depends on monitor
% MV = phaseMovie(Projection, Summary, movParams);
% figh = figure;
% figh.Name = 'Trial-averaged movie';
% movie(MV); % shows the movie in a matlab figure window
% movie2avi(MV, 'Trial-avg LFADS-jPCA movie', 'FPS', 12, 'compression', 'none'); % 'MV' now contains the movie



%% Also plot PCs for context
figh = figure;
titlestr = sprintf('PCs %s', datasetName );
figh.Name = titlestr;
figh.Color = 'w';
numPCs = size( Summary.PCs, 2 );
t = Projection(1).times;
for iPC = 1 : numPCs
    axh(iPC) = subplot( 2, numPCs/2, iPC );
    hold on;
    for iLabel = 1 : numel( uniqueLabels )
        myThisPC = Projection(iLabel).tradPCAproj(:,iPC);
        hplot(iLabel) = plot( t, myThisPC, 'Color', cmap(iLabel,:) );
    end
    xlim( [t(1) t(end)] );
    title( sprintf('PC%i (%.1f%%)', iPC, 100*Summary.varCaptEachPC(iPC)) );
end

%% Sanity Check, plot a few electrodes
% should be even number of channels
figh = figure;
titlestr = sprintf('Example LDADS electrodes %s', datasetName );
figh.Name = titlestr;
figh.Color = 'w';
numPlots = numel( plotTheseElecs );
t = Data(1).times;
elecsMinHz = inf; % will be used to standardize 
elecsMaxHz = -inf;
for iChan = 1 :numPlots
    axh(iChan) = subplot( 2, numPlots/2, iChan );
    myChanInd = strcmp( originalDat.datInfo.channelName, plotTheseElecs{iChan} );
    hold on;
    for iLabel = 1 : numel( uniqueLabels )
        myFR = Data(iLabel).A(:,myChanInd);
        hplot(iLabel) = plot( t, myFR, 'Color', cmap(iLabel,:) );
        elecsMinHz = min( [elecsMinHz, min( myFR )] );
        elecsMaxHz = max( [elecsMaxHz, max( myFR )] );
    end
    xlim( [t(1) t(end)] );
    title( sprintf('%s', plotTheseElecs{iChan} ), 'Interpreter', 'none' );
end
linkaxes( axh );
xlim( [t(1) t(end) ])
ylim( [elecsMinHz elecsMaxHz] )

% mark analysis epoch for PCA
for iChan = 1 : numPlots
   axes( axh(iChan) );
   myYlim = get( gca, 'YLim' );
   line( [ Projection(1).times(1) Projection(1).times(1)], myYlim, ...
       'Color', [0.5 0.5 0.5], 'LineWidth', 0.5 );
    line( [ Projection(1).times(end) Projection(1).times(end)], myYlim, ...
       'Color', [0.5 0.5 0.5], 'LineWidth', 0.5 )
end









%% Single-trial structured block jPCA
% Since we'll be doing single-trial for Caterpillar, let's make sure it
% looks fine for the words/phonemes data where we can compare to
% trial-averaged.

numTrials = size( datTensorSmoothed, 3 );

%---------------------
% WAY 1: apply the trial-averaged jPCs to the single-trial data, plot that:
%---------------------
% SingleTrialProjection = struct();
% for iTrial = 1 : numTrials
%     myDat = squeeze( datTensorSmoothed(:,:,iTrial) ); % chans x time
%     % project into PC space
%     myDatJPC = myDat'*Summary.jPCs_highD;
%     myTimeInds = ismember( filteredT, params.dataTimestamps );
%     SingleTrialProjection(iTrial).proj = myDatJPC(myTimeInds,:);
%     SingleTrialProjection(iTrial).times = filteredT(myTimeInds);
%     SingleTrialProjection(iTrial).allTimes =  SingleTrialProjection(iTrial).times;
%     SingleTrialProjection(iTrial).projAllTimes = SingleTrialProjection(iTrial).proj;
% end
% 
% [colorStruct, haxP, vaxP] = phaseSpace( SingleTrialProjection, Summary, plotParams );



%---------------------
% WAY 2: do jPCA on the single-trial data
%---------------------
% This involves the key trial-averaging operation.
for iLabel = 1 : numTrials % note that now each trial is a label
    myDat = squeeze( datTensorSmoothed(:,:,iLabel) ); % chans x time
    SingleTrialData(iLabel).A = myDat'; % time x channel
    SingleTrialData(iLabel).times = filteredT;  
end
[SingleTrialProjection, SingleTrialSummary] = jPCA( SingleTrialData, params.dataTimestamps, params.jPCA_params );
fprintf('%i PCs used capture %.4f overall variance (%s)\n', ...
    params.jPCA_params.numPCs, sum(SingleTrialSummary.varCaptEachPC(1:end)), mat2str( SingleTrialSummary.varCaptEachPC , 4 ) )
[figh, cmap] = makeJPCAplot(  SingleTrialProjection, SingleTrialSummary, plotParams, uniqueLabels );
titlestr = sprintf('Single Trial jPCA trajectories %s', datasetName );
figh.Name = titlestr;



% % Make a movie of single-trial data
% switch params.alignEvent
%     case 'handResponseEvent'
%         movParams.times = -999:10:999; % SPEECH ALIGNMENT        
%     case 'handPreResponseBeep'
%         movParams.times = 399:10:2499; % GO ALIGNMENT
% end
% movParams.pixelsToGet = [600 500 560 420]; % depends on monitor. Make bigger later if I want it higher res
% MV = phaseMovie(SingleTrialProjection, SingleTrialSummary, movParams);
% figh = figure; figh.Name = 'single trial LFADS-JPCA movie';
% movie(MV); % shows the movie in a matlab figure window
% movie2avi(MV, 'single-trial LFDADS-jPCA movie', 'FPS', 12, 'compression', 'none'); % 'MV' now contains the movie




%% Significance testing against surrugate data with primary statistics matched to real data
% (Elsayed and Cunningham, Nature Neuroscience, 2017).


% Rearrange the Data matrix (or rather, part of it that is actually used in the jPCA
% analysis) to a dataTensor as expected by Gamal's code. dataTensor is time x neuron x
% condition.
T = numel( params.dataTimestamps );

% % % % % % % % % % % % % % 
% Choose single-trial vs trial-average to stats on % 
% % % % % % % % % % % % % % 

% apply to trial-averaged data:
statsData = Data;
trueSummary = Summary;
fprintf('DOING SURROGATE STATS ON TRIAL-AVERAGE DATA\n')


% APPLY STATISTICS TO SINGLE-TRIAL DATA
% statsData = SingleTrialData;
% trueSummary = SingleTrialSummary;
% fprintf('DOING SURROGATE STATS ON SINGLE-TRIAL DATA\n')


N = size( statsData(1).A, 2 );
C = numel( statsData );
dataTensor = nan( T, N, C );
tensorTimestamps = params.dataTimestamps;
for iC = 1 : C
    theseInds = ismember( statsData(iC).times, tensorTimestamps );  % matching time inds
    dataTensor(:,:,iC) = statsData(iC).A(theseInds,:);
end


% quantify primary features of the original data
[targetSigmaT, targetSigmaN, targetSigmaC, M] = extractFeatures(dataTensor);


if strcmp(params.surrogate_type, 'surrogate-T')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = [];
    GCparams.margCov{3} = [];
    GCparams.meanTensor = M.T;
elseif strcmp(params.surrogate_type, 'surrogate-TN')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = targetSigmaN;
    GCparams.margCov{3} = [];
    GCparams.meanTensor = M.TN;
elseif strcmp(params.surrogate_type, 'surrogate-TNC')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = targetSigmaN;
    GCparams.margCov{3} = targetSigmaC;
    GCparams.meanTensor = M.TNC; 
else
    error('please specify a correct surrogate type') 
end
maxEntropy = fitMaxEntropy( GCparams );             % fit the maximum entropy distribution

% These are the summary statistics I'll be saving from each surrogate run
R2_Mbest_surr = nan( params.numSurrogates, 1 );
R2_Mskew_surr = R2_Mbest_surr;
R2_MbestPrimary2d_surr = R2_Mbest_surr;
R2_MskewPrimary2d_surr = R2_Mbest_surr;
totalVarCaptured_surr = R2_Mbest_surr;
surrJPCAparams = params.jPCA_params;
surrJPCAparams.suppressText = 1;
for iSurr = 1 : params.numSurrogates
    fprintf('surrogate %d from %d \n', iSurr, params.numSurrogates)
    [surrTensor] = sampleTME(maxEntropy);       % generate TME random surrogate data.
    surrData = dataTensorToDataStruct( surrTensor, tensorTimestamps );
    
    % Run same jPCA analysis on this surrogate data
    [surProjection, surSummary] = jPCA( surrData, params.dataTimestamps, surrJPCAparams );
    R2_Mbest_surr(iSurr) = surSummary.R2_Mbest_kD;
    R2_Mskew_surr(iSurr) = surSummary.R2_Mskew_kD;
    R2_MbestPrimary2d_surr(iSurr) = surSummary.R2_Mbest_2D;
    R2_MskewPrimary2d_surr(iSurr) = surSummary.R2_Mskew_2D;
    totalVarCaptured_surr(iSurr) = sum(surSummary.varCaptEachPC(1:end));
    
    % Make the jPCA plot (for just 1 surrogate dataset
    if iSurr == 1
        [figh, cmap] = makeJPCAplot(  surProjection, surSummary, plotParams, uniqueLabels );
        titlestr = sprintf('SURROGATE LFADS jPCA trajectories %s', datasetName );
        figh.Name = titlestr;
        
        % Make the PCs plot too
        figh = figure;
        titlestr = sprintf('SURROGATE PCs %s', datasetName );
        figh.Name = titlestr;
        figh.Color = 'w';
        numPCs = size( surSummary.PCs, 2 );
        t = surProjection(1).times;
        for iPC = 1 : numPCs
            axh(iPC) = subplot( 2, numPCs/2, iPC );
            hold on;
            for iLabel = 1 : numel( uniqueLabels )
                myThisPC = surProjection(iLabel).tradPCAproj(:,iPC);
                hplot(iLabel) = plot( t, myThisPC, 'Color', cmap(iLabel,:) );
            end
            xlim( [t(1) t(end)] );
            title( sprintf('PC%i (%.1f%%)', iPC, 100*surSummary.varCaptEachPC(iPC)) );
        end
    end
end

%% evaluate a P value
fprintf('\nSTATISTICS FOR LFADS-REGULAR DATA\n')
trueMetric = trueSummary.R2_Mskew_kD;
surrMetrics = R2_Mskew_surr;
P = mean( trueMetric <= surrMetrics); % (upper-tail test)
fprintf('True R2_Mskew_kD is %g, which is > %i/%i surrogates (P value = %g). Mean of surrogotes = %g\n', ...
    trueMetric, nnz( trueMetric > surrMetrics ), numel( surrMetrics ), P, mean( surrMetrics ) )
fprintf('True R2_Mbest_kD is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mbest_kD, mean( R2_Mbest_surr ) )
fprintf('True R2_Mskew_2D is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mskew_2D, mean( R2_MskewPrimary2d_surr ) )
fprintf('True R2_Mbest_2D is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mbest_2D, mean( R2_MbestPrimary2d_surr ) )
fprintf('True variance explained by first %i PCs is %g; mean for surrogates is %g\n', ...
    numel( trueSummary.varCaptEachPC ), sum( trueSummary.varCaptEachPC ), mean( totalVarCaptured_surr ) );

%%%%%%%%%%%%%%%% plot null distribution
x = 0:0.03:1;
h = hist(surrMetrics, x);
figh = figure;
set(figh, 'color', [1 1 1]);
hold on
box on
hb = bar(x, h);
set(hb,'facecolor',[0.5000    0.3118    0.0176],'barwidth',1,'edgecolor','none')
p = plot(trueMetric, 0, 'ko', 'markerfacecolor', 'k', 'markersize',10);
xlabel('summary statistic (R^2)')
ylabel('count')
xlim([0 1])
set(gca, 'FontSize',12)
set(gca, 'xtick',[-1 0 1])
legend([p, hb], {'original data', params.surrogate_type})
legend boxoff
titlestr = sprintf('Surrogate distribution LFADS %s', datasetName );
figh.Name = titlestr;


fprintf('PAUSING BEFORE CATERPILLAR\n')
keyboard
% =======================================================================
%% Load the Caterpillar LFADS data
% =======================================================================
lfadsPreDir = ['/net/home/fwillett/Data/Derived/pre_LFADS/' datasetNameCater filesep];
lfadsPostDir = ['/net/home/fwillett/Data/Derived/post_LFADS/' datasetNameCater filesep];
originalDatCat = load( originalDataPathCater );
catBins = size(originalDatCat.datTensor,3); % how many time bins per 'trial'
catTrials = size(originalDatCat.datTensor,1); % how many faux-trials the caterpillar data is divided into
numChans = size(originalDatCat.datTensor,2); % # electrodes

fileTrain = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_train_posterior_sample_and_average'];
fileValid = [lfadsPostDir datasetNumStr filesep 'model_runs_h5_valid_posterior_sample_and_average'];
fileMat = [lfadsPreDir 'matlabDataset.mat'];

resultTrain = hdf5load(fileTrain);
resultValid = hdf5load(fileValid);
matInput = load(fileMat);
smoothRates = zeros(size(matInput.all_data));
smoothRates(:,:,matInput.trainIdx) = resultTrain.output_dist_params;
smoothRates(:,:,matInput.validIdx) = resultValid.output_dist_params; % chan x time x trial

% Make into non-overlapping time series;
catSlide = originalDatCat.datInfo.params.slideBinsForEachTrial; % in samples, NOT ms
catRates = []; % t x channels
tWithinReadThrough = []; % t x 1
dt = originalDatCat.datInfo.params.sampleEveryNms; %  neural data is every how many ms?

% I'll also want to track the audio data that accompanies this neural data.
audioSamplesPerNeural = 30*dt;
catAudio.dat = []; % will fill as I go
catAudio.t = [];
for iTrial = 1 : catTrials
    catAudio.dat = [catAudio.dat; originalDatCat.audioMatrix(iTrial,1:audioSamplesPerNeural*catSlide)'];
    % what are the times of this? in ms 
    myT = 1/30 : 1/30 : catSlide*dt;
    myT = myT + 1000*originalDatCat.datInfo.tWithinReadthrough(iTrial,1) - dt;
    catAudio.t = [catAudio.t; myT'];
end

% % WAY 1: just go with one 'trial' as veridical. This will be jumpier. 
for iTrial = 1 : catTrials
    catRates = [catRates; smoothRates(:,1:catSlide,iTrial)'];
    tWithinReadThrough = [tWithinReadThrough; originalDatCat.datInfo.tWithinReadthrough(iTrial,1:catSlide)'];
end


% WAY 2: 'trial'-average in the overlapping portions of data across LFADS
% trials
% numOverlappingTrials = catBins/catSlide; % 6
% for iTrial = numOverlappingTrials : catTrials-numOverlappingTrials
%     timesMat = [];
%     datMat = [];% local, will be averaged;
%     ptr = 1;
%     for jTrial = iTrial : -1 : iTrial - numOverlappingTrials + 1
%         myStartInd = ptr;
%         myEndInd = ptr + catSlide - 1;
%         timesMat = [timesMat; originalDatCat.datInfo.tWithinReadthrough(jTrial,myStartInd:myEndInd)];
%         ptr = ptr + catSlide;     
%         datMat = cat(3, datMat, squeeze( smoothRates(:,myStartInd:myEndInd,jTrial) ));
%     end    
%     catRates = [catRates; squeeze( mean( datMat, 3 ) )'];
%     tWithinReadThrough = [tWithinReadThrough; mode( timesMat )']; % mode or else inter-readthrough gets wonky and scrws up rollover detect below
% end





% Divide into separate 'trials' for each Caterpillar read-through
startOfReadInds = [1 ; find( diff( tWithinReadThrough ) < 0 )+1];
% how long is each trial? I need this to make them all the same length,
% which will be the maximum length of a trial
lengthEachRead = diff( [startOfReadInds; numel( tWithinReadThrough )] );
numReads = numel( lengthEachRead );
uniformLength = min( lengthEachRead );
datTensorCater = nan( numChans, uniformLength, numReads ); % chans x time x reads
for iRead = 1 : numReads
    datTensorCater(:,:,iRead) = catRates(startOfReadInds(iRead):startOfReadInds(iRead)+uniformLength-1,:)';
end


% smooth all the single-trial data first, so that if I want to I can also
% plot single-trial jPCA.
filteredT = [0 : 10 : size( datTensorCater,2 )*10-1]'; % ms;  
% trim off not suitably filtered parts
filteredT(1:numSTD*gaussSD) = [];
filteredT(end-numSTD*gaussSD+1:end) = [];
datTensorCaterSmoothed = datTensorCater;
for iTrial = 1 : size( datTensorCaterSmoothed,  3 )
    datTensorCaterSmoothed(:,:,iTrial) = filter( gkern, 1, squeeze( datTensorCaterSmoothed(:,:,iTrial) )' )';
end
% cut off the not-to-be-trusted-due-to-filtering portions
datTensorCaterSmoothed(:,1:2*numSTD*gaussSD,:) = []; % 2 x because only taking from front, to shift everything back

% Put into the jPCA code format
CaterData = struct();
labelNames = {};
for iLabel = 1 : numReads % note that now each read is a label
    myDat = squeeze( datTensorCaterSmoothed(:,:,iLabel) ); % chans x time
    CaterData(iLabel).A = myDat'; % time x channel
    CaterData(iLabel).times = filteredT;
end
CaterForjPCA = CaterData; % long read-throughs
caterExampleTimes = 10000:10500; % plot this brief window in a jPCA plot just to have some example

% --  ALTERNATIVE APPROACH --
%  Chop up into additional mini-trials
miniTrialLengthMS = 2000; % 2 second mini-trials
numMinisPerRead = floor( uniformLength*10/miniTrialLengthMS );
ptrMini = 1;
CaterMiniData = struct();
for iRead = 1 : numReads
    ptr = 1;
    for iMini = 1 : numMinisPerRead
        CaterMiniData(ptrMini).A = CaterData(iRead).A(ptr:-1+ptr+miniTrialLengthMS/dt,:);
        CaterMiniData(ptrMini).times = [dt:dt:miniTrialLengthMS]';
        ptrMini = ptrMini + 1;
        ptr = ptr + miniTrialLengthMS/dt;
    end
end
CaterForjPCA = CaterMiniData; % short chopped up
caterExampleTimes = 500:1000; % short bit of this data







% Run through jPCA
[CaterProjection, CaterSummary] = jPCA( CaterForjPCA, CaterForjPCA(1).times, params.jPCA_params );
fprintf('%i PCs used capture %.4f overall variance (%s)\n', ...
    params.jPCA_params.numPCs, sum(CaterSummary.varCaptEachPC(1:end)), mat2str( CaterSummary.varCaptEachPC , 4 ) )

% Make a plot of a bit of example data
[CaterProjectionExample, CaterSummaryExample] = jPCA( CaterForjPCA, caterExampleTimes, params.jPCA_params );
[figh, cmap] = makeJPCAplot(  CaterProjectionExample, CaterSummaryExample, plotParams );
titlestr = sprintf('Caterpillar jPCA trajectories %s', datasetName );
fprintf('Plotting caterpillar example for times %g to %g of each of %i conditions\n', ...
    caterExampleTimes(1), caterExampleTimes(end), numel( CaterForjPCA ) )
figh.Name = titlestr;



%% Surrogate data statistics on the Caterpillar jPCA


% Rearrange the Data matrix to a dataTensor as expected by Gamal's code. 
% dataTensor is time x neuron x
% condition.
T = numel( CaterForjPCA(1).times );
statsData = CaterForjPCA;
trueSummary = CaterSummary;
N = size( statsData(1).A, 2 );
C = numel( statsData );
dataTensor = nan( T, N, C );
tensorTimestamps =  CaterForjPCA(1).times;
for iC = 1 : C
    theseInds = ismember( statsData(iC).times, tensorTimestamps );  % matching time inds
    dataTensor(:,:,iC) = statsData(iC).A(theseInds,:);
end


% quantify primary features of the original data
[targetSigmaT, targetSigmaN, targetSigmaC, M] = extractFeatures(dataTensor);


if strcmp(params.surrogate_type, 'surrogate-T')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = [];
    GCparams.margCov{3} = [];
    GCparams.meanTensor = M.T;
elseif strcmp(params.surrogate_type, 'surrogate-TN')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = targetSigmaN;
    GCparams.margCov{3} = [];
    GCparams.meanTensor = M.TN;
elseif strcmp(params.surrogate_type, 'surrogate-TNC')
    GCparams.margCov{1} = targetSigmaT;
    GCparams.margCov{2} = targetSigmaN;
    GCparams.margCov{3} = targetSigmaC;
    GCparams.meanTensor = M.TNC; 
else
    error('please specify a correct surrogate type') 
end
maxEntropy = fitMaxEntropy( GCparams );             % fit the maximum entropy distribution

% These are the summary statistics I'll be saving from each surrogate run
R2_Mbest_surr = nan( params.numSurrogates, 1 );
R2_Mskew_surr = R2_Mbest_surr;
R2_MbestPrimary2d_surr = R2_Mbest_surr;
R2_MskewPrimary2d_surr = R2_Mbest_surr;
totalVarCaptured_surr = R2_Mbest_surr;
surrJPCAparams = params.jPCA_params;
surrJPCAparams.suppressText = 1;
for iSurr = 1 : params.numSurrogates
    fprintf('surrogate %d from %d \n', iSurr, params.numSurrogates)
    [surrTensor] = sampleTME(maxEntropy);       % generate TME random surrogate data.
    surrData = dataTensorToDataStruct( surrTensor, tensorTimestamps );
    
    % Run same jPCA analysis on this surrogate data
    [surProjection, surSummary] = jPCA( surrData, filteredT(1):10:filteredT(end), surrJPCAparams );
    R2_Mbest_surr(iSurr) = surSummary.R2_Mbest_kD;
    R2_Mskew_surr(iSurr) = surSummary.R2_Mskew_kD;
    R2_MbestPrimary2d_surr(iSurr) = surSummary.R2_Mbest_2D;
    R2_MskewPrimary2d_surr(iSurr) = surSummary.R2_Mskew_2D;
    totalVarCaptured_surr(iSurr) = sum(surSummary.varCaptEachPC(1:end));
    
end

%% evaluate a P value
fprintf('\nSTATISTICS FOR LFADS-CATERPILLAR\n')
trueMetric = trueSummary.R2_Mskew_kD;
surrMetrics = R2_Mskew_surr;
P = mean( trueMetric <= surrMetrics); % (upper-tail test)
fprintf('True R2_Mskew_kD is %g, which is > %i/%i surrogates (P value = %g). Mean of surrogotes = %g\n', ...
    trueMetric, nnz( trueMetric > surrMetrics ), numel( surrMetrics ), P, mean( surrMetrics ) )
fprintf('True R2_Mbest_kD is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mbest_kD, mean( R2_Mbest_surr ) )
fprintf('True R2_Mskew_2D is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mskew_2D, mean( R2_MskewPrimary2d_surr ) )
fprintf('True R2_Mbest_2D is %g,  Mean of surrogotes = %g\n', ...
    trueSummary.R2_Mbest_2D, mean( R2_MbestPrimary2d_surr ) )
fprintf('True variance explained by first %i PCs is %g; mean for surrogates is %g\n', ...
    numel( trueSummary.varCaptEachPC ), sum( trueSummary.varCaptEachPC ), mean( totalVarCaptured_surr ) );

%%%%%%%%%%%%%%%% plot null distribution
x = 0:0.03:1;
h = hist(surrMetrics, x);
figh = figure;
set(figh, 'color', [1 1 1]);
hold on
box on
hb = bar(x, h);
set(hb,'facecolor',[0.5000    0.3118    0.0176],'barwidth',1,'edgecolor','none')
p = plot(trueMetric, 0, 'ko', 'markerfacecolor', 'k', 'markersize',10);
xlabel('summary statistic (R^2)')
ylabel('count')
xlim([0 1])
set(gca, 'FontSize',12)
set(gca, 'xtick',[-1 0 1])
legend([p, hb], {'original data', params.surrogate_type})
legend boxoff
titlestr = sprintf('Surrogate distribution Caterpillar LFADS %s', datasetName );
figh.Name = titlestr;



%% Project each read through into the jPC plane
% This is what gets saved to a file that I can later use to plot the
% rotations video with accompanying audio.
jpcMovie = struct; 
% divide up the audiodata read-throughs
rollovers = [1 ;find( diff( catAudio.t ) < 0 )+1];
audioEnds = [rollovers(2:end)-1; numel( catAudio.t )];

% Use projection from single-trial words/phonemes
% projectInfo.projectionMatrix = SingleTrialSummary.jPCs_highD;
% projectInfo.Summary = SingleTrialSummary;

% Use projection from chopped-up Caterpillar
projectInfo.projectionMatrix = CaterSummary.jPCs_highD;
projectInfo.Summary = CaterSummary;

for iRead = 1 : numReads
     % grab my neural data 
  
     jpcMovie(iRead).projection = CaterData(iRead).A * projectInfo.projectionMatrix;
     jpcMovie(iRead).times = CaterData(iRead).times;
     % grab my audio data
     jpcMovie(iRead).audioDat = catAudio.dat(rollovers(iRead):audioEnds(iRead));
     jpcMovie(iRead).audioT = catAudio.t(rollovers(iRead):audioEnds(iRead));
end
caterProjFilename = sprintf('%scaterLFADS_run%i', saveResultsDir, runID);
save( caterProjFilename, 'jpcMovie' );
fprintf('Saved %s\n', caterProjFilename )



end

%% Support functions
function DataOut = dataTensorToDataStruct( dataTensor, timestamps )
    % takes a dataTensor (format of data used and generated by Gamal & John's TME code)
    % and converts it into the data structure expected by Mark's jPCA code
    % Preserves ordering of conditions in dataTensor and in the data structure
    for iC = 1 : size( dataTensor, 3 )
        DataOut(iC).A = dataTensor(:,:,iC); % time x neuron
        DataOut(iC).times = forceCol( timestamps );
    end
end


function [figh, cmap] = makeJPCAplot( Projection, Summary, plotParams, uniqueLabels )
    % Makes the jPCA plot using Mark's code.

    [colorStruct, haxP, vaxP] = phaseSpace( Projection, Summary, plotParams );

    % identify the groups
    [ indsLeftToRight, cmap ] = whichGroupIsWhichJpca( Projection );
    
    % Label the end points of each condition with its label. Note this won't work if more than
    % one plane was plotted (because it'll try to plot on the last plane using data from first
    % plane. So make plotParams.planes2plot = 1 to use this .
    figh = gcf;
    if nargin > 3
        for iLabel = 1 : numel( uniqueLabels )
            myH = Projection(iLabel).proj(end,1);
            myV = Projection(iLabel).proj(end,2);
            th(iLabel) = text( myH, myV, uniqueLabels{iLabel} );
        end
    end

end