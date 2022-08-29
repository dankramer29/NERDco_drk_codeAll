dmDates = {'2018.04.16', '2018.04.18', '2018.04.23', '2018.05.14', '2018.05.16', '2018.06.25'};
load('/Users/sharlene/CachedData/processed/all_TF.mat')
%%
for sesh = 1:5
aggR(sesh).HM = PSTH_byRT_condensed(aggR(sesh).HM, 'HM', dmDates{sesh});
aggR(sesh).BC = PSTH_byRT_condensed(aggR(sesh).BC, 'BC', dmDates{sesh});
aggR(sesh).HM = PSTH_byCoh_condensed(aggR(sesh).HM, 'HM', dmDates{sesh});
aggR(sesh).BC = PSTH_byCoh_condensed(aggR(sesh).BC, 'BC', dmDates{sesh});
end
sesh = 6;
aggR(sesh).HM = PSTH_byRT_condensed(aggR(sesh).HM, 'HM', dmDates{sesh});
aggR(sesh).HM = PSTH_byCoh_condensed(aggR(sesh).HM, 'HM', dmDates{sesh});
%save(['Users/sharlene/CachedData/processed/', 'all_TF.mat'], 'aggR', '-v7.3');
%% 
for sesh = 1:5
aggR(sesh).HM = VMcontin(aggR(sesh).HM);
aggR(sesh).BC = VMcontin(aggR(sesh).BC);
end
sesh = 6;
aggR(sesh).HM = VMcontin(aggR(sesh).HM);