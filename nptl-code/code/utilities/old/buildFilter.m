function buildFilter(buildAll)

blockNumListStr = inputdlg('Which block number should I build a filter from?');
filterNameStr = inputdlg('What should I name this filter?');
exList = inputdlg('Which channels should I exclude?');


if((nargin ~= 1) || ~buildAll)
    rmsMultListStr = inputdlg('What RMS multiplier(s) should I use?');
    chCountListStr = inputdlg('How many channels should I use (can be a list to build multiple filters)?');

    rmsMultList = str2num(rmsMultListStr{1});
    chCountList = str2num(chCountListStr{1});
else
    rmsMultList = [-5:0.5:-0.5 0.5:0.5:5];
    chCountList = 1:96;
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
    
    % Thresh and bin HARDCODED CONSTANTS
    [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0);
    
    TX = [T.X];
    TZ = [T.Z];
    
    for i = 1:96
        mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
        pval(i) = min(mdl.anova.pValue(1:2));
    end
    
    
    pval(str2num(exList{1})) = 1;
    
    [y, chIdx] = sort(pval);
    
    for i = chCountList
        
        
        filterName = [filterNameStr{1} '_' num2str(10*rmsMult) 'rms_' num2str(i) 'channels'];
        
        model = fitKalmanV(T, chIdx(1:i));
        model.thresholds = thresholds;
        model.rmsMult = rmsMult;
        model.channelCount = i;
        model.excludeChannels = str2num(exList{1});
        
        try
            save(fullfile('session', 'data', 'filters', filterName), 'model');
        catch err
            error(['Could not save filter:' filterName]);
            return;
        end
        
        
    end
end
    
