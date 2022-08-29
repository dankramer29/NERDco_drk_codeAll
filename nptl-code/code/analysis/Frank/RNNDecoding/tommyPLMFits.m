%%
blockSets1 = {[6 7 8 9 10],[13 14 15 16 17];
    [21 22 23 24 25],[29 30 31 32 33];
    [34 35 38 39 40 41],[42 43 44 45 46 47]};
blockSets2 = {[5 6 7 8 9],[10 11 12 14 15 16];
    [17 18 19 20 21 29],[24 25 26 27 28];
    [30 31],[32];
    };
slcDirs = {'/Users/frankwillett/Data/tommyRNN/','/Users/frankwillett/Data/tommyRNN2/'};
allBlockSets = {blockSets1, blockSets2};

colors = [1.0 0 0;
    0 0 1.0];
cWeight = [1,0.75,0.5];
noiseValues = [];
noiseCoef = [];
fModels = {};

for dayIdx=1:length(allBlockSets)
    blockSets = allBlockSets{dayIdx};
    decType = 2;
    
    for setIdx=1:length(blockSets)
        bSet = blockSets{setIdx,decType};
        if isempty(bSet)
            continue
        end

        %%
        for bNum=1:length(bSet)
            slc = LoadSLC(bSet(bNum),slcDirs{dayIdx});

            in.outlierRemoveForCIS = false;
            in.cursorPos = slc.task.receivedKin.values(:,1:2);
            in.targetPos = slc.task.goal.values(:,1:2);
            
            breakIdx = [find(any(diff(in.targetPos)~=0,2))];
            re = [breakIdx(1:(end-1)), breakIdx(2:end)]+1;
            
            in.reachEpochs = re;
            in.reachEpochs_fit = re;
            in.features = double([slc.ncTX.values, slc.spikePower.values]);
            
            reachIdx = expandEpochIdx(in.reachEpochs);
            badIdx = find(all(in.features(reachIdx,:)==0));
            in.features(:,badIdx) = [];
            
            targDist = sqrt(sum((in.cursorPos - in.targetPos).^2,2));
            in.maxDist = 1;
            in.plot = true;
            in.gameType = 'fittsImmediate';

            in = fit4DimModel_RNN_simple( in );

            %%
            in.modelType = 'FMP';
            fullModel = fitPhasicAndFB_6(in);

            cFeatures = in.features - fullModel.featureMeans;
            rawSignals = cFeatures * fullModel.filts;

            reachIdx_cVec = expandEpochIdx([in.reachEpochs(:,1)+in.rtSteps, in.reachEpochs(:,2)]);
            [fScalModel, fScalValues] = fitFTarg(in.kin.targDist(reachIdx_cVec), rawSignals(reachIdx_cVec,3), in.maxDist, 10);
            [fTargModel, fTargVec] = fitFTarg(in.kin.posErrForFit(reachIdx_cVec,:), rawSignals(reachIdx_cVec,1:2), in.maxDist, 10);

            rawSignals(:,1:2) = rawSignals(:,1:2) / fTargModel(end,2);
            rawSignals(:,3) = (rawSignals(:,3) - fScalModel(1,2))/(fScalModel(end,2)-fScalModel(1,2));

            modelValues = [fTargVec, fScalValues];
            noise = rawSignals(reachIdx_cVec,1:3) - modelValues;
            noise(isnan(noise))=0;
            [ arModel ] = fitARNoiseModel( noise, [1 size(noise,1)], 2 );

            tmpCoef = horzcat(arModel.coef{:});
            noiseValues = [noiseValues; diag(sqrt(arModel.covNoise))'];
            noiseCoef = [noiseCoef; diag(tmpCoef)'];
            
            fModels = [fModels; {fTargModel, fScalModel}];
        end
    end
end

%%
figure
hold on;
plot(noiseValues(1:16,3),'o');
plot(noiseValues(17:end,3),'o');
legend({'Day1','Day2'});

%%
figure
hold on;
plot(mean(noiseValues(1:16,1:2),2),'o');
plot(mean(noiseValues(17:end,1:2),2),'o');
legend({'Day1','Day2'});

%%
colors = [repmat([0.8 0 0],16,1); repmat([0 0 0.8],16,1)];

figure
hold on
for x=1:size(fModels,1)
    plot(fModels{x,1}(:,1), fModels{x,1}(:,2)/fModels{x,1}(end,2), '-o', 'Color', colors(x,:));
end

concatModels = [];
for x=1:size(fModels,1)
    Y = fModels{x,1}(:,2);
    Y = Y/Y(end);
    tmp = interp1(fModels{x,1}(:,1), Y, linspace(0,1,100));
    concatModels = [concatModels; tmp];
end

avg1 = mean(concatModels(1:16,:));
avg2 = mean(concatModels(17:end,:));

figure
hold on
plot(avg1,'LineWidth',2);
plot(avg2,'LineWidth',2);
legend({'Day1','Day2'});

%%
figure
hold on
for x=1:size(fModels,1)
    Y = fModels{x,2}(:,2);
    Y = (Y-Y(1))/(Y(end)-Y(1));
    plot(fModels{x,2}(:,1), Y, '-o', 'Color', colors(x,:));
end

concatModels = [];
for x=1:size(fModels,1)
    Y = fModels{x,2}(:,2);
    Y = (Y-Y(1))/(Y(end)-Y(1));
    tmp = interp1(fModels{x,2}(:,1), Y, linspace(0,1,100));
    concatModels = [concatModels; tmp];
end

avg1 = mean(concatModels(1:16,:));
avg2 = mean(concatModels(17:end,:));

figure
hold on
plot(avg1,'LineWidth',2);
plot(avg2,'LineWidth',2);
legend({'Day1','Day2'});

%     0.2846
%     0.3247
%     0.1423
%     0.9163
