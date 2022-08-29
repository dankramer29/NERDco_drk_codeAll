function buildFilterHackRestrict(buildAll)

blockNumListStr = inputdlg('Which block number should I build a filter from?');
filterNameStr = inputdlg('What should I name this filter?');
%exList = inputdlg('Which channels should I exclude?');
filterType = inputdlg('What type of filter should I build (VKF, VFBKF, REFIT)?');


if((nargin ~= 1) || ~buildAll)
    rmsMultListStr = inputdlg('What RMS multiplier(s) should I use?');
    chCountListStr = inputdlg('How many channels should I use (can be a list to build multiple filters)?');

    rmsMultList = str2num(rmsMultListStr{1});
    chCountList = str2num(chCountListStr{1});
else
    rmsMultList = [-2.5:0.5:-1.5 1.5:0.5:2.5];
    
end

blockNumList = str2num(blockNumListStr{1});

try
    R = [];
    for i = 1:length(blockNumList)
        R = [R onlineR(fullfile('session', 'data', 'blocks', 'rawData', num2str(blockNumList(i))))];
    end
catch err
    error(['Could not build R for specified block number: ' num2str(blockNumList(i))]);
    return;
end


for rmsMult = rmsMultList
    
    
    [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'mouse');
    
    
    TX = [T.X];
    TZ = [T.Z];
    
    for i = 1:96
        mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
        pval(i, :) = (mdl.anova.pValue(1:2));
    end
    
    exList = [4 6 8 10 14 34 7 9 11 12 16 18 36 5 17 13 23 20 22 38 48 15 19 25 27 24 40 42 50 54 21 29 26 43 44 46 52 62 31 28 47 51 56 58 60 64 30 53 55 57 59 61 32];
    pval(exList, :) = 1;
    
    [y, chIdx] = sort(pval);
    
    % Thresh and bin HARDCODED CONSTANTS
    switch lower(filterType{1})
        case {'vkf', 'vfbkf'}            
            [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'mouse');
        case 'refit'
            [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'refit');
    end
   
    for i = 1:(96-length(exList))
        
        tmp = chIdx(1:i, :);
        chSortList = unique(tmp(:));
        
        
        
        filterName = [filterNameStr{1} '_' num2str(10*rmsMult) 'rms_' num2str(i) 'channels_' lower(filterType{1})];
        
        
        switch lower(filterType{1})
            case {'vkf'}
                model = fitKalmanV(T, chSortList);
            case {'vfbkf', 'refit'}
                model = fitKalmanVFB(T, chSortList);
        end
        
        model.thresholds = thresholds;
        model.rmsMult = rmsMult;
        model.channelCount = i;
        model.excludeChannels = exList;
        
        try
            save(fullfile('session', 'data', 'filters', filterName), 'model');
        catch err
            error(['Could not save filter:' filterName]);
            return;
        end
        
        
    end
end
    
