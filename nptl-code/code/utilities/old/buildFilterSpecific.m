function model=buildFilterSpecific(blockNumList, rmsMult, channels, filterType)

%filterNameStr = inputdlg('What should I name this filter?');
%filterType = inputdlg('What type of filter should I build (VKF, VFBKF, REFIT)?');


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


% Thresh and bin HARDCODED CONSTANTS
switch lower(filterType{1})
  case {'vkf', 'vfbkf'}            
    [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'mouse');
  case 'refit'
    [T, thresholds] = onlineTfromR(R, false, rmsMult, 50, 0, 'refit');
end

TX = [T.X];
TZ = [T.Z];

chSortList = channels;
i = length(channels);



switch lower(filterType{1})
  case {'vkf'}
    model = fitKalmanV(T, chSortList);
  case {'vfbkf', 'refit'}
    model = fitKalmanVFB(T, chSortList);
end

model.thresholds = thresholds;
model.rmsMult = rmsMult;
model.channelCount = i;
model.excludeChannels = [];
model.filterType = lower(filterType{1});

if exist('filterNameStr','var')
    filterName = [filterNameStr{1} '_' num2str(10*rmsMult) 'rms_' num2str(i) 'channels_' lower(filterType{1})];

    try
        save(fullfile('session', 'data', 'filters', filterName), 'model');
    catch err
        error(['Could not save filter:' filterName]);
        return;
    end
end

