function [streamsOut] = buildFilterDialog(streams, options,prompt)

global CURRENT_FILTER_NUMBER
if isempty(CURRENT_FILTER_NUMBER)
    CURRENT_FILTER_NUMBER = 1;
else
    CURRENT_FILTER_NUMBER = CURRENT_FILTER_NUMBER + 1;
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
    options.useTx = true;
    options.showFigures = true;

    %% list revised on 2014-03-25
    options.neuralChannels = ...
        [ 32	45    60:64 ...
	  65    66    67    68    69    70    71    72    73    74 ...
          75    76    77    78    79    80    81    82    83    84 ...
          85    86    87    88    89    90    91    92    93    94 ...
          95    96 ...
        ]; 

    %% list revised 2014-03-25
    options.neuralChannelsHLFP = [...
        1:9  ...
	10 11 13:17 19 ...
	20:28 ...
        30:35 37 38 ...
        40:49    ...
        50:59   ...
        60:69    ...
        70:79    ...
        80:89    ...
        90:96];  


	% all channels
%	options.neuralChannels = [1:96];
%	options.neuralChannelsHLFP = [1:96];

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
    prompt.useHLFP = 'true';
    prompt.normalizeTx = 'true';
    prompt.normalizeHLFP = 'true';
    prompt.tSkip = '100';
    prompt.useDwell = 'true';
    prompt.hLFPDivisor = '2500';
    prompt.maxChannels = '100';
    prompt.gaussSmoothHalfWidth = '25';
%	prompt.normalizeRadialVelocities  = '52';
	prompt.normalizeRadialVelocities  = '47';   % hands down
    prompt.neuralOnsetAlignment = 'false';
end

promptfields = fieldnames(prompt);
%response=inputdlg(promptfields,'Filter options', 1, struct2cell(prompt));
response=inputdlgcol(promptfields,'Filter options', 1, struct2cell(prompt),'on',2);

if isempty(response)
    disp('filter build canceled')
    streamsOut = nan;
    return
end
%% get the starting filter num
startingFilterNum = str2num(response{1});

for nn=2:length(response)
    options.(promptfields{nn}) = str2num(response{nn});
end

%% set some defaults
if ~isfield(options,'useSqrt')
    disp('buildFilterDialog: Setting useSqrt to false.');
    options.useSqrt = false;
end

if ~isfield(options,'neuralOnsetAlignment')
    disp('buildFilterDialog: Setting neuralOnsetAlignment to false.');
    options.neuralOnsetAlignment = false;
end

if ~isfield(options,'addCorrectiveBias')
    disp('buildFilterDialog: Setting addCorrectiveBias to false.');
    options.addCorrectiveBias = false;
end

global modelConstants;
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

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




iFilter=0;
% binWidth sweep

threshSet=[];
for nn = 1:length(options.fixedThreshold)
    threshSet(end+1).multsOrThresholds = options.fixedThreshold(nn);
    threshSet(end).useFixedThresholds=true;
end
for nn = 1:length(options.rmsMultiplier)
    threshSet(end+1).multsOrThresholds = options.rmsMultiplier(nn);
    threshSet(end).useFixedThresholds=false;
end

for b = 1 : numel(options.binSize)
for nsmoothsize = 1:length(options.gaussSmoothHalfWidth)
for ndelay = 1:length(options.delayMotor)
for nthreshold = 1:length(threshSet)
    iFilter = iFilter+1;


    optionsCur = options;
    optionsCur.binSize = options.binSize(b);
    optionsCur.gaussSmoothHalfWidth = options.gaussSmoothHalfWidth(nsmoothsize);
    optionsCur.delayMotor = options.delayMotor(ndelay);
    optionsCur.multsOrThresholds = threshSet(nthreshold).multsOrThresholds;
    optionsCur.useFixedThresholds = threshSet(nthreshold).useFixedThresholds;
    
    if ~exist('streams', 'var') || isempty(streams)
        [models, streams, modelsFull] = filterSweep(sessionPath,optionsCur);
    else
        [models, ~, modelsFull]= filterSweep(sessionPath, optionsCur, streams);
    end
    
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
    model.hLFPDivisor = optionsCur.hLFPDivisor;
    
    txtstr = '';
    blockStr = sprintf('%03g_',optionsCur.blocksToFit);
    filterNum = startingFilterNum + iFilter - 1;
    filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
    %% output filename for filter
    fn = sprintf('%03g-blocks%s-thresh%g-ch%g-bin%gms-smooth%gms-delay%gms',filterNum,blockStr(1:end-1),thresh,numChannels, optionsCur.binSize,optionsCur.gaussSmoothHalfWidth,optionsCur.delayMotor);
    if usingSavedModelForKinematics
        fn = [fn '-savedKinematics'];
    end

    disp(['saving filter : ' fn]);
    save([filterOutDir fn '.mat'],'model','models','modelsFull','options','optionsCur');
    
    figOutDir = [modelConstants.sessionRoot modelConstants.analysisDir 'FilterBuildFigs/'];
    if options.showFigures
        figure(20)
        saveas(figure(20),sprintf('%s%03g-sweep.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-sweep.png',figOutDir,filterNum));
        figure(21)
        saveas(figure(21),sprintf('%s%03g-bias.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-bias.png',figOutDir,filterNum));
        close all
    end

end
end
end
end
streamsOut = streams;
