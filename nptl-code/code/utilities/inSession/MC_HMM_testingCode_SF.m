% testing HMM MC code:
%% init stuff:
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

filterOutDir = [sessionRoot(2:end) modelConstants.discreteFilterDir];

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
    %% options that are prompted
if ~exist('prompt','var')

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
end
%% only do this if prompt is non-empty
if ~isempty(prompt)
    % set the default starting filter num
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
    options=setDefault(options,'numOutputDims', double(DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS), true);
else
    options=setDefault(options,'numOutputDims', double(DecoderConstants.NUM_CONTINUOUS_CHANNELS), false);
end
%% using T5 offline data:
% build a channel exclusion list
allChannels = 1:192;
%updated 9/27/17:
excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];
options.neuralChannels = setdiff(allChannels,excludeChannels);
options.neuralChannelsHLFP = options.neuralChannels;

options.normalizeTx = options.normalize;
options.normalizeHLFP = options.normalize;

options.txNormFactor = options.normFactor;
options.HLFPNormFactor = options.normFactor;
%% arraySpecificThresholds should be a cell array of vectors
if ~isempty(options.arraySpecificThresholds) && ~iscell(options.arraySpecificThresholds)
    options.arraySpecificThresholds = {options.arraySpecificThresholds};
end

options.clickSource = DiscreteStates.STATE_SOURCE_DWELL;
if isempty(options.delayMotor)
    if options.neuralAlignment
        options.delayMotor=0;
    else
        error('buildHMMDialog: must specify delayMotor or set neuralAlignment to true');
    end
end
threshSet=[];
for nn = 1:length(options.fixedThreshold)
    threshSet(end+1).multsOrThresholds = options.fixedThreshold(nn);
    threshSet(end).useFixedThresholds=true;
    threshSet(end).arraySpecificThresholds = [];
end
% per-array fixed threshold (cell array of vectors, each vec has one element per array)
for nn = 1:length(options.arraySpecificThresholds)
    threshSet(end+1).multsOrThresholds = 1;
    threshSet(end).useFixedThresholds=true;
    threshSet(end).arraySpecificThresholds = options.arraySpecificThresholds{nn};
end
% rms multiplier
for nn = 1:length(options.rmsMultiplier)
    if ~isempty(options.fixedThreshold),
        error('Please specify either a fixed threshold or an RMS muliplier, not both!')
    end
    threshSet(end+1).multsOrThresholds = options.rmsMultiplier(nn);
    threshSet(end).useFixedThresholds=false;
    threshSet(end).arraySpecificThresholds = [];
end
%% load some data y'all
for nb = 1:length(options.blocksToFit)
    blockNum = options.blocksToFit(nb);
    %if on SF's laptop: 
    flDir = '/Users/sharlene/CachedData/t5.2019.02.04/Data/FileLogger/';
   % flDir = [sessionRoot modelConstants.filelogging.outputDirectory];
    streams{nb} = loadStream([flDir num2str(blockNum) '/'], blockNum);
end
allOptions = options;

iFilter = 0;
nthreshold = 1;
options = allOptions;
options.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
options.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
options.arraySpecificThresholds= threshSet(nthreshold).arraySpecificThresholds;

%% now calculate the actual threshold values
if ~options.useFixedThresholds
    % not using fixed thresholds, so we need to calculate thresholds
    % based on an rms multiplier
    % do this using the first stream passed in
    rmsvals = channelRMS(streams{1}.neural);
    actualThreshVals = options.multsOrThresholds * rmsvals;
else
    % one threshold per array?
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
ndelay = 1;
nsmoothsize = 1;
options.gaussSmoothHalfWidth = allOptions.gaussSmoothHalfWidth(nsmoothsize);
options.delayMotor = allOptions.delayMotor(ndelay);
options.shiftSpikes = options.delayMotor;
options.shiftHLFP = options.delayMotor;
%% build R struct
R = [];

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
    
    if options.neuralAlignment
        % run factor analysis
        processed = runFAonRstruct(stream.neural,...
            struct('useChannels',options.neuralChannels,...
            'blockNums',options.blocksToFit(nb),...
            'thresholds',actualThreshVals));
        stream.neural.xorth = zeros(size(stream.neural.minAcausSpikeBand,1), 1);
        tmpa=resample(processed.seqTrain.xorth(1,:),processed.binWidth,1);
        tmpt = length(tmpa);
        stream.neural.xorth(1:tmpt,1) = tmpa;
    end
    %% oh hey here's the first time an R struct gets built, let's mess with it:
    [R1] = onlineR(stream); %doesn't pass in options...
    
    options.tskip = 0;
    options.tchop = 0;
    
    %% actually do the alignment
    if options.neuralAlignment
        minlen = min(arrayfun(@(x) size(x.xorth,2),R1));
        setAlignOpts.rangeSoftNorm = 2.5;
        setAlignOpts.factorsToUse = 1;
        setAlignOpts.maxShiftPerIter = 20;
        setAlignOpts.maxIter = 40;
        setAlignOpts.allSamples = 1:minlen;
        setAlignOpts.whichSamples = 201:minlen-201;
        options.tskip = 200;
        options.tchop = 200;
        for nn = 1:numel(R1)
            traceSet(1,nn,1:minlen) = R1(nn).xorth(1:minlen);
        end
        tshifts = alignTraceSets(traceSet,setAlignOpts);
        
        figure(25); clf;
        subplot(1,2,1)
        for nn=1:numel(R1)
            xo=R1(nn).xorth; xo2=xo/(range(xo)+0.2); plot(xo2-mean(xo2)); hold on;
        end
        title('non-aligned');
        subplot(1,2,2)
        for nn=1:numel(R1)
            xo=R1(nn).xorth;
            t=1:length(xo);
            xo2=xo/(range(xo)+0.2);
            plot(t-tshifts(nn),xo2-mean(xo2)); hold on;
        end
        title('aligned');
        for nn = 1:numel(R1)
            R1(nn).neuralShift = tshifts(nn);
        end
    end
    R = [R(:);R1(:)];
end
%% we only try one of each of these at a time
npca = 1;
nbinsize = 1;
iFilter = iFilter+1;

options.numPCsToKeep = allOptions.numPCsToKeep(npca);
options.binSize = allOptions.binSize(nbinsize);
options.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
options.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
options.arraySpecificThresholds= threshSet(nthreshold).arraySpecificThresholds;
options.delayMotor = allOptions.delayMotor(ndelay);
%% had problems with LFP values being weirdly out of bounds. screen for those trials
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
%% SNF doesn't understand why we need this 
%make a D-struct with no dimension reduction
tmpoptions2 = options;
tmpoptions2.shiftSpikes=0;
tmpoptions2.shiftHLFP=0;
tmpoptions2.useLDA = true;
tmpoptions2.usePCA = false;
tmpoptions2.numOutputDims = DecoderConstants.NUM_CONTINUOUS_CHANNELS;
%this returns a projector of size 384 x 384, in comparison to the one later
%on which is 384 x 20 (20 = max num PCs) and only filled in the number of
%PCs I specified in the prompt 
dm2 = calculateDiscreteParams(R,tmpoptions2);
dm2.thresholds = options.thresh;
dm2.options.shiftSpikes=options.shiftSpikes;
dm2.options.shiftHLFP=options.shiftHLFP;

tmpoptions = dm2.options;
tmpoptions.shiftSpikes=0;
tmpoptions.shiftHLFP=0;
Dfull = onlineDfromR(R,[],dm2,tmpoptions);
Z=[Dfull.Z];

%% obtain click labels again for channel selection:
% BJ: here, HMM is being built using all neural features (instead of first
% N PCs) so best features can be chosen for dimension-reduced HMM later.
% Use same options as do for actual click build.
[clickLabels, indsToChop] = findClickTimes(Dfull, options);

% BJ: if excludeAmbiguousData, chop out datapoints indsToChop (otherwise,
% they remain labeled non-click, as set by default in findClickTimes):
if options.excludeAmbiguousData
    clickLabels(indsToChop) = [];
    Z(:,indsToChop) = [];
end

% con = clickLabels==1; %SNF should this be >=?
con = clickLabels>=1; %SNF says yes
coff = clickLabels==0;

if options.useHLFP
    allChannels = [options.neuralChannels(:);192+options.neuralChannelsHLFP(:)];
else
    allChannels = [options.neuralChannels(:);];
end

%% Important channel selection logic:
% It goes through each channel and does a ranksum test between
% firing rates during what are marked as click times and what are marked as
% not click times. Then it applies a threshold of 0.1
HMMchannelIncludePvalThreshold = 0.10;
pval = ones(1,max(allChannels));
for ic= 1:numel(allChannels)
    nc=allChannels(ic);
    Z1 = Z(nc,:);
    zon=Z1(con);
    zoff=Z1(coff);
    [p,~]=ranksum(zon,zoff);
    
    %mdl = LinearModel.fit(clickTimes(:), Z1(:));
    %pval(nc) = mdl.anova.pValue(1);
    pval(nc) = p;
    if isnan(pval(nc)) %SNF fixed this stupid 'shortcut'
        pval(nc)=1;
    end
end

y= find(pval < HMMchannelIncludePvalThreshold);
fprintf('keeping %g channels for HMM decoder\n',numel(y));
options.neuralChannels = intersect(options.neuralChannels,y);
options.neuralChannelsHLFP = intersect(options.neuralChannelsHLFP,y-192);

%seriously, why twice????
%% mask out the "shiftspikes" and "shifthlfp" options as those have been applied earlier
tmpoptions = options;
tmpoptions.shiftSpikes=0;
tmpoptions.shiftHLFP=0;
% SNF: shiftspikes and shiftlfp were *not* applied
% earlier. useLDA was used earlier and, in theory, is
% still active because these values are being used from
% the same struct.

%% calculate discrete parameters
%SNF: tmpoptions are from the last time we called
%calculateDiscreteParams, 70 lines ago.
dm = calculateDiscreteParams(R,tmpoptions);
dm.thresholds = options.thresh;
options = dm.options;
dm.options.shiftSpikes=options.shiftSpikes;
dm.options.shiftHLFP=options.shiftHLFP;

tmpoptions = options;
tmpoptions.shiftSpikes=0;
tmpoptions.shiftHLFP=0;
% if options.statesToUse > 3 %if it's a multiclick task
%     taskConstants.CLICK_LCLICK = DiscreteStates.CLICK_LCLICK; %SF: this is a flag for the next function to use multiclick logic
%     D = onlineDfromR(R, taskConstants, dm, tmpoptions);
%     %D = onlineDfromR_multiClick(R, taskConstants, dm, tmpoptions);
% else
    D = onlineDfromR(R,[],dm,tmpoptions); %why are we doing this again?? This is so uneccessary other than now it uses dm.
% end
%% fit the classifier / HMM
hmmOptions = options;
hmmOptions.clickSource = options.clickSource;
%% 5-state: MOVE + 4 CLICKS
if isfield(options,'probStayMove')
    probStayMove = options.probStayMove^(50/options.binSize);
else
    probStayMove = 0.999^(50/options.binSize);
end
probLeaveMove = (1-probStayMove)/4; %SNF to turn this hard-coded 4 into a macro... this whole thing is hard coded and shouldn't be
if isfield(options,'probStayClick')
    probStayClick1 = options.probStayClick^(50/options.binSize);
    probStayClick2 = options.probStayClick^(50/options.binSize);
    probStayClick3 = options.probStayClick^(50/options.binSize);
    probStayClick4 = options.probStayClick^(50/options.binSize);
else
    probStayClick1 = 0.85^(50/options.binSize);
    probStayClick2 = 0.85^(50/options.binSize);
    probStayClick3 = 0.85^(50/options.binSize);
    probStayClick4 = 0.85^(50/options.binSize);
end
probLeaveClick1 = 1-probStayClick1;
probLeaveClick2 = 1-probStayClick2;
probLeaveClick3 = 1-probStayClick3;
probLeaveClick4 = 1-probStayClick4;
%columns sum to 1, rows don't have to:
% hmmOptions.trans = [probStayMove    probLeaveClick1 probLeaveClick2 probLeaveClick3 probLeaveClick4;...
%     probLeaveMove   probStayClick1  0               0                           0;...
%     probLeaveMove   0               probStayClick2  0                           0;...
%     probLeaveMove   0               0               probStayClick3              0;...
%     probLeaveMove   0               0               0               probStayClick4];
hmmOptions.stateModel = DiscreteStates.STATE_MODEL_MULTICLICK;

hmmOptions.numDimensionsToUse = options.numPCsToKeep;
hmmOptions.showLowD = options.showFigures;

%% split into training and test sets
%SNF: this previously saved only odd trials for
%testing, which are the same target in multiClick.
testIdx = randperm(length(D));
testTrials = false(size(D));
testTrials(testIdx(1:4:end)) = true;
Dtrain = D(~testTrials);
Dtest = D(testTrials);
hmmOptions.excludeAmbiguousData = false;
hmmOptions.useFA = false; 
hmmOptions.usePCA = false; 
hmmOptions.useLDA = true; 
dm.discreteDecoderType = DecoderConstants.DISCRETE_DECODER_TYPE_HMMLDA; 
[discretemodel, figh] = fitHMM(Dtrain,dm,hmmOptions);
discretemodel.options = hmmOptions;
discretemodel.hLFPDivisor = options.HLFPDivisor;
%% make sure to get the smoothing kernel used if one exists
if exist('smoothKernel','var')
    discretemodel.smoothingKernel = smoothKernel;
    disp('saving gaussian kernel');
end

[se,~,DtestOut]=decodeDstruct(Dtest,discretemodel, struct('resetEachTrial',false));
likelihoods = se(:,2); %SF ccheck size of se from the above fxn
%[likelihoods, decodedState] = max(se,[],2);
filterNum = options.startingFilterNum-1+iFilter;
figOutDir = [modelConstants.sessionRoot modelConstants.analysisDir 'FilterBuildFigs/'];

if options.showFigures
    set( figh, 'Name', sprintf('lowD discreteFilt%i', filterNum) );
    if options.saveFigures
        saveas(figh ,sprintf('%s%03i-lowD.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%03i-lowD.png',figOutDir,filterNum));
    end
end

% note from BJ: switching to STATE_SOURCE_DWELL and turning off
% maxClickLength for purpose of testing click decoder on hold-out data.
% Ground truth should be *only* whether cursor is over the target or not.
% We shouldn't be relabeling on-target data as not-on-target, nor evaluating
% the new click decoder based on whether it agrees with the old decoder,
% since that decoder is now stale.
options_temp = options;
options_temp.clickSource = DiscreteStates.STATE_SOURCE_DWELL;
options_temp.maxClickLength = [];
clickTimes_testData = findClickTimes(DtestOut, options_temp);  %BJ: chopping of ambiguous data not relevant here: only using on-target for evaluation

%BJ: compute z-value of likelihoods during click vs non-click periods of hold-out data:
l_on=likelihoods(logical(clickTimes_testData));
l_off=likelihoods(~(logical(clickTimes_testData)));
[p_click_vs_nonclick, ~, STATS]=ranksum(l_on,l_off);
zval = STATS.zval;
%% Figures
if options.showFigures
    figh = figure;
    %% plot concatenated likelihoods
    subplot(1,5,1:4);
    plot(clickTimes_testData,'k');
    labels{1} = 'on target';
    hold on
    plot(se(:,2),'r');
    ylim([-.1 1.1])
    labels{2} = 'stateEstimate';
    if exist('overTargetTimes','var')
        plot(overTargetTimes,'b');
        labels{3} = 'overTarget';
    end
    axis('tight');
    ylim([-0.05 1.05]);
    xlabel('Test Bin')
    legend(labels);
    title(['z-value = ' num2str(zval)])
    
    % Individual trials
    subplot(1,5,5);
    minlen = min(arrayfun(@(x) size(x.stateEstimate,2),DtestOut)); % number of bins in test data
    setrial=zeros(1,minlen);
    %% plot per-trial likelihoods
    for nt = 1:numel(DtestOut)
        plot([DtestOut(nt).clickState],'k')
        hold on;
        plot(DtestOut(nt).stateEstimate(2,:),'r', 'LineWidth', 0.5);
        setrial = setrial(:)'+DtestOut(nt).stateEstimate(2,1:minlen)/numel(DtestOut); % running mean I think -SDS
        hold on;
    end
    plot(setrial,'Color', [.5 0 0], 'LineWidth', 2);
    xlabel('% Trial Time')
    axis('tight'); ylim([-0.05 1.05]);
    set(figh,'position',[20 50 800 300]);
    set(figh,'paperposition',[0 0 7 4]);
    set(figh,'paperunits','inches');
    set(figh, 'Name', sprintf('%03i-decoding.fig',filterNum) );
    if options.saveFigures
        saveas(figh,sprintf('%s%03i-decoding.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%03i-decoding.png',figOutDir,filterNum));
    end
end

if options.showFigures
    figh = figure;
    axh = subplot(2,1,1); hist(l_on, 0:0.01:1);
    axis('tight'); ylabel('count');
    title('likelihoods during click (-=mean,--=median)')
    % Plot mean/median
    myYlim = get( axh, 'YLim');
    line( [mean(l_on) mean(l_on)], myYlim, 'Color', 'r', 'LineStyle', '-')
    line( [median(l_on) median(l_on)], myYlim, 'Color', 'r', 'LineStyle', '--')
    axh = subplot(2,1,2); hist(l_off, 0:0.01:1);
    axis('tight'); ylabel('count');
    % Plot mean/median
    myYlim = get( axh, 'YLim');
    line( [mean(l_off) mean(l_off)], myYlim, 'Color', 'b', 'LineStyle', '-')
    line( [median(l_off) median(l_off)], myYlim, 'Color', 'b', 'LineStyle', '--')
    title('likelihoods during non-click')
    suptitle(['Filter ' num2str(filterNum) '; z = ' num2str(zval) '; p = ' num2str(p_click_vs_nonclick)])
    set( figh, 'Name', sprintf('%03i-quantiles.txt',filterNum) );
end

thresholdSuggestion = sprintf('suggested quantiles (for threshold):\n  q0.90-> %0.3f, q0.91-> %0.3f, q0.92-> %0.3f, \nq0.93-> %0.3f, q0.94-> %0.3f, q0.95-> %0.3f\n',...
    quantile(likelihoods,[0.9 0.91 0.92 0.93 0.94 0.95]));
fprintf(1, '%s', thresholdSuggestion);