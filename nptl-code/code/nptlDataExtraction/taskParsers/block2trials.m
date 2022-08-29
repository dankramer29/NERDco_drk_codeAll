function out = block2trials(block, startTimes, endTimes)

ntrials = length(startTimes);

%% add "pretrial" and "posttrial" for smoothing
streamFields = {'clock','LFP','HLFP','minAcausSpikeBand','xorth','SBsmoothed','HLFPsmoothed','spikeraster'};
whichStreams = {};
postTrialKeep=500;
preTrialKeep=500;

%%% if there are missing samples: make user explicitly acknowledge that some data is missing
if any(diff(block.continuous.clock)>1)
    disp('block2trials: somehow missed xpc samples');

    [inds] =find(diff(block.continuous.clock)>1);
    disp(sprintf('after %g ms is the last good stretch of data. restricting data to that stretch', ...
         block.continuous.clock(inds)));

    startTimes = startTimes(startTimes > block.continuous.clock(inds));
    endTimes = endTimes(endTimes > startTimes(1));

    f = fields(block.continuous);
    for nf = 1:numel(f)
        block.continuous.(f{nf}) = block.continuous.(f{nf})(inds(end)+1:end,:);
    end
    disp('press any key to acknowledge and continue');
    pause;
end

tmp = num2cell(startTimes);
[out(1:ntrials).startcounter] = deal(tmp{:});
tmp = num2cell(endTimes);
[out(1:ntrials).endcounter] = deal(tmp{:});

%% get indices by offsetting by first point
starts = startTimes -block.continuous.clock(1)+1;
ends= endTimes -block.continuous.clock(1)+1;

arrayfun(@(x,y) assert(block.continuous.clock(x) == y, 'ugh'), starts, startTimes);

cFields = fields(block.continuous);
[~,ai,~] = intersect(streamFields,cFields);
for nn=1:numel(ai)
    whichStreams{ai(nn)} = 'continuous';
end

for nf = 1:length(cFields)
    data = getfield(block.continuous, cFields{nf});
    fsize = size(data);
    nshift = 1;
    %% find singleton dimensions, dimshift/squeeze them out
    tmpshift = min(find(fsize==1));
    if ~isempty(tmpshift) & tmpshift < length(fsize)
        nshift = tmpshift;
    end
    %    tmp=arrayfun(@(x,y) reshape(block.continuous.(cFields{nf})(x:y,:),[y-x+1, fsize(2:end)]), starts, ends,'uniformoutput',false);
    tmp=arrayfun(@(x,y) squeeze(shiftdim(reshape(data(x:y,:),[y-x+1, fsize(2:end)]),nshift)), starts, ends,'uniformoutput',false);
    [out(1:ntrials).(cFields{nf})] = deal(tmp{:});
end

if isfield(block, 'neural') & ~isempty(block.neural)
    %% find the start and ending indices of the continuousData in the neuralData
    neuralStartInd = find(block.continuous.clock(1) == block.neural.clock);
    neuralEndInd = find(block.continuous.clock(end) == block.neural.clock);
    if isempty (neuralStartInd) | isempty(neuralEndInd)
        warning(['block2trials: couldnt find all continuous data ' ...
                 'indices in neural data stream']);
        if isempty(neuralEndInd)
            neuralEndInd = length(block.neural.clock);
            contEndInd = find(block.continuous.clock == block.neural.clock(neuralEndInd));
            
            disp(sprintf('trimming %d samples from continuous', length(block.continuous.clock) - contEndInd));
            tmp = fields(block.continuous);
            for nn = 1:length(tmp)
                f = getfield(block.continuous,tmp{nn});
                f = f(1:contEndInd,:);
                block.continuous = setfield(block.continuous,tmp{nn},f);
            end
        end
    end
    nFields = fields(block.neural);

    [~,ai,~] = intersect(streamFields,nFields);
    for nn=1:numel(ai)
        whichStreams{ai(nn)} = 'neural';
    end

    neuralOffset = neuralStartInd-1;
    neuralStarts = starts+neuralOffset;
    neuralEnds = ends+neuralOffset;

    % CP: 2016-10-26 - added this to deal with power failure
    if any(neuralEnds > block.neural.clock(end)) 
        trials2keep = find(neuralEnds <= ...
                           block.neural.clock(end));
        disp(' ');
        disp('-------------');
        disp(['block2trials: WARNING - through some (likely ' ...
              'catastrophic) failure, neural data is missing on ' ...
              'some trials']);
        disp(sprintf(['%i trials are going to have continuous ' ...
                      'data, but will be missing other streams\n'], ...
                     numel(neuralEnds) - numel(trials2keep)));
        if isfield(out, 'startTrialParams') & isfield(out.startTrialParams, ...
                                                      'blockNumber')
            disp(sprintf(' this is block %i', ...
                         out.startTrialParams.blockNumber));
        end
        disp(' ');
        disp('press any key to acknowledge');
        disp('-------------');
        pause;

        neuralEnds = neuralEnds(trials2keep);
        neuralStarts = neuralStarts(trials2keep);
        ntrials = numel(trials2keep);
    end
    %% add the neural data to the rstruct
    for nf = 1:length(nFields)
        data = getfield(block.neural, nFields{nf});
        %% the data is expected to be TIME x 1
        % if the leading dimension is 1, do a shift
        if size(data,1) == 1
            data = shiftdim(data,1);
        end
        fsize = size(data);
        nshift = 1;
        %% find singleton dimensions, dimshift/squeeze them out
        tmpshift = min(find(fsize==1));
        if ~isempty(tmpshift) && tmpshift < length(fsize)
            nshift = tmpshift;
        end
        %trial-ize the stream data
        tmp=arrayfun(@(x,y) squeeze(shiftdim(reshape(data(x:y,:), [y-x+1, fsize(2:end)]),nshift)), ...
                     neuralStarts, neuralEnds, 'uniformoutput', false);
        [out(1:ntrials).(nFields{nf})] = deal(tmp{:});
    end
    trialWarned = false(size(out));
    %% do this for the "pretrial" and "posttrial" fields
    for nf = 1:numel(streamFields)
        if isfield(block.neural,streamFields{nf})
            data = getfield(block.neural, streamFields{nf});
            %% the data is expected to be TIME x 1
            % if the leading dimension is 1, do a shift
            if size(data,1) == 1
                data = shiftdim(data,1);
            end

            fsize = size(data);
            %% pretrial
            for nt = 1:numel(out)
                x=starts(nt)+neuralOffset-500;
                y=starts(nt)+neuralOffset-1;
                try
                    tmp2=squeeze(shiftdim(reshape(data(x:y,:),[y-x+1, fsize(2:end)]),nshift));
                    out(nt).preTrial.(streamFields{nf}) = tmp2;
                catch
                    if ~trialWarned(nt)
                        warning(sprintf('block2trials: couldnt get pre trial data for trial %g',nt));
                        trialWarned(nt)=true;
                    end
                    out(nt).preTrial.(streamFields{nf}) = [];
                end
            end
            %%posttrial
            for nt = 1:numel(out)
                x=ends(nt)+neuralOffset+1;
                y=ends(nt)+neuralOffset+500;
                try
                    tmp2=squeeze(shiftdim(reshape(data(x:y,:),[y-x+1, fsize(2:end)]),nshift));
                    out(nt).postTrial.(streamFields{nf}) = tmp2;
                catch
                    if ~trialWarned(nt)
                        warning(sprintf('block2trials: couldnt get post trial data for trial %g',nt));
                        trialWarned(nt)=true;
                    end
                    out(nt).postTrial.(streamFields{nf}) = [];
                end
            end
        end
    end 
end
%% a couple blocks, due to errors, do not have discrete packets (e.g. t7.2013.11.26).
%% Make the best by skipping the discrete
if isempty(block.discrete)
    [out.startTrialParams] = deal([]);
else
    [discretePacketTimes] = block.discrete.clock;
    dFields = fields(block.discrete);
    for nt = 1:length(startTimes)
        %% for some tasks, startTimes and discrete data inds are offset by 1 clock period
        %% that is, start times are generally on transitions, discrete data might be sent afterwards?
        dind = find(discretePacketTimes == startTimes(nt));
        if isempty(dind)
            dind = find(discretePacketTimes == startTimes(nt)+1);
        end
        %%% HACK FOR FITTS_STREAMPARSER
        if isempty(dind) 
            dind = find(discretePacketTimes == startTimes(nt)+21);
            disp(sprintf('block2trials: warning - using a hack meant for fitts tasks. this task is %s', block.taskDetails.taskName));
        end
        % movement cue task was setup to output multiple discrete packets per trial. be aware.
        if strcmp(block.taskDetails.taskName,'movementCue')
            % find out if there are discrete packets before the next trial. If so, put all that data into startTrialParams
            lastDind = max(find(discretePacketTimes <= endTimes(nt)));
        else
            lastDind = dind;
        end
        
        for nf = 1:length(dFields)
            out(nt).startTrialParams.(dFields{nf}) = squeeze(block.discrete.(dFields{nf})(dind:lastDind,:,:))';
        end
    end
end
%% tack on decoder discrete fields 
if isfield(block, 'decoderD') && ~isempty(block.decoderD)
    decoderDFields = fields(block.decoderD);
    decoderDTimes = [block.decoderD.clock];
    for nt = 1:numel(out)
        startClock = out(nt).startcounter;
        %% find the decoder discrete packet that's appropriate here
        dind = find(decoderDTimes <= startClock,1,'last');
        for nf = 1:numel(decoderDFields)
            out(nt).decoderD.(decoderDFields{nf}) = ...
                squeeze(block.decoderD.(decoderDFields{nf})(dind,:,:))';
        end
    end
end
%% tack on decoder continuous fields 
if isfield(block, 'decoderC') && ~isempty(block.decoderD)
    decoderCFields = fields(block.decoderC);
    for nt = 1:numel(out)
        [~,keepInds,~] = intersect(block.decoderC.clock,startTimes(nt):endTimes(nt));
        for nf = 1:numel(decoderCFields)
            out(nt).decoderC.(decoderCFields{nf}) = ...
                squeeze(block.decoderC.(decoderCFields{nf})(keepInds,:,:))';
        end
    end
end

for nt = 1:length(out)
    out(nt).taskDetails = block.taskDetails;
    if(isfield(block, 'thresholdData'))
        txstart = 1+(startTimes(nt)-block.thresholdData.txStartTimeXpc);
        txend = 1+(endTimes(nt)-block.thresholdData.txStartTimeXpc);
        out(nt).spikeRaster=sparse(double(block.thresholdData.samples(txstart:txend,:)'));
    end
end