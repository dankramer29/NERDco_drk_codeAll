function [Rout, wfs] = addSortedToR(sortedPath,R, dataset, block, ...
                                    ch)

    sortedPath = '/net/home/chethan/localdata/';

    if ~exist('ch','var')
        fullDir = sprintf('%s%s/%g/ch*.nex',...
                          sortedPath,dataset,block);
        allChannelFiles = dir(fullDir);
    end
    nexFile = sprintf('%s%s/%g/ch%g.nex',...
                      sortedPath,dataset,block,ch);
    
    nex = readNexFile(nexFile);
    
    startTime = double(R(1).startcounter);
    %spikeTimes = (nex.neurons{1}.timestamps)*1000+startTime-20.6667*1000; %skip the filter warmup time
    %% this was set at "20.6667" but that seems like an old number,
    %% correct value should be 1
    spikeTimes = (nex.neurons{1}.timestamps)*1000+startTime-1*1000; %skip the filter warmup time
    for nt = 1:length(R)
        st = spikeTimes(between(spikeTimes,[R(nt).startcounter R(nt).endcounter]))-double(R(nt).startcounter);
        Rout(nt).spiketimes = sparse([],[],[],1,size(R(nt).state,2),0);
        sp = ceil(st)+1;        
        Rout(nt).spiketimes(sp)=1;
    end
