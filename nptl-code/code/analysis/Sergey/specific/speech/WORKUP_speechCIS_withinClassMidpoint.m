% Used dPCA to plot how much of the speech neural data is condition-independent versus
% condition-dependent.
%
% Sergey Stavisky, March 14 2017
clear


saveFiguresDir = [FiguresRootNPTL '/speech/CIS/'];
if ~isdir( saveFiguresDir )
    mkdir( saveFiguresDir )
end
% saveResultsRoot = [ResultsRootNPTL '/speech/psths/']; % I don't think there will be results file generated



%% Dataset specification
% a note about params.acceptWrongResponse: if true, then labels like 'da-ga' (he was cued 'da' but said 'ga') 
% are accepted.3 The RESPONSE label ('ga' in above example) is used as the label for this trial.


% t5.2017.10.23 Phonemes
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-phonemes.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = true;

% t5.2017.10.25 Words
participant = 't5';
Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t5.2017.10.25-words_lfpPow_125to5000_50ms.mat'; % has sorted units
params.excludeChannels = datasetChannelExcludeList( 't5.2017.10-25_-4.5RMSexclude' );
params.acceptWrongResponse = false;

% t5.2017.10.23 Movements
% participant = 't5';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t5.2017.10.23-movements.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;


% t8.2017.10.17 Phonemes
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-phonemes.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = true;

% % t8.2017.10.18 Words
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/sorted/R_t8.2017.10.18-words_lfpPow_125to5000_50ms.mat'; % has sorted units
% params.excludeChannels = datasetChannelExcludeList('t8.2017.10-18_-4.5RMSexclude');
% params.acceptWrongResponse = false;
% [params.excludeTrials, params.excludeTrialsBlocknum] = datasetTrialExcludeList( Rfile );


% t8.2017.10.17 Movements
% participant = 't8';
% Rfile = '/Users/sstavisk/CachedDatasets/NPTL/constructedR/R_t8.2017.10.17-movements.mat';
% params.excludeChannels = participantChannelExcludeList( participant );
% params.acceptWrongResponse = false;

% use this to specifically look at exclude channels (are any of them amazing and maybe
% shouldn't be excluded?
% params.excludeChannels = setdiff( [1:192], participantChannelExcludeList( participant ) );


%%
% Get labels, ignore silence/no movement conditions.
includeLabels = labelLists( Rfile ); % lookup;
includeLabels(strcmp(includeLabels, 'silence')) = [];
includeLabels(strcmp(includeLabels, 'stayStill')) = [];


numArrays = 2; % don't anticipate this changing

%% Analysis Parameters
% RMS Thresholds
params.thresholdRMS = -4.5; % spikes happen below this RMS
params.neuralFeature = 'spikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 28 ms SD Gaussian as in Kaufman 2016

% Spike-sorted
% params.neuralFeature = 'sortedspikesBinnedRateGaussian_28ms'; % spike counts binned smoothed with 25 ms SD Gaussian 
% params.thresholdRMS = [];
% params.minimumQuality = 3;



% Note: soft-norm currently works only on the data range analyzed. The range does capture
% most of the peak but it's worth being aware of this.
% params.softenNorm = []; % leave empty to not do this
params.softenNorm = 5; % if not empty, how many Hz to add to range denominator

% NOTE: Kaufman 2016 does soft-norm. 


params.maxDims = 8; 


params.subspaceaDims = 2; % report subspace angle between CIS1 and these many condition-dependent DIMS


% Align to speak go cue. (matched to Kaufman 2016 Go Cue alignment)
if isempty( strfind( Rfile, 'movements') ) %#ok<STREMP>
    % Speaking
    params.alignEvent = 'handPreResponseBeep';
    params.startEvent = 'handPreResponseBeep - 0.200';
    params.endEvent= 'handPreResponseBeep + 0.400';
else
    % Align to MOVEMENT go cue, which is 'handResponseEvent'
    % ONLY use this for movement data
    params.alignEvent = 'handResponseEvent';
    params.startEvent = 'handResponseEvent - 0.200';
    params.endEvent= 'handResponseEvent + 0.400';
end

% Alignments for single-trial VOT finding 
% these are taken from Matt's methods which look at 60 ms before to 
% 500 ms after.
% (plus a bit extra toa ccount for Gaussian smoothing chop)
params.singleTrial.startEvent = 'handPreResponseBeep - 0.100'; 
params.singleTrial.alignEvent = 'handPreResponseBeep';  % Go Cue
params.singleTrial.endEvent = 'handPreResponseBeep + 0.600';
params.singleTrial.neuralFeature = 'spikesBinnedRate_10ms';
params.singleTrial.gaussianSmoothMS = 30; % how many milliseconds standard deviation Gaussian smoothing to apply to the binned rates
params.singleTrial.crossingThreshold = 0.5; % at what fraction of max( z~(t) ) - min ( z~(t) ) to determine the "crossover" and use this as predictor of RT

result.params = params;
result.params.Rfile = Rfile;



%% Load the data
in = load( Rfile );
R = in.R;
clear('in')
datasetName = regexprep( pathToLastFilesep(Rfile,1), {'.mat', 'R_'}, '');
datasetName = regexprep( datasetName, '_lfpPow_125to5000_50ms', ''); %otherwise names get ugly
sortQuality = speechSortQuality( datasetName ); % manual entry since I forgot to include this in R struct : (

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
if any( cell2mat( strfind( params.alignEvent, 'vot' ) ) )
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



%% Make PSTH
% I'm going to create a cell with each trial's trial-averaged mean/std/se,
% firing rate in the plot window.
% Here I also get a single average rate for each channel per trial.
for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );
    jenga = AlignedMultitrialDataMatrix( R(myTrialInds), 'featureField', params.neuralFeature, ...
        'startEvent', params.startEvent, 'alignEvent', params.alignEvent, 'endEvent', params.endEvent );
    result.(myLabel).t = jenga.t;
    result.(myLabel).psthMean = squeeze( mean( jenga.dat, 1 ) );
    result.(myLabel).psthStd = squeeze( std( jenga.dat, 1 ) );
    for t = 1 : size( jenga.dat,2 )
        result.(myLabel).psthSem(t,:) =  sem( squeeze( jenga.dat(:,t,:) ) );
    end
    result.(myLabel).numTrials = jenga.numTrials;
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



%% Format for dPCA


% firingRatesAverage: N x S x D x T
%
% N is the number of neurons
% S is the number of conditions for factor 1
% T is the number of time-points (note that all the trials/conditions should have the
% same length in time!)
%
N = size( result.(uniqueLabels{1}).psthMean, 2 );
S = numel( uniqueLabels );
T = numel( result.(uniqueLabels{1}).t )-1; % drop last sample so its even 100s of ms
combinedParams = {{1, [1 2]}, {2}}; %so marginalization 1 is condition and condition/time, and marg. 2 is just time
margNames = {'Condition-dependent', 'Condition-independent'};
margColours = [250 0 0; 0 0 250]./255;


featureAverages = nan(N, S, T);
for iLabel = 1 : numel( uniqueLabels )
    featureAverages(:,iLabel,:) = result.(uniqueLabels{iLabel}).psthMean(1:end-1,:)';
end

if ~isempty( params.softenNorm )
    fprintf('Doing Soften-norm %g Hz\n', params.softenNorm )
    % range for each channel
    allChannelRange =  max( max( featureAverages, [], 3 ), [], 2 ) - min( min( featureAverages, [], 3 ), [], 2 );
    allChannelRange = allChannelRange + params.softenNorm;
    featureAverages = featureAverages .* repmat( 1./allChannelRange, 1, size( featureAverages, 2 ), size( featureAverages, 3 ) );
end



%% do DPCA
[W,V,whichMarg] = dpca(featureAverages, params.maxDims, ...
    'combinedParams', combinedParams);

explVar = dpca_explainedVariance(featureAverages, W, V, ...
    'combinedParams', combinedParams, ...
    'numOfTrials', 1);


% I can plot using the built-in dPCA plotting tools. 
% for plotting we define time
plotTime = jenga.t(1:end-1);
% Time events of interest (e.g. stimulus onset/offset, cues etc.)
% They are marked on the plots with vertical lines
timeEvents = 0; 
dpca_plot(featureAverages, W, V, @dpca_plot_default, ...
        'explainedVar', explVar, ...
        'marginalizationNames', margNames, ...
        'marginalizationColours', margColours, ...
        'whichMarg', whichMarg,                 ...
        'time', plotTime,                        ...
        'timeEvents', timeEvents,               ...
        'timeMarginalization', 3,           ...
        'legendSubplot', 16);
    
numCDdims = nnz( whichMarg == 1 );
numCIdims = nnz( whichMarg == 2 );
fprintf('%i condition-dependent dimensions and %i condition-INDEPENDENT dims together explain %.2f%% overall variance\n', ...
    numCDdims, numCIdims, explVar.cumulativeDPCA(end) );

    
    
% re-sort based on how much condition-independent activity there is
eachVarExplained = explVar.margVar;
CIdims = whichMarg==2;
CIdimsInds = find( CIdims );
[~, sortIndsByCI] = sort( explVar.margVar(2,CIdims), 'descend');
% start with the CI dimensions
eachVarExplained = explVar.margVar(:,CIdimsInds(sortIndsByCI));
eachVarExplained = [eachVarExplained, explVar.margVar(:,~CIdims)];
% also grab all the W vectors with this order
Wreordered = [W(:,CIdimsInds(sortIndsByCI)), W(:,~CIdims)];

fprintf('CD: %s\n', mat2str( eachVarExplained(1,:), 5 ) )
fprintf('CI: %s\n', mat2str( eachVarExplained(2,:), 5 ) )

% What fraction of variance does CIS 1 explain? Note I'm including both its CI and CD
% marginalization (latter is tiny though)
totVarDPCA = explVar.cumulativeDPCA(end);
varCIS1 = sum( eachVarExplained(:,1) );
fprintf('CIS1 (which includes a tiny bit of CD marganization) explains %.1f%% of top %i dPCs and %.1f%% of full-D variance\n', ...
    100*varCIS1/totVarDPCA, numCDdims+numCIdims, varCIS1 );


%% How orthogonal is CIS_1 to the movement dims?
CIS1 = Wreordered(:,1);
CDdims = Wreordered(:,numel(CIdimsInds)+1:end);

for i = 1: size( CDdims, 2 )
    angleBetween = angleBetweenVectors(CIS1,CDdims(:,i));
    if angleBetween > 90
        angleBetween = 180- angleBetween;
    end
    fprintf('Angle between CIS1 and CD%i is %.3fdeg\n', i,  angleBetween)
end
suba = rad2deg( subspacea( CIS1, CDdims(:,1:params.subspaceaDims) ) );
fprintf('Subspace angle between CIS1 and first %i condition-dependent dims is %.2f deg\n', ...
    params.subspaceaDims, suba );
subaAll = rad2deg( subspacea( CIS1, CDdims ) );
fprintf('Subspace angle between CIS1 and ALL %i condition-dependent dims is %.2f deg\n', ...
    size( CDdims, 2 ), subaAll );

%% make rod-and-disk figure showing how orthogonal CIS1 is to the first N CD-dims

figh = figure;
figh.Color = 'w';
circle( [0,0],1,[.5 .5 .5],1)
axh = gca;
ch = axh.Children;
axh.Visible = 'off';
axis equal
rayx = cos( deg2rad( suba ) );
rayy = sin( deg2rad( suba ) );
lh = line( [0 0], [0 rayx], [0 rayy], 'LineWidth', 2', 'Color', 'k');
view(3)
titlestr = sprintf('disk and rot dPCA %s', datasetName);
figh.Name = titlestr;
ExportFig( figh, [saveFiguresDir titlestr] );



%% Plot how much each component explains    
% (Presented as in Kaufman et al. 2016)
figh = figure;
figh.Color = 'w';
titlestr = sprintf('CIS dPCA %s', datasetName);
figh.Name = titlestr;
axh_var = subplot( 2, 1, 1 );
axh_var.TickDir = 'out';
hbar = barh( eachVarExplained', 'stacked' );
axh_var.YDir = 'reverse';
hbar(1).BarWidth = 1;
hbar(2).BarWidth = 1;
hbar(2).FaceColor = margColours(1,:);
hbar(1).FaceColor = margColours(2,:);

ylabel('dPCA Component');
xlabel('% Overall Variance Explained')

%% Plot each condition's CIS_1
axh_CIS = subplot( 2, 1, 2 ); hold on;

CIS1dim = Wreordered(:,1);
for iLabel = 1 : numel( uniqueLabels )
    myCIS1 = squeeze( featureAverages(:,iLabel,:) )' * CIS1dim; % T x 1
    plot( plotTime, myCIS1, 'Color', colors(iLabel,:), ...
        'LineWidth', 1 );
end

axh_CIS.TickDir = 'out';
xlim( [plotTime(1) plotTime(end) ] );
xlabel( sprintf( 'Time wrt %s (s)', params.alignEvent ) );



%% Plot activity in all the dPCs
    
figh = figure;
figh.Color = 'w';
titlestr = sprintf('All dPCs %s', datasetName);
figh.Name = titlestr;
Ncols = ceil( params.maxDims/2 );
for iDPC = 1 : params.maxDims
   axh = subplot( 2,  Ncols, iDPC );
   myDim = Wreordered(:,iDPC);
   title( sprintf('CI: %.2f, CD: %.2f', ... 
       eachVarExplained(2,iDPC), eachVarExplained(1,iDPC) ) );
   hold on;
   for iLabel = 1 : numel( uniqueLabels )
       myComponents = squeeze( featureAverages(:,iLabel,:) )' * myDim; % T x 1
       plot( plotTime, myComponents, 'Color', colors(iLabel,:), ...
           'LineWidth', 1 );
   end
   xlim( [plotTime(1) plotTime(end) ] );   
end

%% Look for single-trial VOT timing correlates
% add an end event to each trial
for i = 1 : numel( R )
    R(i).endOfTrial = numel( R(i).clock );
end

% Add the binned spike rate to all trials
R = AddFeature( R, params.singleTrial.neuralFeature );
if ~isempty( params.excludeChannels )
    fprintf('Removing channels %s\n', mat2str( params.excludeChannels ) );
    R = RemoveChannelsFromR( R, params.excludeChannels, 'sourceFeature', params.singleTrial.neuralFeature );
end
% apply Gaussian smoothing to this
fprintf( 'Smoothing %s with %i ms s.d. Gaussian kernel\n', params.singleTrial.neuralFeature, params.singleTrial.gaussianSmoothMS )
stdMS = params.singleTrial.gaussianSmoothMS;
numSTD = 3; % will make the kernel out to this many standard deviations
% now make the Gaussian kernel out to 3 standard deviations
x = -numSTD*stdMS:1:numSTD*stdMS;
gkern = normpdf( x, 0, stdMS );
% normalize to area 1
gkern = gkern ./ sum( gkern );
for iTrial = 1 : numel( R ) % can probably be parfor to speed things up
    R(iTrial).(params.singleTrial.neuralFeature).dat = filter( gkern, 1, double( R(iTrial).(params.singleTrial.neuralFeature).dat' ) )';
    % trim to only valid parts of filtered data
    R(iTrial).(params.singleTrial.neuralFeature).t(1:numSTD*stdMS) = [];
    R(iTrial).(params.singleTrial.neuralFeature).t(end-numSTD*stdMS+1:end)=[];
    R(iTrial).(params.singleTrial.neuralFeature).dat(:,1:2*numSTD*stdMS)=[]; % 2 x because only taking from front, to shift everything back
end

% Soft-normalize all the trials
for iTrial = 1 : numel( R ) % can probably be parfor to speed things up
    NF = repmat( 1./allChannelRange, 1, size( R(iTrial).(params.singleTrial.neuralFeature).dat,2 ));
    R(iTrial).(params.singleTrial.neuralFeature).dat = R(iTrial).(params.singleTrial.neuralFeature).dat .* NF;
end

% Calculate CIS Dim 1 for all trials
jenga = AlignedMultitrialDataMatrix( R, 'featureField', params.singleTrial.neuralFeature, ...
    'startEvent', params.singleTrial.startEvent, 'alignEvent', params.singleTrial.alignEvent, 'endEvent', params.singleTrial.endEvent );
singleTrialCIS1t = jenga.t;
singleTrialCIS1 = nan( jenga.numTrials, jenga.numSamples );   % trials x time
for iTrial = 1 : numel( R )
    singleTrialCIS1(iTrial,:) = squeeze( jenga.dat(iTrial,:,:) )* CIS1dim;
end

% Plot all trials' CIS1
figh = figure;
figh.Color = 'w';
axh = axes;
titlestr = sprintf('All Trials CIS1 %s', datasetName);
figh.Name = titlestr;
plot( singleTrialCIS1t, singleTrialCIS1', 'Color', 'r');
xlabel( sprintf( 'Time after %s (s)', params.singleTrial.alignEvent ) )
ylabel('CIS1');
hold on;


% Calculate the midpoint using the Kaufman 2016 method:
% "To find that criterion value, we took the median of z(t,r) across trials, producing z~(t). We set the criterion value 
% to be the midpoint of z?(t): [max( z~(t) ) + min( z~(t) ]/2.



% Do it separately within each label since the relationship between muscle start and VOT
% can differ between sounds
allValidCrossingTimes = [];
allValidNormRTs = []; % will get filled in with accepted trials

for iLabel = 1 : numel( uniqueLabels )
    myLabel = uniqueLabels{iLabel};
    myTrialInds = strcmp( allLabels, myLabel );    
    myRTs = [R(myTrialInds).handResponseEvent] - [R(myTrialInds).handPreResponseBeep];
    myNormRTs = (myRTs - mean( myRTs )) ./ std( myRTs );

    
    % crossing times within this particular label
    medianCIS1 = median( singleTrialCIS1(myTrialInds,:) );
    midpointCIS1 = params.singleTrial.crossingThreshold * (max( medianCIS1 ) + min( medianCIS1 ));
    myColor = speechColors( myLabel );
    plot( singleTrialCIS1t, medianCIS1', 'Color', myColor, 'LineWidth', 1.5);

    
    myCrossingTimes = []; % will be in MS after go cue
    % will note trials that violate rule from Kaufman 2016:
    % Trials that never exceeded the criterion value, or that exceeded it before the go cue, were
    % discarded from the analysis. Such trials were uncommon,
    % especially for the better prediction methods (0?9%, de-pending on dataset and method). "
    thisLabelTrials = find( myTrialInds );
    for iTrial = 1 : numel( thisLabelTrials )
        iAmInvalid = false;
        thisTrial = thisLabelTrials(iTrial);
        myCrossing = find( singleTrialCIS1(thisTrial,:) > midpointCIS1, 1, 'first' );
        % is this a valid trial?
        if singleTrialCIS1t(myCrossing) <= 0
            % exceeds before go cue
            iAmInvalid = true;
        end
        if isempty( myCrossing )
            % never exceeds
            iAmInvalid = true;
        end
        
        if iAmInvalid == true
          
        else
            allValidCrossingTimes(end+1,1) = round( 1000.* singleTrialCIS1t(myCrossing) ); % MS
            allValidNormRTs(end+1,1) = myNormRTs(iTrial);
        end
    end
end

fprintf('%i/%i (%.1f%%) trials discarded to to no CIS1 midpoint crossing or crossing is before go cue\n', ...
   numel( R )- numel( allValidCrossingTimes ), numel( R ), 100* (numel( R )-numel( allValidCrossingTimes )) / numel( R ) )

% NORMALIZED RT WITHIN EACH LABEL
figh = figure;
figh.Color = 'w';
axh = axes; hold on;
titlestr = sprintf('RT vs CIS1 %s', datasetName);
figh.Name = titlestr;

% Linear fit
lm = fitlm( allValidCrossingTimes, allValidNormRTs );
yint = lm.Coefficients.Estimate(1);
slope = lm.Coefficients.Estimate(2);
RTpval = lm.coefTest;

sh = scatter( allValidCrossingTimes, allValidNormRTs, 16, 'filled', 'Marker', 'o' );
% draw the fit line
x1 = min( allValidCrossingTimes );
x2 = max( allValidCrossingTimes );
y1 = yint + slope*x1;
y2 = yint + slope*x2;
lh = line( [x1 x2], [y1 y2], 'Color', 'k', 'LineWidth', 1.5);
xlabel( 'Crossing time (ms) ' );
ylabel( 'RT (z-score)' );
r = corr( allValidCrossingTimes, allValidNormRTs );
fprintf('Correlation between crossing time and z-scored RT = %f (p=%f)\n', ...
    r, RTpval )


