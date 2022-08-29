function [RTIdata, options] = buildFilterDialog(streams, options, prompt)


global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

global CURRENT_FILTER_NUMBER

if exist('prompt','var') && isfield(prompt,'startingFilterNum')
    CURRENT_FILTER_NUMBER = str2num(prompt.startingFilterNum);
elseif exist('options','var') && isfield(options,'startingFilterNum')
    CURRENT_FILTER_NUMBER = options.startingFilterNum;
else
    if isempty(CURRENT_FILTER_NUMBER)
        CURRENT_FILTER_NUMBER = 1;
    else
        CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
    end
end

if exist('streams','var') && ~isempty(streams)
    disp('buildFilterDialog: warning - you are passing in streams, but bFD will not pass them forward'); 
end

if ~exist('options','var')
    %% hard-coded options
    options.withinSampleXval = 9;
    options.kinematics = 'refit';
    options.useAcaus = true;
    options.useSqrt = false;
    options.normBinSize = 50;
    options.txNormFactor = options.normBinSize*0.03;
    options.hLFPNormFactor = options.normBinSize*0.03;
    options.usePCA = false;
    options.showFigures = true;
    options.neuralOnsetAlignment = false;
    options.minimumTargetAcquireMS = 100; % SDS June 2017; removes ultrashort trials like if target and cursor both at center

	% all channels
	options.neuralChannels = [1:192];
	options.neuralChannelsHLFP = [1:192];

end


if ~exist('prompt','var')
    %% options that are prompted
    prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
    prompt.blocksToFit = '';
    prompt.binSize = '15';
    prompt.delayMotor = '0';
    prompt.useVFB = 'false';
    prompt.fixedThreshold = num2str(-50);
    prompt.rmsMultiplier = '';
    prompt.useTx = 'true';
    prompt.useHLFP = 'true';
    prompt.normalizeTx = 'true';
    prompt.normalizeHLFP = 'true';
    prompt.tSkip = '150';
    prompt.useDwell = 'true';
    prompt.hLFPDivisor = '2500';
    prompt.maxChannels = '100';
    prompt.gaussSmoothHalfWidth = '25';
    %	prompt.normalizeRadialVelocities  = '52';
    prompt.normalizeRadialVelocities  = '0';   % hands down
    prompt.neuralOnsetAlignment = 'false';
    prompt.ridgeLambda = '0';
end

promptfields = fieldnames(prompt);
%response=inputdlg(promptfields,'Filter options', 1, struct2cell(prompt));
response=inputdlgcol(promptfields,'Filter options', 1, struct2cell(prompt),'on',2);

if isempty(response)
    disp('filter build canceled')
    return
end

disp('Processing...');

%% get the starting filter num
startingFilterNum = str2num(response{1});

for nn=2:length(response)
    options.(promptfields{nn}) = str2num(response{nn});
end

options = setDefault(options,'arraySpecificThresholds',[],false);

%% if Pixels are the units, undo the scaling that is by default performed for meters.
% BJ: speed of 1 seems correct if pixels true, but 5000+ if pixels false.
% not sure why W is having this effect? 
if isfield(options, 'pixels') && options.pixels,
    options.savedModel.W = options.savedModel.W ./ (2.5e-4)^2;
end

%% must have passed in some blocks to fit off of
if isempty(options.blocksToFit)
    error(['buildFilterDialog: did you mean to specify blocks to fit?']);
end

%% arraySpecificThresholds should be a cell array of vectors
if ~isempty(options.arraySpecificThresholds) && ~iscell(options.arraySpecificThresholds)
    options.arraySpecificThresholds = {options.arraySpecificThresholds};
end

%% set some defaults
options = setDefault(options,'useSqrt',false);
options = setDefault(options,'neuralOnsetAlignment',false);
options = setDefault(options,'addCorrectiveBias',false);
options = setDefault(options,'fixedThreshold',[]);
options = setDefault(options,'rescaleSpeeds',false);
options = setDefault(options,'numPCsToKeep',20);
options = setDefault(options,'minChannels',1);
options = setDefault(options,'removePCs',[]);
options = setDefault(options, 'minimumTargetAcquireMS', 100);

% check for saved kinematics
if isfield(modelConstants.sessionParams, 'savedModelForKinematics')
    savedModelForKinematics = modelConstants.sessionParams.savedModelForKinematics;
    if ~isempty(savedModelForKinematics)
        usingSavedModelForKinematics = true;
        options.savedModel.A = savedModelForKinematics.model.A;
        options.savedModel.W = savedModelForKinematics.model.W;
    else
        usingSavedModelForKinematics = false;
    end
else
    usingSavedModelForKinematics = false;
end

sessionPath = modelConstants.sessionRoot;



if isempty(options.blocksToFit)
    error('buildFilterDialog: maybe you didn''t specify the blocks to use in your fit?');
end

iFilter=0;
% binWidth sweep

threshSet=[];
%% single fixed threshold
for nn = 1:length(options.fixedThreshold)
    threshSet(end+1).multsOrThresholds = options.fixedThreshold(nn);
    threshSet(end).useFixedThresholds=true;
    threshSet(end).arraySpecificThresholds = [];
end

%% per-array fixed threshold (cell array of vectors, each vec has one element per array)
for nn = 1:length(options.arraySpecificThresholds)
    threshSet(end+1).multsOrThresholds = 1;
    threshSet(end).useFixedThresholds=true;
    threshSet(end).arraySpecificThresholds = options.arraySpecificThresholds{nn};
end

%% rms multiplier
for nn = 1:length(options.rmsMultiplier)
    threshSet(end+1).multsOrThresholds = options.rmsMultiplier(nn);
    threshSet(end).useFixedThresholds=false;
    threshSet(end).arraySpecificThresholds = [];
end

if isfield(options, 'RTI') && options.RTI.useRTI,
    useRTI = true;  %BJ: shortcut for the above line
else
    useRTI = false;
end

for b = 1 : numel(options.binSize)
for nsmoothsize = 1:length(options.gaussSmoothHalfWidth)
for ndelay = 1:length(options.delayMotor)
for nthreshold = 1:length(threshSet)
for nradialvel = 1:length(options.normalizeRadialVelocities)
    iFilter = iFilter+1;
    filterNum = startingFilterNum + iFilter - 1;

    optionsCur = options;
    optionsCur.binSize = options.binSize(b);
    optionsCur.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth(nsmoothsize);
    optionsCur.delayMotor = options.delayMotor(ndelay);
    optionsCur.normalizeRadialVelocities = options.normalizeRadialVelocities(nradialvel);
    optionsCur.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
    optionsCur.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
    optionsCur.arraySpecificThresholds= threshSet(nthreshold).arraySpecificThresholds;
    optionsCur.filterNum = filterNum; %added by BJ for relabelDataUsingRTI figure saving
    
    [models, modelsFull, sumOut, RTIdata, frs] = filterSweep(sessionPath,optionsCur);
    
    if length(optionsCur.multsOrThresholds) > 1
        reply = input('What threshold value? ', 's');
        
        thresh = str2num(reply);
        threshInd = find(optionsCur.multsOrThresholds == thresh);
        if isempty(threshInd)
            error(sprintf('Sorry I couldnt find threshold %s : %g',reply,thresh));
        end
    else
        threshInd = 1;
        thresh=optionsCur.multsOrThresholds(threshInd);
    end

    reply2 = input('How many channels? ', 's');
    numChannels = str2num(reply2);
    if isempty(numChannels) || numChannels<1 || numChannels > size(models,2)
        error(sprintf('Sorry I couldnt understand %s : %g',reply,numChannels));
    end
    
    %% actually save from the "modelsFull" variable
    %model = models(threshInd,numChannels);
    model = modelsFull(threshInd,numChannels);

    %%
    %potentially orthogonalize the chosen decoder to trial-averaged
    %dimensions occuring in other blocks
    if isfield(options, 'orthoBlocks') && ~isempty(options.orthoBlocks)
        addpath(genpath([modelConstants.sessionRoot modelConstants.projectDir '/' modelConstants.codeDir ...
            modelConstants.analysisDir 'Frank']));
        streams = loadAllStreams(sessionPath, options.orthoBlocks);
        R = [];
        for nb = 1:length(options.orthoBlocks)
            [R1, taskDetails, ~, smoothKernel] = onlineR(streams{nb}, sumOut.parseOptions);

            %% quick check for MINO
            R1 = removeMINO(R1,taskDetails);
            R = [R(:);R1(:)];
        end
        clear streams
          
        [allT, thresholds] = onlineTfromR(R, sumOut.Toptions);
        
        continuous.clock = [R.clock];
        continuous.minAcausSpikeBand = [R.minAcausSpikeBand];
        continuous.HLFP = [R.HLFP];
        if sumOut.options.gaussSmoothHalfWidth
            continuous.SBsmoothed = [R.SBsmoothed];
            continuous.HLFPsmoothed = [R.HLFPsmoothed];
        end
        lowDModel = calculateLowDProjection(continuous, sumOut.normOptions);
        disp('applying soft normalization');
        if size(allT(1).Z,1) == 96
            allT = applySoftNormToT(allT,lowDModel.invSoftNormVals([1:96 193:288]));
        else
            allT = applySoftNormToT(allT,lowDModel.invSoftNormVals);
        end
        
        %get trial condition numbers based on target positions
        tPos = horzcat(allT.posTarget)';
        centerTargIdx = find(all(tPos==0,2));
        nDimOriginal = size(tPos,2);
        if centerTargIdx(1)==1
            removeFirstTrial = true;
            centerTargIdx(centerTargIdx==1) = 2;
        else
            removeFirstTrial = false;
        end
        
        tPosAug = [tPos, zeros(size(tPos,1),1)];   
        tPosAug(centerTargIdx,1:nDimOriginal) = tPos(centerTargIdx-1,:);
        tPosAug(centerTargIdx,end) = 1;
        [targList, ~, targIdx] = unique(tPosAug, 'rows');
        
        if removeFirstTrial
            targIdx = targIdx(2:end);
            allT = allT(2:end);
        end
        
        %compute trial-averaged activity matrix
        spikeMat = horzcat(allT.Z)';
        trigIdx = 1;
        for x=2:length(allT)
            trigIdx = [trigIdx, trigIdx(end)+length(allT(x-1).clock)];
        end
        concatDat = triggeredAvg( spikeMat, trigIdx, [0, 100] );
        
        %compute trial-averages
        trlAvg = cell(size(targList,1),1);
        for x=1:size(targList,1)
            trlAvg{x} = squeeze(mean(squeeze(concatDat(targIdx==x,:,:)),1));
        end
        
        %plot trial-averaged decoder output applied to each trial
        colors = hsv(size(targList,1))*0.8;
        dimNames = {'Dim 1','Dim 2'};
        figure('Position',[481   346   600   278]);
        for dimIdx=1:2
            subplot(1,2,dimIdx);
            hold on; 
            
            kIdx = dimIdx*2;
            for x=1:length(trlAvg)
                neural = bsxfun(@plus, trlAvg{x}, -model.C(:,end)');
                plot(trlAvg{x}*model.K(kIdx,:)','Color',colors(x,:));
            end
            xlim([1 size(trlAvg{x},1)]);
            xlabel('Time (15 ms bins)');
            ylabel([dimNames{dimIdx} ' Decoder Output']);
        end
        
        %PCA
        allAvgNeural = vertcat(trlAvg{:});
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(allAvgNeural);
        
        %orthogonalize decoding matrix
        topN = 6;
        projCoef = model.K * COEFF;
        orthoK = model.K - (COEFF(:,1:topN) * projCoef(:,1:topN)')';
        
        %plot orthogonalized decoder output for comparison
        figure('Position',[481   346   600   278]);
        for dimIdx=1:2
            subplot(1,2,dimIdx);
            hold on; 
            
            kIdx = dimIdx*2;
            for x=1:length(trlAvg)
                neural = bsxfun(@plus, trlAvg{x}, -model.C(:,end)');
                plot(trlAvg{x}*orthoK(kIdx,:)','Color',colors(x,:));
            end
            xlim([1 size(trlAvg{x},1)]);
            xlabel('Time (15 ms bins)');
            ylabel([dimNames{dimIdx} ' Decoder Output']);
        end
        
        %use ortho decoder
        model.K = orthoK;
    end
    
    %% insert velocity distribution for biaskiller
    if strcmp(modelConstants.rig, 't7') %TODO: does this need to be generalized for east coast or something?
        flDir = [sessionPath modelConstants.dataDir 'FileLogger/'];
        blockNum = optionsCur.blocksToFit(1);
        R=onlineR(loadStream([flDir num2str(blockNum) '/'], blockNum));
        model.blockVelocityMagnitudes = calcBKVelocities(R, model, options.binSize);
        clear R;
    end

    
    %% if meansTrackingInitial is not defined, just set it to the bias term
    if ~isfield(model,'meansTrackingInitial')
        model.meansTrackingInitial = double(model.C(:,end)) / double(model.dtMS); % updated from col 5 to col end
        model.meansTrackingInitial = model.meansTrackingInitial(:);
        if isfield(model,'invSoftNormVals')
            isnvDefined = find(model.invSoftNormVals);
%            isnvDefined = find(model.invSoftNormVals([1:96 193:288]));
            model.meansTrackingInitial(isnvDefined) = model.meansTrackingInitial(isnvDefined) ./ double(model.invSoftNormVals(isnvDefined));
        end
    end
    
    model.hLFPDivisor = optionsCur.hLFPDivisor;
	models = modelsFull;    %BJ: why are we returning "models" from filtersweep and then overwriting it with modelsFull?
    
    blockStr = sprintf('%03g_',optionsCur.blocksToFit);
    filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
    %% output filename for filter
    fn = sprintf('%03g-blocks%s-thresh%g-ch%g-bin%gms-smooth%gms-delay%gms',filterNum,blockStr(1:end-1),thresh,numChannels, optionsCur.binSize,optionsCur.gaussSmoothHalfWidth,optionsCur.delayMotor);
    if usingSavedModelForKinematics
        fn = [fn '-savedKinematics'];
    end
    
    if useRTI,
        fn = [fn '-RTI'];
    end

    disp(['saving filter : ' fn]);
    save([filterOutDir fn '.mat'],'model','modelsFull','options','optionsCur');
    %save([filterOutDir fn '.mat'],'model','models','options','optionsCur');
    
    figOutDir = [modelConstants.sessionRoot modelConstants.analysisDir 'FilterBuildFigs/'];
    if ~exist(figOutDir,'dir')
        mkdir(figOutDir);
    end
    if options.showFigures
        figure(20)
        saveas(figure(20),sprintf('%s%03g-sweep.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-sweep.png',figOutDir,filterNum));
        figure(21)
        saveas(figure(21),sprintf('%s%03g-bias.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-bias.png',figOutDir,filterNum));   
        figure(23)
        saveas(figure(23),sprintf('%s%03g-fTarg.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-fTarg.png',figOutDir,filterNum));
%         close all
    end

end
end
end
end
end

%BJ: need to save smoothKernel for HMM build if RTI (there might be a better way...)  
if useRTI,
    options.smoothingKernel = modelsFull(end).smoothingKernel;  
end

%Plot final filter's PDs:
% filterBaselineDim = size(model.minDim.C,2);  %BJ: assuming last dimension of C always stores baseline rates
% filterBaselines = model.minDim.C(:,filterBaselineDim);
figure; subplot(2,2,1)
filterPDs = model.minDim.C(:,model.reducedVelDims);
plotPDs(filterPDs, 1:size(model.C,1))
title(['FilterNum = ' num2str(filterNum)])
%also show firing rates of all channels in filter (only from segments that 
%went into filter build; trials are parsed in R, firing rates are extracted 
%in onlineTfromR; then trials are concatenated together to make frs).
subplot(2,1,2)
unitsInFilter = find(filterPDs(:,1));  %channel IDs of units in the final filter
frsOfUnitsInFilter = frs(unitsInFilter,:);
imagesc(frsOfUnitsInFilter); colormap(1-gray); colorbar
set(gca, 'ytick', 1:length(unitsInFilter), 'yticklabel', unitsInFilter, 'tickdir', 'out')
title(['Firing rates of all ' num2str(length(unitsInFilter)) ' units in filter'])
print([figOutDir 'PDs_filter' num2str(filterNum, '%03.0f')], '-djpeg')

CURRENT_FILTER_NUMBER = filterNum;
