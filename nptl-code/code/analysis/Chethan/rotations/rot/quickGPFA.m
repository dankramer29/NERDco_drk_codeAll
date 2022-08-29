function rotr=quickGPFA(rotr,channels,thresholds, ldoptions)
% QUICKGPFA    
% 
% rotr=quickGPFA(rotr,channels,thresholds, ldoptions)
%  only specify thresholds if you don't want to use the ones in rotr.blocks.thresholds

    allSessions = {rotr.blocks.session};
    uSessions = unique(allSessions);

    for nSession = 1:numel(uSessions)
            
        sessBlocks = find(strcmp(allSessions,uSessions{nSession}));

        trialId = 0;
        clear dat;
        sessBlock = [rotr.blocks(sessBlocks).trials];

        if isempty(channels)
            useChannels = rotr.blocks(sessBlocks(1)).channels;
        else
            useChannels = channels;
        end
        if isempty(thresholds)
            useThresh = rotr.blocks(sessBlocks(1)).thresholds(useChannels);
        else
            useThresh = thresholds;
        end


        for nt = 1:length(sessBlock)
            trialId = trialId+1;
            %dat(nt).spikes = R(nt).spikes(t6Keep,:);
            for ic=1:numel(useChannels)
                ch=useChannels(ic);
                dat(nt).spikes(ic,:) = sessBlock(nt).minAcausSpikeBand(ch,:)<useThresh(ic);
            end
            dat(nt).trialId = trialId;
        end

        allBlocks = [rotr.blocks(sessBlocks).blockNum];

        blockstr = sprintf('%g_',allBlocks);
        blockstr = blockstr(1:end-1);
        
        outputDir = sprintf('%s%s_%s', ldoptions.outputPref,...
                            uSessions{nSession},blockstr);
        
        % Extract neural trajectories
        result = neuralTraj(ldoptions.runIdx, dat, ...
            'method', ldoptions.method, 'xDim', ldoptions.xDim, 'outputDir',outputDir);

        % Orthonormalize neural trajectories
        [estParams, seqTrain] = postprocess(result);
        [jnk,sorted]=sort([seqTrain.trialId],'ascend');
        seqTrain = seqTrain(sorted);
        
        for ib = 1:length(sessBlocks)
            nb = sessBlocks(ib);
            rotr.blocks(nb).gpfa.params = result;
            [jnk,ai,bi] = intersect([seqTrain.trialId],[rotr.blocks(nb).trials.trialId]);
            rotr.blocks(nb).gpfa.trials = seqTrain(ai);
            rotr.blocks(nb).gpfa.channels = useChannels;
            rotr.blocks(nb).gpfa.thresholds = useThresh;
            rotr.blocks(nb).gpfa.binWidth = result.binWidth;
            rotr.blocks(nb).gpfa.Corth = estParams.Corth;
            rotr.blocks(nb).gpfa.d = estParams.d;
            rotr.blocks(nb).gpfa.R = estParams.R;
            rotr.blocks(nb).gpfa.gamma = estParams.gamma;
            rotr.blocks(nb).gpfa.eps = estParams.eps;
        end
    end
