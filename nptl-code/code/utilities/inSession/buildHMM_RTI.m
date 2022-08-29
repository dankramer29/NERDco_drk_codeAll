function output = buildHMM_RTI(R, options, actualThreshVals)
%buildHMM_RTI modeled off of buildHMMDialog, but for RTI
%
%called automatically inside buildRTIfilters; using RTIdata instead of streams, skips stream->R stuff of usual
%buildHMMDialog and goes straight to R->D

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

% options that are prompted for HMM only (otherwise, default to same inputs
% as for Kalman RTI build):
prompt.normalize = 'false';  %SELF: what does this do?
prompt.numPCsToKeep = '4';
prompt.clickSource = 'RTI';  %SELF: add this as a possible click source to downstream code; just use the inds saved in R.movingInds, R.clickingInds!!
%     prompt.clickStateThreshold = '0.5';  %SELF: shouldn't need this for RTI
%     prompt.statesToUse = '2';  %SELF: shouldn't need this for RTI
prompt.maxClickLength = '500';  %BJ: used to end click periods that remain above threshold for too long
%     prompt.normFactor = num2str(50 * 0.03);  %SELF: this appears to be same as txNormFactor and hLFPNormFactor; see if removing it causes any probs
prompt.usePCA = 'true';  %was false for Kalman RTI; change to true for HMM
prompt.useLDA = 'false';
% prompt.neuralAlignment = 'false';  %SELF: shouldn't need this for RTI...
% prompt.excludeAmbiguousData = 'false'; % BJ: new option added 2/2017 to
% allow ambiguous data (clicking off target, or not clicking
% while on target) to not be used for calibration instead of
% labeling it as non-click (previous behavior; keeping as default for now.)


%% only do this if prompt is non-empty
if ~isempty(prompt)
    %% set the default starting filter num
    prompt = setDefault(prompt,'startingFilterNum',num2str(CURRENT_DISCRETE_FILTER_NUMBER),true);
    promptfields = fieldnames(prompt);
    % add more descriptive options
    promptfieldsDisplay = promptfields;  % just for dialog box display, can be more descriptive.
    %     promptfieldsDisplay{strcmp( promptfieldsDisplay, 'clickSource' )} = 'clickSource (dwell, click, click+overtarget)';   %SELF: not sure what this does... make sure RTI appears for clickSource?
    response=inputdlgcol(promptfieldsDisplay,'Click decoder options', 1, struct2cell(prompt),'on',2);
    
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
    %% if number conversion didn't work, just keep the string
    if isempty(options.(promptfields{nn}))
        options.(promptfields{nn}) = response{nn};
    end
end


%% set some defaults
options=setDefault(options,'arraySpecificThresholds',[],false);
options=setDefault(options,'restSpeedThresholdPercent', 0.1,true);
options=setDefault(options,'neuralAlignment', false,true);
options=setDefault(options,'rmsMultiplier', [],true);
options=setDefault(options,'useFA', false,true);
options=setDefault(options,'useLDA',false,true);
options=setDefault(options,'removePCs',false,true);
options=setDefault(options,'rollingTimeConstant',0,false);
options=setDefault(options,'showFigures', true, true);
options=setDefault(options,'saveFigures', true, true);
options=setDefault(options,'saveFilters', true, true);

options.excludeAmbiguousData = false; % should have no effeect in RTI
options.normalizeHLFP = false;  %useHLFP should already be false from kin build
options.HLFPDivisor = options.hLFPDivisor;  %not used for RTI, but field is checked for anyway for some reason (even though normalizeHLFP is false), and case is slightly different from the one used for kin build. Sigh.
options.statesToUse = 2; %2 = click and non-click only (no rest)
options.clickStateThreshold = .5;  %shouldn't need for RTI but checkOption-ed by fitHMM.

if options.usePCA || options.useFA
    options=setDefault(options,'numOutputDims', double(DecoderConstants.MAX_DISCRETE_DECODE_CHANNELS), true);
else
    options=setDefault(options,'numOutputDims', double(DecoderConstants.NUM_CONTINUOUS_CHANNELS), false);
end

switch modelConstants.rig
    case 't5'

        % build a channel exclusion list
        allChannels = 1:192;
        %updated 9/27/17:
        excludeChannels = [2 46 66 67 68 69 73 76 77 78 82 83 85 86 94 95 96];
        options.neuralChannels = setdiff(allChannels,excludeChannels);
        options.neuralChannelsHLFP = options.neuralChannels;
        
%         nc = 1:192;
%         nc2 = 1:192;
%         options = setDefault(options,'neuralChannels', nc, true);
%         options = setDefault(options,'neuralChannelsHLFP', nc2, true);
    otherwise
        nc = 1:192;
        nc2 = 1:192;
        options = setDefault(options,'neuralChannels', nc, true);
        options = setDefault(options,'neuralChannelsHLFP', nc2, true);
        warning('Please ensure options are set correctly for this participant!')
end

%% need some signal source
if ~options.useHLFP && ~options.useTx
    error('buildHMMDialog: neither Tx nor HLFP are selected...');
end
% 
% %% arraySpecificThresholds should be a cell array of vectors
% if ~isempty(options.arraySpecificThresholds) && ~iscell(options.arraySpecificThresholds)
%     options.arraySpecificThresholds = {options.arraySpecificThresholds};
% end

assert(strcmp(options.clickSource, 'RTI'), 'Click source is not specified as RTI; should not be calling this function.')

%% do some checks...
if sum([options.usePCA options.useFA options.useLDA])>1
    error('buildHMMDialog: using multiple dimensionality reduction techniques... not allowed');
end

%%% start iterating over parameters
iFilter = 0;
options.thresh = actualThreshVals;  %BJ: reuse these from previous filter build

for ndelay = 1:numel(options.delayMotor)
    for nsmoothsize = 1:length(options.gaussSmoothHalfWidth)
        options.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth(nsmoothsize);
        options.delayMotor = options.delayMotor(ndelay);
        options.shiftSpikes = options.delayMotor;
        options.shiftHLFP = options.delayMotor;
        
        for npca = 1:length(options.numPCsToKeep)
            for nbinsize = 1:length(options.binSize)
                iFilter = iFilter+1;
                
                options.numPCsToKeep = options.numPCsToKeep(npca);
                options.binSize = options.binSize(nbinsize);
                
                options.delayMotor = options.delayMotor(ndelay);
                
                %%make a D-struct with no dimension reduction
                tmpoptions2 = options;
                tmpoptions2.shiftSpikes=0;
                tmpoptions2.shiftHLFP=0;
                tmpoptions2.useLDA = true;
                tmpoptions2.usePCA = false;
                tmpoptions2.numOutputDims = DecoderConstants.NUM_CONTINUOUS_CHANNELS;
                tmpoptions2.HLFPNormFactor = tmpoptions2.hLFPNormFactor;  %BJ: so dumb, but expected case doesn't match between HMM and kin build!
                         
                dm2 = calculateDiscreteParams(R,tmpoptions2);
                dm2.thresholds = options.thresh;
                dm2.options.shiftSpikes=options.shiftSpikes;
                dm2.options.shiftHLFP=options.shiftHLFP;
                
                tmpoptions = dm2.options;
                tmpoptions.shiftSpikes=0;
                tmpoptions.shiftHLFP=0;
                
                Dfull = onlineDfromR(R,[],dm2,tmpoptions);
                1;
                Z=[Dfull.Z];
                
                %% obtain click labels again for channel selection:
                % BJ: here, HMM is being built using all neural features (instead of first
                % N PCs) so best features can be chosen for dimension-reduced HMM later.
                % Use same options as do for actual click build.
                [clickLabels, indsToChop] = findClickTimes(Dfull, options);
                
                % BJ: if excludeAmbiguousData, chop out datapoints indsToChop (otherwise,
                % they remain labeled non-click, as set by default in findClickTimes):
                if options.excludeAmbiguousData,
                    clickLabels(indsToChop) = [];
                    Z(:,indsToChop) = [];
                end
                
                con = clickLabels==1;
                coff = clickLabels==0;
                
                if options.useHLFP
                    allChannels = [options.neuralChannels(:);192+options.neuralChannelsHLFP(:)];
                else
                    allChannels = [options.neuralChannels(:);];
                end
                
                % Important channel selection logic:
                % It goes through each channel and does a ranksum test between
                % firing rates during what are marked as click times and what are marked as
                % not click times. Keeps all features whose p-value < 0.1.
                HMMchannelIncludePvalThreshold = 0.10;
                pval = ones(1,max(allChannels));
                for ic=1:numel(allChannels)
                    nc=allChannels(ic);
                    Z1 = Z(nc,:);
                    zon=Z1(con);
                    zoff=Z1(coff);
                    [p,h]=ranksum(zon,zoff);
                    
                    %mdl = LinearModel.fit(clickTimes(:), Z1(:));
                    %pval(nc) = mdl.anova.pValue(1);
                    pval(nc) = p;
                    if isnan(pval(nc)), pval(nc)=1; end
                end
                
                y= find(pval < HMMchannelIncludePvalThreshold);
                fprintf('keeping %g channels for HMM decoder\n',numel(y));
                options.neuralChannels = intersect(options.neuralChannels,y);
                options.neuralChannelsHLFP = intersect(options.neuralChannelsHLFP,y-192);
                
                %% mask out the "shiftspikes" and "shifthlfp" options as those have been applied earlier
                tmpoptions = options;
                tmpoptions.shiftSpikes=0;
                tmpoptions.shiftHLFP=0;
                
                
                %% calculate discrete parameters
                dm = calculateDiscreteParams(R,tmpoptions);
                dm.thresholds = options.thresh;
                options = dm.options;
                dm.options.shiftSpikes=options.shiftSpikes;
                dm.options.shiftHLFP=options.shiftHLFP;
                
                tmpoptions = options;
                tmpoptions.shiftSpikes=0;
                tmpoptions.shiftHLFP=0;
                D = onlineDfromR(R,[],dm,tmpoptions);
                
                %% fit the classifier / HMM
                hmmOptions = options;
                hmmOptions.clickSource = options.clickSource;
                
                
                %BJ: this part hard-codes state transition probabilities, I think:
                if options.statesToUse==2
                    %% TWO-STATE
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
                    hmmOptions.trans = [probStayMove  probLeaveClick;
                        probLeaveMove probStayClick];
                    hmmOptions.stateModel = DiscreteStates.STATE_MODEL_MOVECLICK;
                else
                    %% THREE STATE
                    probStayMove = 0.999^(50/options.binSize);
                    probLeaveMove = 1-probStayMove;
                    probStayIdle=0.5;
                    probLeaveIdle1=0.25;
                    probLeaveIdle2=0.25;
                    probStayClick = 0.85^(50/options.binSize);
                    probLeaveClick = 1-probStayClick;
                    hmmOptions.trans = [probStayMove  probLeaveIdle1 probLeaveClick;
                        probLeaveMove probStayIdle                0;
                        0             probLeaveIdle2 probStayClick];
                    
                    hmmOptions.stateModel = DiscreteStates.STATE_MODEL_MOVEIDLECLICK;
                    % use the 'clickState' field of the Dstruct to indicate clicks
                    hmmOptions.idleSource = DiscreteStates.STATE_SOURCE_DWELL;
                end
                
                hmmOptions.numDimensionsToUse = options.numPCsToKeep;
                hmmOptions.showLowD = options.showFigures;
                
                
                %% split into training and test sets
                testTrials = false(size(D));
                testTrials(1:4:end) = true;
                Dtrain = D(~testTrials);
                Dtest = D(testTrials);
                
                [discretemodel, figh] = fitHMM(Dtrain,dm,hmmOptions);
                discretemodel.options = hmmOptions;
                discretemodel.hLFPDivisor = options.HLFPDivisor;
                
                %% get the smoothing kernel that was used from the kin build:
                discretemodel.smoothingKernel = options.smoothingKernel;
                disp('obtaining gaussian kernel from the one saved in options from kin RTI...');
                
                [se,~,DtestOut]=decodeDstruct(Dtest,discretemodel, struct('resetEachTrial',false));
                likelihoods = se(:,2);
                
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
                % since that decoder is now stale.  %SELF: might need to be modified for RTI.
                options_temp = options;
                options_temp.clickSource = DiscreteStates.STATE_SOURCE_DWELL;
                options_temp.maxClickLength = [];
                [clickTimes_testData]  = findClickTimes(DtestOut, options_temp);  %BJ: chopping of ambiguous data not relevant here: only using on-target for evaluation
                
                %BJ: compute z-value of likelihoods during click vs non-click periods of hold-out data:
                l_on=likelihoods(clickTimes_testData);
                l_off=likelihoods(~clickTimes_testData);
                [p_click_vs_nonclick, ~, STATS]=ranksum(l_on,l_off);
                zval = STATS.zval;
                
                if options.showFigures
                    figLik = figure;
                    clf;
                    %% plot concatenated likelihoods
                    subplot(1,5,1:4);
                    plot(clickTimes_testData,'k');
                    legendLabels{1} = 'Over Target (testGndTruth)';
                    hold on
                    plot(se(:,2),'r');
                    legendLabels{2} = 'stateEstimate';
                    ylim([-.1 1.1])
                    %     if exist('overTargetTimes','var')
                    %         plot(overTargetTimes,'b');
                    % SDS: This is removed because for TEST ONLY we assume
                    % being over target is click intention ground truth
                    %     end
                    legendLabels{3} = 'overTarget';
                    title(['z-value (click vs nonclick) = ' num2str(zval)])
                    legend(legendLabels);
                    
                    
                    subplot(1,5,5);
                    minlen = min(arrayfun(@(x) size(x.stateEstimate,2),DtestOut));
                    setrial=zeros(1,minlen);
                    %% plot per-trial likelihoods
                    for nt = 1:numel(DtestOut)
                        plot([DtestOut(nt).clickState],'k')
                        hold on;
                        plot(DtestOut(nt).stateEstimate(2,:),'r');
                        setrial = setrial(:)'+DtestOut(nt).stateEstimate(2,1:minlen)/numel(DtestOut);
                        hold on;
                    end
                    plot(setrial,'Color', [.5 0 0], 'LineWidth', 2);
                    xlabel('% Trial Time')
                    set(figLik,'position',[20 20 800 300]);
                    set(figLik,'paperposition',[0 0 7 4]);
                    set(figLik,'paperunits','inches');
                    set(figLik, 'Name', sprintf('%03i-decoding.fig',filterNum) );
                    
                    if options.saveFigures
                        saveas(figLik,sprintf('%s%03i-decoding.fig',figOutDir,filterNum));
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
                    title('likelihoods during non-click')
                    suptitle(['Filter ' num2str(filterNum) '; z = ' num2str(zval) '; p = ' num2str(p_click_vs_nonclick)])
                    set( figh, 'Name', sprintf('%03i-quantiles.txt',filterNum) );
                    % Plot mean/median
                    myYlim = get( axh, 'YLim');
                    line( [mean(l_off) mean(l_off)], myYlim, 'Color', 'b', 'LineStyle', '-')
                    line( [median(l_off) median(l_off)], myYlim, 'Color', 'b', 'LineStyle', '--')
                    
                end
                
                thresholdSuggestion = sprintf('suggested quantiles (for threshold):\n  q0.90-> %0.3f, q0.91-> %0.3f, q0.92-> %0.3f, \nq0.93-> %0.3f, q0.94-> %0.3f, q0.95-> %0.3f\n',...
                    quantile(likelihoods,[0.9 0.91 0.92 0.93 0.94 0.95]));
                fprintf(1, '%s', thresholdSuggestion);
                
                if options.saveFigures
                    outFile = fopen(sprintf('%s%03i-quantiles.txt',figOutDir,filterNum),'w');
                    fprintf(outFile, '%s', thresholdSuggestion);
                    fclose(outFile);
                end
                
                if options.neuralAlignment && options.saveFigures
                    filAl = figure;
                    saveas(filAl,sprintf('%s%03i-discreteAlignment.fig',figOutDir,filterNum));
                    print('-dpng',sprintf('%s%03i-discreteAlignemnt.png',figOutDir,filterNum));
                end
                
                %% save the actual filter
                if options.saveFilters
                    blockStr = sprintf('%03i,',options.blocksToFit);
                    fn = sprintf('%03i-hmm-blocks%s-binsize%gms-smooth%gms-npca%g-delay%ims-RTI', ...
                        filterNum,blockStr(1:end-1),options.binSize,options.gaussSmoothHalfWidth, ...
                        options.numPCsToKeep, options.delayMotor);
                    disp(['saving filter : ' fn]);
                    save([filterOutDir fn],'discretemodel','hmmOptions','likelihoods');
                end
                
                %% assign output if desired
                if nargout > 0
                    output(iFilter).discretemodel = discretemodel;
                    output(iFilter).hmmOptions = hmmOptions;
                    output(iFilter).likelihoods = likelihoods;
                end
                
                
                if options.saveFigures
                    set(gcf,'position',[20 320 800 300]);
                    set(gcf,'paperposition',[0 0 7 4]);
                    set(gcf,'paperunits','inches');
                    saveas(gcf,sprintf('%s%03i-histogram.fig',figOutDir,filterNum));
                    print('-dpng',sprintf('%s%03i-histogram.png',figOutDir,filterNum));
                end
                
                fprintf('Filter %i built.\n\n', filterNum);
                
            end
        end
    end
end

%% outside the for loop over parameters...

% save new likelihoods
modelConstants.sessionParams.hmmLikelihoods = likelihoods;

CURRENT_DISCRETE_FILTER_NUMBER = filterNum;

end
