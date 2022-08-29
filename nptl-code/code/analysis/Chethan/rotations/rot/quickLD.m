function rotr=quickGPFA(rotr,ldoptions)
% QUICKGPFA    
% 
% rotr=quickGPFA(rotr,channels,thresholds, ldoptions)
%  only specify thresholds if you don't want to use the ones in rotr.blocks.thresholds

    allSessions = {rotr.blocks.session};
    uSessions = unique(allSessions);
    ldoptions = setDefault(ldoptions,'channels',[])
    ldoptions = setDefault(ldoptions,'thresholds',[])

    for nSession = 1:numel(uSessions)
            
        sessBlocks = find(strcmp(allSessions,uSessions{nSession}));

        trialId = 0;
        clear dat;
        sessBlock = [rotr.blocks(sessBlocks).trials];

        %% if no channels specified (empty arg), use the channels listed in the structure info
        if isempty(ldoptions.channels)
            useChannels = rotr.blocks(sessBlocks(1)).channels;
        else
            useChannels = ldoptions.channels;
        end
        %% if no thresholds specified (empty arg), use the thresholds listed in the structure info
        if isempty(ldoptions.thresholds)
            useThresh = rotr.blocks(sessBlocks(1)).thresholds(useChannels);
        else
            useThresh = ldoptions.thresholds(useChannels);
        end

        %% iterate over trials, save spiketrains specified
        for nt = 1:length(sessBlock)
            trialId = trialId+1;
            for ic=1:numel(useChannels)
                ch=useChannels(ic);
                if isfield(sessBlock(nt),'minAcausSpikeBand')
                    dat(nt).spikes(ic,:) = sessBlock(nt).minAcausSpikeBand(ch,:)<useThresh(ic);
                else
                    dat(nt).spikes(ic,:) = sessBlock(nt).SBsmoothed(ch,:);
                end
            end
            dat(nt).trialId = trialId;
        end

        allBlocks = [rotr.blocks(sessBlocks).blockNum];

        blockstr = sprintf('%g_',allBlocks);
        blockstr = blockstr(1:end-1);
        
        outputDir = sprintf('%s%s_%s', ldoptions.outputPref,...
                            uSessions{nSession},blockstr);
        
        switch ldoptions.method
          case 'gpfa'
            % Extract neural trajectories
            result = neuralTraj(ldoptions.runIdx, dat, ...
                'method', ldoptions.method, 'xDim', ldoptions.xDim, 'outputDir',outputDir);
            % Orthonormalize neural trajectories
            [estParams, seqTrain] = postprocess(result);
          case 'fa'
            if ~isfield(ldoptions,'kernSD')
                error('quickLD: for FA, must supply kernSD param in ldoptions')
            end
            result = neuralTraj(ldoptions.runIdx, dat, ...
                'method', ldoptions.method, 'xDim', ldoptions.xDim, 'kernSDList',ldoptions.kernSD,'outputDir',outputDir);
            % Orthonormalize neural trajectories
            [estParams, seqTrain] = postprocess(result,'kernSD',ldoptions.kernSD);
        end
        if size(estParams.Corth,1) < numel(useChannels)
            warning('quickLD: byrons code truncated the number of channels.')
        end
        if numel(seqTrain) ~= numel(dat)
            warning('quickLD: trials missing!!')
        end
        [jnk,sorted]=sort([seqTrain.trialId],'ascend');
        seqTrain = seqTrain(sorted);
        
        for ib = 1:length(sessBlocks)
            nb = sessBlocks(ib);
            rotr.blocks(nb).ld.params = result;
            [jnk,ai,bi] = intersect([seqTrain.trialId],[rotr.blocks(nb).trials.trialId]);
            rotr.blocks(nb).ld.trials = seqTrain(ai);
            rotr.blocks(nb).ld.channels = useChannels;
            rotr.blocks(nb).ld.thresholds = useThresh;
            rotr.blocks(nb).ld.binWidth = result.binWidth;
            rotr.blocks(nb).ld.method = ldoptions.method;
            switch ldoptions.method
              case 'gpfa'
                rotr.blocks(nb).ld.Corth = estParams.Corth;
                rotr.blocks(nb).ld.d = estParams.d;
                rotr.blocks(nb).ld.R = estParams.R;
                rotr.blocks(nb).ld.gamma = estParams.gamma;
                rotr.blocks(nb).ld.eps = estParams.eps;
              case 'fa'
                lambda = estParams.Corth;
                psi = estParams.R;
                means = estParams.d;
                % create a projection matrix 
                B=lambda'*pinv(psi+lambda*lambda');
                rotr.blocks(nb).ld.Corth = lambda;
                rotr.blocks(nb).ld.d = means;
                rotr.blocks(nb).ld.R = psi;
                rotr.blocks(nb).ld.B = B';
            end
        end
    end
