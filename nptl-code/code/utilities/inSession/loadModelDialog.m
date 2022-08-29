function out = loadModel( )

	global modelConstants
	if isempty(modelConstants)
		modelConstants = modelDefinedConstants();
	end

	filterFiles = dir([modelConstants.sessionRoot modelConstants.filterDir '*.mat']);
	[selection, ok] = listdlg('PromptString', 'Select base filter:', 'ListString', {filterFiles.name}, ...
		'SelectionMode', 'Single', 'ListSize', [400 300]);
	filename = [modelConstants.sessionRoot modelConstants.filterDir filterFiles(selection).name];

	out=load(filename);

end
