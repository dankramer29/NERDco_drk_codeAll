function Data = jpcaPrepRsplit(Rsplits, opts)
    Data = struct;
    Data(1).A = [];
    Data(1).cursorPosition=[];
    Data(1).cursorXVelocity=[];
    Data(1).cursorYVelocity=[];
    Data(1).cursorSpeed=[];
    
    checkOption(opts,'channels','need to define ');
    checkOption(opts,'keepTimes','need to define ');
    opts=setDefault(opts,'useTx',true,true);
    opts=setDefault(opts,'useHLFP',false,true);

    channels = opts.channels;
    for nb = 1:numel(Rsplits)
        
        for id = 1:numel(Rsplits{nb}) %(rota.blocks(1).conditions)
            if numel(Data) < id
                Data(id).A=[];
                Data(id).cursorPosition=[];
                Data(id).cursorXVelocity=[];
                Data(id).cursorYVelocity=[];
                Data(id).cursorSpeed=[];
            end
            m=0;
            if isfield(Rsplits{nb}(id),'moveOnset')
                m=Rsplits{nb}(id).moveOnset;
            end
            [~,timeInds,~] = intersect(Rsplits{nb}(id).times-m,opts.keepTimes);

            if numel(timeInds)~=numel(opts.keepTimes)
                error('jpcaPrepRsplit: can''t find all times');
            end
            if opts.useTx
                Data(id).A = [Data(id).A'; Rsplits{nb}(id).SBavg(opts.channels,timeInds)]';
            end
            if opts.useHLFP
                Data(id).A = [Data(id).A'; Rsplits{nb}(id).HLFPavg(opts.channels,timeInds)]';
            end

            Data(id).times = opts.keepTimes(:);

            % don't have preTrial / postTrial data for cursor vel or position
            if isfield(Rsplits{nb}(id),'cursorPosition')
                P=Rsplits{nb}(id).cursorPosition(:,opts.keepTimes(opts.keepTimes>0));
                Data(id).cursorPosition = P;
            end

            if isfield(Rsplits{nb}(id),'cursorVelocity')
                V=Rsplits{nb}(id).cursorVelocity(:,opts.keepTimes(opts.keepTimes>0));
                Data(id).cursorXVelocity = [Data(id).cursorXVelocity'; V(1,:)]';
                Data(id).cursorYVelocity = [Data(id).cursorYVelocity'; V(2,:)]';
                Data(id).cursorSpeed = [Data(id).cursorSpeed'; sqrt(sum(V.^2))]';
            end
        end
    end



