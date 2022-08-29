function [rms, allms] = channelRMS(R)

    if isfield(R,'meanSquaredAcaus')
        f1= 'meanSquaredAcaus';
        f2= 'meanSquaredAcausChannel';
    else
        f1= 'meanSquared';
        f2= 'meanSquaredChannel';
    end
    allMS = [R.(f1)];
    allMSinds = [R.(f2)];

    
    if size(allMSinds,1) < size(allMSinds,2)
        allMSinds = allMSinds';
        allMS = allMS';
    end

    %% do we need to renumber the channels?
    addOffsets = false;
    for narray = 1:size(allMSinds,2)
        chs{narray}=unique(allMSinds(:,narray));
    end
    if length(chs)>1 && numel(intersect(chs{:}))
        addOffsets = true;
    end

    for narray = 1:size(allMSinds,2)
        x = unique(allMSinds(:,narray));
        x = x(x>0);
        for ic = 1:length(x)
            nc=x(ic);
            if addOffsets
                ncout = nc+double(DecoderConstants.NUM_CHANNELS_PER_ARRAY)*(narray-1);
            else
                ncout = nc;
            end
            allmschannel{ncout} = allMS(allMSinds(:,narray) == nc,narray);
            rms(ncout) = sqrt(mean(allmschannel{ncout}));
        end
    end
    msminlength = min(cellfun(@length,allmschannel));
    for ic = 1:numel(allmschannel)
        allms(ic,:) = allmschannel{ic}(1:msminlength);
    end
