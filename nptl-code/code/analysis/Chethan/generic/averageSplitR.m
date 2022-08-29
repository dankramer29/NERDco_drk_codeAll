function Rsplit = averageSplitR(Rsplit, opts)

opts.foo=false;
opts = setDefault(opts,'useAlignment','none');
opts = setDefault(opts,'preKeep',0);
opts = setDefault(opts,'postKeep',0);
opts = setDefault(opts,'useHLFP',false, true);

numChannels = size(Rsplit(1).R(1).SBsmoothed,1);
numLDDims = size(Rsplit(1).R(1).xorth,1);

for nc = 1:numel(Rsplit)
    numTrials = numel(Rsplit(nc).R);
    minLength = min(arrayfun(@(x) size(x.SBsmoothed,2),Rsplit(nc).R));
    %minLength = 600;
    Rsplit(nc).SBavg = zeros(numChannels,minLength +opts.postKeep +opts.preKeep);
    if opts.useHLFP
        Rsplit(nc).HLFPavg = zeros(numChannels,minLength +opts.postKeep +opts.preKeep);
    end
    %Rsplit(nc).cursorVelocity = zeros(2,minLength);
    Rsplit(nc).cursorPosition = zeros(2,minLength);
    Rsplit(nc).moveOnsets = [];

    Rsplit(nc).xorth = zeros(numLDDims,minLength +opts.postKeep + opts.preKeep);
    for nt = 1:numTrials
        rt = Rsplit(nc).R(nt);

        switch(opts.useAlignment)
            case 'neural'
              if isfield(rt,'tshift')
                  tshift = rt.tshift;
              else 
                  disp('supposed to use neural alignment, required field missing');
              end
          case 'move'
              if isfield(rt,'moveOnset')
                  tshift = rt.moveOnset;
              else 
                  disp('supposed to use movemenbt alignment, required field missing');
              end
          case 'none'
            tshift = 0;
          otherwise
            disp('averageSplitR: don''t know how to use this alignment');
        end

        if isfield(rt,'moveOnset')
            Rsplit(nc).moveOnsets(end+1) = rt.moveOnset;
        end

        %% first average the spikeband data
        sb = [rt.preTrial.SBsmoothed rt.SBsmoothed rt.postTrial.SBsmoothed];
        ptlen = size(rt.preTrial.SBsmoothed,2);
        for nch = 1:numChannels
            Rsplit(nc).SBavg(nch,:) = Rsplit(nc).SBavg(nch,:) +...
                sb(nch,ptlen+tshift+((1-opts.preKeep):(minLength+opts.postKeep)))/numTrials;
        end

        %% avg HLFP data if requested
        %% first average the spikeband data
        if opts.useHLFP
            sb = [rt.preTrial.HLFPsmoothed rt.HLFPsmoothed rt.postTrial.HLFPsmoothed];
            ptlen = size(rt.preTrial.HLFPsmoothed,2);
            for nch = 1:numChannels
                Rsplit(nc).HLFPavg(nch,:) = Rsplit(nc).HLFPavg(nch,:) +...
                    sb(nch,ptlen+tshift+((1-opts.preKeep):(minLength+opts.postKeep)))/numTrials;
            end
        end


        %% now average the low-d data
        sb = [rt.preTrial.xorth rt.xorth rt.postTrial.xorth];
        ptlen = size(rt.preTrial.xorth,2);
        for nxo = 1:numLDDims
            Rsplit(nc).xorth(nxo,:) = Rsplit(nc).xorth(nxo,:) +...
                sb(nxo,ptlen+tshift+((1-opts.preKeep):(minLength+opts.postKeep)))/numTrials;
        end

        for ndim = 1:size(Rsplit(nc).R(nt).cursorPosition,1)
            Rsplit(nc).cursorPosition(ndim,:) = Rsplit(nc).cursorPosition(ndim,:) + ...
                Rsplit(nc).R(nt).cursorPosition(ndim,1:minLength) / numTrials;
        end

        % %% average the cursor velocities if they exist
        % if isfield(Rsplit(nc).R(nt), 'cursorVelocity')
        %     for ndim = 1:size(Rsplit(nc).R(nt).cursorVelocity,1)
        %         Rsplit(nc).cursorVelocity(ndim,:) = Rsplit(nc).cursorVelocity(ndim,:) + ...
        %             Rsplit(nc).R(nt).cursorVelocity(ndim,1:minLength) / numTrials;
        %     end
        % end
    end

    Rsplit(nc).times = ((1-opts.preKeep):(minLength+opts.postKeep));
end
 
