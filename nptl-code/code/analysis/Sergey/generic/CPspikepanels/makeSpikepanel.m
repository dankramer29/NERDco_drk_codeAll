function f=makeSpikepanel(participant, ns5file, options)
% MAKESPIKEPANEL    
% 
% makeSpikepanel(participant, ns5file, options)
%
% utility to make spikepanel figure
% input arguments:
%   participant (string) - currently handles 's3', 't6', 't7'
%       (note: this really only sets the mapping of electrode numbers to spikepanel position, and this turns
%        out to be identical for these 3 participants / 4 arrays)
%
%   ns5file (string) - full path to the ns5 (30kHz broadband) file being processed
%
%   options (struct) - various important plotting and processing options, see source file for more info
%
% subdirectory "utils/" must be in path.
%
% (c) Chethan Pandarinath, 2015-04

%%processing options
options.participant = participant;
options = setDefault(options, 'narray', 1); % for the given participant, which array
options = setDefault(options,'CAR', true); % perform common avg referencing
options = setDefault(options,'showChannelNums',false); % show channel
options = setDefault(options,'removeCoincident', true); % remove coincident events
options = setDefault(options,'thresholdMultiplier', -4.5); % what threshold to use
options = setDefault(options,'ylim',[-150 150]); % y limits in uV
options = setDefault(options,'yscaling', 0.25); % newer data (e.g., T6, T7) has a 4x multiplier on 
                                                % the raw voltage values read by NPMK. older (e.g. S3) does not.
options = setDefault(options, 'startTime', 60); % (seconds) how far into the recording to start
options = setDefault(options, 'secondsToShow', 60); % (seconds) how much of the recording to use

if isunix
    global dispUnixWarning
    if isempty(dispUnixWarning)
        warning(['for UNIX machines, the ''patchline'' function ' ...
                 'requires that ''opengl software'' be called in ' ...
                 'startup.m. otherwise plots will be blank.']);
        dispUnixWarning = true;
    end
end


% cerebus times
ct=(options.startTime + [0 options.secondsToShow])*30000;

%% load the data for that amount of time
tic;
timeString = sprintf('t:%i:%i',ct(1),ct(2));
ns5 = openNSx('read',ns5file, timeString);
data = single(ns5.Data);
t=toc;
disp(sprintf('took %f seconds for data load',t));

%% perform CAR
if options.CAR
    tic;
    x=mean(data);
    for nch = 1:size(data,1)
        data(nch,:) = data(nch,:) - x;
    end
    t=toc;
    disp(sprintf('took %f seconds for CAR',t));
end

%% perform spikesMedium filtering
tic;
filt = spikesMediumFilter();
for nch = 1:size(data,1)
    data(nch,:) = filt.filter(data(nch,:)')';
end
t=toc;
disp(sprintf('took %f seconds for spikesmedium',t));

f=plotTxPanel(data, options); %-4, participant, 1, [-150 150], true)
set(f, 'paperposition',[0.5 0.5 5.5 5.5]);

