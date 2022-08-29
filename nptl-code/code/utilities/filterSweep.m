function [models, modelsFull, summaryOut, RTIdata, frs] = ...
    filterSweep(sessionPath, options)
% FILTERSWEEP
%
%   models = filterSweep(dataPath, options)
%
%   INPUTS
%     sessionPath = path to directory containing session
%       from there, assumes data is in
%            session/data/blocks/rawData/[BLOCK_NUM]/
%       also must have (or will create) a
%            session/data/blocks/matStructs/ directory
%     options = structure with tons of options for fitting.
%   OUTPUTS
%     models  decoders trained with held-out data (for testing
%     modelsFull  decoders trained from all data.
%     summaryOut   Added SDS Feb 2017, this outputs the offline decode accuracy
%                  results. Useful for running parameter sweeps
%                  offline using the same build stack.
global modelConstants

global summary
clear summary

options = setDefault(options,'eliminateDelay', true);
neuralChannels = options.neuralChannels;
neuralChannelsHLFP = options.neuralChannelsHLFP;
multsOrThresholds = options.multsOrThresholds;
useFixedThresholds = options.useFixedThresholds;
arraySpecificThresholds = options.arraySpecificThresholds;
withinSampleXval = options.withinSampleXval;
blocksToFit = options.blocksToFit;
useVFB = options.useVFB;
usePCA = options.usePCA;
checkOption(options,'numPCsToKeep','numPCsToKeep must be defined if usePCA used','usePCA');
normalizeTx = options.normalizeTx;
txNormFactor = options.txNormFactor;
normalizeHLFP = options.normalizeHLFP;
hLFPNormFactor = options.hLFPNormFactor;
showFigures = options.showFigures;
%showFigures = false;
addCorrectiveBias = options.addCorrectiveBias;
ridgeLambda = options.ridgeLambda;

Toptions.neuralOnsetAlignment = options.neuralOnsetAlignment;
Toptions.useAcaus = options.useAcaus;
Toptions.useSqrt = options.useSqrt;
Toptions.tSkip = options.tSkip;
Toptions.useDwell = options.useDwell;
Toptions.delayMotor = options.delayMotor;
Toptions.dt = options.binSize;
Toptions.isThresh = options.useFixedThresholds;
Toptions.hLFPDivisor = options.hLFPDivisor;
Toptions.kinematicVar = options.kinematics;
Toptions.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth;
Toptions.excludeLiftoffs = true;
Toptions.normalizeRadialVelocities = options.normalizeRadialVelocities;
Toptions.rescaleSpeeds = options.rescaleSpeeds;
Toptions.eliminateDelay = options.eliminateDelay;
Toptions.minimumTargetAcquireMS = options.minimumTargetAcquireMS; %

%BJ: possible functional change from what was (silently) happening previously:
% options.eliminateFailures was getting overwritten by "true" downstream
% in onlineTfromR because that field wasn't manually copied from
% options. Is this mechanism a deliberate "protection" of Toptions from filter
% build options that happen to have the same name, or an oversight/design fail?


try
    Toptions.eliminateFailures = options.eliminateFailures;  %BJ: if specified in filter build, use that
catch
    Toptions = setDefault(Toptions,'eliminateFailures',true,true);  %BJ: otherwise, set default as before
    %(NOTE: setDefault was previously overriding options.eliminateFailures during filter build, even if it was specified there, b/c wasn't transferred from options to Toptions before passing Toptions into filterSweep)
end

%if RTI field exists, also copy RTI fields over:
if isfield(options, 'RTI'),
    Toptions.RTI = options.RTI;
end

streams = loadAllStreams(sessionPath, blocksToFit);

if isfield(options,'savedModel')
    s = options.savedModel;
    disp('Using specified Kalman state matrices');
end

%% CP20141008 - this is no longer participant specific
% % participant-sensitive paramaters
% numSpikeChannels = size(streams{1}.neural.minAcausSpikeBand,3);
% numHLFPChannels = size(streams{1}.neural.HLFP,3);
% numChans = numSpikeChannels + numHLFPChannels;
numSpikeChannels = double(DecoderConstants.NUM_SPIKE_CHANNELS);
numHLFPChannels = double(DecoderConstants.NUM_HLFP_CHANNELS);
numChans = double(DecoderConstants.NUM_CONTINUOUS_CHANNELS);
truefalse = false([numChans,1]);
if options.useTx,
    truefalse(neuralChannels) = true; % BJ: setting desired subset of TX channels to true only if options.useTx.
end
if options.useHLFP,
    % sensitive paramater
    truefalse(numSpikeChannels+neuralChannelsHLFP) = true; % BJ: setting desired subset of LFP channels to true if options.useHLFP.
end

actives = find(truefalse);

if ~isempty(arraySpecificThresholds)
    threshLabels = sprintf('%g,',arraySpecificThresholds);
    threshLabels = threshLabels(1:end-1);
else
    threshLabels = arrayfun(@num2str,multsOrThresholds,'uniformoutput',false);
end

cellRange = options.minChannels:min(length(actives),options.maxChannels);
clear models m;



%% (need thresholds in order to properly smooth)
for rmsMultN = 1:length(multsOrThresholds)
    
    %% reload streams on every iteration (if not already loaded above). yeah it's dumb, but, memory
    if ~exist('streams','var') || isempty(streams)
        streams = loadAllStreams(sessionPath, blocksToFit);
    end
    
    if ~useFixedThresholds
        %% not using fixed thresholds, so we need to calculate thresholds
        %% based on an rms multiplier
        %% do this using the first stream passed in
        rmsvals = channelRMS(streams{1}.neural);
        actualThreshVals = multsOrThresholds(rmsMultN) * rmsvals;
        Toptions.isThresh = true;
    else
        %% one threshold per array?
        if ~isempty(arraySpecificThresholds)
            actualThreshVals = zeros(1, numel(arraySpecificThresholds) * double(DecoderConstants.NUM_CHANNELS_PER_ARRAY));
            for nast = 1:numel(arraySpecificThresholds)
                actualThreshVals((1:double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)) + ...
                    (nast-1) * double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)) = arraySpecificThresholds(nast);
            end
        else
            actualThreshVals = repmat(multsOrThresholds(rmsMultN), [1 size(streams{1}.neural.minAcausSpikeBand,3)]);
        end
    end
    
    if rmsMultN == 1
        firstRun = true;
    else
        firstRun = false;
    end
    Toptions.rmsMultOrThresh = actualThreshVals;
    
    parseOptions.gaussSD = Toptions.gaussSmoothHalfWidth;
    parseOptions.useHalfGauss = true;
    parseOptions.normalizeKernelPeak = false;
    parseOptions.thresh = Toptions.rmsMultOrThresh;
    parseOptions.useFixedThresholds = useFixedThresholds;
    parseOptions.neuralChannels = options.neuralChannels;
    parseOptions.neuralChannelsHLFP = options.neuralChannelsHLFP;
    if isfield(options, 'RTI'),
        parseOptions.useRTI = options.RTI.useRTI;
    end
    
    if options.neuralOnsetAlignment
        Rtmp = [];
        %% first combine the streams, then run FA, then separate the results across streams
        for nb = 1:length(blocksToFit)
            Rtmp(nb).minAcausSpikeBand = squeeze(streams{nb}.neural.minAcausSpikeBand)';
        end
        processed = runFAonRstruct(Rtmp,...
            struct('useChannels',options.neuralChannels,...
            'blockNums',options.blocksToFit,...
            'thresholds',actualThreshVals));
        clear Rtmp;
        factsToKeep = 2;
        for nb = 1:length(blocksToFit)
            streams{nb}.neural.xorth = zeros(size(streams{nb}.neural.minAcausSpikeBand,1), factsToKeep);
            for nf = 1:factsToKeep
                tmpa=resample(processed.seqTrain(nb).xorth(nf,:),processed.binWidth,1);
                tmpt = length(tmpa);
                streams{nb}.neural.xorth(1:tmpt,nf) = tmpa;
            end
        end
    end
    
    R = [];
    for nb = 1:length(blocksToFit)
        [R1, taskDetails, ~, smoothKernel] = onlineR(streams{nb}, parseOptions);
        
        %% quick check for MINO
        R1 = removeMINO(R1,taskDetails);
        R = [R(:);R1(:)];
    end
    clear streams;
    
    R = remapKinematicData(R, options);  %BJ: this appears to guess and 
                       %rearrange kinematic dimensions if they're unknown?
    
    %% BJ: RTI parsing happens here
    if isfield(options, 'RTI')  &&  options.RTI.useRTI,  
        useRTI = true;
        
        % do RTI if specified, chopping up Rs into trials with target
        % locations defined by clicks; recompute "cursorPosition" relative
        % to those target positions given decoded velocity data (since
        % cursorPositions might be bogus relative to BCI user's actual
        % operational space; e.g. tablet)
                
        %I don't know how to get the click thresholds for specific blocks,
        %so I'll just use the one saved in modelConstants for now and assume 
        %it's not getting changed much from block to block (SELF: see if I 
        %can get this out of stream too)
        options.RTI.clickThreshold = modelConstants.sessionParams.hmmClickLikelihoodThreshold;            
        
        %obtain and save RTI-reparsed R structs (including both moving 
        %and click data) so they can be used to create D in click decoder 
        %build quickly, without re-parsing same data
        RTIdata.R_moveAndClick = relabelDataUsingRTI(R, options.RTI, options.filterNum, blocksToFit);  
        
        %also keep tx thresholds so can reuse them for click decoder (instead of recomputing them from same data.) (WARNING: this only works if only 1 threshold value was specified in input!)
        RTIdata.actualThreshVals = actualThreshVals; 
        
        %save R_moveAndClick for use by click decoder build (inclues click periods),
        %but for kin build, only keep the moving-toward-target part of R:
        R = extractMovingR_RTI(RTIdata.R_moveAndClick); 
    else
        useRTI = false;
        RTIdata = [];
        R(1) = []; % first trial is messed up % SDS March 30 2017
        %BJ: can't do this if useRTI because there's only 1 trial per block 
        %and it contains all the data at this stage. (Sergey, is first trial 
        %always messed up if not RTI? Is there a way to fix this in game so 
        %it's not messed up?)
    end
    
    %% now actually run the sweep
    [m, mFull, frs] = runFitTest(firstRun, R, useRTI); % Here's the KEY FUNCTION CALL
    if ~exist('models','var')
        models(1:length(multsOrThresholds),:) = m;
        modelsFull(1:length(multsOrThresholds),:) = mFull;
    end
    models(rmsMultN,:) = m;
    modelsFull(rmsMultN,:) = mFull;
end

if showFigures    
    % ANGULAR ERROR FIGURE  %BJ: should now be accurate for 3D+ (using
    % mean of *absolute* angular error - what the standard deviation of
    % angular error was meant to compute but was inaccurate because
    % angular error distribution was often strongly bimodal)
    figh = figure(20);
    clf;
    valids  = find(summary{1}.maAE(1,:));
    plot(valids,rad2deg(summary{1}.maAE(:,valids))')
    axis('tight')
    xlabel('Min Number of Channels Per Dim.');
    ylabel('Mean of absolute Angular Error (Degrees)')
    legend(threshLabels);
%     ylim([0 90]);
    
    set( figh, 'Name', 'Angular Error Plot');
    
    % BIAS FIGURE
    % Updated Oct 2016 by SDS to plot bias for all dimensions
    figh = figure(21);
    clf;
    colors = lines( numDims );
    for iDim = 1 : numDims
        subplot( numDims,1,iDim );
        plot(valids,summary{1}.biasEachDim(:,valids,iDim), ...
            'Color', colors(iDim,:));
        ylabel( sprintf('Bias Dim%i', iDim ) );
        axis('tight')
        hline(0);
        if iDim == numDims
            xlabel('Min Number of Channels Per Dim.');
        end
    end
    % set(gca,'ylim',[-1 1])
    % legend(threshLabels,'best');
    set( figh, 'Name', 'Bias Plot' );
    % legend(threshLabels,'best');
        
    % ------------------------
    %% Any-d specific figure
    % ------------------------
    % New as of October 2016 -SDS
    numDims = size( summary{1}.decodeR, 3 );
    colors = lines( numDims );
    
    figh = figure(22);
    set( figh, 'Name', 'Correlation Plot' )
    clf;
    % Top subplot: correlation coefficient for each dimension
    axh = subplot(2,1,1); hold on;
    for iDim = 1: numDims
        lineNames{iDim} = sprintf('Dim%i', iDim);
        plot( valids, summary{1}.decodeR(1,valids,iDim), ...
            'Color', colors(iDim,:) );
    end
    % plot mean of these
    plot( valids, summary{1}.meanDecodeR(valids), ...
        'Color', 'k', 'LineWidth', 1.5);
    lineNames{end+1} = 'Mean';
    legend( lineNames, 'Location', 'SouthEast' );
    legend boxoff
    ylabel('Correlation Coefficient')
    axis('tight')
    ylim([0 1]);
    
    % Bottom subplot: hold : move speed ratios
    axh = subplot(2,1,2); hold on;
    for iDim = 1: numDims
        plot( valids, summary{1}.holdMeanSpeedRatioEachDim(1,valids,iDim), ...
            'Color', colors(iDim,:) );
    end
    axis('tight')
    xlabel('Min Number of Channels Per Dim.');
    ylabel('Hold:Move Speed Ratio')
    
    %fTarg figure to confirm filter normalization if using Frank's
    %reparameterization
    if isfield(summary{1}, 'fTarg'),
        figure(23);
%         set(gcf,'Position',[45 547 1277 319]);
        subplot(3,1,1);
        plot(summary{1}.fTarg(:,1), summary{1}.fTarg(:,2), '-o');
        xlabel('Distance');
        ylabel('f_{targ}');
        axis('tight')
        yLimitDefault = get(gca,'YLim');
        ylim([0 yLimitDefault(2)]);
        title('fTarg should be near 1 when far from target.');
        
        subplot(3,1,2);
        hold on
        for iDim=1:numDims
            plot(summary{1}.fTargSingle{iDim}(:,1), ...
                summary{1}.fTargSingle{iDim}(:,2), '-o', 'Color', colors(iDim,:));
        end
        xlabel('Distance');
        ylabel('f_{targ}');
        axis('tight')
        yLimitDefault = get(gca,'YLim');
        ylim([0 yLimitDefault(2)]);
        legend(lineNames);
        title('Separate f_{targ} for each dimension');
        
        subplot(3,1,3);
        hold on;
        plot(summary{1}.pushTimeAxis, summary{1}.avgPushSingle);
        xlabel('Time (s)');
        ylabel('Neural Push');
        title('Neural push for each dimension');
        legend(lineNames);
    end
    
    if numDims > 2
        figure(22); % brings the individual dim correlation plot to center
    end
    
    figure(20); % brings angular error plot into focus

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [m1, m1Full, firingRates] = runFitTest(isFirstRun, allR, useRTI)
        if isFirstRun
            clear m1;
            clear summary;
        end
                
        if Toptions.neuralOnsetAlignment
            switch modelConstants.rig
                case 't6'
                    %% CP: these parameters are optimized for T6 based on t6.2014.07.14
                    %Toptions.minRescaleTimeMS = 300;
                    %Toptions.maxRescaleTimeMS = 750;
                    %% CP: tweaking now that preTrial data is included
                    Toptions.minRescaleTimeMS = 150;
                    Toptions.maxRescaleTimeMS = 900;
                    Toptions.backToCenterShift = 150;
                case 't7'
                    %% CP: these parameters are optimized for T7 based on t7.2014.08.25
                    %Toptions.minRescaleTimeMS = 300;
                    %Toptions.maxRescaleTimeMS = 700;
                    %% CP: tweaking now that pretrial data is included
                    Toptions.minRescaleTimeMS = 1;
                    Toptions.maxRescaleTimeMS = 1000;
                    Toptions.backToCenterShift = 100;
            end
            
            [allR] = alignOpenLoopR(allR,neuralChannels,...
                Toptions.rmsMultOrThresh,blocksToFit, Toptions);
        end
        
        %% split into train and test sets for cross-validation (Xval)
        fitters = true(size(allR));
        if withinSampleXval
            %guys. come on. this skips X trials, in dev it's 4. For center
            %out tasks, that means the test values are all center targets. 
            testIdx     = randperm(length(fitters));
            %fitTrials  = true(size(fitters));
            fitters(testIdx(1:withinSampleXval:end)) = false;
           % fitters(1:withinSampleXval:end) = false;
            testers = ~fitters;
        else
            warning('Cross-validation is not being used. Training data and testing data are the same!')
            % if no cross-validation, make test data same as training data:
            testers = fitters;
        end
        
        %next, allR gets split into training and testing data:
        R_test = allR(testers);
        R_fit = allR(fitters);
                 
        %% Get a T-struct from R-struct (T for "training data"?)
        if Toptions.neuralOnsetAlignment
            allT = openLoopTfromR(allR, Toptions);
            Toptions.prePeak = 500;
            Toptions.postPeak = 500;
            [T,thresholds] = openLoopTfromR(R_fit, Toptions);
            Toptions2 = Toptions;
            % restrict the testing data to around the velocity peak, to avoid the unavoidable angular decoding error for
            % low velocities
            Toptions2.prePeak = 300;
            Toptions2.postPeak = 300;
            [T2,thresholds2] = openLoopTfromR(R_test, Toptions2);
        else
            allT = onlineTfromR(allR, Toptions);
            [T,thresholds] = onlineTfromR(R_fit, Toptions);
            Toptions2 = Toptions;
            [T2,thresholds2] = onlineTfromR(R_test, Toptions2);
        end
        
        % BJ: get firing rates from full T, for plotting data going into 
        % filter build (remain in temporal order):
        firingRates = [allT.Z];
        
        % save holdout data for decoding test
        T2Orig = T2;
        
        normOptions.useTx = options.useTx;
        normOptions.useHLFP = options.useHLFP;
        normOptions.normalizeTx = normalizeTx;
        normOptions.normalizeHLFP = normalizeHLFP;
        normOptions.binSize = options.normBinSize;
        normOptions.thresh = thresholds;
        normOptions.neuralChannels = neuralChannels;
        normOptions.neuralChannelsHLFP = neuralChannelsHLFP;
        normOptions.HLFPDivisor = Toptions.hLFPDivisor;
        normOptions.txNormFactor = txNormFactor;
        normOptions.HLFPNormFactor = hLFPNormFactor;
        normOptions.numOutputDims = double(DecoderConstants.NUM_CONTINUOUS_CHANNELS);
        %        normOptions.numOutputDims = double(size(T(1).Z,1));
        normOptions.usePCA = options.usePCA;
        normOptions.numPCsToKeep = options.numPCsToKeep;
        normOptions.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth;
        normOptions.removePCs = options.removePCs;
        
        %% apply soft normalization if requested
        if normalizeTx > 0 || normalizeHLFP > 0
            % This looks wrong because it enters if either of the normalize__
            % is true, but the normalization values with be 1 if, for example,
            % Tx is 0.
            continuous.clock = [R_fit.clock];
            continuous.minAcausSpikeBand = [R_fit.minAcausSpikeBand];
            continuous.HLFP = [R_fit.HLFP];
            if options.gaussSmoothHalfWidth
                if ~isfield(R_fit,'SBsmoothed');
                    error('filterSweep: should have SBsmoothed field in Rstruct, but its not there')
                    %R_fit = smoothR(R_fit,options.thresh,options.gaussSmoothHalfWidth,true);
                end
                continuous.SBsmoothed = [R_fit.SBsmoothed];
                continuous.HLFPsmoothed = [R_fit.HLFPsmoothed];
            end
            %Z = [T.Z];
            lowDModel = calculateLowDProjection(continuous, normOptions);
            disp('applying soft normalization');
            if size(T(1).Z,1) == 96
                T = applySoftNormToT(T,lowDModel.invSoftNormVals([1:96 193:288]));
                T2 = applySoftNormToT(T2,lowDModel.invSoftNormVals([1:96 193:288]));
                allT = applySoftNormToT(allT,lowDModel.invSoftNormVals([1:96 193:288]));
            else
                T = applySoftNormToT(T,lowDModel.invSoftNormVals);
                T2 = applySoftNormToT(T2,lowDModel.invSoftNormVals);
                allT = applySoftNormToT(allT,lowDModel.invSoftNormVals);
            end
        end
        if normOptions.usePCA
            T=applyPCA(T,lowDModel);
            T2=applyPCA(T2,lowDModel);
            allT=applyPCA(allT,lowDModel);
        end
        
        % TMP hack
        
        
        TX = [T.X];
        TZ = [T.Z];
        if all(TZ(:) == 0)
            beep
            fprintf(2,'WARNING: All training data is zeros. Were NSPs/amps/Central turned on?\n')
            fprintf(2,'         Did you choose the right block(s) to train from?\n')
        end
        fprintf('size Tfit: %g, Ttest: %g\n',length(T),length(T2));
        
        % Smart Dimensionality Inference (added by SDS August 2016)
        % 1. identify unused dimensionality in the kinematic state.
        nullXdims = ~any( TX' );
        liveXdims = ~nullXdims;
        liveXidx = find( liveXdims );
        % 2. identify position and velocity dimensions
        numDims = floor( numel(liveXidx)/2 ); % e.g 2D or 3D,
        % So actual dimensions if generated matrix will be 2*numDims+1, for velocity and 1
        posDimsOrig = liveXidx(1:numDims);
        velDimsOrig = liveXidx(numDims+1:2*numDims);
        
        % Channelwise regression
        for nn = 1:length(actives)
            i = actives(nn);
            mdl = LinearModel.fit( double( TX(velDimsOrig,:) )', double( TZ(i,:) )'); % needs double conversion
            pval(nn, :) = (mdl.anova.pValue(1:numDims));  % gets p-values of all channels, separately for each dim
        end
        
        %format data for alpha/beta reparameterization
        if ~isempty(options.alpha) && ~isempty(options.beta)
%             allT = [T(:); T2(:)];  %BJ: allT used to be all out of order,
%             and had different-sized snippets of different trials. Now,
%             all in temporal order and possibly more uniform trial
%             snippets.
            targPos = [];
            rEpochs = zeros(length(allT),2);
            eIdx = 1;
            for t=1:length(allT)
                nBins = size(allT(t).X,2);
                targPos = [targPos; repmat(allT(t).posTarget',nBins,1)];
                rEpochs(t,:) = [eIdx, eIdx+nBins-1];
                eIdx = eIdx + nBins;
            end
            
            cursPos = [allT.X]';
            cursPos = cursPos(:,1:numDims);
            targPos = targPos(:,1:numDims);  %BJ: this had to be done for targPos too to make dimensions line up correctly (I think they're correct now, anyway!)
            
            rp.rtBins = 10;
            rp.farDistFraction = 0.7;
            rp.posErr = targPos - cursPos;
            rp.targDist = sqrt(sum(rp.posErr.^2,2));
            rp.maxDist = prctile(rp.targDist(rEpochs(:,1)),75);
            rp.allTZ = [allT.Z]';
            rp.rIdx = expandEpochIdx([rEpochs(:,1)+rp.rtBins, rEpochs(:,2)]);
        end
        
        % Loops across increasing number of channels used for decode.
        for nCells = cellRange;
            %selects channels by p-value. Note this is *max* num cells per dim.
            % so if nCells is 2, and it's a 3D task, it'll return between 2 and
            % 6 channels.
            [~, chIdx] = sort(pval);
            tmp = chIdx(1:nCells, :);
            chSortInds = unique(tmp(:));
            
            chSortList = actives(chSortInds);
            chSortListCurr = chSortList;
            if ~exist('s','var')
                s.A = [];
                s.W = [];
            end
            
            Tfit = T;
            T2fit = T2;
            if normOptions.usePCA
                [Tfit.Z] = deal(Tfit.ZPCA);
                [T2fit.Z] = deal(T2fit.ZPCA);
                chSortListCurr = 1:nCells;
            end
            
            fitOpts =struct('ridgeLambda',ridgeLambda);
            if isfield( options, 'posSubtraction' ) && options.posSubtraction
                % SDS June 2017: Adding position feedback subtraction
                % possibility, similar to what is done in rigC's modelType
                % 13 (fitKalmanVPFB2DZ.m from NPSL rigC codebase).
                % This is intended for a one-off experiment for Sergey's
                % cursor position subtraction project.
                model1 = fitKalmanVposSubtraction(Tfit, chSortListCurr, s.A, s.W, fitOpts);
                model1Full = fitKalmanVposSubtraction([Tfit(:);T2fit(:)], chSortListCurr, s.A, s.W, fitOpts); 
            elseif useVFB % SDS June 2017: I think this is the same as fitKalmanV.. why?! Chethan at some point
                % copied some fitKalmanV changes to fitKalmnVFB, maybe he
                % overwrote the distinctive parts? Though it seems like we
                % assume zero position uncertainty always anyhow...
                model1 = fitKalmanVFB(Tfit, chSortListCurr, s.A, s.W, fitOpts); % A and W clamped
                model1Full = fitKalmanVFB([Tfit(:);T2fit(:)], chSortListCurr, s.A, s.W, fitOpts); % A and W clamped
            else
                model1 = fitKalmanV(Tfit, chSortListCurr, s.A, s.W, fitOpts);
                model1Full = fitKalmanV([Tfit(:);T2fit(:)], chSortListCurr, s.A, s.W, fitOpts);
            end
            
            %%
            %normalize according to alpha (smoothing) and beta (gain) parameters
            if ~isempty(options.alpha) && ~isempty(options.beta)
                %first, we compute the actual gain and smoothing implied by the Kalman
                %matrices
                neural = bsxfun(@plus, rp.allTZ, -model1Full.C(:,end)');
                K = model1Full.K(2:2:(numDims*2),:);
                A = model1Full.A(2:2:(numDims*2),2:2:(numDims*2));
                C = model1Full.C(:,2:2:(numDims*2));
                
                %alpha and beta are the smoothing and gain parameters for
                %model1Full, and D is a normalized version of K that produces
                %vectors of unit magnitude (on average).
                [ alpha, beta, D ] = reparamKalman( K, A, C, rp.posErr(rp.rIdx,:), neural(rp.rIdx,:), ...
                    [rp.farDistFraction * rp.maxDist, rp.maxDist]);
                
                %fit the (total) neural push as a function of distance from 
                %the target, for plotting and for single DoF norm
                decVectors = neural*D;
                fTarg = fitFTarg(rp.posErr(rp.rIdx,:), decVectors(rp.rIdx,:), rp.maxDist, 12);
                summary{1}.fTarg = fTarg;
                
                %fit individual fTarg functions for each dimension
                for t=1:numDims
                    summary{1}.fTargSingle{t} = fitFTarg(rp.posErr(rp.rIdx,t), ...
                        decVectors(rp.rIdx,t), rp.maxDist, 12);
                end
                
                %collect info about each dimension's push as a function of 
                %time (for later plotting): 
                timeWindow = [0 150];
                tmpTraj = cell(numDims,1);
                for trlIdx=1:size(rEpochs,1)
                    loopIdx = (rEpochs(trlIdx,1)+timeWindow(1)):(rEpochs(trlIdx,1)+timeWindow(2));
                    if loopIdx(end)>size(rp.posErr,1)
                        break;
                    end
                    targSigns = sign(rp.posErr(rEpochs(trlIdx,1),:));
                    for t=1:numDims
                        tmpTraj{t} = [tmpTraj{t}; decVectors(loopIdx,t)'*targSigns(t)];
                    end
                end
                summary{1}.pushTimeAxis = (timeWindow(1):timeWindow(2))*T(1).dt/1000;
                for t=1:numDims
                    summary{1}.avgPushSingle(t,:) = mean(tmpTraj{t});
                end
                
                %do single degree of freedom normalization, which attempts to make
                %the gain of every dimension the same
                if options.singleDOFNorm
                    fTargVectors = bsxfun(@times, rp.posErr, interp1(fTarg(:,1), ...
                        fTarg(:,2), rp.targDist)./rp.targDist);
                    fTargVectors(isinf(fTargVectors))=0;
                    tmpDV = decVectors(rp.rIdx,:);
                    tmpFTV = fTargVectors(rp.rIdx,:);
                    scaleFactors = zeros(1, numDims);
                    for n=1:numDims
                        scaleFactors(n) = regress(tmpDV(:,n), tmpFTV(:,n));
                    end
                    
                    D = bsxfun(@times, D, 1./scaleFactors);
                end
                
                %now we enforce the desired alpha and beta parameters by first
                %computing what M1 and M2 should be, and then modifying A and K
                %to realize them.
                M1 = zeros(numDims);
                for n=1:numDims
                    M1(n,n)=options.alpha;
                end
                
                M2 = (options.beta/1000)*(1-options.alpha)*D';
                
                fullK = model1Full.K;
                fullK(2:2:(numDims*2),:) = M2;
                
                A = (eye(numDims)-fullK(2:2:(numDims*2),:)*model1Full.C(:,2:2:(numDims*2)))\M1;
                fullA = model1Full.A;
                for n=1:numDims
                    fullA(2*n,2:2:(numDims*2)) = A(n,:);
                end
                
                model1Full.A = fullA;
                model1Full.K = fullK;
                
                %for later interpretation
                model1.alpha = options.alpha;
                model1.beta = options.beta;
                
                %The code below checks that the application of this Kalman filter has the same effect as
                %first order smoothing with the alpha and beta parameters.
%                             kOut = zeros(size(neural,1),21);
%                             for k=2:size(neural,1)
%                                 vPrior = model1Full.A*kOut(k-1,:)';
%                                 kOut(k,:) = vPrior + model1Full.K*(neural(k,:)'-model1Full.C*vPrior);
%                             end
%                 
%                             lnB = (options.beta/1000)*(1-options.alpha);
%                             lnA = [1, -options.alpha];
%                             kOut2 = filter(lnB,lnA,neural*D);
%                 
%                             figure
%                             hold on
%                             plot(kOut(:,2)*1000);
%                             plot(kOut2(:,1)*1000,'--r');
%                             title('Red and blue lines should overlap');
            end
            
            %% for this sweep, model.A and model.W will never change again
            % so just save them down so they are not recalculated every time
            s.A = model1Full.minDim.A; % SDS August 2016: recycle the lower-dim version
            s.W = model1Full.minDim.W; % SDS August 2016: recycle the lower-dim version
            
            model1.thresholds = single(thresholds);
            model1.useAcaus = Toptions.useAcaus;
            %% default decoder type:
            model1.decoderType = DecoderConstants.DECODER_TYPE_VFBSSKF;
            if normalizeTx > 0 || normalizeHLFP > 0
                model1.decoderType = DecoderConstants.DECODER_TYPE_VFBNORMSSKF;
                model1.invSoftNormVals = lowDModel.invSoftNormVals;
                model1.projector = lowDModel.projector;
                model1.pcaMeans = lowDModel.pcaMeans;
            end
            if options.usePCA
                model1.decoderType = DecoderConstants.DECODER_TYPE_PCAVFBSSKF;
                model1.invSoftNormVals = lowDModel.invSoftNormVals;
                model1.projector = lowDModel.projector;
                model1.pcaMeans = lowDModel.pcaMeans;
            end
            
            % use the non-normalized T2 for decoding testing
            [stat,decodeReg,Tmod] = testDecode(T2Orig, model1, useRTI, options.eliminateFailures);  %BJ: adding (optional) useRTI input to testDecode
            
            if isempty(stat)
                disp('filterSweep: output of testDecode is empty. Err....?');
                %             keyboard
            else
                stats{1}(rmsMultN,nCells) = stat;
                regX = [decodeReg.X];
                
                
                %% reduce how often these plots come up...
                %           if stat.numDims == 2  % uncomment to stp plotting circular angles
                % BJ: should now be fine for 3D+ as well.
                if ~mod(nCells,5) && showFigures
                    figure(rmsMultN+30);
                    clf;
                    circ_plot([stats{1}(rmsMultN,nCells).angleError]', 'hist');
                end
                %         end
                summary{1}.mAE(rmsMultN,nCells) = circ_mean(stats{1}(rmsMultN,nCells).angleError');  %BJ: error angles can be + or -; what we really want (as an assessment of the mean of the angular errors) is the mean of the absolute value of the angular errors (summary{1}.maAE below) (otherwise, might average out to 0 even when lots of large deviations from VtoT)
                summary{1}.sAE(rmsMultN,nCells) = circ_std(stats{1}(rmsMultN,nCells).angleError');   %BJ: standard deviation of the angular errors is incorrect when the AE values are bimodal; maAE does what this was supposed to do
                summary{1}.maAE(rmsMultN,nCells) = circ_mean(abs(stats{1}(rmsMultN,nCells).angleError)'); %BJ: THIS is the metric we should be plotting downstream!
                
                % Bias is reported for each velocity dimension individually
                summary{1}.biasEachDim(rmsMultN,nCells,:) = mean(regX(decodeReg(1).velDims,:),2);
                % below two lines are obsolete, keeping in case they're used
                % somewhere I don't know about - SDS October 2016
                %             summary{1}.biasX(rmsMultN,nCells) = mean(regX(decodeReg(1).velDims(1),:));
                %             summary{1}.biasY(rmsMultN,nCells) = mean(regX(decodeReg(1).velDims(2),:));
                
                % New statistics for high dimensional decoding
                summary{1}.decodeR(rmsMultN,nCells,:) = stats{1}(rmsMultN,nCells).decodeR;
                summary{1}.meanDecodeR(rmsMultN,nCells) = stats{1}(rmsMultN,nCells).meanDecodeR;
                summary{1}.holdMeanSpeedRatioEachDim(rmsMultN,nCells,:) = ...
                    mean( stats{1}(rmsMultN,nCells).holdMeanSpeedRatioEachDim, 2 ); % averages across test trials
            end
            
            %% make sure a smoothing kernel is defined
            model1.smoothingKernel= [1; zeros([DecoderConstants.MAX_KERNEL_LENGTH-1 1])];
            if exist('smoothKernel','var')
                model1.smoothingKernel = smoothKernel;
            else
                disp('no smoothing kernel saved');
            end
            
            %% add a corrective bias if requested  (%BJ: this seems like an odd way of estimating bias - goes by # of decoded trials for each direction?)
            if addCorrectiveBias
                DT1 = kalmanIterative(model1,T,true);
                DT2 = kalmanIterative(model1,T2,true);
                DTtot = [DT1(:);DT2(:)];
                
                %% group the Rstruct by trial type
                DTspl = splitRByTrajectory(DTtot);
                
                velBiasTot = [0;0];
                %% for each direction
                numDirs = numel(DTspl);
                for ndir = 1:numDirs
                    %% how many decoded trials for this direction?
                    trialsThisDir = numel(DTspl(ndir).R);
                    %% figure out the bias for this direction
                    b = mean([DTspl(ndir).R.xk]');
                    b=b(3:4);
                    velBiasTot = velBiasTot + b(:) / trialsThisDir / numDirs;
                end
                if ndir < 16
                    fprintf('filterSweep: warning - no trials for a given direction..?\n');
                end
                %% bias correction is inversion of calculated bias
                model1.velBias = -velBiasTot;
            end
            
            
            m1(nCells) = model1;
            %% also save down the full model
            m1Full(nCells) = model1;
            modelFields = fields(model1Full);
            for nf = 1:numel(modelFields)
                m1Full(nCells).(modelFields{nf}) = model1Full.(modelFields{nf});
            end
        end

        summaryOut = summary; % Added SDS Feb 2017, this outputs the offline decode accuracy
        summaryOut.parseOptions = parseOptions;
        summaryOut.Toptions = Toptions;
        summaryOut.options = options;
        summaryOut.normOptions = normOptions;
        % results. Useful for running parameter sweeps
        % offline using the same build stack.
    end
end

