dat = load('/Users/frankwillett/Data/movSweepNet/firstTest.mat');

unitSets = {1:50, 51:100, 101:150, 151:200};
nLayers = length(fieldnames(dat))-2;
layers = cell(nLayers,1);
for l=1:nLayers
    layers{l} = dat.(['h' num2str(l)]);
end

%%
figure
imagesc(dat.h0(1:32,:));

for l=1:length(layers)
    figure; 
    for unitSetIdx=1:length(unitSets)
        singleEff = layers{l}(1:32,unitSets{unitSetIdx});
        singleEff = singleEff - mean(singleEff);
        
        subplot(2,length(unitSets),unitSetIdx);
        imagesc(corr(singleEff'),[-1,1]);
        title(['Area ' num2str(unitSetIdx)]);
        
        effSets = {1:8, 9:16, 17:24, 25:32};
        for setIdx=1:length(effSets)
            singleEff(effSets{setIdx},:) = singleEff(effSets{setIdx},:)-mean(singleEff(effSets{setIdx},:));
        end

        subplot(2,length(unitSets),length(unitSets)+unitSetIdx);
        imagesc(corr(singleEff'),[-1,1]);
    end
end

figure('Position',[680         645        1092         453]);
for l=1:length(layers)
    modSize = zeros(4,4);
    meanRate = zeros(4,4);
    for unitSetIdx=1:length(unitSets)
        singleEff = layers{l}(1:32,unitSets{unitSetIdx});
        effSets = {1:8, 9:16, 17:24, 25:32};
        for setIdx=1:length(effSets)
            modSize(unitSetIdx, setIdx) = sum(var(singleEff(effSets{setIdx},:)));
            meanRate(unitSetIdx, setIdx) = mean(mean(singleEff(effSets{setIdx},:)));
        end
    end

    subplot(2,length(layers),l);
    imagesc(modSize);
    colorbar;
    title(['Layer ' num2str(l)]);
    
    subplot(2,length(layers),l+length(layers));
    imagesc(meanRate);
    colorbar;
end

%%
singleAndDual = [17, 21, 25, 29, 32+1, 32+5, 32+33, 32+37];
for l=1:length(layers)
    dualEff = layers{l}(singleAndDual,1:51);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dualEff);
    
    figure
    plot(SCORE(:,1), SCORE(:,2), 'o');
    axis equal;
end


%%
reducedCon = [1,5,33,37];

figure
imagesc(dat.h0(33:end,:));

for l=1:length(layers)
    dualEff = layers{l}(33:(33+64),1:51);
    dualEff = dualEff(reducedCon,:);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dualEff);
    
    figure
    plot(SCORE(:,1), SCORE(:,2), 'o');
    axis equal;
end

figure; 
imagesc(corr(singleEff'));