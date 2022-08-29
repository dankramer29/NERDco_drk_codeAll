function stream = mergeAddonWithStream(stream,addon)

    %% save down minacausspikeband for use in FA
    if isfield(addon, 'minSpikeBand')
        addon.minAcausSpikeBand = addon.minSpikeBand;
        addon.minAcausSpikeBandInd = addon.minSpikeBandInd;
        addon = rmfield(addon,{'minSpikeBand','minSpikeBandInd'});
    end
    if isfield(addon,'lfp')
        addon.LFP = addon.lfp;
        addon = rmfield(addon,{'lfp'});
    end
    if isfield(addon,'gamma')
        addon.HLFP = addon.gamma;
        addon = rmfield(addon,{'gamma'});
    end


    if isempty(stream.neural)
        stream.neural = addon;
    else
        stream.neural = mergeTwoStructsByClock(stream.neural, ...
                                               addon);
    end


    % sfields = fields(addon);
    % for nf = 1:numel(sfields)
    %     if isfield(stream.neural, sfields{nf})
    %         if numel(stream.neural.(sfields{nf})) ~= ...
    %                 numel(addon.(sfields{nf}))
    %             disp('dont know how to merge these fields');
    %             keyboard
    %         end
    %         continue;
    %     end
    %     stream.neural.(sfields{nf}) = addon.(sfields{nf});
    % end
