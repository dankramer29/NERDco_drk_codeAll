function rotr=quickFA(rotr,channels,thresholds, outputPref, nAlignBins, alignPt, binWidth, kernSD)
% QUICKFA    
% 
% rotr=quickFA(rotr,channels,thresholds, outputPref, nAlignBins, alignPt, binWidth)
%  only specify thresholds if you don't want to use the ones in rotr.blocks.thresholds

if ~exist('nAlignBins','var') || isempty(nAlignBins)
    nAlignBins = 1:25;
end
if ~exist('alignPt','var') || isempty(alignPt)
    alignPt = 0.7;
end

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
        runIdx = 1;
        method = 'fa';
        xDim = 8;
        

        allBlocks = [rotr.blocks(sessBlocks).blockNum];

        blockstr = sprintf('%g_',allBlocks);
        blockstr = blockstr(1:end-1);
        
        outputDir = sprintf('%s%s_%s', outputPref,...
                            uSessions{nSession},blockstr);
        
        % Extract neural trajectories
        result = neuralTraj(runIdx, dat, 'method', method, 'xDim', xDim, 'outputDir',outputDir, 'binWidth', binWidth);
        % Orthonormalize neural trajectories
        [estParams, seqTrain] = postprocess(result, 'kernSD', kernSD);
        [jnk,sorted]=sort([seqTrain.trialId],'ascend');

        seqTrain = seqTrain(sorted);
        seqTrain = alignGPFACursor(seqTrain,result.binWidth,sessBlock,alignPt,nAlignBins, true);
        
        for ib = 1:length(sessBlocks)
            nb = sessBlocks(ib);
            rotr.blocks(nb).gpfa.params = result;
            [jnk,ai,bi] = intersect([seqTrain.trialId],[rotr.blocks(nb).trials.trialId]);
            rotr.blocks(nb).gpfa.trials = seqTrain(ai);
            rotr.blocks(nb).gpfa.channels = useChannels;
            rotr.blocks(nb).gpfa.thresholds = useThresh;
            sids = [seqTrain.trialId];
            for it = 1:length(rotr.blocks(nb).trials)
                rotr.blocks(nb).trials(it).moveOnset = ...
                    seqTrain([sids==rotr.blocks(nb).trials(it).trialId]).moveOnset;
            end
        end
    end
