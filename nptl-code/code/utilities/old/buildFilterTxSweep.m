function buildFilterTxSweep(buildAll)

blockNumListStr = inputdlg('Which block number should I build a filter from?');
filterNameStr = inputdlg('What should I name this filter?');
exList = inputdlg('Which channels should I exclude?');


if((nargin ~= 1) || ~buildAll)
    chCountListStr = inputdlg('How many channels should I use (can be a list to build multiple filters)?');

    chCountList = str2num(chCountListStr{1});
else
    chCountList = 1:96;
end

rmsMultList = [-5:0.5:-0.5 0.5:0.5:5];

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

% Thresh and bin HARDCODED CONSTANTS
[T, thresholds] = onlineTfromR(R, false, -10, 50, 0);
[thresholds, txInds, pval, pvalsx, pvalsy] = perChannelThresholdSweep(R, T, ...
                                                  rmsMultList);
%xvals = pvalsx(txInds); yvals = pvalsy(txInds);
%pval = [xvals(:) yvals(:)];

%for rmsMult = rmsMultList
%    
%    % Thresh and bin HARDCODED CONSTANTS
%    [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0);
%    
%   TX = [T.X];
%    TZ = [T.Z];
    
%    for i = 1:96
%        mdl = LinearModel.fit(TX(3:4,:)', TZ(i,:)');
%        pval(i, :) = (mdl.anova.pValue(1:2));
%    end
    
    
    pval(str2num(exList{1}), :) = 1;
    
    [y, chIdx] = sort(pval);
    
   
    for i = chCountList
        
        tmp = chIdx(1:i, :);
        chSortList = unique(tmp(:));
        
        filterName = [filterNameStr{1} '_txSweep_' num2str(i) 'channels'];
        
        [T, thresholds] = onlineTfromR(R, true, thresholds, 50, 0);
        model = fitKalmanV(T, chSortList);
        model.thresholds = thresholds;
        %model.rmsMult = rmsMult;
        model.channelCount = i;
        model.excludeChannels = str2num(exList{1});
        
        try
            save(fullfile('session', 'data', 'filters', filterName), 'model');
        catch err
            error(['Could not save filter:' filterName]);
            return;
        end
        
        
    end
    %end
    
