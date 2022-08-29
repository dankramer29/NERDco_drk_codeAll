function [stats, summary] = testAllFiltersRestrict(filterPrefix)


blockNumStr = inputdlg('Which block number should I test filters on?');
blockNumList = str2num(blockNumStr{1});

filterType = inputdlg('What type of filter should I test (VKF, VFBKF, REFIT)?');

rmsMultList = [-2.5:0.5:-1.5 1.5:0.5:2.5];

try
    R = [];
    for i = 1:length(blockNumList)
        R = [R onlineR(fullfile('session', 'data', 'blocks', 'rawData', num2str(blockNumList(i))))];
    end
catch err
    error(['Could not build R for specified block number: ' num2str(blockNumList(i))]);
    return;
end

j = 1;

exList = [4 6 8 10 14 34 7 9 11 12 16 18 36 5 17 13 23 20 22 38 48 15 19 25 27 24 40 42 50 54 21 29 26 43 44 46 52 62 31 28 47 51 56 58 60 64 30 53 55 57 59 61 32];
    

for j = 1:length(rmsMultList)
    
    for i = 1:(96-length(exList))
        models(i) = load([filterPrefix '_' num2str(10*rmsMultList(j)) 'rms_' num2str(i) 'channels_' lower(filterType{1})]);
        
    end

        
    % Thresh and bin HARDCODED CONSTANTS
    switch lower(filterType{1})
        case {'vkf', 'vfbkf'}            
            [T, thresholds] = onlineTfromR(R, true, models(i).model.thresholds, 50, 0, 'mouse');
        case 'refit'
            [T, thresholds] = onlineTfromR(R, true, models(i).model.thresholds, 50, 0, 'mouse');
    end
    
    for i = 1:42
        
        stats(j, i) = testDecode(T, models(i).model);
        summary.sAE(j,i) = circ_std(stats(j, i).angleError');
        summary.mAE(j,i) = circ_mean(stats(j, i).angleError');
        %summary.sRatio(j,i) = mean(stats(j,i).holdSpeedTotal) / mean(stats(j,i).maxSpeed);
    end
    
    j
end

summary.rmsMultList = rmsMultList;