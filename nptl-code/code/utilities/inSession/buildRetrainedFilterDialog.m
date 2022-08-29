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
    options.normalizeTx = true;
    options.normalizeHLFP = true;
    options.normBinSize = 50;
    options.txNormFactor = options.normBinSize*0.03;
    options.hLFPNormFactor = options.normBinSize*0.03;
    options.usePCA = false;
    options.useTx = true;
    options.useHLFP = true;
    options.showFigures = true;

    %% list revised 20130115 based on array histograms from t6.2014.01.10
    options.neuralChannels = ...
        [ 32	45    60:64 ...
	  65    66    67    68    69    70    71    72    73    74 ...
          75    76    77    78    79    80    81    82    83    84 ...
          85    86    87    88    89    90    91    92    93    94 ...
          95    96 ...
        ]; 

    %% list revised 20130115 based on array histograms from t6.2014.01.10
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


    %% fix the state model
    options.savedModel.A = [1 0 15     0      0;
                            0 1 0      15     0;
                            0 0 0.9721 0      0;
                            0 0 0      0.9721 0;
                            0 0 0      0      1];
    options.savedModel.W = [0 0 0         0 0;
                            0 0 0         0 0;
                            0 0 0.0097956 0 0;
                            0 0 0 0.0097956 0;
                            0 0 0         0 0];
                    

	% all channels
%	options.neuralChannels = [1:96];
%	options.neuralChannelsHLFP = [1:96];

end

if ~exist('prompt','var')
    %% options that are prompted
    prompt.startingFilterNum = num2str(CURRENT_FILTER_NUMBER);
    prompt.blocksToFit = '';
    prompt.binSize = '20';
    prompt.delayMotor = '0';
    prompt.useVFB = 'false';
    prompt.fixedThreshold = num2str(-50);
    prompt.rmsMultiplier = '';
    prompt.normalize = 'true';
    prompt.tSkip = '150';
    prompt.useDwell = 'true';
    prompt.hLFPDivisor = '2500';
    prompt.maxChannels = '100';
    prompt.gaussSmoothHalfWidth = '50';
end

promptfields = fieldnames(prompt);
response=inputdlg(promptfields,'Filter options', 1, struct2cell(prompt));

if isempty(response)
    disp('filter build canceled')
    return
end
%% get the starting filter num
startingFilterNum = str2num(response{1});

for nn=2:length(response)
    options.(promptfields{nn}) = str2num(response{nn});
end

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
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
        [models streams] = filterSweep(sessionPath,optionsCur);
    else
        models = filterSweep(sessionPath, optionsCur, streams);
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
    model = models(threshInd,numChannels);
    model.hLFPDivisor = optionsCur.hLFPDivisor;
    
    %% rescale binsize if desired
%     if options.outputBinSize ~= optionsCur.binSize
%         if model.dtMS ~= optionsCur.binSize
%             error('huh??');
%         end
%         model = scaleKalmanBinsize(model, options.outputBinSize, options.binSize);
%         model.dtMS = options.outputBinSize;
%     end
    
    txtstr = '';
    blockStr = sprintf('%g_',optionsCur.blocksToFit);
    filterNum = startingFilterNum + iFilter - 1;
    filterOutDir = [modelConstants.sessionRoot modelConstants.filterDir];
    fn = sprintf('%g-blocks%s-thresh%g-ch%g-bin%gms-smooth%gms-delay%gms',filterNum,blockStr(1:end-1),thresh,numChannels, optionsCur.binSize,optionsCur.gaussSmoothHalfWidth,optionsCur.delayMotor);
    disp(['saving filter : ' fn]);
    save([filterOutDir fn],'model','models','options','optionsCur');
    
    figOutDir = [modelConstants.sessionRoot modelConstants.analysisDir 'FilterBuildFigs/'];
    if options.showFigures
        figure(20)
        saveas(figure(20),sprintf('%s%g-sweep.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-sweep.png',figOutDir,filterNum));
        figure(21)
        saveas(figure(21),sprintf('%s%g-bias.fig',figOutDir,filterNum));
        print('-dpng',sprintf('%s%g-bias.png',figOutDir,filterNum));
        close all
    end

end
end
end
end
streamsOut = streams;
