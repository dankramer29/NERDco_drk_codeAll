function blocks = removeBlockfilePauseblockDuplicates(blocks)

for nb = 1:numel(blocks)
    thisBlock=blocks(nb);
    if iscell(thisBlock.nsxFile)
        keep = false(size(thisBlock.array));
        [allArrays,~,arrayInds] = unique(thisBlock.array);
        % restrict to longest segment from each array
        for na=1:numel(allArrays)
            thisInds = find(strcmp(thisBlock.array, ...
                                   allArrays{na}));
            xpclens = diff(thisBlock.xpcTimes(thisInds,:)');
            [~,keepInd] = max(xpclens);
            keep(thisInds(keepInd)) = true;
        end
        thisBlock.xpcStartTime = thisBlock.xpcStartTime(keep);
        thisBlock.xpcEndTime = thisBlock.xpcEndTime(keep);
        thisBlock.xpcTimes = thisBlock.xpcTimes(find(keep),:);
        thisBlock.nevFile = thisBlock.nevFile(keep);
        thisBlock.nsxFile = thisBlock.nsxFile(keep);
        thisBlock.nevPauseBlock = thisBlock.nevPauseBlock(keep);
        thisBlock.array = thisBlock.array(keep);
        thisBlock.cerebusStartTime = thisBlock.cerebusStartTime(keep);
        thisBlock.cerebusEndTime = thisBlock.cerebusEndTime(keep);
        thisBlock.cerebusTimes = thisBlock.cerebusTimes(find(keep), ...
                                                        :);
        blocks(nb) = thisBlock;
    end
end