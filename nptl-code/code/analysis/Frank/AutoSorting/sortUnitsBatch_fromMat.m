paths = getFRWPaths( );

addpath(genpath([paths.codePath 'code/analysis/Frank/AutoSorting']));
saveDir = [paths.dataPath filesep 'sortedUnits'];

arrayNames = {'_array1','_array2'};
sessionList = {'t5.2017.09.20',[1 2 3 4 5 6]; };

mkdir([paths.dataPath filesep 'tmpSortingJunk']);
cd([paths.dataPath filesep 'tmpSortingJunk']);

%%
for s=1:size(sessionList,1)
    disp(sessionList{s,1}); 
    resultDir = [saveDir filesep sessionList{s,1} '.' num2str(sessionList{s,2}(1)) '-' num2str(sessionList{s,2}(end))];
    mkdir(resultDir);
    
    globalChanOffset = 0;
    for a=1:length(arrayNames)
        ns5Dir = ['/net/derivative/sort/' sessionList{s,1}(1:2) filesep sessionList{s,1} filesep];
        
        %preload all data
        neuralData = cell(length(sessionList{s,2}),1);
        ns5Breaks = [];
        for b=1:length(sessionList{s,2})
            disp(b);
            fileName = dir([ns5Dir '*' num2str(sessionList{s,2}(b),'%0.3d') arrayNames{a} '_forSorting.mat']);
            fileName = [ns5Dir fileName(end).name];
            neuralData{b} = load(fileName);
            ns5Breaks = [ns5Breaks, length(neuralData{b}.nsxDat)];
        end

        for c=1:96
            try
                data = [];
                for b=1:length(neuralData)
                    data = [data, double(neuralData{b}.nsxDat(:,c))'];
                end

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

%%
%package results
for s=3:size(sessionList,1)
    disp(sessionList{s,1}); 
    resultDir = [saveDir filesep sessionList{s,1} '.' num2str(sessionList{s,2}(1)) '-' num2str(sessionList{s,2}(end))];
    
    globalChanOffset = 0;
    spikeTimes = cell(0);
    spikeWaveforms = cell(0);
    unitIdentity = [];
    globalUnitIdx = 1;
    ns5FileBreaks = cell(0);
    
    for a=1:length(arrayNames)
        for c=1:96
            disp(c);
            newFileName = [resultDir filesep 'chan' num2str(c+globalChanOffset) ' sorted spikes.mat'];
            tmp = load(newFileName);
            
            unitList = unique(tmp.cluster_class(:,1));
            unitList(unitList==0)= [];
            nUnits = length(unitList);
            if nUnits==0
                continue;
            end
            
            for n = 1:nUnits
                spikeIdx = tmp.cluster_class(:,1)==unitList(n);
                
                spikeTimes{globalUnitIdx} = tmp.index(spikeIdx);
                spikeWaveforms{globalUnitIdx} = tmp.spikes(spikeIdx,:);
                unitIdentity = [unitIdentity; [globalUnitIdx, a, c, unitList(n)]];
                ns5FileBreaks{globalUnitIdx} = cumsum(tmp.ns5Breaks)/30;
                
                globalUnitIdx = globalUnitIdx + 1;
            end
        end
    end
    
    spikeTimesPerBlock = spikeTimes;
    for c=1:length(spikeTimes)
        spikeTimesPerBlock{c} = cell(length(ns5FileBreaks{c}),1);
        tmpBreaks = [0, ns5FileBreaks{c}];
        for b=1:length(ns5FileBreaks{c})
            spikeIdx = spikeTimes{c}>=tmpBreaks(b) & spikeTimes{c}<=tmpBreaks(b+1);
            spikeTimesPerBlock{c}{b} = spikeTimes{c}(spikeIdx) - tmpBreaks(b);
        end
    end
    
    save([resultDir filesep 'packaged.mat'],'spikeTimes','spikeWaveforms','unitIdentity','ns5FileBreaks','spikeTimesPerBlock');
end