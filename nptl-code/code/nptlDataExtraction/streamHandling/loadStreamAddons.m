function [str] = loadStreamAddons(participant,session,block, streamdir, streamvar)
% LOADSTREAMWITHADDONS    
% 
% [str] = loadStreamWithAddons(participant,session,block, streamdir, streamvar)
% streamdir: e.g. 'spikeband' or 'lfpband'
% streamvar: e.g. 'spikeband' or 'lfpband'


    switch participant
      case 't6'
        indir = sprintf('/net/derivative/stream/%s/%s/%s/',participant, session, streamdir);
        str = loadvar(sprintf(['%s%g'], indir, block), streamvar);
      case {'t7','t5'}
        arrays = {'_Lateral','_Medial'};
        for narray=1:numel(arrays)
            try
                indir = sprintf('/net/derivative/stream/%s/%s/%s/%s/',...
                                participant, session, streamdir,arrays{narray});
                strtmp{narray} = loadvar(sprintf(['%s%g'], indir, ...
                                              block), streamvar);
            catch
                warning(lasterr)
                str{narray} = [];
            end
        end

        str = vertcatTwoStructsByClock(strtmp{1}, strtmp{2});
    end
