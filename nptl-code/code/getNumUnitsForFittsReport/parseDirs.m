function MPaths = parseDirs(dirs, expPath)
% returns structure with full paths to M structs

% MPaths is a days x dayCursorFilter matrix of all the filters built that day

MPaths = struct;

cursorFiltersDir = 'Data/Filters/';

numDays = numel(dirs);

for i = 1 : numDays % dir/day counter
	dayMs = dir(fullfile(expPath, dirs(i).name, cursorFiltersDir, '*.mat'));

	for j = 1 : numel(dayMs) % number of M structs in this day counter

		MPaths(i, j).expDay = dirs(i).name;
		MPaths(i, j).MName = dayMs(j).name;
		MPaths(i, j).MFullPath = fullfile(expPath, dirs(i).name, cursorFiltersDir, dayMs(j).name);
	end
end

% trim the fat
dropDays = logical(zeros(1, numDays)); 
for i = 1 : numDays
	if isempty([MPaths(i, :).expDay])
		dropDays(i) = true;
	end
end
MPaths(dropDays, :) = []; % drop

end
