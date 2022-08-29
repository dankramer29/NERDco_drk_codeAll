% load all DM data into one mega struct: 
dmDates = {'2018.06.06', '2018.06.11','2018.06.27'};
dmHMblocks = {[9:12], [9:12], [0:8,10]}; %notes say 6/11 was a great HM day
dmBCblocks = {[3:7], [4:7], []};
%dmBCblocks_cleanest = {[15], [7:9, 12], [14, 15], [11], [6:8, 10, 11], []};
filtOpts.filtFields = {'rigidBodyPosXYZ'};
filtOpts.filtCutoff = 10/500; 
gaussWidth = 80; 
%% HM blocks
for sesh = 1:length(dmHMblocks) 
    binnedR_All = [];
    streamsHM = [];
    littleR = [];
    [ littleR, streamsHM] = getStanfordRAndStream_SF( ['Users/sharlene/CachedData/t5.', dmDates{sesh}, '/'], dmHMblocks{sesh}, -3.5, dmHMblocks{sesh}(1), filtOpts);
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
    R(sesh).HM = littleR; 
    binnedR_All = PSTH_byRT_condensed_CF(binnedR_All , 'HM', dmDates{sesh});
    binnedR_All = PSTH_byCoh_condensed_CF(binnedR_All, 'HM', dmDates{sesh});
    save(['Users/sharlene/CachedData/processed/', dmDates{sesh}, '_HM_ChF.mat'], 'binnedR_All', '-v7.3');
    %TF_FRdiff;
    %TF_FRdiff_moveAlign; 
   % clear binnedR streamsHM binnedR_All;
end
%SFaggR = aggR(1:sesh); 
 save(['Users/sharlene/CachedData/processed/', 'allHM_ChF.mat'], 'aggR', '-v7.3');
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
    save(['Users/sharlene/CachedData/processed/', dmDates{sesh}, '_BC.mat_ChF'], 'binnedR_All', '-v7.3');
    TF_FRdiff;
    TF_FRdiff_moveAlign; 
    clear binnedR streamsBC binnedR_All;
end
 save(['Users/sharlene/CachedData/processed/', 'allBC_ChF.mat'], 'aggR', '-v7.3');
%% 