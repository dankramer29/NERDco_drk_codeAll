function blocks = parseCentralDataDirectory(participantID,sessionID)
%% it's the caller's responsibility to figure out where to put this data
% streamDir = '/net/derivative/stream/';
experimentDir = [participantID '/' sessionID '/'];

global modelConstants
if isempty(modelConstants)
    modelConstants = modelDefinedConstants();
end

baseDir = '/net/experiments/';
dirName0 = [baseDir participantID '/' sessionID '/' modelConstants.dataDir ];

if ~exist('dirName0','dir')
    dirName0=strrep(dirName0,'\','/');
end

assert(exist(dirName0, 'dir') ~= 0, ['Cant find directory ' dirName0]);
disp(sprintf('browsing %s',dirName0));

htext = '*.nev';

dataDirs = participantNSPDirectories(participantID);

blocks=[];

numBlocks = 0;
for nd = 1:length(dataDirs)
    dirName = [dirName0 '/' dataDirs{nd} '/' modelConstants.nevDir];
    disp(sprintf('browsing %s',dirName));

    %% get NEV files
    nevFiles = getFiles(dirName, htext);
    
    %% get the block numbers and timestamps in each nev file
    %% then find out how many blocks are represented, which files they are in, and what
    %% timestamps they span
    for nnev = 1:length(nevFiles)
        disp(nevFiles(nnev).name);
        fullFn = [dirName nevFiles(nnev).name];
        nevs(nnev) = openNEV('read', 'nosave', fullFn);
        
        ts = extractNevSerialTimeStamps(nevs(nnev));

        %nevs(nnev).Data.SerialDigitalIO.UnparsedData);
        if isempty(ts) | isempty(fields(ts))
            if exist([fullFn(1:end-4) '.ns3'])
                try
                    ts = extractNS3BNCTimeStamps(fullFn(1:end-4));
                catch
                    disp('timestamp extraction failed');
                    ts = [];
                end
            else
                disp('no ns3 file found, skipping')
            end
        end

        if isempty(ts) | ~numel(fields(ts))
            disp('no info found in this ns3 file');
            continue;
        end

        for nc = 1:length(ts)
            if ~isempty(ts(nc).blockId)
                [blockIds1, startInds] = unique(ts(nc).blockId, 'first');
                [blockIds2, endInds] = unique(ts(nc).blockId, 'last');
                assert(all(blockIds1 == blockIds2), 'start and end ids dont match up');
                %% NOTE: CURRENTLY ASSUMES BLOCK IS ENTIRELY CONTAINED IN SINGLE NEV
                for nb = 1:length(blockIds1)
                    %% get rid of 1-block glitches
                    if startInds(nb) == endInds(nb)
                        continue;
                    end
                    %% sometimes we catch the tail end of a previous block in the file. 
                    %% (if cerebus was stopped before xPC). If so,
                    %% we don't want to record that as a block. so we set an arbitrary cutoff
                    %% (e.g. 5 min) - if xPCStartTime is greater than that, skip this "block"
                    %% it is likely in another NEV file
                    
                    if ts(nc).xpcTime(startInds(nb)) < 1000* 5*60
                        if isempty(blocks)
                            numBlocks = 1;
                            xtmp = numBlocks;
                            nfnum=1;
                            blocks(xtmp).blockId = blockIds2(nb);
                        else
                            xtmp = find([blocks.blockId] == blockIds2(nb));
                            %% have we logged this block for a different nev file yet?
                            if isempty(xtmp)
                                numBlocks = numBlocks+1;
                                xtmp = numBlocks;
                                nfnum = 1;
                                blocks(xtmp).blockId = blockIds2(nb);
                            else
                                nfnum = length(blocks(xtmp).xpcStartTime)+1;
                            end
                        end
                        blocks(xtmp).xpcStartTime(nfnum) = ts(nc).xpcTime(startInds(nb));
                        blocks(xtmp).xpcEndTime(nfnum) = ts(nc).xpcTime(endInds(nb));
                        blocks(xtmp).xpcTimes(nfnum,:) = [blocks(xtmp).xpcStartTime(nfnum) ...
                                            blocks(xtmp).xpcEndTime(nfnum)];
                        blocks(xtmp).cerebusStartTime(nfnum) = ts(nc).cerebusTime(startInds(nb));
                        blocks(xtmp).cerebusEndTime(nfnum) = ts(nc).cerebusTime(endInds(nb));
                        blocks(xtmp).cerebusTimes(nfnum,:) = [blocks(xtmp).cerebusStartTime(nfnum) blocks(xtmp).cerebusEndTime(nfnum)];
                        if length(dataDirs{nd})
                            fn = [nevFiles(nnev).name];
                            %fn = [dataDirs{nd} '/' modelConstants.nevDir nevFiles(nnev).name];
                        else
                            fn = [modelConstants.nevDir nevFiles(nnev).name];
                        end
                        blocks(xtmp).nevFile{nfnum}=fn;
                        NEVnum = ts(nc).NEVnum;
                        if numel(NEVnum)>1 && ~all(NEVnum==NEVnum(1))
                            error('parseCentralDataDirectory: invalid NEVnum for this block');
                        end
                        blocks(xtmp).nevPauseBlock(nfnum) = NEVnum(1);
                        blocks(xtmp).array{nfnum} = dataDirs{nd};
                    end
                end
            end
        end
    end
end

allids = [blocks.blockId];

toKeep = true(size(blocks));
for nn = 1:length(allids)
    blockswiththisid = find(allids==allids(nn));
    if any(blockswiththisid~=nn)
        warning(sprintf('block %g is repeated in multiple nev files. keeping the longer one',allids(nn)));
        for ii = 1:length(blockswiththisid)
            blength(ii) = abs(diff(blocks(blockswiththisid(ii)).xpcTimes));
        end
        
        [jnk, longestwiththisid] = max(blength);
        toKeep(blockswiththisid) = false;
        toKeep(blockswiththisid(longestwiththisid)) = true;
    end
end
blocks = blocks(toKeep);
allids = [blocks.blockId];

assert(length(allids) == length(unique([blocks.blockId])), ...
    'error in relationship between blocks and NEV files');

%% get NSX files, match them with the nevFile
htext = '*.ns5';
% actually just getting ns5 file here
nsxfiles = getFiles(dirName, htext);
nsxfilenames={nsxfiles.name};
for nn=1:length(blocks)
    for nf = 1:length(blocks(nn).nevFile)
        %% just assume nsx has same name as nev
        blocks(nn).nsxFile{nf} = [blocks(nn).nevFile{nf}(1:end-3) 'ns5'];
    end
end


function files = getFiles(dirName, template)
files = dir([dirName template ]);
