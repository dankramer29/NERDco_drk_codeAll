function matchBlocksNoSyncSignal(sessionID, blockNum, options)
% function matchBlocksNoSyncSignal(sessionID, blockNum, options)
%
% uses the filelogged broadband data to sync blocks with ns5s
%
% options.blocksFile - the blocks file to read and write
%   defaults to /net/derivative/stream/[PID]/[SESSIONID]/blocks.mat
%

dotind = strfind2(sessionID,'.',1);
pid = sessionID(1:dotind-1);

options.foo = false;
if ~isfield(options, 'blocksFile')
    options.blocksFile = sprintf(['/net/derivative/stream/%s/%s/' ...
                        'blocks.mat'],pid,sessionID);
end

if ~isfield(options, 'displayStats')
    options.displayStats = false;
end

blocks = loadvar(options.blocksFile, 'blocks');

bids = [blocks.blockId];
if any(bids==blockNum)
    error(sprintf(['matchBlocksNoSyncSignal: already have a match ' ...
                   'for %s block %i'], sessionID, blockNum));
end


if ~isfield(options, 'arrays')
    switch pid
      case 't6'
        options.arrays={''};
      case 't7'
        options.arrays={'_Lateral','_Medial'};
    end
end

for narray = 1:numel(options.arrays)
    arraytxt = '';
    if ~isempty(options.arrays{narray})
        arraytxt = sprintf('%s/',options.arrays{narray});
    end
    centralDirs{narray} = sprintf(['/net/experiments/%s/%s/Data/%sNSP ' ...
                        'Data/'],pid,sessionID,arraytxt);
end

%% pull out the CAR'd cerebus frame
stream = parseDataDirectoryBlock(sprintf(['/net/experiments/%s/%s/' ...
                    'Data/FileLogger/%i'], pid, sessionID, ...
                                         blockNum));

%% let's skip ahead 20 seconds, and take 20 seconds of data
startind = 20*1000*30;
endind = startind+20*1000*30;
% also be sure to get the row-ordering correct...
cbframe=stream.neural.cerebusFrame';
cbframe=cbframe(:);

%% filtering produces sharper peaks in the xcorr
filt = spikesMediumFilter();
cbframe = filt.filter(cbframe);

cbframe = cbframe(startind:endind);
cbframestart = stream.neural.clock(startind/30);


%% get the .ns5 files that already have matching xpc blocks
alreadyMatched = {};
for nn = 1:numel(blocks)
    alreadyMatched{end+1} = blocks(nn).nsxFile{1};
end

targetNevs = dir(fullfile(centralDirs{1},'*.ns5'));
unmatched = setdiff({targetNevs.name}, alreadyMatched);


maxCrossCorr = zeros(size(unmatched));
for nf = 1:numel(unmatched)
    fn = fullfile(centralDirs{1}, unmatched{nf});
    nevfn = strcat(fn(1:end-4),'.nev');
    
    %x=openNEV(nevfn,'nosave');
    x=openNSx(fn,'read');

    if ~iscell(x.Data)
        Data = {x.Data};
    else
        Data = x.Data;
    end
    for np = 1:numel(Data)
        d1 = Data{np};
        %% use at max 120s of data
        dlen = min(size(d1,2),120*30000);
        d = double(d1(1,1:dlen)) - mean(double(d1(:,1:dlen)));
        d = filt.filter(d);
        
        co = xcorr(double(cbframe(:)),d(:))/(numel(cbframe));
        % simple diagnostic
        if options.displayStats
            disp(sprintf('%s - %i: %.3f', unmatched{nf}, np, ...
                         max(co)));
        end
        if max(co) > maxCrossCorr(nf)
            maxCrossCorr(nf) = max(co);
            pauseNum(nf) = np;
        end
    end
end
clear x d co d1 cbframe

[~, maxInd] = max(maxCrossCorr);
nf = maxInd;
np=pauseNum(maxInd);
disp(sprintf('Most likely match is %s', unmatched{nf}));

fn = fullfile(centralDirs{1}, unmatched{nf});
ns3fn = fullfile(centralDirs{1}, [unmatched{nf}(1:end-1) '3']);

%% fields to populate
% blockId
% xpcStartTime (one per nsx/array)
% xpcEndTime (one per nsx/array)
% xpcTimes (one row per nsx/array)
% cerebusStartTime (one per nsx/array)
% cerebusEndTime (one per nsx/array)
% cerebusTimes (one row per nsx/array)
% nevFile (cell array, 1 per nsx/array)
% nevPauseBlock (vector, 1 per nsx/array)
% array (cell array)
% nsxFile (cell array, 1 per nsx/array)

blocks(end+1).blockId = blockNum;
blocks(end).nevFile{1} = [unmatched{nf}(1:end-3) 'nev'];
blocks(end).nevPauseBlock(1) = np;
blocks(end).array{1} = options.arrays{1};
blocks(end).nsxFile{1} = unmatched{nf};


%% now get down to brass tacks. match up the datastreams exactly
dstream=openNSx(fn,'read');
ns3stream=openNSx(ns3fn,'read');
if ~iscell(dstream.Data)
    Data = {dstream.Data};
    ns3Data = {ns3stream.Data};
else
    Data = dstream.Data;
    ns3Data = ns3stream.Data;
end

d=double(Data{np}(1,:))-mean(double(Data{np}));
d = filt.filter(d);
clear Data ns3stream

cbframe=stream.neural.cerebusFrame';
cbframe=double(cbframe(:));
cbframe = filt.filter(cbframe);
cbframestart = double(stream.neural.clock(1));

[a,b] = xcorr(cbframe(:),d(:));
[~,maxind] = max(a);
lag = b(maxind);


% positive 'lag" means we need to shift the NSP data forward to
%    match cerebus
if lag > 0
    % xpc recording started before cerebus
    xpcshift = floor(double(lag) / 30)+1;
    blocks(end).xpcStartTime(1) = double(xpcshift);
    blocks(end).cerebusStartTime(1) = 30-mod(lag,30);
else
    % xpc recording started after cerebus
    blocks(end).xpcStartTime(1) = cbframestart;%xpcshift;
    blocks(end).cerebusStartTime(1) = -lag;
end

% ns5 length in nsp samples
cerebusTotal = size(dstream.Data{np},2);
cerebusLength = cerebusTotal-blocks(end).cerebusStartTime(1)+1;

% xpc length in nsp samples
xpcLength = (double(stream.neural.clock(end)) - blocks(end).xpcStartTime(1) + 1)*30;

if cerebusLength > xpcLength
    blocks(end).xpcEndTime(1) = blocks(end).xpcStartTime(1)+xpcLength ...
        / 30;
    blocks(end).cerebusEndTime(1) = blocks(end).cerebusStartTime + xpcLength;
else
    cerebusLength = 30*floor(cerebusLength/30);
    blocks(end).xpcEndTime(1) = blocks(end).xpcStartTime(1) + cerebusLength/30;
    blocks(end).cerebusEndTime(1) = blocks(end).cerebusStartTime + cerebusLength;
end
blocks(end).cerebusTimes(1,:) = [blocks(end).cerebusStartTime blocks(end).cerebusEndTime];
blocks(end).xpcTimes(1,:) = [blocks(end).xpcStartTime ...
                    blocks(end).xpcEndTime];

%% if there are other arrays, match them
for narray = 2:numel(options.arrays)
    %% find files for this array that have already been matched
    alreadyMatched = {};
    for nn = 1:numel(blocks)
        matchingArray = find(strcmp(blocks(nn).array, ...
                                    options.arrays{narray}));
        for nmatched = 1:numel(matchingArray)
            alreadyMatched{end+1} = ...
                blocks(nn).nsxFile{matchingArray(nmatched)};
        end
    end
    targetNevs = dir(fullfile(centralDirs{narray},'*.ns5'));
    unmatched = setdiff({targetNevs.name}, alreadyMatched);

    nxd = double(ns3Data{np})-mean(double(ns3Data{np}));
    clear maxcorr maxlag pausenum

    %% try correlating the noise on the ns3 line
    for nf = 1:numel(unmatched)
        fn = fullfile(centralDirs{narray}, unmatched{nf});
        ns3fn = strcat(fn(1:end-1),'3');
        x=openNSx(ns3fn,'read'); %just get metatags
        if ~iscell(x.Data)
            x.Data = {x.Data};
        end
        xd = double(x.Data{end})-mean(double(x.Data{end}));

        [jnk1,jnk2] = xcorr(nxd,xd);
        [maxcorr(nf), jnk3] = max(jnk1);
        maxlag(nf) = jnk2(jnk3);
        pausenum(nf) = numel(x.Data);
    end
    [~,whichfile] = max(maxcorr);
    disp(sprintf('likely 2nd array match is %s', unmatched{whichfile}));

    fn = fullfile(centralDirs{narray}, unmatched{whichfile});
    ns3fn = strcat(fn(1:end-1),'3');
    x=openNSx(ns3fn,'read'); %just get metatags
    if ~iscell(x.Data)
        x.Data = {x.Data};
    end
    xd = double(x.Data{end})-mean(double(x.Data{end}));

    [jnk1,jnk2] = xcorr(nxd,xd);
    [maxcorr, jnk3] = max(jnk1);
    maxlag = double(jnk2(jnk3));
    %% ns3 files are 2kHz, switch to units of 1kHz
    maxlag = floor(maxlag/2);

    blocks(end).array{narray} = options.arrays{narray};
    blocks(end).nevPauseBlock(narray) = pausenum(whichfile);
    if maxlag > 0
        blocks(end).xpcStartTime(narray) = blocks(end).xpcStartTime(1)+maxlag;
        blocks(end).cerebusStartTime(narray) = blocks(end).cerebusStartTime(1)+maxlag*30;
    else
        if abs(maxlag) >= blocks(end).xpcStartTime(1)
            blocks(end).xpcStartTime(narray) = ...
                blocks(end).xpcStartTime(1);
            blocks(end).cerebusStartTime(narray) = ...
                blocks(end).cerebusStartTime(1) - maxlag*30;
        else
            blocks(end).xpcStartTime(narray) = ...
                blocks(end).xpcStartTime(1)+maxlag;
            blocks(end).cerebusStartTime(narray) = ...
                blocks(end).cerebusStartTime(1);
        end
        disp('second array starts before first');
    end

    % ns5 length in nsp samples (convert from 2kHz samples (ns3))
    cerebusTotal = size(x.Data{end},2)*15;
    cerebusLength = cerebusTotal-blocks(end).cerebusStartTime(narray)+1;
    
    % xpc length in nsp samples
    xpcLength = (double(stream.neural.clock(end)) - blocks(end).xpcStartTime(narray) + 1)*30;

    if cerebusLength > xpcLength
        blocks(end).xpcEndTime(narray) = blocks(end).xpcStartTime(narray)+xpcLength ...
            / 30;
        blocks(end).cerebusEndTime(narray) = blocks(end).cerebusStartTime(narray) + xpcLength;
    else
        cerebusLength = 30*floor(cerebusLength/30);
        blocks(end).xpcEndTime(narray) = blocks(end).xpcStartTime(narray) + cerebusLength/30;
        blocks(end).cerebusEndTime(narray) = blocks(end).cerebusStartTime(narray) + cerebusLength;
    end
    blocks(end).cerebusTimes(narray,:) = [blocks(end).cerebusStartTime(narray) blocks(end).cerebusEndTime(narray)];
    blocks(end).xpcTimes(narray,:) = [blocks(end).xpcStartTime(narray) ...
                        blocks(end).xpcEndTime(narray)];

    blocks(end).nevFile{narray} = [unmatched{whichfile}(1:end-3) 'nev'];
    blocks(end).nsxFile{narray} = unmatched{whichfile};

end

save(options.blocksFile,'blocks');


        %dn1 = datenum(dstream.MetaTags.DateTimeRaw([1 2 4 5 6 7]));
        %dn2 = datenum(x.MetaTags.DateTimeRaw([1 2 4 5 6 7]));
        
        %diffnum(nf) = dn1 - dn2;

        %headerVec{nf} = x.RawData.DataHeader-dstream.RawData.DataHeader;
