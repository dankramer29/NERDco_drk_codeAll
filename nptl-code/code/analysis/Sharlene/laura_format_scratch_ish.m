date = '2018.07.30'; 
blocks = [1:8, 10:20]; 
filtOpts.filtFields = {'rigidBodyPosXYZ'};
saveDir = '/Users/sharlene/CachedData/t5.2018.07.30/Data'
filtOpts.filtCutoff = 10/500;
%%
for i = [1:15, 18,19] %16:length(blocks)
[ ~, streams ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', date, '/'], blocks(i), -3.5, blocks(i), filtOpts);
streams{1}.continuous.spikeRaster = streams{1}.spikeRaster; 
streams{1}.continuous.spikeRaster2 = streams{1}.spikeRaster2; 
binnedRstream = binStream(streams{1}, 20, 100, {'effectorCursorPos', 'state', 'xk', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'stimConds', 'currentTarget'});
save([saveDir, '/', date, '_block', num2str(blocks(i)), '.mat'], 'streams', 'binnedRstream', 'filtOpts','-v7.3');
clear streams binnedRstream
end
