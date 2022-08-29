function [str] = loadStreamWithAddons(participant,session,block,streamdir, streamvar)
% function [str] = loadStreamWithAddons(participant,session,block,streamdir, streamvar)
%
%  example usage:
%     stream=loadStreamWithAddons('t6','t6.2014.06.30',9,{'lfpband'},{'lfpband'});
%     stream=loadStreamWithAddons('t6','t6.2014.06.30',9,{'spikeband','lfpband'},{'spikeband','lfpband'});
%
%  both streamdir and streamvar default to {'spikeband','lfpband'}

if ~exist('streamdir','var')
    streamdir={'spikeband','lfpband'};
end

if ~exist('streamvar','var')
    streamvar={'spikeband','lfpband'};
end


fn = sprintf('/net/derivative/stream/%s/%s/%i.mat', ...
             participant,session,block);
str = load(fn);

%% kill the current "neural" stream
str.neural = [];

if ~iscell(streamdir)
    streamdir = {streamdir};
end

if ~iscell(streamvar)
    streamvar = {streamvar};
end

for nn =1:numel(streamdir)
    stra = loadStreamAddons(participant,session,block, ...
                            streamdir{nn},streamvar{nn});
    str=mergeAddonWithStream(str,stra);
end

