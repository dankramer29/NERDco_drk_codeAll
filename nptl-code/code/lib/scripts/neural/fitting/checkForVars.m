function checkForVars(vars)
%
% checks cell array to see if named variables are present in called workspace
%

numVars = numel(vars);

for i = 1 : numVars;
	if evalin('caller', sprintf('~exist(''%s'', ''var'')', vars{i}) )
		error('util:checkForVars', sprintf('specified variable %s does not exist', vars{i}));
	end
end
