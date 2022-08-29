function buildFilterHack(buildAll)

blockNumListStr = inputdlg('Which block number should I build a filter from?');
filterNameStr = inputdlg('What should I name this filter?');
exList = inputdlg('Which channels should I exclude?');
filterType = inputdlg('What type of filter should I build (VKF, VFBKF, REFIT)?');


if((nargin ~= 1) || ~buildAll)
    rmsMultListStr = inputdlg('What RMS multiplier(s) should I use?');
    chCountListStr = inputdlg('How many channels should I use (can be a list to build multiple filters)?');

    rmsMultList = str2num(rmsMultListStr{1});
    chCountList = str2num(chCountListStr{1});
else
    %rmsMultList = [-5:0.5:-0.5 0.5:0.5:5];
    rmsMultList = [-3.5:0.5:-1.5 1.5:0.5:3.5];
    chCountList = 1:50;
end

blockNumList = str2num(blockNumListStr{1});

try
    R1 = [];
    for i = 1:length(blockNumList)
        fn = fullfile('session', 'data', 'blocks', 'matStructs', ['R_' num2str(blockNumList(i)) '.mat'] );
        disp(fn);
        if exist(fn,'file')
            tmp = load(fn);
            R = tmp.R;
            taskDetails = tmp.taskDetails;
        else
            [R taskDetails] = onlineR(fullfile('session', 'data', 'blocks', 'rawData', num2str(blockNumList(i))));
            save(fn, 'R', 'taskDetails');
        end
        
        R1 = [R1 R];
    end
catch err
    error(['Could not build R for specified block number: ' num2str(blockNumList(i))]);
    return;
end
R = R1;
clear R1;

for rmsMult = rmsMultList
    
    % Thresh and bin HARDCODED CONSTANTS
    switch lower(filterType{1})
        case {'vkf', 'vfbkf'}            
            [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'mouse');
        case 'refit'
            [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'refit');
    end
    
    TX = [T.X];
    TZ = [T.Z];
    
    for i = 1:96
        mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
        pval(i, :) = (mdl.anova.pValue(1:2));
    end
    
    
    pval(str2num(exList{1}), :) = 1;
    
    [y, chIdx] = sort(pval);
    
    
   
    for i = chCountList
        
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
        model.excludeChannels = str2num(exList{1});
        model.filterType = lower(filterType{1});
        
        try
            save(fullfile('session', 'data', 'filters', filterName), 'model');
        catch err
            error(['Could not save filter:' filterName]);
            return;
        end
        
        
    end
end
    
