function [spikeCounts, newSpikeCounts] = RemoveDuplicateTXevents(R, threshold, usedChanInds)
% RemoveDuplicateTXevents
%
% Counts threshold crossings, removing events that are counted twice 
% because a single threshold crossing event occurred at the boundary 
% between two bins. Compares the tuningSNRs using original and new spike
% counts. For now, ignores the fact that boundaries between trials might
% skip a couple samples. 
%  
% Beata Jarosiewicz, 2013

if ~exist('threshold', 'var') || isempty(threshold),
    threshold = -50;  %in mV
end

% merge relevant data across trials: 
minAcausSpikeBand = [R.minAcausSpikeBand];
minAcausSpikeBandInd = [R.minAcausSpikeBandInd];
cursorPos = [R.cursorPosition];
targetPos = [R.currentTarget];
state = [R.state];

% for fitting PDs, only use data where state == 2 or 3 (new target, or 
% moving - see processTaskDetails(taskDetails)):
indsToUse = (state == 2 | state == 3);

%SELF: to figure out which channels were used in filter, load model from 'filters'
%directory of data folder, and find non-zero elements of model.C (vel 
%filter coefficients are in columns 3 and 4): usedChanInds = find(sum(model.C(:,1:4),2))';

if ~exist('usedChanInds', 'var') || isempty(usedChanInds),
    numChans = size(minAcausSpikeBand,1); % assumes same # of channels in all trials
    usedChanInds = 1:numChans; 
end

for chanIdx = usedChanInds,
    minASB = minAcausSpikeBand(chanIdx,:);
    minASBinds = minAcausSpikeBandInd(chanIdx,:);
    % compute spike counts before and after removing duplicate events
    [spikeCounts(chanIdx,:), newSpikeCounts(chanIdx,:)] = RemoveDupes(minASB, minASBinds, threshold);
end

keyboard

% call this in Stanford's code (onlineTfromR and filterSweep) to fit model
% and assess the improvements gained by these different methods


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [spikeCounts, newSpikeCounts] = RemoveDupes(minASB, minASBinds, threshold)

% find bins containing threshold crossings, turn them into "spike counts":
binsWithTXevents = find(minASB<threshold);
spikeCounts = zeros(size(minASB));
spikeCounts(binsWithTXevents) = 1;

% are any of these consecutive pairs of bins? 
consecBinsWithTXevents = find(diff(binsWithTXevents) == 1);

% if so, go through each pair and make sure any minima are not within
% 1 msec of each other:
newSpikeCounts = spikeCounts; %initialize with previous spikeCounts, remove spikes where duplicated
for cbInd = consecBinsWithTXevents,
    ind1 = minASBinds(binsWithTXevents(cbInd)); %index (30 per ms) of where spike occurred in this bin
    ind2 = minASBinds(binsWithTXevents(cbInd+1)); %index (30 per ms) of where spike occurred in the next bin
    if ind1 > ind2, %mins in these consecutive bins happened within 1 ms
        newSpikeCounts(binsWithTXevents(cbInd+1)) = 0;
    end
end

% inform user how many spikes were removed:
numSpikesRemoved = sum(spikeCounts - newSpikeCounts);
prctSpikesRemoved = numSpikesRemoved./length(spikeCounts)*100;

%disp([num2str(numSpikesRemoved) ' spikes removed (' num2str(prctSpikesRemoved) ' % of spikes)'])  
disp(sprintf('%d spikes removed (%3.3f percent)', numSpikesRemoved, prctSpikesRemoved))  
    


