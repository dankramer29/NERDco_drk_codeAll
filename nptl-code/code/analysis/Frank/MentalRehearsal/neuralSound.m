%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));
outDir = [paths.dataPath filesep 'Derived' filesep 'WatchVideoAlignment'];

%%
%load from file
nsFileName = '/Users/frankwillett/Data/BG Datasets/t5.2016.09.28/Data/_Lateral/NSP Data/0_cursorTask_Complete_t5_bld(000)-010.ns5';

analogData = openNSx_v620(nsFileName, 'read', 'c:1:96');
raw = double(analogData.Data{end}');
[B,A] = butter(3,[300,5000]/15000);
filteredRaw = filtfilt(B,A,raw);

plotIdx = 1:10;
for n=1:10
    figure;
    hold on;
    for p=1:length(plotIdx)
        plot(zscore(filteredRaw(1:(30000*10),plotIdx(p)))+6*p);
        text(0,6*p,num2str(plotIdx(p)));
    end
    plotIdx = plotIdx + 10;
end

audiowrite('neuralSound.wav',zscore(filteredRaw((16*30000):(46*30000),71))/20,30000);
