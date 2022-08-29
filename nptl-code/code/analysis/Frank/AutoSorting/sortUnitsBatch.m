paths = getFRWPaths( );

addpath(genpath([paths.codePath 'code/analysis/Frank/AutoSorting']));
saveDir = [paths.dataPath 'sortedUnits'];

arrayNames = {'_Lateral','_Medial'};
sessionList = {'t5.2016.09.28',[4 6];
    't5.2016.09.28',[7 8 9 10]; };

mkdir([paths.dataPath filesep 'tmpSortingJunk']);
cd([paths.dataPath filesep 'tmpSortingJunk']);

%%
for s=1:size(sessionList,1)
    disp(sessionList{s,1}); 
    resultDir = [saveDir filesep sessionList{s,1} '.' num2str(sessionList{s,2}(1)) '-' num2str(sessionList{s,2}(end))];
    mkdir(resultDir);
    if strcmp(sessionList{s,1}(1:2),'t5')
        blockNumOffset = 1;
    else
        blockNumOffset = 0;
    end
    
    globalChanOffset = 0;
    for a=1:length(arrayNames)
        ns5Dir = [getBGSessionPath(sessionList{s,1}) filesep 'Data' filesep arrayNames{a} filesep 'NSP Data' filesep];
        for c=1:96
            try
                data = [];
                ns5Breaks = [];
                for b=1:length(sessionList{s,2})
                    fileName = dir([ns5Dir '*-' num2str(sessionList{s,2}(b)+blockNumOffset,'%0.3d') '.ns5']);
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