% load all DM data into one mega struct: 
dmDates = {'2018.04.16', '2018.04.18', '2018.04.23', '2018.05.14', '2018.05.16', '2018.06.25'};
dmHMblocks = {[3:8, 17:20], [14:17], [1:5], [1:6], [13:16], [2:11] };
dmBCblocks = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], [] };
dmBCblocks_cleanest = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], []};
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussWidth = 80; 
%% HM blocks
for sesh = 1:length(dmHMblocks) 
    streamsHM = [];
    [ ~, streamsHM] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', dmDates{sesh}, '/'], dmHMblocks{sesh}, -3.5, dmHMblocks{sesh}(1), filtOpts);
    %binnedR(sesh).HM = [];
    binnedR = [];
    for i = 1:length(streamsHM)
    %    [binnedR(sesh).HM] = [binnedR(sesh).HM, binStream( streamsHM{i}, 20, gaussWidth, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
        [binnedR] = [binnedR, binStream( streamsHM{i}, 20, gaussWidth, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
    end
   % aggR(sesh).HM = aggregateDM_R(binnedR(sesh).HM, 5);
    %save([date, 'HM.mat'],  'binnedR'); 
    binnedR_All = aggregateDM_R(binnedR); 
    aggR(sesh).HM = binnedR_All; 
    save(['Users/sharlene/CachedData/processed/', dmDates{sesh}, '_HM.mat'], 'binnedR_All');
    TF_FRdiff;
    TF_FRdiff_moveAlign; 
    clear binnedR streamsHM binnedR_All;
end
 save(['Users/sharlene/CachedData/processed/', 'allHM_TF.mat'], 'aggR', '-v7.3');
%% BC blocks 
clear aggR %change this if you want to save all HM and BCI in the same variable
for sesh = 1:length(dmBCblocks) -1
    streamsBC = [];
    [ ~, streamsBC ] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', dmDates{sesh}, '/'], dmBCblocks{sesh}, -4.5, dmBCblocks{sesh}(1), filtOpts);
    %binnedR(sesh).BC = [];
    binnedR = [];
    for i = 1:length(streamsBC)
    %    [binnedR(sesh).BC] = [binnedR(sesh).BC, binStream( streamsBC{i}, 20, gaussWidth, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ',  'rigidBodyPosXYZ_speed', 'successPoints'})];
        [binnedR] = [binnedR, binStream( streamsBC{i}, 20, gaussWidth, {'effectorCursorPos', 'stimCondMatrix', 'xk', 'state', 'rigidBodyPosXYZ', 'rigidBodyPosXYZ_speed', 'successPoints'})];
    end
    %aggR(sesh).BC = aggregateDM_R(binnedR(sesh).BC, 10); 
    binnedR_All = aggregateDM_R(binnedR); 
    aggR(sesh).BC = binnedR_All; 
    save(['Users/sharlene/CachedData/processed/', dmDates{sesh}, '_BC.mat'], 'binnedR_All');
    TF_FRdiff;
    TF_FRdiff_moveAlign; 
    clear binnedR streamsBC binnedR_All;
end
 save(['Users/sharlene/CachedData/processed/', 'allBC_TF.mat'], 'aggR', '-v7.3');
%% 