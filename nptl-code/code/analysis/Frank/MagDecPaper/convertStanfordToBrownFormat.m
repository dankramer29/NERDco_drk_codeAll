function [ R, cursorPos, targetPos, reaches, decoder, targRad, features, featLabels, decFeatures, allZero, decVel ] = ...
    convertStanfordToBrownFormat( sessionDir, blockNums, gameType )

    %get all R files
    global modelConstants;
    if isempty(modelConstants)
        modelConstants = modelDefinedConstants();
    end
    cd(sessionDir);
    
    R = [];
    for b=1:length(blockNums)
        disp(b);
        tmp = onlineR(loadStream([sessionDir filesep 'Data' filesep 'FileLogger' filesep num2str(blockNums(b)) filesep], blockNums(b)));
        R = [R, tmp];
    end
    
    %make spike raster by applying thresholds
    load([sessionDir filesep 'Data' filesep 'Filters' filesep R(1).decoderD.filterName '.mat']);
    for t=1:length(R)
        R(t).spikeRaster = bsxfun(@lt, R(t).minAcausSpikeBand, model.thresholds');
    end
    
    opts.filter = false;
    data = unrollR_generic(R, 20, opts);
    
    cursorPos = data.cursorPos(:,1:2);
    targetPos = data.targetPos(:,1:2);
    reaches = [data.reachEvents(:,2), data.reachEvents(:,3)];
    reaches(reaches<1) = 1;
    
    if strcmp(gameType,'grid_t5')
        reaches(2:end,1) = reaches(2:end,1)-round(700/20)+1;
        reaches(reaches>length(cursorPos)) = length(cursorPos);
    end
    
    decoder = model.K([2 4],1:192);
    decoder = bsxfun(@times, decoder, model.invSoftNormVals(1:192)');
    
    if isfield(R(1).startTrialParams,'targetDiameter')
        targRad = 25 + double(R(1).startTrialParams.targetDiameter/2);
    else
        targRad = zeros(size(cursorPos,1),1) + 55.5;
    end
    
    features = data.spikes;
    featLabels = cell(192,1);
    for f=1:length(featLabels)
        featLabels{f} = ['TX ' num2str(f)];
    end
    allZero = (all(features==0));
    features(:,allZero) = [];
    features = zscore(features);
    
    decFeatures = (data.spikes/50)*(15/20);
    decFeatures = bsxfun(@plus, decFeatures, -mean(decFeatures));
    
    decVel = [R.xk]';
    decVel = decVel(1:20:end,2:2:4);
end

