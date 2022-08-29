function out = getBlockTypes(dataDir)
    % Call this in the FileLogger directory of a raw data directory.
    % Returns a stuct array wich fields .blockNum and .taskType.
    % For example, call as blocks = getBlockTypes('/net/experiments/t6/t6.2014.06.30/Data/FileLogger')
    l = dir(dataDir);
    out=struct;
    oind = 1;
    for n=1:numel(l)
        if ~any(strcmp(l(n).name,{'.','..'})) && l(n).isdir
            b=parseDataDirectoryBlock(fullfile(dataDir,l(n).name),{'continuous','discrete','decoderC','decoderD', ...
                                'system','neural','meanTracking'});
            if ~isempty(b.taskDetails)
                out(oind).blockNum = str2double(l(n).name);
                out(oind).taskType = b.taskDetails.taskName;
                oind = oind+1;
            end
        end
    end
