function [stats, summary] = testAllFilters(filterPrefix)

if nargin < 1
    error('need to enter filterPrefix as argument')
end

if nargout <2
    error('need to catch the stats and summary output arguments')
end


blockNumStr = inputdlg('Which block number should I test filters on?');
blockNumList = str2num(blockNumStr{1});

filterType = inputdlg('What type of filter should I test (VKF, VFBKF, REFIT)?');

%rmsMultList = [-3:0.5:-0.5 0.5:0.5:3];
rmsMultList = [-3.5:0.5:-1.5 1.5:0.5:3.5];
numChannelCounts = 50;

try
    R1 = [];
    for i = 1:length(blockNumList)
        fn = fullfile('session', 'data', 'blocks', 'matStructs', ['R_' num2str(blockNumList(i)) '.mat'] );
        disp(fn);
        if exist(fn,'file')
            tmp = load(fn);
            R = tmp.R;
        else
            R = onlineR(fullfile('session', 'data', 'blocks', 'rawData', num2str(blockNumList(i))));
            save(fn, 'R');
        end
        
        R1 = [R1 R];
    end
catch err
    error(['Could not build R for specified block number: ' num2str(blockNumList(i))]);
    return;
end
R = R1;
clear R1;


j = 1;


for j = 1:length(rmsMultList)
    
    for i = 1:numChannelCounts
        models(i) = load([filterPrefix '_' num2str(10*rmsMultList(j)) 'rms_' num2str(i) 'channels_' lower(filterType{1})]);
        
    end
    [T, thresholds] = onlineTfromR(R, true, models(i).model.thresholds, 50, 0, 'mouse');
        
    
    
    for i = 1:numChannelCounts
        
        stats(j, i) = testDecode(T, models(i).model);
        summary.sAE(j,i) = circ_std(stats(j, i).angleError');
        summary.mAE(j,i) = circ_mean(stats(j, i).angleError');
        summary.sRatio(j,i) = mean(stats(j,i).holdSpeedTotal) / mean(stats(j,i).maxSpeed);
    end
    
    j
end

summary.rmsMultList = rmsMultList;