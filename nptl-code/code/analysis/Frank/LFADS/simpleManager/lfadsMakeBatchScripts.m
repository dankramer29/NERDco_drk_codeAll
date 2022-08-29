function lfadsMakeBatchScripts( scriptDir, dataDir, outputDir, lfadsCodeDir, ...
    datasetNames, paramStructs, availableGPU, displayNum, mode )

    nRuns = length(datasetNames);
    nGPU = length(availableGPU);
    
    gpuIdx = 1;
    runAssign = zeros(nRuns,1);
    for n=1:nRuns
        runAssign(n) = availableGPU(gpuIdx);
        gpuIdx = gpuIdx + 1;
        if gpuIdx > length(availableGPU)
            gpuIdx = 1;
        end
    end
    
    for g=1:nGPU
        runIdx = find(runAssign == availableGPU(g));
        if isempty(runIdx)
            continue;
        end
        
        for r=1:length(runIdx)
            paramStructs(runIdx(r)).data_dir = dataDir;
            paramStructs(runIdx(r)).data_filename_stem = datasetNames{runIdx(r)};
            paramStructs(runIdx(r)).lfads_save_dir = [outputDir '/' num2str(runIdx(r))];
        end
        
        lfadsMakeShellScriptSimple( [scriptDir 'gpu' num2str(availableGPU(g))], lfadsCodeDir, paramStructs(runIdx), ...
            availableGPU(g), displayNum, mode );
    end
    
    %master script that tmuxes everything
    fid = fopen([scriptDir 'master.sh'],'w');
    fprintf(fid,'#!/bin/bash');
    
    for g=1:nGPU
        newLine = ['\ntmux new-session -d -s lfads_tmux_gpu_' num2str(availableGPU(g)) ' ''sh ./gpu' num2str(availableGPU(g)) '.sh''']; 
        fprintf(fid, newLine);
    end
    
    fclose(fid);
end

