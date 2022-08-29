function oneTouchExp(runID)
% oneTouchExpt(runID)
%
% assumes R structs are available

	setAnalysisConstants;

	[runID runIDtrim] = parseRunID(runID);
	participant = runIDtrim(1:2);

	blocks = queryExpRBlocks(runID);
	numBlocks = numel(blocks);

	%%%
	% Things to do before any R structs have been parsed

	% create OTP folder
	oTPFolder = fullfile(analysisConstants.derivativePath, 'oneTouchPlots', participant, runID);
	mkdir(oTPFolder);

	% open machine log
	mLogPath = fullfile(analysisConstants.derivativePath, 'machineLog', sprintf('%s.txt', runIDtrim));
	mLog = fopen(mLogPath, 'w');
	fprintf(mLog, 'Machine Log - %s\n\n\n', runIDtrim);



	for i = 1 : numBlocks

		blockNum = str2num(blocks(i).name(3:end));
		R = loadR(runID, blockNum);

		%%%%
		% Things to do for each parsed R struct

		%% binned spike plot
		switch(participant)
			case 't6'
				thresholds = -50*ones(1, 96)';
				R = addRSpikeRaster(R, thresholds);
			case {'t5', 't7'}
				R = addRSpikeRasterT7(R);
		end

		f = plotBinnedSpikeRaster(R);
		print(f, '-dpsc2', '-cmyk', fullfile(oTPFolder, sprintf('sr_%03i.ps', blockNum)) );
		close(f);

		% bin error plot
		if strcmp(participant, 't7')
			taskName = R(1).taskDetails.taskName;
			if isfield(R(1), 'decoderD') && (strcmp(taskName, 'cursor') || isRGrid(R))
				if isRGrid(R)
					R = keyboardPreprocessR(R);
				end
				f = plotOneTouchContrib(runID, R, 500); % 500 ms bins
				if f
					print(f, '-dpsc2', '-cmyk', fullfile(oTPFolder, sprintf('contribError_%03i.ps', blockNum)) );
					close(f);
				end
			end
		end

		% machineLog related stuff
		outputRMachineLog(mLog, R);

	end

	%%%
	% Things to do after all R structs parsed

	fclose(mLog);

end
