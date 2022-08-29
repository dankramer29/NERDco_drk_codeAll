function updateRate = findCursorUpdateRate(R)
%
% updateRate = findCursorUpdateRate(R)
%
% assumes R is just one trial
%
% finds update rate of cursor (hand based or decode based)


if numel(R) > 1
	error('utils:findCursorUpdate:tooManyTrials', 'R struct is not a single trial');
end

localizeFields(R);


% need to determine update rate from length of zero order holds
cpDiff = cursorPos(:, 1 : end - 1) - cursorPos(:, 2 : end);
% updateTimes = find(cpDiff(1, 2 : end));
updateTimes=[];
updateRate=[];
for nx=1:size(cpDiff,1)
    updateTimes=find(cpDiff(nx, 2 : end));
    localRates = updateTimes(2:end) - updateTimes(1:end-1);
    if ~isempty(localRates)
        updateRate = [updateRate(:); mean(localRates)];
    end
end
updateRate=mean(updateRate);
if ~(startTrialParams.decodeOn) && abs(updateRate - 16) < 2
	updateRate = 100/6;		% almost certainly polaris updates
end

% hacks galore
% if updateRate < 3	% continuous update is on
% 	updateRate = startTrialParams.decodeBinWidth;
% end
