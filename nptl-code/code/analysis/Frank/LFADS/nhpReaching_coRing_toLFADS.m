addpath(genpath('/Users/frankwillett/nptlBrainGateRig/code/analysis/Frank'));

dataDir = '/Users/frankwillett/Documents/Monk/';
datasets = {'JenkinsData','R_2016-02-02_1.mat','Jenkins'

    };

%%
for d=1:length(datasets)
    %%
    %format data and produce simple PSTH    
    load([dataDir filesep datasets{d,1} filesep datasets{d,2}]);
    data = unrollR_co( R, 20, datasets{d,3} );
    
    %use outer ring targets only 
    outerIdx = ismember(data.trlCodes, data.outerRingCodes);
    delayTimes = vertcat(R.delayTime);
    noDelayIdx = ~isnan(delayTimes);
    trlIdx = find(outerIdx & noDelayIdx);
    
    %use 0-1000 ms after target appearance
    timeStep = 5;
    trialLen = 1000;
    nBins = floor(trialLen/timeStep);
    nTrl = length(trlIdx);
    nUnits = 192;
    
    shuffIdx = randperm(nTrl);
    trainPct = 0.8;
    cutoffIdx = round(trainPct*nTrl);
    trainIdx = shuffIdx(1:cutoffIdx);
    validIdx = shuffIdx((cutoffIdx+1):end);
    
    all_data = zeros(nUnits, nBins, nTrl);
    for x=1:length(trlIdx)
        fullRaster = [R(trlIdx(x)).spikeRaster', R(trlIdx(x)).spikeRaster2'];
        if size(fullRaster,1)<1000
            nextRaster = [R(trlIdx(x)+1).spikeRaster', R(trlIdx(x)+1).spikeRaster2'];
            fullRaster = [fullRaster; nextRaster];
        end
        
        binCounts = zeros(nBins, nUnits);
        binIdx = 1:5;
        for t=1:nBins
            binCounts(t,:) = sum(fullRaster(binIdx,:));
            binIdx = binIdx+5;
        end
        
        all_data(:,:,x) = binCounts';
    end
    
    train_data = all_data(:,:,trainIdx);
    valid_data = all_data(:,:,validIdx);
    
    h5create([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/train_data',size(train_data),'Datatype','int64');
    h5create([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/valid_data',size(valid_data),'Datatype','int64');
    h5create([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/train_percentage',1);
    h5create([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/dt',1);
    
    h5write([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/train_data',int64(train_data));
    h5write([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/valid_data',int64(valid_data));
    h5write([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/train_percentage',0.8);
    h5write([dataDir datasets{d,2}(1:(end-4)) '.h5'],'/dt',0.005);
    
    h5disp([dataDir datasets{d,2}(1:(end-4)) '.h5']);
end
