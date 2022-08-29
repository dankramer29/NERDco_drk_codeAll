%all 2D cusor control datasets that are a standard target acquisition task

%meta: decoder type, subject, date, effector, task, EA, experiment description
%task parameters: intertrial delay, instructed delay, click, dwell time
%continuous: target size, cursor size, target position, cursor position,
%block number, actual time (?), nsp1, nsp2, decoded velocity
%trial segmentation: move epochs, intertrial delay epochs, instructed delay
%epochs, isSuccess
%features: 2.5, 3.5, 4.5, 5.5, 6.5 TX, spike power
%20 ms bins?

readDir = '/net/experiments/';
saveDir = '/net/home/fwillett/Data/Derived/2dDatasets';
mkdir(saveDir);

%%
t5sess = getT5_2D_CL_Datasets();
for s=3
    disp(t5sess{s,1});
    if strcmp(t5sess{s,3},'east')
        formatEast2DDataset(t5sess(s,:), saveDir, [readDir 't5east']);
    elseif strcmp(t5sess{s,3},'west')
        formatWest2DDataset(t5sess(s,:), saveDir, [readDir 't5']);
    end
end

%%
t6sess = getT6_2D_CL_Datasets();
for s=1:length(t6sess)
    disp(t6sess{s,1});
    if strcmp(t6sess{s,3},'east')
        formatEast2DDataset(t6sess(s,:), saveDir, [readDir 'Q']);
    elseif strcmp(t6sess{s,3},'west')
        formatWest2DDataset(t6sess(s,:), saveDir, [readDir 't6']);
    end
end
