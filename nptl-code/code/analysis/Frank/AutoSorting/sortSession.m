function sortSession(tmpFilePath, saveDir, sessionDir, sessionName, blockList, arrayNames)
    disp(sessionName); 
    resultDir = [saveDir filesep sessionName '.' num2str(blockList(1)) '-' num2str(blockList(end))];
    mkdir(resultDir);
    
    cd(tmpFilePath);
    
    globalChanOffset = 0;
    for a=1:length(arrayNames)
        ns5Dir = [sessionDir filesep 'Data' filesep arrayNames{a} filesep 'NSP Data' filesep];
        for c=1:96
            try
                data = [];
                ns5Breaks = [];
                for b=1:length(blockList)
                    fileName = dir([ns5Dir num2str(blockList(b)) '_*.ns5']);
                    fileName = [ns5Dir fileName(end).name];
                    neuralData = openNSx_v620(fileName, 'read', ['c:' num2str(c)]);
                    if iscell(neuralData.Data)
                        neuralData.Data = neuralData.Data{end};
                    end
                    data = [data, neuralData.Data];
                    ns5Breaks = [ns5Breaks, length(data)];
                end

                data = double(data);
                save('tmp','data');
                Get_spikes;
                Do_clustering;
                load('tmp_spikes.mat','index');
                save('times_tmp.mat','index','ns5Breaks','-append');

                newFileName = [resultDir filesep 'chan' num2str(c+globalChanOffset) ' sorted spikes.mat'];
                copyfile('times_tmp.mat',newFileName);

                newFileName = [resultDir filesep 'chan' num2str(c+globalChanOffset) ' sorted spikes.jpg'];
                copyfile('fig2print_tmp.jpg',newFileName);
            end
            close all;
        end
        globalChanOffset = globalChanOffset + 96;
    end
end