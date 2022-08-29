function [binnedl, clickSource] = calcBlockHMMQuantiles(blockNum)

global modelConstants;

if ~exist('blockNum', 'var') || isempty(blockNum),
    reply = inputdlg('Enter last block number that had reasonable click:', 'Block number');
    blockNum = str2num(reply{1});
end

if isempty(blockNum)
    disp('Didnt understand that block number');
    return
end
streamDir = sprintf('%s/Data/FileLogger/%g/', modelConstants.sessionRoot, blockNum);
stream = parseDataDirectoryBlock(streamDir);

if isempty(stream)
    fprintf('Couldnt parse that directory: %s\n', streamDir);
end

try
    clickSource = stream.discrete.clickSource;  
catch
    %SELF: clickSource doesn't seem to exist for linux/tablet streams; 
    %for now, get it from modelParams (has to be the same for RTI 
    %anyway):
    clickSource = getModelParam('clickSource');
end

startClock = stream.continuous.clock(find(~stream.continuous.pause,1));
endClock = stream.continuous.clock(find(~stream.continuous.pause,1,'last'));

startInd = find(stream.decoderC.clock == startClock);
if isempty(startInd)
    disp('warning: startInd was empty. workaround');
    [~, startInd] = min(abs(double(stream.decoderC.clock) - double(startClock)));
end
endInd = find(stream.decoderC.clock == endClock);
if isempty(endInd)
    disp('warning: endInd was empty. workaround');
    [~, endInd] = min(abs(double(stream.decoderC.clock) - double(endClock)));
end

% pull out the click likelihoods
cumsuml = cumsum(stream.decoderC.discreteStateLikelihoods(startInd:endInd,2));
% bin at 15 ms
dt = 15;
binnedl = diff(cumsuml(1:dt:end))/dt;

fprintf('suggested quantiles (for threshold):\n  q0.90-> %0.3f, q0.91-> %0.3f, q0.92-> %0.3f,\n  q0.93-> %0.3f, q0.94-> %0.3f, q0.95-> %0.3f\n',...
        quantile(binnedl,[0.9 0.91 0.92 0.93 0.94 0.95]));

end
