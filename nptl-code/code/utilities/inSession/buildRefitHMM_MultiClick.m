function output = buildHMM_MultiClick(streams, options, prompt)
% SNF: Commandeering the existing buildHMMOpenLoop code to do all the
% multiclick decoding. Per BJ's comment, this will automatically detect if
% it was an open or closed-loop trial to decode and will build an HMM to identify which of
% the 4 clicks or move was desired. No IDLE state. 
% SF Aug 2019 

%*think* the only thing we need to do differently is have clickSource
%default to dwell for OL, but click+overtarget for CL. 

if exist('streams','var') && ~isempty(streams)
    disp('buildFilterDialog: warning - you are passing in streams, but bFD will not pass them forward'); 
end

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end
sessionRoot = modelConstants.sessionRoot;
% check for trailing /
if sessionRoot(end) ~= '/'
    sessionRoot(end+1) = '/';
end

filterOutDir = [sessionRoot modelConstants.discreteFilterDir];

if ~isdir(filterOutDir)
    disp(['creating discrete output directory ' filterOutDir]);
    mkdir(filterOutDir);
end

global CURRENT_DISCRETE_FILTER_NUMBER
if ~exist('CURRENT_DISCRETE_FILTER_NUMBER', 'var') || isempty(CURRENT_DISCRETE_FILTER_NUMBER)
    CURRENT_DISCRETE_FILTER_NUMBER = 1;
else
    CURRENT_DISCRETE_FILTER_NUMBER = CURRENT_DISCRETE_FILTER_NUMBER + 1;
end

if ~exist('prompt','var')
    %% options that are prompted
    prompt.blocksToFit = '';
    prompt.binSize = '15';
    prompt.delayMotor = '-250';
     prompt.fixedThreshold = ''; 
     prompt.rmsMultiplier = num2str(-4.5);
    prompt.normalize = 'true';
    prompt.HLFPDivisor = '2500';
    prompt.numPCsToKeep = '16'; %SNF flag: changed from 4
    prompt.clickSource = 'dwell'; %SNF flag for options.clickSource 
    %prompt.outputBinSize = prompt.binSize;
    prompt.statesToUse = '5'; %SNF flag
    prompt.gaussSmoothHalfWidth = '25';
    prompt.maxClickLength = '500';
    prompt.normFactor = num2str(50 * 0.03);
    prompt.useTx = 'true';
    prompt.useHLFP = 'false';
    prompt.usePCA = 'true';
    prompt.useLDA = 'false';
    prompt.neuralAlignment = 'false';
    prompt.excludeAmbiguousData = 'false'; % BJ: for OL calibration, excludes data beyond max click length (rather than labeling it as "non-click")
switch modelConstants.isSim
    case true
        prompt.fixedThreshold = num2str(-95);
        prompt.rmsMultiplier = '';
    case false
        prompt.fixedThreshold = '';
        prompt.rmsMultiplier = num2str(-3.5);
end
end
%% only do this if prompt is non-empty
if ~isempty(prompt)
    %% set the default starting filter num
    prompt = setDefault(prompt,'startingFilterNum',num2str(CURRENT_DISCRETE_FILTER_NUMBER),true);
    promptfields = fieldnames(prompt);
    response=inputdlgcol(promptfields,'Filter options', 1, struct2cell(prompt),'on',2);

    if isempty(response)
        disp('filter build canceled')
        return
    end
else
    response = [];
end

pause(0.1);
disp('Processing...')

%% populate options with the selected responses
for nn=1:length(response)
    options.(promptfields{nn}) = str2num(response{nn});
    % if number conversion didn't work, just keep the string
    if isempty(options.(promptfields{nn}))
        options.(promptfields{nn}) = response{nn};
    end
end

%% set some defaults
options=setDefault(options,'arraySpecificThresholds',[],false);
options=setDefault(options,'restSpeedThresholdPercent', 0.1,true);
options=setDefault(options,'clickStateThreshold', 0.5,true);
options=setDefault(options,'neuralAlignment', false,true);
options=setDefault(options,'rmsMultiplier', [],true);
options=setDefault(options,'useFA', false,true);
options=setDefault(options,'useLDA',false,true);
options=setDefault(options,'removePCs',false,true);
options=setDefault(options,'rollingTimeConstant',0,false);
options=setDefault(options,'showFigures', true, true);
options=setDefault(options,'saveFigures', true, true);
options=setDefault(options,'saveFilters', true, true);

if options.usePCA || options.useFA
    options = setDefault(options,'numOutputDims', double(DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS), true);
else
    options = setDefault(options,'numOutputDims', double(DecoderConstants.NUM_CONTINUOUS_CHANNELS), false);
end

if modelConstants.isSim % development on rigH
    % hardcode to use only the electrodes that xNeuralSim (with sergey's encoding model) uses for click
    nc = [ 1:192]; % all electrodes for now -SDS Jan 13 2017
    options = setDefault(options,'neuralChannels', nc, true);
    options = setDefault(options,'neuralChannelsHLFP', nc, true);
else %T5
    % build a channel exclusion list
    allChannels = 1:192;
    %updated 9/27/17:
    excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];
    options.neuralChannels = setdiff(allChannels,excludeChannels);
    options.neuralChannelsHLFP = options.neuralChannels;
end
%% need some signal source
if ~options.useHLFP && ~options.useTx
    error('buildHMMDialog: neither Tx nor HLFP are selected...');
end
%% post-process the options that were just selected
options.normalizeTx = options.normalize;
options.normalizeHLFP = options.normalize;
options.txNormFactor = options.normFactor;
options.HLFPNormFactor = options.normFactor;
%% convert clickSource from string to macro number
switch options.clickSource
  case 'dwell'
    options.clickSource = DiscreteStates.STATE_SOURCE_DWELL;
  case 'click'
    % use the 'clickState' field of the Dstruct to indicate clicks
    options.clickSource = DiscreteStates.STATE_SOURCE_CLICK;
  case 'click+overtarget'
    % use the 'clickState' field of the Dstruct to indicate clicks
    options.clickSource = DiscreteStates.STATE_SOURCE_CLICKOVERTARGET;
  otherwise
        error('buildHMMDialog: Don''t understand this clickSource. Options are ''dwell'', ''click'', or ''click+overtarget''.');
end
%% do some checks...
if isempty(options.blocksToFit)
    error(['buildHMMDialog: did you mean to specify blocks to fit?']);
end
if sum([options.usePCA options.useFA options.useLDA])>1
    error('buildHMMDialog: using multiple dimensionality reduction techniques... not allowed');
end
if isempty(options.delayMotor)
    if options.neuralAlignment
        options.delayMotor=0;
    else
        error('buildHMMDialog: must specify delayMotor or set neuralAlignment to true');
    end
end
threshSet=[];
%% ways of setting thresholds:
% arraySpecificThresholds should be a cell array of vectors
if ~isempty(options.arraySpecificThresholds) && ~iscell(options.arraySpecificThresholds)
    options.arraySpecificThresholds = {options.arraySpecificThresholds};
end
% single fixed threshold
for nn = 1:length(options.fixedThreshold)
    threshSet(end+1).multsOrThresholds      = options.fixedThreshold(nn);
    threshSet(end).useFixedThresholds       = true;
    threshSet(end).arraySpecificThresholds  = [];
end
% per-array fixed threshold (cell array of vectors, each vec has one element per array)
for nn = 1:length(options.arraySpecificThresholds)
    threshSet(end+1).multsOrThresholds      = 1;
    threshSet(end).useFixedThresholds       = true;
    threshSet(end).arraySpecificThresholds  = options.arraySpecificThresholds{nn};
end
% rms multiplier    
for nn = 1:length(options.rmsMultiplier)
    if ~isempty(options.fixedThreshold),
        error('Please specify either a fixed threshold or an RMS muliplier, not both!')
    end
    threshSet(end+1).multsOrThresholds      = options.rmsMultiplier(nn);
    threshSet(end).useFixedThresholds       = false;
    threshSet(end).arraySpecificThresholds  = [];
end 
%% end configuration and parameter setting. 
%% load some data y'all
for nb = 1:length(options.blocksToFit)
    blockNum = options.blocksToFit(nb);
    flDir = [sessionRoot modelConstants.filelogging.outputDirectory];
    streams{nb} = loadStream([flDir num2str(blockNum) '/'], blockNum);
end
%%
allOptions = options; %keep a stable/ground truth set of options to pull from
%% start iterating over parameters: thresholds, motor delays, gauss smoothing, num PCs and bin sizes
iFilter = 0;
for nthreshold = 1:numel(threshSet) %how many thresholds are we going to try? 
    options = allOptions;
    options.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
    options.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
    options.arraySpecificThresholds= threshSet(nthreshold).arraySpecificThresholds;
    %% now calculate the actual threshold values
    if ~options.useFixedThresholds
    %calculate thresholds based on an rms multiplier using the first stream passed in
        rmsvals = channelRMS(streams{1}.neural);
        actualThreshVals = options.multsOrThresholds * rmsvals;
    else
    % one threshold per array
        if ~isempty(options.arraySpecificThresholds)
            actualThreshVals = zeros(1, numel(options.arraySpecificThresholds) * double(DecoderConstants.NUM_CHANNELS_PER_ARRAY));
            for nast = 1:numel(options.arraySpecificThresholds)
                actualThreshVals((1:double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)) + ...
                    (nast-1) * double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)) = options.arraySpecificThresholds(nast);
            end
        else
            actualThreshVals = repmat(options.multsOrThresholds, [1 size(streams{1}.neural.minAcausSpikeBand,3)]);
        end
    end
    options.thresh = actualThreshVals;
%% sweep through the shifts - how much we shift neural data around to align neural click with behavior
    for ndelay = 1:numel(allOptions.delayMotor) 
        for nsmoothsize = 1:length(allOptions.gaussSmoothHalfWidth) %loop over smoothing params 
            %this is somehow not working when numel(allOptions.delayMotor) > 1
            options.gaussSmoothHalfWidth = allOptions.gaussSmoothHalfWidth(nsmoothsize);
            options.delayMotor = allOptions.delayMotor(ndelay);
            options.shiftSpikes = options.delayMotor;
            options.shiftHLFP = options.delayMotor;
            %SNF: this line was getting overwritten later and screwing up
            %if you tried to sweep decoders over ndelays 
            options.neuralChannelsHLFP = allOptions.neuralChannelsHLFP; 
            R = [];
%% make stream struct with this combo of:
% thresholds, motor delays and gauss smoothing 
            for nb = 1:length(options.blocksToFit)
                gaussSD = options.gaussSmoothHalfWidth;
                useHalfGauss = true;
                thresh = options.thresh;
                
                stream = streams{nb};
                if gaussSD
                    [stream.neural, smoothKernel] = smoothStream(stream.neural, thresh, gaussSD, useHalfGauss, ...
                        false, options.neuralChannels, options.neuralChannelsHLFP);
                    if options.shiftSpikes
                        stream.neural = shiftStream(stream.neural,'SBsmoothed',-options.shiftSpikes);
                    end
                    if options.shiftHLFP
                        stream.neural = shiftStream(stream.neural,'HLFPsmoothed',-options.shiftHLFP);
                    end
                else
                    smoothKernel=1;
                end
                
                if options.shiftSpikes
                    stream.neural = shiftStream(stream.neural,'minAcausSpikeBand',-options.shiftSpikes);
                end
                if options.shiftHLFP
                    stream.neural = shiftStream(stream.neural,'HLFP',-options.shiftHLFP);
                end
                %% calculate rolling means if requested
                if options.rollingTimeConstant
                    stream.neural = calcRollingMeans(stream.neural,thresh, options.rollingTimeConstant, options.neuralChannels, options.neuralChannelsHLFP);
                end
                %% run factor analysis %SNF says wtf is this? Does this actually get used? 
                if options.neuralAlignment 
                    processed = runFAonRstruct( stream.neural,...
                                                struct('useChannels',options.neuralChannels,...
                                                'blockNums',options.blocksToFit(nb),...
                                                'thresholds',actualThreshVals));
                    stream.neural.xorth = zeros(size(stream.neural.minAcausSpikeBand,1), 1);
                    tmpa=resample(processed.seqTrain.xorth(1,:),processed.binWidth,1);
                    tmpt = length(tmpa);
                    stream.neural.xorth(1:tmpt,1) = tmpa;
                end
                %% oh hey here's the first time an R struct gets built, let's mess with it:
                [R1] = onlineR(stream); %options were inherited in the stream 
                % cut off wonky time steps: 
                options.tskip = 0; %or don't, if these are 0
                options.tchop = 0; %or don't, if these are 0
                %% actually do the alignment
                if options.neuralAlignment %this if has to happen twice because earlier you mess wtih the stream used to make the R
                    minlen = min(arrayfun(@(x) size(x.xorth,2),R1));
                    setAlignOpts.rangeSoftNorm = 2.5;
                    setAlignOpts.factorsToUse = 1;
                    setAlignOpts.maxShiftPerIter = 20;
                    setAlignOpts.maxIter = 40;
                    setAlignOpts.allSamples = 1:minlen;
                    setAlignOpts.whichSamples = 201:minlen-201;
                    options.tskip = 200;
                    options.tchop = 200;
                    %SNF is 90% sure this can be condensed from 4 identical for loops to 2... 
                    % and low key hates whoever wrote the horrific earlier version of this code
                    figure(25); clf;
                    subplot(1,2,1)
                    for nn = 1:numel(R1)
                        %data-ing:
                        traceSet(1,nn,1:minlen) = R1(nn).xorth(1:minlen);
                        %plotting:
                        xo  = R1(nn).xorth; 
                        xo2 = xo/(range(xo)+0.2); 
                        plot(xo2-mean(xo2)); 
                        hold on;
                    end
                    tshifts = alignTraceSets(traceSet,setAlignOpts);
                    % continuing the figure
                    title('non-aligned'); %Assigning the title to the previuos plot
                    subplot(1,2,2)
                    for nn=1:numel(R1)
                        %plotting: 
                        xo=R1(nn).xorth;
                        t=1:length(xo);
                        xo2=xo/(range(xo)+0.2);
                        plot(t-tshifts(nn),xo2-mean(xo2)); 
                        hold on;
                        %data-ing: 
                        R1(nn).neuralShift = tshifts(nn);
                    end
                     title('aligned');
                end
                R = [R(:);R1(:)];
            end %end adding blocks to the R struct
%% sweep over number of PCAs and bin sizes to test
% looped params now include: num PCs, bin sizes, thresholds, motor delays and gauss smoothing 
            for npca = 1:length(allOptions.numPCsToKeep)
                for nbinsize = 1:length(allOptions.binSize)
            % making a new filter nwo that all params are ready, increment filter count
                    iFilter = iFilter+1;
            % final set of options before filter build - this is redundant
                    options.numPCsToKeep = allOptions.numPCsToKeep(npca);
                    options.binSize = allOptions.binSize(nbinsize);
%                     options.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
%                     options.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
%                     options.arraySpecificThresholds= threshSet(nthreshold).arraySpecificThresholds;
%                     options.delayMotor = allOptions.delayMotor(ndelay);
                     % had problems with LFP values being weirdly out of bounds. screen for those trials
                    if options.useHLFP
                        keepers = true(size(R));
                        for nn = 1:length(R)
                            if any(abs(R(nn).HLFP(:))>200)
                                keepers(nn) = false;
                            end
                        end
                        if sum(~keepers)
                            fprintf(1,'removing %g / %g trials for out of bounds LFP values',sum(~keepers), length(R));
                            R=R(keepers);
                        end
                    end
%% make a D-struct with no dimension reduction 
% SNF renamed these to be less useless Aug 2019, reflecting that they use
% the full/raw data and produce "Dfull" 
                    tmpoptionsFull              = options;
                    tmpoptionsFull.shiftSpikes  = 0;
                    tmpoptionsFull.shiftHLFP    = 0;
                    tmpoptionsFull.useLDA       = true;
                    tmpoptionsFull.usePCA       = false;  %if this is the FULL one, why is this true? 
                    tmpoptionsFull.numOutputDims= DecoderConstants.NUM_CONTINUOUS_CHANNELS;
                    % calc Discrete params based on the options above
                    dmFull = calculateDiscreteParams(R,tmpoptionsFull);
                    % then override/add fields to align with the global options
                    dmFull.thresholds           = options.thresh;
                    dmFull.options.shiftSpikes  = options.shiftSpikes;  %isn't it weird that this doesn't align with tmpoptionsFull? 
                    dmFull.options.shiftHLFP    = options.shiftHLFP;    %isn't it weird that this doesn't align with tmpoptionsFull? 
                    % then copy this so we can modify the options but not
                    % the discrete model values... idk why... 
               %this variable is reused later... someone (not SNF) is playing with fire.... 
                    tmpoptions                  = dmFull.options;
                    tmpoptions.shiftSpikes      = 0;
                    tmpoptions.shiftHLFP        = 0;
 % now make the non-reduced D struct using the options above- LDA is used, PCA isn't, no shifting of anything
 % and use that to get click labels 
                    Dfull = onlineDfromR_Refit(R(2:end),[],dmFull,tmpoptions);
                    Z=[Dfull.Z]; % now only extract the neural data for later and never use the rest of Dfull
                    %% click time - with new D struct logic, this is pretty useless: 
                   % [clickLabels, indsToChop] = findClickTimes(Dfull, options);
                    clickLabels = [Dfull.clickTarget]; %SNF: this is def true for OL MultiClick
                    con = clickLabels>=1; %SNF says yes
                    coff = clickLabels==0;
                  %% channel selection time                     
                   if options.useHLFP
                        allChannels = [options.neuralChannels(:);192+options.neuralChannelsHLFP(:)];
                    else
                        allChannels = options.neuralChannels;
                    end
% Important channel selection logic: go through each channel and does a ranksum test between
% firing rates during what are marked as click times and what are marked as not click times. 
% Then it applies a threshold of 0.1 (SNF: because we <3 hard-coded random numbers for thresholds)
                    HMMchannelIncludePvalThreshold = 0.10;
                    pval = ones(1,max(allChannels));
                    for ic = 1:numel(allChannels)
                        nc = allChannels(ic);
                        Z1 = Z(nc,:);
                        zon =Z1(con);
                        zoff =Z1(coff);
                        [p,~]=ranksum(zon,zoff);
                        pval(nc) = p; 
                        if isnan(pval(nc)) 
                            pval(nc)=1; 
                        end
                    end
                    y= find(pval < HMMchannelIncludePvalThreshold);
                    fprintf('keeping %g channels for HMM decoder\n',numel(y));
                    options.neuralChannels = intersect(options.neuralChannels,y);
                    options.neuralChannelsHLFP = intersect(options.neuralChannelsHLFP,y-192);
% end use of full neural data D struct. So now make a new D struct with dim reduction
%% calculate discrete parameters (again)- this gives us dim reduced neural data
                    tmpoptions                  = options; %these lines were *just* done above -SNF
                    tmpoptions.shiftSpikes      = 0;
                    tmpoptions.shiftHLFP        = 0;
             
                    dm = calculateDiscreteParams(R,tmpoptions);
                    dm.thresholds               = options.thresh;
                    options                     = dm.options;
                    dm.options.shiftSpikes      = options.shiftSpikes;
                    dm.options.shiftHLFP        = options.shiftHLFP;
                    
                    tmpoptions                  = options;
                    tmpoptions.shiftSpikes      = 0; 
                    tmpoptions.shiftHLFP        = 0;
                    D = onlineDfromR_Refit(R(2:end),[],dm,tmpoptions); %why are we doing this again?? This is so uneccessary other than now it uses dm. 
% we don't have to run click times again because we did that with the other
% D struct. Seems like we could have made it one function call that returns
% full neural data and also the reduced space... problem for later -SNF 
%% split into training and test sets
%SNF: this previously saved only odd trials for testing, 
% which is not okay when every other trial is dwell.  
                    testIdx     = randperm(length(D));
                    testTrials  = false(size(D));
                    testTrials(testIdx(1:4:end)) = true;
                    Dtrain      = D(~testTrials);
                    Dtest       = D(testTrials);
%% fit the classifier / HMM
                    %things true for all HMM builds: 
                    hmmOptions                      = options; %these just got redefined from "calculate discrete params"
                    hmmOptions.clickSource          = options.clickSource; %SNF: "dwell" or "click"
                    hmmOptions.numDimensionsToUse   = options.numPCsToKeep;
                    hmmOptions.showLowD             = options.showFigures;
                    hmmOptions.excludeAmbiguousData = false; 
% SNF Trans probabilities were hand-tuned for each participant by PN/CP once upon a time. 
% updated to fit them to the data for multiclick. probStayMove is rarely different from the hard-coded value
% TWO-STATE : hard-coded transition probabilities
                    if options.statesToUse==2                        
                        if isfield(options,'probStayMove')
                            probStayMove = options.probStayMove^(50/options.binSize);
                        else
                            probStayMove = 0.999^(50/options.binSize);
                        end
                        probLeaveMove = 1-probStayMove;
                        if isfield(options,'probStayClick')
                            probStayClick = options.probStayClick^(50/options.binSize);
                        else
                            probStayClick = 0.85^(50/options.binSize);
                        end
                        probLeaveClick = 1-probStayClick;
                        
                        hmmOptions.trans        = [ probStayMove  probLeaveClick;
                                                    probLeaveMove probStayClick];
                        hmmOptions.stateModel   = DiscreteStates.STATE_MODEL_MOVECLICK;
% MULTI + TWO STATE (move + 4 clicks) : solve for trans matrix
                    elseif options.statesToUse==5 %multiclick + 2-state
                        % transition probabilities are solved for by the data
                        stateSeq = [D.clickTarget]; %SNF note: clickTargets are all one number smaller than their macro defs 
                        states = unique(stateSeq);  
                        %SNF: to make this flexible, options.statesToUse =
                        %length(states); 
                        options.statesToUse = length(states); %SNF debug sept 10
                        trans = zeros(options.statesToUse); %states x states transition mat
                        for i = 1 : options.statesToUse
                        % find the indices for this state
                            stateIdx = find( stateSeq(1 : end - 1) == states(i) ); %time in state i
                            statesTotal = numel(stateIdx); 
                            for j = 1 : options.statesToUse
                                %when in state i, how often do you transition to state j
                                %out of all the time you spend in state i:
                                trans(j, i) = sum(stateSeq( stateIdx + 1) == states(j))/statesTotal;
                            end
                        end
                        hmmOptions.statesToUse = options.statesToUse; %SNF edit sept 10
                        hmmOptions.trans        = trans; 
                        hmmOptions.stateModel   = DiscreteStates.STATE_MODEL_MULTICLICK;
                    end
%SNF notes: if you don't pass in the transition matrix, the
%Gaussian version of fitHMM will calculate the
%transition probabilities from the data- SNF copied
%that code into the above logic for multiclick
                    [discretemodel, figh]     = fitHMM(Dtrain,dm,hmmOptions);
                    discretemodel.options     = hmmOptions;
                    discretemodel.hLFPDivisor = options.HLFPDivisor;
                    % make sure to get the smoothing kernel used if one exists
                    if exist('smoothKernel','var')
                        discretemodel.smoothingKernel = smoothKernel;
                        disp('saving gaussian kernel');
                    end
% the HMM is now fit to the training data 
%% test the decoder  
% SNF: likelihoods = se(:, 2) is really "likelihood of click" in the single-click variant
                    [se,~,DtestOut] = decodeDstruct(Dtest,discretemodel, struct('resetEachTrial',false));
                    if options.statesToUse < 3
                        likelihoods = se(:,2); %SF: this is only good for one click. It's not the likelihoods of each state, it's the likelihood of click. 1-this = likelihood of move. 
                    else 
                        likelihoods = se(:, 2:end); %SF: if this needs to return the actual state, use [stateMax, target] =  max(se(:, 2:end), [], 2);
                    end
                    filterNum = options.startingFilterNum-1+iFilter;
                    
                    %% confusion matrix of times when the actual state was i and the SE predicted j
                    cMat = zeros(options.statesToUse);
                    [likelihoodOfState, stateEstimate] = max([DtestOut.stateEstimate], [], 1);
                    for actualTarg = unique([DtestOut.clickTarget])
                        stateIdx = find([DtestOut.clickTarget] == actualTarg);
                        actualState = length(stateIdx);
                        for predTarg = unique(stateEstimate-1)
                            predStateProp = sum((stateEstimate(stateIdx)-1) == predTarg);
                            cMat(actualTarg+1, predTarg+1) = predStateProp/actualState;
                        end
                    end
                    figure; 
                    imagesc(cMat); 
                    ylabel('Actual State')
                    xlabel('Predicted State')
                    colormap hot
                    colorbar;
                    caxis([0 1]);
                    ax = gca; 
                    set(ax, 'XTick', 1:options.statesToUse)
                    set(ax, 'YTick', 1:options.statesToUse)
                    title(['Delay:', num2str(allOptions.delayMotor(ndelay)), 'ms_', 'Bin Size:', num2str(allOptions.binSize(nbinsize)), 'ms_',...
                            'numPCs:', num2str(allOptions.numPCsToKeep(npca))]); 
%                                         
%                     if options.statesToUse == 5
%                         set(ax, 'YTickLabel', {'Move', 'R Leg <-', 'R Leg ->', 'Bicep', 'R Leg Up'})
%                         set(ax, 'XTickLabel', {'Move', 'R Leg <-', 'R Leg ->', 'Bicep', 'R Leg Up'})
%                     end
                    
                    % note from BJ: switching to STATE_SOURCE_DWELL and turning off
                    % maxClickLength for purpose of testing click decoder on hold-out data.
                    % Ground truth should be *only* whether cursor is over the target or not.
                    % We shouldn't be relabeling on-target data as not-on-target, nor evaluating
                    % the new click decoder based on whether it agrees with the old decoder,
                    % since that decoder is now stale.
%                     options_temp = options;
%                     options_temp.clickSource = DiscreteStates.STATE_SOURCE_DWELL;
%                     options_temp.maxClickLength = [];
%                     clickTimes_testData = findClickTimes(DtestOut, options_temp);  %BJ: chopping of ambiguous data not relevant here: only using on-target for evaluation
%                     
                    %BJ: compute z-value of likelihoods during click vs non-click periods of hold-out data:
%                     l_on=likelihoods(clickTimes_testData);
%                     l_off=likelihoods(~clickTimes_testData);
%                     [p_click_vs_nonclick, ~, STATS]=ranksum(l_on,l_off);
%                     zval = STATS.zval;
%                     
%                     if options.showFigures
%                         figh = figure;
%                         %% plot concatenated likelihoods
%                         subplot(1,5,1:4);
%                         plot(clickTimes_testData,'k');
%                         labels{1} = 'on target';
%                         hold on
%                         plot(se(:,2),'r');
%                         ylim([-.1 1.1])
%                         labels{2} = 'stateEstimate';
%                         if exist('overTargetTimes','var')
%                             plot(overTargetTimes,'b');
%                             labels{3} = 'overTarget';
%                         end
%                         axis('tight');
%                         ylim([-0.05 1.05]);
%                         xlabel('Test Bin')
%                         legend(labels);
%                         title(['z-value = ' num2str(zval)])
%                         
%                         % Individual trials
%                         subplot(1,5,5);
%                         minlen = min(arrayfun(@(x) size(x.stateEstimate,2),DtestOut)); % number of bins in test data
%                         setrial=zeros(1,minlen);
%                         %% plot per-trial likelihoods
%                         for nt = 1:numel(DtestOut)
%                             plot([DtestOut(nt).clickState],'k')
%                             hold on;
%                             plot(DtestOut(nt).stateEstimate(2,:),'r', 'LineWidth', 0.5);
%                             setrial = setrial(:)'+DtestOut(nt).stateEstimate(2,1:minlen)/numel(DtestOut); % running mean I think -SDS
%                             hold on;
%                         end
%                         plot(setrial,'Color', [.5 0 0], 'LineWidth', 2);
%                         xlabel('% Trial Time')
%                         axis('tight'); ylim([-0.05 1.05]);
%                         set(figh,'position',[20 50 800 300]);
%                         set(figh,'paperposition',[0 0 7 4]);
%                         set(figh,'paperunits','inches');
%                         set(figh, 'Name', sprintf('%03i-decoding.fig',filterNum) );
%                         if options.saveFigures
%                             saveas(figh,sprintf('%s%03i-decoding.fig',figOutDir,filterNum));
%                             print('-dpng',sprintf('%s%03i-decoding.png',figOutDir,filterNum));
%                         end
%                     end
%                     
%                     if options.showFigures
%                         figh = figure;
%                         axh = subplot(2,1,1); hist(l_on, 0:0.01:1);
%                         axis('tight'); ylabel('count');
%                         title('likelihoods during click (-=mean,--=median)')
%                         
%                         % Plot mean/median
%                         myYlim = get( axh, 'YLim');
%                         line( [mean(l_on) mean(l_on)], myYlim, 'Color', 'r', 'LineStyle', '-')
%                         line( [median(l_on) median(l_on)], myYlim, 'Color', 'r', 'LineStyle', '--')
%                         
%                         axh = subplot(2,1,2); hist(l_off, 0:0.01:1);
%                         axis('tight'); ylabel('count');
%                         % Plot mean/median
%                         myYlim = get( axh, 'YLim');
%                         line( [mean(l_off) mean(l_off)], myYlim, 'Color', 'b', 'LineStyle', '-')
%                         line( [median(l_off) median(l_off)], myYlim, 'Color', 'b', 'LineStyle', '--')
%                         
%                         
%                         title('likelihoods during non-click')
%                         suptitle(['Filter ' num2str(filterNum) '; z = ' num2str(zval) '; p = ' num2str(p_click_vs_nonclick)])
%                         set( figh, 'Name', sprintf('%03i-quantiles.txt',filterNum) );
%                     end
%                     
%                     thresholdSuggestion = sprintf('suggested quantiles (for threshold):\n  q0.90-> %0.3f, q0.91-> %0.3f, q0.92-> %0.3f, \nq0.93-> %0.3f, q0.94-> %0.3f, q0.95-> %0.3f\n',...
%                         quantile(likelihoods,[0.9 0.91 0.92 0.93 0.94 0.95]));
%                     fprintf(1, '%s', thresholdSuggestion);
%                     
%                     if options.saveFigures
%                         outFile = fopen(sprintf('%s%03i-quantiles.txt',figOutDir,filterNum),'w');
%                         fprintf(outFile, '%s', thresholdSuggestion);
%                         fclose(outFile);
%                         
%                         set(figh,'position',[20 320 800 300]);
%                         set(figh,'paperposition',[0 0 7 4]);
%                         set(figh,'paperunits','inches');
%                         saveas(figh,sprintf('%s%03i-histogram.fig',figOutDir,filterNum));
%                         print('-dpng',sprintf('%s%03i-histogram.png',figOutDir,filterNum));
%                     end
%                     
%                     if options.neuralAlignment && options.saveFigures
%                         filAl = figure;
%                         saveas(filAl,sprintf('%s%03i-discreteAlignment.fig',figOutDir,filterNum));
%                         print('-dpng',sprintf('%s%03i-discreteAlignemnt.png',figOutDir,filterNum));
%                     end
                    %% save the actual filter
                    if options.saveFilters
                        blockStr = sprintf('%03i,',options.blocksToFit);
                        fn = sprintf('%03i-hmm-blocks%s-binsize%gms-smooth%gms-npca%g-delay%ims-maxclick%ims', ...
                            filterNum,blockStr(1:end-1),options.binSize,options.gaussSmoothHalfWidth, ...
                            options.numPCsToKeep, options.delayMotor, options.maxClickLength);
                        disp(['saving filter : ' fn]);
                        save([filterOutDir fn],'discretemodel','hmmOptions','likelihoods');
                    end
                    %% assign output if desired
                    if nargout > 0
                        output(iFilter).discretemodel = discretemodel;
                        output(iFilter).hmmOptions = hmmOptions;
                        output(iFilter).likelihoods = likelihoods;
                        output(iFilter).cMat = cMat; 
                    end
                   fprintf('Filter %i built.\n\n', filterNum);
                end
            end
        end
    end
end
%% outside the for loop over parameters...
% save new likelihoods
modelConstants.sessionParams.hmmLikelihoods = likelihoods;
	
CURRENT_DISCRETE_FILTER_NUMBER = filterNum;

end
