% log of dates and block numbers for psychophysics: 
%% crunch day 1 data
april16HMblocks = [3:8, 17:20];
april16BCblocks = [15];
april16 = '2018.04.16';
%R_HM16 = makeRstructs(april16, april16HMblocks); 
%R_BC16 = makeRstructs(april16, april16BCblocks); 
%cd('\');
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussSD = 20;

[ ~, streamsHM1 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april16, '/'], april16HMblocks, -4.5, april16HMblocks(1), filtOpts);
binnedR_HM1 = [];
for i = 1:length(streamsHM1)
    [binnedR_HM1] = [binnedR_HM1, binStream( streamsHM1{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
end
% [ ~, streamsBC1 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april16, '/'], april16BCblocks, -4.5, april16BCblocks(1), filtOpts);
% binnedR_BC1 = [];
% for i = 1:length(streamsBC1)
%     [binnedR_BC1] = [binnedR_BC1, binStream( streamsBC1{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
% end
%binRHM1 = plot1and2factorDPCA(binnedR_HM1, 75, 50,  5);
%binRBC1 = plot1and2factorDPCA(binnedR_BC1, 75, 50, 10); %insufficient trials for 2 factor
binRHM1 = aggregateDM_R(binnedR_HM1, 5); 
%binRBC1 = aggregateDM_R(binnedR_BC1, 10); 
clear binned_RHM1 binned_RBC1 streamsBC1 streamsHM1
%% april 18th data 
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
april18BCblocks = [7:9, 12];
april18HMblocks = [14:17];
april18 = '2018.04.18';
% parse the data Frank's way: 
%flDir = 'Users/sharlene/CachedData/t5.2018.04.18/Data/FileLogger/';
%cd('');
[ ~, streamsHM2 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april18, '/'], april18HMblocks, -4.5, april18HMblocks(1), filtOpts);
[ ~, streamsBC2 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april18, '/'], april18BCblocks, -4.5, april18BCblocks(1), filtOpts);
binnedR_HM2 = [];
for i = 1:length(streamsHM2)
    [binnedR_HM2] = [binnedR_HM2, binStream( streamsHM2{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
end
binnedR_BC2 = [];
for i = 1:length(streamsBC2)
    [binnedR_BC2] = [binnedR_BC2, binStream( streamsBC2{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state',  'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed',  'successPoints'})];
end
% binRHM2 = plot1and2factorDPCA(binnedR_HM2, 75, 50,  5);
% binRBC2 = plot1and2factorDPCA(binnedR_BC2, 75, 50, 10);
% clear binnedR_BC2 binnedRHM2
binRHM2 = aggregateDM_R(binnedR_HM2, 5); 
binRBC2 = aggregateDM_R(binnedR_BC2, 10); 
clear binned_RHM2 binned_RBC2 streamsBC2 streamsHM2
%% day 3 data
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
april23 = '2018.04.23';
april23BCblocks = [14, 15];%, 19, 22]; %blocks 19 and 22 corrupted by bias, not to be used for pCurves, proceeed with caution. Bias was random and could be overcome in block 11. pre-movement periods should be clean
april23HMblocks = [1:5];
%cd('');
[ ~, streamsHM3 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april23, '/'], april23HMblocks, -4.5, april23HMblocks(1), filtOpts);
[ ~, streamsBC3 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', april23, '/'], april23BCblocks, -4.5, april23BCblocks(1), filtOpts);

binnedR_HM3 = [];
for i = 1:length(streamsHM3)
    [binnedR_HM3] = [binnedR_HM3, binStream( streamsHM3{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
end

binnedR_BC3 = [];
for i = 1:length(streamsBC3)
    [binnedR_BC3] = [binnedR_BC3, binStream( streamsBC3{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state',  'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed',  'successPoints'})];
end
binRHM3 = aggregateDM_R(binnedR_HM3, 5); 
binRBC3 = aggregateDM_R(binnedR_BC3, 10); 
clear binned_RHM3 binned_RBC3 streamsBC3 streamsHM3
% binRHM3 = plot1and2factorDPCA(binnedR_HM3, 75, 50,  5);
% binRBC3 = plot1and2factorDPCA(binnedR_BC3, 75, 50, 10);
% %% old way
% %R_HM18 = makeRstructs(april18, april18HMblocks); 
% [R_BC18, streamBC18] = makeRstructs(april18, april18BCblocks); 
% [binnedR] = binStream( streams{1}, 20, 100, {'effectorCursorPos', 'stimCondMatrix', 'xk'})
% % Spikes
% rmsMultiplier = -4.5;
% [rmsBCI, allmsBCI] = channelRMS(R_BC18);
% R_BC18 = RastersFromMinAcausSpikeBand(R_BC18, rmsBCI.*rmsMultiplier);
% numUnits = size(R_BC18(1).spikeRaster,1);
% 
% [rmsHM, allmsHM] = channelRMS(R_HM18);
% R_HM18 = RastersFromMinAcausSpikeBand(R_HM18, rmsHM.*rmsMultiplier);
% %numUnits = size(R_BC18(1).spikeRaster,1);
%% May 14
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
may14 = '2018.05.14';
may14BCblocks = [11];% bias appeared ~6.5 minutes into the block. Ended session after one block. 
may14HMblocks = [1:6];
%cd('');
[ ~, streamsHM4 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', may14, '/'], may14HMblocks, -4.5, may14HMblocks(1), filtOpts);
[ ~, streamsBC4 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', may14, '/'], may14BCblocks, -4.5, may14BCblocks(1), filtOpts);

binnedR_HM4 = [];
for i = 1:length(streamsHM4)
    [binnedR_HM4] = [binnedR_HM4, binStream( streamsHM4{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
end

binnedR_BC4 = [];
for i = 1:length(streamsBC4)
    [binnedR_BC4] = [binnedR_BC4, binStream( streamsBC4{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state',  'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed',  'successPoints'})];
end
binRHM4 = aggregateDM_R(binnedR_HM4, 5); 
binRBC4 = aggregateDM_R(binnedR_BC4, 10); 
clear binned_RHM4 binned_RBC4 streamsBC4 streamsHM4
%% day 5 May 16
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
may16 = '2018.05.16';
may16BCblocks = [6:8, 10, 11];% block 10 and end of block 8corrupted by bias, not to be used for pCurves, proceeed with caution
may16HMblocks = [13:16];
%cd('');
[ ~, streamsHM5 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', may16, '/'], may16HMblocks, -4.5, may16HMblocks(1), filtOpts);
[ ~, streamsBC5 ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', may16, '/'], may16BCblocks, -4.5, may16BCblocks(1), filtOpts);

binnedR_HM5 = [];
for i = 1:length(streamsHM5)
    [binnedR_HM5] = [binnedR_HM5, binStream( streamsHM5{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
end

binnedR_BC5 = [];
for i = 1:length(streamsBC5)
    [binnedR_BC5] = [binnedR_BC5, binStream( streamsBC5{i}, 20, 30, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state',  'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed',  'successPoints'})];
end
binRHM4 = aggregateDM_R(binnedR_HM5, 5); 
binRBC4 = aggregateDM_R(binnedR_BC5, 10); 
clear binned_RHM5 binned_RBC5 streamsBC5 streamsHM5