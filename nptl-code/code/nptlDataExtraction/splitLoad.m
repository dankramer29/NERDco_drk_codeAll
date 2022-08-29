function mergedArray = splitLoad(saveName)
%
% mergedArray = splitLoad(saveName)
%
% v1 - paul - 2014/05/21
%
% loads a splitSaved file set and returns the merged array of structures
% intended to be used with splitSave
%
% NOTE: will break if additional other mat files exist in saveName directory

	existStatus = exist(saveName);
	if existStatus ~= 7 % directory
		error('splitLoad:saveName:notDir', sprintf(['saveName ' ...
                '%s not a directory, cannot load'], saveName));
	end

	whatOut = what(saveName);

	if isempty(whatOut.mat)
		error('splitLoad:saveName:empty', sprintf(['saveName ' ...
                '%s directory is empty, nothing to load'], saveName));
	end


	numMats = numel(whatOut.mat);
	mergedArray = [];
	for i = 1 : numMats
		wrapper = load(fullfile(saveName, sprintf('%04d.mat', i)));
		mergedArray = [mergedArray wrapper.splitData];
	end

end
