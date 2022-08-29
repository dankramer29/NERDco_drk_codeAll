load('/Users/frankwillett/Data/Derived/post_LFADS/sleep_2016_1122_1arr/collatedMatFiles/sleep_2016_1122_1arr.mat');

nBins = size(matInput.all_data,2);
nChan = size(matInput.all_data,1);
tmp = zeros(nChan,nBins,size(matInput.all_data,3));
tmp(:,:,matInput.trainIdx) = allResults{4,1};
tmp(:,:,matInput.validIdx) = allResults{4,2};

nTrl = size(tmp,3);
neuralStack = zeros(nBins*nTrl,nChan);
nsReal = zeros(nBins*nTrl,nChan);
binIdx = 1:nBins;
for t=1:size(tmp,3)
    disp(t);
    neuralStack(binIdx,:) = tmp(:,:,t)';
    nsReal(binIdx,:) = matInput.all_data(:,:,t)';
    binIdx = binIdx + nBins;
end

%%
plotIdx = (100000):(110000);

figure
ax1 = subplot(2,1,1);
imagesc(neuralStack');

ax2 = subplot(2,1,2);
imagesc(nsReal');

linkaxes([ax1, ax2]);

figure;
plot(neuralStack);

%%
figure;
plot(neuralStack);

%%
