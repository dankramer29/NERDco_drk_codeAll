%add delayed reach data
% load all DM data into one mega struct: 
c4Dates = {'2018.04.16', '2018.04.18', '2018.04.23', '2018.05.14', '2018.05.16', '2018.06.25'};
c4HMblocks = { 2, 13,  0,  0, 17, 1};
c4BCblocks = {13,  6, 13, 10, 12, []};
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
%% HM blocks
for sesh = 1:length(c4HMblocks) 
    streamsHM = [];
    [ ~, streamsHM] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', c4Dates{sesh}, '/'], c4HMblocks{sesh}, -4.5, c4HMblocks{sesh}(1), filtOpts);
    binnedR = [];
    for i = 1:length(streamsHM)
    %    [binnedR(sesh).HM] = [binnedR(sesh).HM, binStream( streamsHM{i}, 20, 100, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
        [binnedR] = [binnedR, binStream( streamsHM{i}, 20, 100, {'cursorPosition', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'currentTarget', 'clickState'})];
    
    end
     binnedR_All = aggregateC4_R(binnedR); 
     aggR(sesh).HM_C4 = binnedR_All; 
     save(['Users/sharlene/CachedData/processed/', c4Dates{sesh}, '_HM_C4.mat'], 'binnedR_All');
%    aggRc4(sesh).HM = aggregateC4_R(binnedR(sesh).HM;
end
 save(['Users/sharlene/CachedData/processed/', 'all_HM_C4.mat'], 'aggR', '-v7.3');
%% BC blocks 
for sesh = 1:length(c4BCblocks) 
    streamsBC = [];
    [ ~, streamsBC ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', c4Dates{sesh}, '/'], c4BCblocks{sesh}, -4.5, c4BCblocks{sesh}(1), filtOpts);
    binnedR(sesh).BC = [];
    for i = 1:length(streamsBC)
        [binnedR(sesh).BC] = [binnedR(sesh).BC, binStream( streamsBC{i}, 20, 100, {'cursorPosition', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'currentTarget'})];
    end
    aggRc4(sesh).BC = aggregateC4_R(binnedR(sesh).BC, 10); 
end
save(['Users/sharlene/CachedData/processed/', 'all_BC_C4.mat'], 'aggRc4', '-v7.3');
%% 