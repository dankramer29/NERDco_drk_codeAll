function remakeR(datestr,blocknums)

for nb = 1:length(blocknums)
    blocknum = blocknums(nb);

    try
        clear block;
        block = parseDataDirectoryBlock(['/net/experiments/Q/'...
            datestr '/nptlBrainGateRig/session/data/blocks/rawData/' num2str(blocknum) '/']);
        
        clear R;
        taskParseCommand = ['R = ' block.taskDetails.taskName '_streamParser(block);'];
        eval(taskParseCommand);
        
        %     R = cursor_streamParser(block);
        taskDetails = block.taskDetails;
        
        save(['/net/derivative/R/Q/' datestr '/R_' num2str(blocknum)],'R','taskDetails');
    catch
        [a,b] = lasterr
        disp(['skipping ' num2str(blocknum) ', perhaps it is an aborted block?']);
        blockSkipped = true;
    end
end

