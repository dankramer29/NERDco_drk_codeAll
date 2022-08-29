function packageSortResults(sessionName, saveDir, arrayNames, blockList)
    disp(sessionName); 
    resultDir = [saveDir filesep sessionName '.' num2str(blockList(1)) '-' num2str(blockList(end))];
    
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
            if ~exist(newFileName,'file')
                continue;
            end
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
                ns5FileBreaks{globalUnitIdx} = (tmp.ns5Breaks)/30;
                
                globalUnitIdx = globalUnitIdx + 1;
            end
        end
        globalChanOffset = globalChanOffset + 96;
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