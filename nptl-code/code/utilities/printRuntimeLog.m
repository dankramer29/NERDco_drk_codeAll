load('E:\Session\Data\Log\runtimeLog.mat');
for b=1:length(blocks)
    try
        disp(' ');
        disp(['--- Block ' num2str(blocks(b).blockNum) ' ---']);
        disp(['Start time: ' datestr( blocks(b).systemStartTime)]);
        disp(['Param script: ' blocks(b).parameterScript]);
        disp(['End time: ' datestr( blocks(b).systemStopTime)]);
    end
end