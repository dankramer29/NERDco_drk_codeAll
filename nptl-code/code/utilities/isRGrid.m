function isGrid = isRGrid(R)
% isGrid = isRGrid(R)
%
% tests to see if R is a grid task

isGrid = 0;

gridTasks = [3:8, 12:19, 21:24]; % this is s

sTP = [R.startTrialParams];


if isfield(sTP, 'keyboard')
	
	k = [sTP.keyboard];

	if all(ismember(unique(k), gridTasks))
		isGrid = 1;
	end

end
