function [ fileNames ] = getWestNS5FileNames( sessionDir, blockList, subjectCode )
    if strcmp(subjectCode,'t6')
        arrayNames = [];
        nArrays = 1;
    else
        arrayNames = {'_Lateral','_Medial'};
        nArrays = 2;
    end
    fileNames = cell(length(blockList),nArrays);
    for a=1:nArrays
        for b=1:length(blockList)
            if isempty(arrayNames)
                ns5Dir = [sessionDir filesep 'Data' filesep 'NSP Data' filesep];
            else
                ns5Dir = [sessionDir filesep 'Data' filesep arrayNames{a} filesep 'NSP Data' filesep];
            end
            fname = dir([ns5Dir num2str(blockList(b)) '_*.ns5']);
            if isempty(fname)
                fname = dir([ns5Dir '*-' num2str(blockList(b)+1,'%03d') '.ns5']);
            end
            if ~isempty(fname)  
                fileNames{b,a} = [ns5Dir fname(end).name];
            end
        end
    end
end

