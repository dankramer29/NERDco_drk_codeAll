
set_paths;


dpath = '/net/experiments/t5/t5.2016.09.21/Data/';
fs = {'_Lateral/NSP Data/13_movementCueTask_Complete_t5_bld(013)015.ns5','_Medial/NSP Data/13_movementCueTask_Complete_t5_bld(013)015.ns5'};


participant = 't5';
date = '2016-09-21';

for nf = 1%1:numel(fs)

    narray = nf;
    makeSpikepanel(participant, fullfile(dpath,fs{nf}), ...
                   struct('showChannelNums',true, 'thresholdMultiplier',-3));

end

