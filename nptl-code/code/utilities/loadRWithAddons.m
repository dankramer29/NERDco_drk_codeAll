function [R,taskDetails] = loadRWithAddons(participant,session,block,addons,remove)

% function [R,taskDetails] = loadRWithAddons(participant,session,block,addons,remove)

    if nargout >= 2
        % NOTE: Don't try to do this anymore, this seems to only work for
        % old data (before splitload started being used, as shown below).
        [R taskDetails] = loadvar(sprintf('/net/derivative/R/%s/%s/R_%g',participant,session,block),'R', ...
                                  'taskDetails');
    else
        fn = sprintf('/net/derivative/R/%s/%s/R_%g.mat',participant,session,block);
        if exist(fn,'file')
            [R] = loadvar(fn,'R');
        else
            fn = sprintf('/net/derivative/R/%s/%s/R_%03i',participant,session,block);
            R = splitLoad(fn);
        end
    end
    
    if exist('remove','var')
        for na = 1:length(remove)
            if isfield(R,remove{na})
                R=rmfield(R,remove{na});
            end
        end
    end
    
    for na = 1:length(addons)
        R2 = loadvar(sprintf('/net/derivative/R/%s/%s/%s/R_%g',participant,session,addons{na},block),'R');
        x = fields(R2);
        for nx = 1:length(x)
            if ~strcmp(x{nx},'clock')
                if strcmp(class(R2(1).(x{nx})),'double')
                    for nn=1:length(R)
                        R(nn).(x{nx}) = single(R2(nn).(x{nx}));
                    end
                else
                    [R.(x{nx})] = deal(R2.(x{nx}));
                end
            end
        end
    end

    %% merge the dual array data into one field
    if isfield(R,'minAcausSpikeBand1')
        for nn = 1:length(R)
            R(nn).minAcausSpikeBand = [R(nn).minAcausSpikeBand1;R(nn).minAcausSpikeBand2];
        end
        R = rmfield(R,'minAcausSpikeBand1');
        R = rmfield(R,'minAcausSpikeBand2');
    end

    if isfield(R,'HLFP1')
        for nn = 1:length(R)
            R(nn).HLFP = [R(nn).HLFP1;R(nn).HLFP2];
        end
        R = rmfield(R,'HLFP1');
        R = rmfield(R,'HLFP2');
    end