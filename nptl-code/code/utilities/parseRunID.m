function [runID runIDtrim] = parseRunID(rID)
% [runID runIDtrim] = parseRunID(rID)
%
% returns properly formatted runIDs based on input
%
% 
% valid inputs are in one of two formats:
% runID format: PP.YYYY.MM.DD (length 13)
% runIDtrim format: PPYYMMDD (length 8)

rIDLen = numel(rID);

if rIDLen == 8
   inputIsTrim = 1;
elseif rIDLen == 13
	inputIsTrim = 0;
else
	error('parseRunID:invalidLength', 'invalid length for runID');
end

% check first letter
firstLetter = lower(rID(1));
if firstLetter ~= 's' && firstLetter ~= 't'
	error('parseRunID:invalidParticipantType', 'invalid pariticpant type, check first letter passed in');
end

% check numbers and periods
if inputIsTrim
	if ~all(ismember(rID(2:8), ['0':'9']))
		error('parseRunID:invalidDate', 'non numeric date input');
	end
else
	if ~all(ismember(rID([2 4:7 9 10 12 13]), ['0':'9']))
	   error('parseRunID:invalidDate', 'nonnumeric date input');
	end
	if rID([3 8 11]) ~= '...'
		error('parseRunID:invalidRunIDFormat', 'periods not found where expected');
	end
end


if inputIsTrim
	runID = [rID(1:2) '.20' rID(3:4) '.' rID(5:6) '.' rID(7:8)];
	runIDtrim = rID;
else
	runID = rID;
	runIDtrim = [rID(1:2) rID(6:7) rID(9:10) runID(12:13)];
end

end
