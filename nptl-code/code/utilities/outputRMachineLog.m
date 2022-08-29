function outputRMachineLog(f, R)
% outputRMachineLog(f, R)
%
% outputs machine log of the passed R struct to the file handle f

	% come general structs
	sTP = [R.startTrialParams];
	taskDetails = [R.taskDetails];

	% block number
	blockNum = [sTP.blockNumber];
	if numel(unique(blockNum)) > 1
		error('outputRMachineLog:nonUniqueBlockNumber', 'Bad R struct, has mixed block numbers');
	end
	fprintf(f, 'Block %i\n', blockNum(1));

	% task name
	taskName = {taskDetails.taskName};
	if numel(unique(taskName)) > 1
		error('outputRMachineLog:nonUniqueTaskName', 'Bad R struct, has mixed task names');
	end
	fprintf(f, 'Task Name: %s\n', taskName{1});

	% num trials
	numTrials = numel(R);
	fprintf(f, 'Number of trials: %i\n', numTrials);

	% total time
	startTime = R(1).startcounter;
	stopTime = R(end).endcounter;
	totalTime = double((stopTime - startTime))/1000; % seconds 
	fprintf(f, 'Block Duration: %02i:%02i\n', floor(uint32(totalTime)/60), mod(uint32(totalTime), 60));

	% output decoder discrete stuff, if it exists
	if isfield(R, 'decoderD')
		decoderD = [R.decoderD];
		if size(decoderD(1).filterName, 1) > 1
			for i = 1 : numTrials
				filterName{i} = decoderD(i).filterName';
				discreteFilterName{i} = decoderD(i).discreteFilterName';
			end
		else
			filterName = {decoderD.filterName};
			discreteFilterName = {decoderD.discreteFilterName};
		end

		uniqueFilters  = unique(filterName);
		uniqueDFilters = unique(discreteFilterName);

		for i = 1 : numel(uniqueFilters)
			fName = uniqueFilters{i};
			fZeros = find(fName == 0);
			if ~isempty(fZeros) && fZeros(1) ~= 1
				fprintf(f, 'Filter Name: %s\n', fName(1:fZeros(1)-1));
			end
		end

		for i = 1 : numel(uniqueDFilters)
			dfName = uniqueDFilters{i};
			dfZeros = find(dfName == 0);
			if ~isempty(dfZeros) && dfZeros(1) ~= 1
				fprintf(f, 'Discrete Filter Name: %s\n', dfName(1:dfZeros(1)-1));
			end
		end

	end


	% keyboard specific metrics
	if strcmp(taskName, 'keyboard')

%		R = keyboardPreprocessR(R);

		aK = allKeyboards;
		k = [sTP.keyboard];
		if numel(unique(k)) > 1
			error('outputRMachineLog:nonUniqueKeyboards', 'Bad R struct, has mixed keyboards');
		end

		fprintf(f, 'Keyboard Task Type: %s\n', char(keyboardConstants(k(1))));

		% grid specific metrics
		if isRGrid(R)

			numSuccesses = sum([R.isSuccessful]);
			numErrors = numTrials - numSuccesses;
			successRate = double(numSuccesses)/numTrials;

			fprintf(f, 'Number of Successes: %i\n', numSuccesses);
			fprintf(f, 'Percent correct: %0.2f\n', successRate);

			numKeys = aK(k(1)).keys(1).numKeys;

			bitrate = (log2(double(numKeys)) * (numTrials - numErrors))/totalTime;

			itr = ( log2(double(numKeys)) + successRate * log2(successRate) + (1 - successRate) * log2((1 - successRate)/(double(numKeys) - 1)) ) * double(numTrials) / totalTime;

			fprintf(f, 'Bitrate: %0.2f\n', bitrate);
			fprintf(f, 'ITR: %0.2f\n', itr);
			fprintf(f, 'Fitts bitrate %0.2f\n', fittsGridBitrate(R));
		end

	end

	fprintf(f, '\n\n\n');

end
