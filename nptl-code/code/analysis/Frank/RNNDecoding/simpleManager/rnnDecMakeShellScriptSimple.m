function rnnDecMakeShellScriptSimple( scriptName, codeDir, paramStructs, gpuNum, displayNum )

    fid = fopen([scriptName '.sh'],'w');
    fprintf(fid,'#!/bin/bash');
    
    if gpuNum>=0
        cudaPathLine = '\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/';
        fprintf(fid, cudaPathLine);

        cvd = ['\nexport CUDA_VISIBLE_DEVICES=' num2str(gpuNum)];
        fprintf(fid, cvd);
    else
        cudaPathLine = '\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/';
        fprintf(fid, cudaPathLine);

        cvd = ['\nexport CUDA_VISIBLE_DEVICES=""'];
        fprintf(fid, cvd);        
    end
    
    displayLine = ['\nexport DISPLAY=:' num2str(displayNum)];
    fprintf(fid, displayLine);
    
    for runIdx = 1:length(paramStructs)
        if gpuNum>=0
            paramStructs(runIdx).device = ['/gpu:' num2str(gpuNum)];
        else
            paramStructs(runIdx).device = '/cpu:0';
        end
        
        commandLine = rnnDecMakeCommandSimple(paramStructs(runIdx), codeDir);
        fprintf(fid, ['\n' commandLine]);
    end
    
    fclose(fid);
end

