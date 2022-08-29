function ostr = splitTrialsByMarkers(ostr,startMark,endMark)

	for nb = 1:numel(ostr.blocks)
		for nt = 1:numel(ostr.blocks(nb).trials)
			s = ostr.blocks(nb).trials(nt).(startMark);
			e = ostr.blocks(nb).trials(nt).(endMark);

			% get spiketrains
			ostr.blocks(nb).trials(nt).SBsmoothed = ostr.blocks(nb).trials(nt).SBsmoothed(:,s:e);

			% resample low-d data
			binWidth = ostr.blocks(nb).ld.binWidth;
			xorth = [];
			for nf = 1:size(ostr.blocks(nb).ld.trials(nt).xorth,1)
				res = resample(ostr.blocks(nb).ld.trials(nt).xorth(nf,:),binWidth,1);
				xorth(nf,:) = res(s:binWidth:e);
			end
			ostr.blocks(nb).ld.trials(nt).xorth = xorth;
		end
	end
	
    % allSessions = {ostr.blocks.session};
    % uSessions = unique(allSessions);

    % %% for each session
    % for nSession = 1:numel(uSessions)            
    %     %% get all blocks in this session
    %     sessBlocks = find(strcmp(allSessions,uSessions{nSession}));
    %     sessBlock = [ostr.blocks(sessBlocks).trials];

    %     %% iterate over all trials in this block
    %     for nt = 1:length(sessBlock)
    %     	keyboard
    %     end
    % end