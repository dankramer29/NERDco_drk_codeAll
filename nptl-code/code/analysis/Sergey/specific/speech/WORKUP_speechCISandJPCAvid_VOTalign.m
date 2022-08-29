% Makes a video of the words datasets' neural trajectories starting from ___ to after
% speaking starts. It is projected into CIS1 and the top jPC plane of the CI components,
% as in Kaufman et al 2016.
%
% Technical Note: when soft-normalizing, I pick the soft-normalization denominators from
% the CIS analysis epoch. This choice is somewhat arbitrary (and will likely be the same
% across mutliple ranges), but this way the CIS1 dimension in this video is truly
% identical to the one in the CIS figure. The jPC dimensions will differ anyway, so I
% might as well keep one thing (the CIS1) the same.
%
% Sergey Stavisky, October 12 2018
clear


saveFiguresDir = [FiguresRootNPTL '/speech/CISjCPA/regularized/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
% saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated



%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted.3 The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.25 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
params.acceptWrongResponse = false;

% % t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList('t8.2017.10-18_-4.5RMSexclude');
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );


%% Get labels, ignore silence
includeLabels = labelLists( Rfile ); % lookup;
includeLabels(strcmp(includeLabels, 'silence')) = [];


numArrays = 2; % don't anticipate this changing

%% Analysis Parameters
% RMS Thresholds
params.thresholdRMS = -4.5; % spikes happen below this RMS
% params.neuralFeature = 'spikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 28 ms SD Gaussian as in Kaufman 2016
params.neuralFeature = 'spikesBinnedRateGaussian_30ms'; % spike counts binned smoothed with 28 ms SD Gaussian as done for jPCA analyses per Pandarinath 2015

% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;


% Note: soft-norm currently works only on the data range analyzed. The range does capture
% most of the peak but it's worth being aware of this.
% params.softenNorm = []; % leave empty to not do this
params.softenNorm = 5; % if not empty, how many Hz to add to range denominator
% NOTE: Kaufman 2016 does soft-norm. 
params.maxDims = 8; % main analysis
% params.maxDims = 12; % more dPCs


% Align to speak go cue. (matched to Kaufman 2016 Go Cue alignment)
% Speaking

% VIDEO plot alignment
params.vidAlignEvent = 'handResponseEvent';
params.vidStartEvent = 'handResponseEvent - 3.500'; % ~500 ms before audio cue
params.vidEndEvent= 'handResponseEvent + 1.000'; % 1000 ms after VOT
params.vidEventString = 'AO'; % gets added to clock in corner

% CIS determination epoch
params.CISalignEvent = 'handPreResponseBeep';
params.CISstartEvent = 'handPreResponseBeep - 0.200';
params.CISendEvent= 'handPreResponseBeep + 0.400';
% VOT align
% params.CISalignEvent = 'handResponseEvent';
% params.CISstartEvent = 'handResponseEvent - 1.200';
% params.CISendEvent= 'handResponseEvent + 0.500';
% params.CISalignEvent = 'handResponseEvent';
% params.CISstartEvent = 'handResponseEvent - 0.151';
% params.CISendEvent= 'handResponseEvent + 0.101';

% jPCA determination epoch
% align to VOT
params.jPCAalignEvent = 'handResponseEvent';
params.jPCAstartEvent = 'handResponseEvent - 0.151'; % 1 ms buffer to make sure exact ms is available
params.jPCAendEvent = 'handResponseEvent + 0.101';


% jPCA params
params.downSampleEveryNms = 10; % will downsample firing rates this often. Needed for JPCA
% what timestamps (from the Data structure) to use.
switch params.jPCAalignEvent
    case 'handResponseEvent' % SPEECH ALIGNMENT
        params.dataTimestamps =  -150:params.downSampleEveryNms :100;        
    case 'handPreResponseBeep'  % GO CUE ALIGNMENT
        params.dataTimestamps = 900:params.downSampleEveryNms :1400; % T5 from before
%         params.dataTimestamps = 1200:params.downSampleEveryNms :1450; % T8
end
addpath( genpath( [CodeRootNPTL '/code/analysis/Sergey/generic/jPCA/'] ) ); % Add jPCA code (from Churchland et al 2012, obtained from Chuchland lab website)

% Across-conditions mean subtract (at each time point) during the full video playback
params.jPCA_acrossConditionsMean = true;



% Color scheme and other aesthetics
viz.colorBaseline = [.4 .4 .4]; % trajectory color before the audio cue comes on (GRAY).
viz.colorDelay = [0 0 1]; % trajectory color from audio cue until go cue (BLUE).
viz.LineWidthBaseline = 3;
viz.LineWidthDelay = 4;
viz.LineWidthMove = 5;
viz.FontSize = 50;
viz.MarkerSize = 144; % make 0 to not draw a marker at the current time point.
viz.tvVectorLength = 6; % three vectors length. Default is 5

% Video 
viz.fps = 30.3030; % frames per second of the video (one second may not be one second of data though)
                   % not exactly 30 so an integer of ms between each frame.
viz.dilateTimeBy = 3; % 1 second of task time will be plotted in how many seconds
viz.figurePixels = [1080 1080];

% Camera rotation scripting
viz.cam.view0 = [45, 30]; % starting view (azimuth, elevation)
% note: t is in terms of tVid, meaning seconds relative to alignment of data
% implement the camera rotation in the specified time. Useful for panning at a particular
% time point, for example rotating to look at jPC1, jPC2 around movement onset.
%                  [t, azimuth, elevation]
viz.cam.script = [... 
    -1.1, 5, 10;
    -0.7, 5, 10;
    0.7, 80, 15;
    inf, 45, 30; % terminal epoch
    ];

% Below specifies camera epoch transitions after which the neural playback pauses and the
% camera just spends some time rotating.
% after which epoch to do this, how many seconds to spend, what view to go to
viz.cam.pauseAndRotate = [...
       2, 0.5,  5, 10; % brief pause 
       2, 2.0, 80, 15; % swing to show CIS1
       2, 0.5, 80, 15; % brief pause
       3, 2.0, 5, 10; % rotate to focus on CIS1
       3, 0.75, 5, 10; % brief pause
       3, 1.25, 45, 30; % rotate back to iso view
       ];
% can queu up multiple pause and rotates at a given transition (I don't use this
% currently)

result.params = params;
result.params.Rfile = Rfile;



%% Load the data
in = load( Rfile );
R = in.R;
clear('in')
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly

% exclude some trials?
if isfield( params, 'excludeTrials' ) && ~isempty( params.excludeTrials )
    excludeInds =  find( ismember( [R.trialNumber], params.excludeTrials ) .* ismember( [R.blockNumber], params.excludeTrialsBlocknum ) );
    fprintf('Excluding trials %s from blocks %s (%i trials)\n', ...
        mat2str( params.excludeTrials ), mat2str( params.excludeTrialsBlocknum ), numel( excludeInds ) );
    R(excludeInds) = [];
end

    

%% Annotate the data
% Scan for whether event labels files exist for these blocks. 
% Accept trials with wrong response to cue, if it was one of the included responses
if params.acceptWrongResponse
    numCorrected = 0;
    for iTrial = 1 : numel( R )
        myLabel = R(iTrial).label;
        if contains( myLabel, '-' ) 
            myResponse = myLabel(strfind( myLabel , '-' )+1:end);
            if ismember( myResponse, includeLabels )
                R(iTrial).label = myResponse;
                numCorrected = numCorrected + 1;
            end
        end
    end
    fprintf('%i trials with wrong response included based on their RESPONSE\n', numCorrected )
end

uniqueLabels = includeLabels( ismember( includeLabels, unique( {R.label} ) ) ); % throws out any includeLabels not actually present but keeps order
blocksPresent = unique( [R.blockNumber] );
% Restrict to trials of the labels we care about
R = R(ismember(  {R.label}, uniqueLabels ));
fprintf('PSTHs from %i trials across %i blocks with % i labels: %s\n', numel( R ), numel( blocksPresent ), ...
    numel( uniqueLabels ), CellsWithStringsToOneString( uniqueLabels ) );
% report trial counts for each condition
for iLabel = 1 : numel( uniqueLabels )
    fprintf(' %s: %i trials\n', uniqueLabels{iLabel}, nnz( arrayfun( @(x) strcmp( x.label, uniqueLabels{iLabel} ), R ) ) )
end
result.uniqueLabels = uniqueLabels;
result.blocksPresent = blocksPresent;
result.params = params;
allLabels = {R.label};


% Determine the critical alignment points
% note I choose to do this for each block, since this will better address ambient
% noise/speaker/mic position changes over the day, and perhaps reaction times too (for the
% silence speech time estimation)
if any( cell2mat( strfind( params.vidAlignEvent, 'vot' ) ) ) || ...
        any( cell2mat( strfind( params.CISalignEvent, 'vot' ) ) ) || ...
        any( cell2mat( strfind( params.jPCAalignEvent, 'vot' ) ) )
    fprintf('VOT alignment required, will add those now...\n')
    alignMode = 'VOTdetection';
else
    alignMode = 'handLabels';
end
uniqueBlocks = unique( [R.blockNumber] );
Rnew = [];
for blockNum = uniqueBlocks
    myTrials = [R.blockNumber] == blockNum; 
    Rnew = [Rnew;  speechEventAlignment( R(myTrials), Rfile, 'alignMode', alignMode )];
end
R = Rnew; 
clear( 'Rnew' );


%% Generate neural feature
% Apply RMS thresholding
if strfind( params.neuralFeature, 'sorted' )
    % Quick and easy way to do it: replace rasters with the spike sorted one
    fprintf('Using spike sorted rasters \n');
    [ R, sorted ] = ReplaceRastersWithSorted( R, 'numArrays', numArrays, ...
        'minimumQuality', params.minimumQuality, 'sortQuality', sortQuality, ...
        'manualExcludeList', speechSortedUnitExclusions( datasetName ) );
    params.neuralFeature = regexprep( params.neuralFeature, 'sorted', '');
    R = AddFeature( R, params.neuralFeature, 'channelName', sorted.unitString );
    
elseif ~isempty( params.thresholdRMS )
    % Apply RMS thresholding
    fprintf('Thresholding at %g RMS\n', params.thresholdRMS );
    for iTrial = 1 : numel( R )
        for iArray = 1 : numArrays
            switch iArray
                case 1
                    rasterField = 'spikeRaster';
                otherwise
                    rasterField = sprintf( 'spikeRaster%i', iArray );
            end
            ACBfield = sprintf( 'minAcausSpikeBand%i', iArray );
            myACB = R(iTrial).(ACBfield);
            RMSfield = sprintf( 'RMSarray%i', iArray );
            R(iTrial).(rasterField) = logical( myACB <  params.thresholdRMS .*repmat( R(iTrial).(RMSfield), 1, size( R(iTrial).(rasterField), 2 ) ) );
        end
    end
    R = AddFeature( R, params.neuralFeature  );
    
    if ~isempty( params.excludeChannels )
        fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
        R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.neuralFeature );
    end
else
    error('Feature not yet implemented')
end



%% Make PSTH for each alignment 
% Here I also get a single average rate for each channel per trial.
N = R(1).(params.neuralFeature).numChans;
label1 = uniqueLabels{1}; % convenient indexing into result.
maxTrialNum = 0; % will keep track of maximum number of trials.

for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );
    % 'Video' (whole range) alignment
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.vidStartEvent, 'alignEvent', params.vidAlignEvent, 'endEvent', params.vidEndEvent );
    result.(myLabel).tVid = jenga.t;
    result.(myLabel).psthVid= squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).numTrials = jenga.numTrials;
    % CIS alignment
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.CISstartEvent, 'alignEvent', params.CISalignEvent, 'endEvent', params.CISendEvent );
    result.(myLabel).tCIS = jenga.t;
    result.(myLabel).psthCis = squeeze( mean( jenga.dat, 1 ) );
    
     % save single trials (for CIS)
    result.(myLabel).CISallTrials = jenga.dat; % trials x time x electrode
    result.(myLabel).numTrials = jenga.numTrials;
    maxTrialNum = max( [maxTrialNum, result.(myLabel).numTrials]);
    
    
    % jPCA alignment
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.jPCAstartEvent, 'alignEvent', params.jPCAalignEvent, 'endEvent', params.jPCAendEvent );
    result.(myLabel).tjPCA = jenga.t;
    result.(myLabel).psthJPCA = squeeze( mean( jenga.dat, 1 ) );
    % channel names had best be the same across events/groups, so put them in one place
    result.channelNames = R(find(myTrialInds, 1, 'first')).(params.neuralFeature).channelName;
 end



%% Prep for plotting
% Define the specific colormap
colors = [];
legendLabels = {};
for iLabel = 1 : numel( uniqueLabels )
   colors(iLabel,1:3) = speechColors( uniqueLabels{iLabel} ); 
   legendLabels{iLabel} = sprintf('%s (n=%i)', uniqueLabels{iLabel}, result.(uniqueLabels{iLabel}).numTrials );
end

% Calculate when, on average, events happen relative to the alignment point. I use this to
% color the video.
tVid = result.(label1).tVid;

switch params.vidAlignEvent
  
%     
%     case 'handPreResponseBeep'
%         fprintf('Go cue happens at t=%.3f seconds into the video.\n', tVid(1) )
%         % When is audio cue presented relative to Go Cue?
%         dAudioCue = [R.handPreResponseBeep] - [R.handCueEvent]; % in ms
%         tAudioCue =  -median( dAudioCue )./1000; % in seconds, relative to alignment
%         sampleAudioCue = find( tVid >= tAudioCue, 1, 'first' ); %which sample of the vid data
%         elapsedSecAudioCue = 0 + tAudioCue - tVid(1);
%         fprintf('Audio cue (median across trials) happens at t=%.3f seconds.\n', elapsedSecAudioCue );
%         % When is the go cue?
%         sampleGoCue = find( tVid >= 0, 1, 'first' );
%         elapsedSecGoCue = 0 - tVid(1);
%         fprintf('Go cue (alignment event) happens at t=%.3f seconds.\n', elapsedSecGoCue );
%         % When is VOT?
%         dVOT = [R.handResponseEvent] - [R.handPreResponseBeep];
%         tVOT =  median( dVOT )./1000; % in seconds, relative to alignment
%         sampleVOT = find( tVid >= tVOT, 1, 'first' ); %which sample of the vid data
%         elapsedSecVOT = 0 + tVOT - tVid(1);
%         fprintf('VOT (median across trials) happens at t=%.3f seconds.\n', elapsedSecVOT );

    case {'handPreResponseBeep', 'handResponseEvent' }
        fprintf('Align event %s happens at t=%.3f seconds into the video.\n', params.vidAlignEvent, -tVid(1) )
        for iLabel = 1 : numel( uniqueLabels )
            myLabel = uniqueLabels{iLabel};
            myTrialInds = strcmp( allLabels, myLabel );
            % when is audio cue presented relative to VOT cue?
            dAudioCue = [R(myTrialInds).(params.vidAlignEvent)] - [R(myTrialInds).handCueEvent];
            tAudioCue(iLabel) = -median( dAudioCue )./1000;
            sampleAudioCue(iLabel) = find( tVid >= tAudioCue(iLabel), 1, 'first' ); %which sample of the vid data
            elapsedSecAudioCue(iLabel) = tAudioCue(iLabel) - tVid(1);
            fprintf('Audio cue (median across %s trials) happens at t=%.3f seconds.\n', myLabel, elapsedSecAudioCue(iLabel) );
            % When is the go cue?
            dGoCue = [R(myTrialInds).(params.vidAlignEvent)] - [R(myTrialInds).handPreResponseBeep];
            tGoCue(iLabel) = -median( dGoCue )./1000;
            sampleGoCue(iLabel) = find( tVid >= tGoCue(iLabel), 1, 'first' ); %which sample of the vid data
            elapsedSecGoCue(iLabel) = tGoCue(iLabel) - tVid(1);
            fprintf('Go cue (median across %s trials) happens at t=%.3f seconds.\n', myLabel, elapsedSecGoCue(iLabel) );
            % When is VOT?
            dVOT = [R(myTrialInds).(params.vidAlignEvent)] - [R(myTrialInds).handResponseEvent];
            tVOT(iLabel) =  -median( dVOT )./1000; % in seconds, relative to alignment
            sampleVOT(iLabel) = find( tVid >= tVOT(iLabel), 1, 'first' ); %which sample of the vid data
            elapsedSecVOT(iLabel) = tVOT(iLabel) - tVid(1);
            fprintf('VOT (median across %s trials) happens at t=%.3f seconds.\n', myLabel, elapsedSecVOT(iLabel) );
        end
        
        
    otherwise
        keyboard % don't anticipate doing a different alignment, but if so, different color coding of epochs will be needed.
end



%% Format for dPCA
% firingRatesAverage: N x S x D x T
% Note: operates on the PSTHs from the specified dPCA analysis epoch
% N is the number of neurons
% S is the number of conditions for factor 1
% T is the number of time-points (note that all the trials/conditions should have the
% same length in time!)
%
N = size( result.(uniqueLabels{1}).psthCis, 2 );
S = numel( uniqueLabels );
T = numel( result.(uniqueLabels{1}).tCIS )-1; % drop last sample so its even 100s of ms
combinedParams = {{1, [1 2]}, {2}}; %so marginalization 1 is condition and condition/time, and marg. 2 is just time
margNames = {'Condition-dependent', 'Condition-independent'};


trialNum = nan( N, S );
featureAverages = nan(N, S, T);
featureIndividual = nan(N, S, T, maxTrialNum); % individual trial data

for iLabel = 1 : numel( uniqueLabels )
    featureAverages(:,iLabel,:) = result.(uniqueLabels{iLabel}).psthCis(1:end-1,:)';
    myDat = result.(uniqueLabels{iLabel}).CISallTrials(:,1:end-1,:);
    myNumTrials = size( myDat, 1 );
    trialNum(:,iLabel) = myNumTrials;
    featureIndividual(:,iLabel,:,1:myNumTrials) = permute( myDat, [3, 2, 1] );   
end

% Soft-norm is calculated here (and stored in allChannelRange)
if ~isempty( params.softenNorm )
    fprintf('Doing Soften-norm %g for dPCA Hz\n', params.softenNorm )
    % range for each channel
    allChannelRange =  max( max( featureAverages, [], 3 ), [], 2 ) - min( min( featureAverages, [], 3 ), [], 2 );
    allChannelRange = allChannelRange + params.softenNorm; % this should also be denominator for any soft-norm I want to repeat later
    featureAverages = featureAverages .* repmat( 1./allChannelRange, 1, size( featureAverages, 2 ), size( featureAverages, 3 ) );
    featureIndividual = bsxfun( @times, featureIndividual, 1./allChannelRange );
end


%% do DPCA

isSimultaneous = true; % array data

optimalLambda = dpca_optimizeLambda(featureAverages, featureIndividual, trialNum, ...
    'combinedParams', combinedParams, ...
    'simultaneous', isSimultaneous, ...
    'numRep', 10, ...  % increase this number to ~10 for better accuracy
    'filename', 'tmp_optimalLambdas.mat');
Cnoise = dpca_getNoiseCovariance(featureAverages, ...
    featureIndividual, trialNum, 'simultaneous', isSimultaneous);

% Key output is CIS1dim
[W,V,whichMarg] = dpca(featureAverages, params.maxDims, ...
        'combinedParams', combinedParams, ...
        'lambda', optimalLambda, ...
        'Cnoise', Cnoise);

explVar = dpca_explainedVariance(featureAverages, W, V, ...
    'combinedParams', combinedParams, ...
    'numOfTrials', 1);


numCDdims = nnz( whichMarg == 1 );
numCIdims = nnz( whichMarg == 2 );   
% re-sort based on how much condition-independent activity there is
eachVarExplained = explVar.margVar;
CIdims = whichMarg==2;
CIdimsInds = find( CIdims );
[~, sortIndsByCI] = sort( explVar.margVar(2,CIdims), 'descend');
% sort all the W vectors with this order
Wreordered = [W(:,CIdimsInds(sortIndsByCI)), W(:,~CIdims)];
Vreordered = [V(:,CIdimsInds(sortIndsByCI)), V(:,~CIdims)];

% What fraction of variance does CIS 1 explain? Note I'm including both its CI and CD
% marginalization (latter is tiny though)
totVarDPCA = explVar.cumulativeDPCA(end);
varCIS1 = sum( eachVarExplained(:,1) );
fprintf('CIS1 (which includes a tiny bit of CD marganization) explains %.1f%% of top %i dPCs and %.1f%% of full-D variance\n', ...
    100*varCIS1/totVarDPCA, numCDdims+numCIdims, varCIS1 );
CIS1dim = Wreordered(:,1);
CDtop2 = Wreordered(:,numCIdims+1:numCIdims+2); % in case I just want to plot CIS1 vs top 2 condition-dependent dPCs



%% do jPCA
% apply softnorm to jPCA psth; keeps things consistent
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    result.(myLabel).psthJPCA_softNormed = result.(myLabel).psthJPCA .* repmat( 1./allChannelRange', size( result.(myLabel).psthJPCA, 1 ) , 1 );
end

params.jPCA_params.normalize = false;  % already done to data
params.jPCA_params.meanSubtract = params.jPCA_acrossConditionsMean;
params.jPCA_params.softenNorm = nan;
params.jPCA_params.suppressBWrosettes = true;
params.jPCA_params.suppressHistograms = true;


% params.jPCA_params.numPCs = min( numCDdims, floor( numCDdims/2 )*2 ); % ensures even number of PCs, which jPCA requires


% Format the data for jPCA
fprintf('jPCA Data: %s, epoch: %s %g to %g\n', params.neuralFeature, params.jPCAalignEvent, params.dataTimestamps(1), params.dataTimestamps(end))

% Subsample every X ms (Mark's code won't subsample itself)
startInd = find( round( 1000.*result.(label1).tjPCA ) == params.dataTimestamps(1), 1, 'first' );
endInd = find( round( 1000.*result.(label1).tjPCA ) == params.dataTimestamps(end), 1, 'first' );

% A critical operation here is to project the data into the CD space found by the dPCA
% operation above.
% CDproj = Wreordered(:,numCIdims+1:end); % only condition-dependent dimensions
% CDproj = Wreordered; % DEV, keep all dPCs including CI ones
% CDproj = eye( size( Wreordered, 1 ) ); % dev, no dim reducction
% CDproj = Wreordered(:,2:end); % DEV, keep all dPCs except CIS1


nspace = null( Vreordered(:,1)' ); %  null space of CIS1
% nspace = null( Wreordered(:,1:numCIdims)' );% null space of all CI
CDproj = nspace;
params.jPCA_params.numPCs = 6;

fprintf('Projecting data into %i-dim dPC space, keeping %i PCs \n', size( CDproj, 2 ), params.jPCA_params.numPCs )
for iLabel = 1 : numel( uniqueLabels )
     myLabel = uniqueLabels{iLabel};
     Data(iLabel).A = result.(myLabel).psthJPCA_softNormed(startInd:params.downSampleEveryNms:endInd,:) * CDproj; % time x dPC
     Data(iLabel).times = round( 1000.* result.(myLabel).tjPCA(startInd:params.downSampleEveryNms:endInd) )';
end

[Projection, Summary] = jPCA( Data, params.dataTimestamps, params.jPCA_params );

% Plot jPCA traditional plot
% (optional but useful for sanity checking jPCA operation)
plotParams.planes2plot = [1 2]; % PLOT

figh_jpca = figure;
% Makes the jPCA plot using Mark's code.
[colorStruct, haxP, vaxP] = phaseSpace( Projection, Summary, plotParams );
% identify the groups
[ indsLeftToRight, cmap ] = whichGroupIsWhichJpca( Projection );
% Label the end points of each condition with its label. Note this won't work if more than
% one plane was plotted (because it'll try to plot on the last plane using data from first
% plane. So make plotParams.planes2plot = 1 to use this .
figh = gcf;
for iLabel = 1 : numel( uniqueLabels )
    myH = Projection(iLabel).proj(end,1);
    myV = Projection(iLabel).proj(end,2);
    th(iLabel) = text( myH, myV, uniqueLabels{iLabel} );
end

% projection matrix that does both the dPCA projection and then the jPCA projection
dim2Proj = CDproj*Summary.jPCs_highD(:,1);
dim3Proj = CDproj*Summary.jPCs_highD(:,2);

colors = cmap;

%% Plot each condition's CIS_1 vs jPC1 vs jPC2 
% apply softnorm to video psth
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    result.(myLabel).psthVid_softNormed = result.(myLabel).psthVid .* repmat( 1./allChannelRange', size( result.(myLabel).psthVid, 1 ) , 1 );
end


% pre-compute the video projections
allVidXYZ = nan( size( result.(myLabel).psthVid_softNormed, 1 ), 3, numel( uniqueLabels ) ); % Time x 3 x (# Conditions)
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myXYZ = [result.(myLabel).psthVid_softNormed * CIS1dim, ...
        result.(myLabel).psthVid_softNormed * dim2Proj, ...
        result.(myLabel).psthVid_softNormed * dim3Proj ];
    allVidXYZ(:,:,iLabel) = myXYZ;
end
figh = figure; figh.Color = 'w';
axh = axes; hold on
plot( tVid, mean( allVidXYZ(:,1,:), 3 ), 'k' )
plot( tVid, mean( allVidXYZ(:,2,:), 3 ), 'r' )
plot( tVid, mean( allVidXYZ(:,3,:), 3 ), 'b' )
legend({'CIS','jPC1', 'jPC2'})
xlabel( sprintf('Time w.r.t %s', params.vidAlignEvent ) )

if params.jPCA_acrossConditionsMean
   allVidXYZ(:,2,:) = allVidXYZ(:,2,:) - repmat( mean( allVidXYZ(:,2,:), 3 ), 1, 1, numel( uniqueLabels ) );
   allVidXYZ(:,3,:) = allVidXYZ(:,3,:) - repmat( mean( allVidXYZ(:,3,:), 3 ), 1, 1, numel( uniqueLabels ) );
end


pauseAndRotate = viz.cam.pauseAndRotate;

figh = figure;
figh.Units = 'pixels';
figh.Position(3) = viz.figurePixels(1);
figh.Position(4) = viz.figurePixels(2);

figh.Color = 'w';
axh = axes;
axis tight
axh.Visible = 'off'; % hide regular axes
% axh.Visible = 'on'; % hide regular axes
hold on; 
xlabel('       CIS_1')

% *********
% Uncomment below to work in CD2,3 space instead of jPC space
% ylabel('  CD_1') % spaces make it look good even upon rotation
% zlabel('CD_2')
% dim2Proj = CDtop2(:,1);
% dim3Proj = CDtop2(:,2);
% *********

ylabel('       jPC_1') % spaces make it look good even upon rotation
zlabel('jPC_2')





% compute the extrema coordinate values so I can pre-set axis dimensions
axh.XLim = [min( min( allVidXYZ(:,1,:)  ) ), max( max( allVidXYZ(:,1,:)  ) )];
axh.YLim = [min( min( allVidXYZ(:,2,:)  ) ), max( max( allVidXYZ(:,2,:)  ) )];
axh.ZLim = [min( min( allVidXYZ(:,3,:)  ) ), max( max( allVidXYZ(:,3,:)  ) )];
view( viz.cam.view0 );


tv = ThreeVector();
axis vis3d % locks aspect ratio so it doesnt change when rotating
tv.axisInset = [1 1]; % moves it within captured area (ad-hoc, since this is in cm);
tv.lineWidth = 5;
tv.lineColor = [0.3 0.3 0.3];
tv.fontSize = viz.FontSize;
tv.vectorLength = viz.tvVectorLength;


% how many samples between frames?
samplesEachFrame = round( 1000 / viz.fps / viz.dilateTimeBy );
totFrames = floor( numel( tVid ) / samplesEachFrame );
axPos = axh.Position;

% Put the time text into the figure corner
axTime = axes( figh, 'OuterPosition', [0.05, 0.8, 0.1, 0.1], 'Color', 'r');
axTime.Visible = 'off';
hTime = text( 0, 1, sprintf('%s%+.1f s', params.vidEventString, tVid(samplesEachFrame) ), 'FontSize', viz.FontSize, ...
    'Units', 'normalized', 'VerticalAlignment', 'top', 'Parent', axTime);
axes( axh )

% Use VideoWriter (built-in MATLAB class) to make the video
saveTo = MakeValidFilename( sprintf('%svideo_%s%ims_to_%ims', saveFiguresDir, datasetName, ...
    tVid(1)*1000, tVid(end)*100 ) );
writerObj = VideoWriter( saveTo );
writerObj.FrameRate = viz.fps;
writerObj.Quality = 100;
open( writerObj );


% initialize
prevCamT = tVid(1);
prevView = viz.cam.view0;
enteredEpochs = [1]; % start in epoch 1 so its already there
for iFrame = 1 : totFrames % note: these are neural trajectory frames, camera rotation pauses don't count here
    mySample = iFrame * samplesEachFrame;
    myT = tVid(mySample);
    
    % Camera rotate?
    % which epoch am I in
    myCamEpoch = find( myT <=  viz.cam.script(:,1) , 1, 'first' );
    
   
    % if it's a new epoch, update prevCamT and prevView
    if ~ismember( myCamEpoch, enteredEpochs )
        fprintf('Entering epoch %i\n', myCamEpoch );
        prevCamT = viz.cam.script(myCamEpoch-1,1);
        prevView = viz.cam.script(myCamEpoch-1,2:3);
        enteredEpochs = union( enteredEpochs, myCamEpoch );
    end
    
    
    % Am I pausing?
    while ismember( myCamEpoch - 1, pauseAndRotate(:,1) )
       thisPauseEventInd = find(  pauseAndRotate(:,1) == myCamEpoch - 1, 1, 'first' );
       thisPauseEvent = pauseAndRotate(thisPauseEventInd,:);
       fprintf('Pause event: %s\n', mat2str( thisPauseEvent ) )
       pauseAndRotate(thisPauseEventInd,:) = []; % remove it from queue
       
       % how many frames will this take and how much should I rotate each frame. 
       pauseFrames = ceil( thisPauseEvent(2) * viz.fps );
       dView = [thisPauseEvent(3:4) - prevView] ./ pauseFrames;
       % do the rotation here in a loop
       for i = 1 : pauseFrames
           myView = myView + dView;
           view( myView )
           tv.updateAxis
           drawnow;
           frame = getframe( figh );
           writeVideo( writerObj, frame );
       end
       prevView = myView;
    end
    
    if ~isempty( myCamEpoch )
        targetView = viz.cam.script(myCamEpoch,2:3);
        targetT = viz.cam.script(myCamEpoch,1);
        fractionEpoch = (myT - prevCamT) / (targetT - prevCamT);
        if fractionEpoch > 1
            fractionEpoch = 1;
        end
        myView = prevView + fractionEpoch.*(targetView - prevView);
        view( myView );
    end
    
    
    hTime.String = sprintf('%s%+.1fs', params.vidEventString, myT );
    try
        delete( lh );
        delete( sh );
    catch
    end
    lh = [];
    sh = [];
    for iLabel = 1 : numel( uniqueLabels )                    
        % Plot baseline
        endBaseline = min( sampleAudioCue(iLabel)-1, mySample );
        x = allVidXYZ(1:endBaseline,1,iLabel);
        y =  allVidXYZ(1:endBaseline,2,iLabel);
        z =  allVidXYZ(1:endBaseline,3,iLabel);
        lh(end+1) = plot3( x, y, z, 'Color', viz.colorBaseline, 'LineWidth', viz.LineWidthBaseline );
        myColor = viz.colorBaseline;
        
        % Plot delay
        if mySample >= sampleAudioCue(iLabel)
            endDelay = min( sampleGoCue(iLabel)-1, mySample );
            x = allVidXYZ(sampleAudioCue(iLabel):endDelay,1,iLabel);
            y = allVidXYZ(sampleAudioCue(iLabel):endDelay,2,iLabel);            
            z = allVidXYZ(sampleAudioCue(iLabel):endDelay,3,iLabel);
            lh(end+1) = plot3( x, y, z, 'Color', viz.colorDelay, 'LineWidth', viz.LineWidthDelay );
            myColor = viz.colorDelay;
        end
        
        % Plot speech
        if mySample >= sampleGoCue(iLabel)
            endSpeech = min( numel( tVid ), mySample );
            x = allVidXYZ(sampleGoCue(iLabel):endSpeech,1,iLabel);
            y = allVidXYZ(sampleGoCue(iLabel):endSpeech,2,iLabel);
            z = allVidXYZ(sampleGoCue(iLabel):endSpeech,3,iLabel);
            lh(end+1) = plot3( x, y, z, 'Color', colors(iLabel,:), 'LineWidth', viz.LineWidthMove ); % replace with Red <--> Green
            myColor = colors(iLabel,:);
        end
        if viz.MarkerSize > 0
            sh(end+1) = scatter3( allVidXYZ(mySample,1,iLabel), allVidXYZ(mySample,2,iLabel), allVidXYZ(mySample,3,iLabel), viz.MarkerSize, myColor, 'filled' );
        end
    end
   % update Three Axis with this method:
    tv.updateAxis
    drawnow;
    frame = getframe( figh );
    writeVideo( writerObj, frame );    
end


% Finish out the video
close( writerObj );
fprintf('Finished video writing\n')
