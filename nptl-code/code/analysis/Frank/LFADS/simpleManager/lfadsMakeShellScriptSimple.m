function lfadsMakeShellScriptSimple( scriptName, lfadsCodeDir, paramStructs, gpuNum, displayNum, mode )

    fid = fopen([scriptName '.sh'],'w');
    fprintf(fid,'#!/bin/bash');
    
    cudaPathLine = '\nexport LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/';
    fprintf(fid, cudaPathLine);
    
    cvd = ['\nexport CUDA_VISIBLE_DEVICES=' num2str(gpuNum)];
    fprintf(fid, cvd);
    
    displayLine = ['\nexport DISPLAY=:' num2str(displayNum)];
    fprintf(fid, displayLine);
    
    for runIdx = 1:length(paramStructs)
        paramStructs(runIdx).device = ['gpu:' num2str(gpuNum)];
        
        commandLine = lfadsMakeCommandSimple(paramStructs(runIdx), lfadsCodeDir);
        fprintf(fid, ['\n' commandLine]);
        
        if strcmp(mode,'pairedSampleAndAverage')
            tmp = paramStructs(runIdx);
            tmp.kind = 'posterior_sample_and_average';
            tmp.batch_size = 1024;
            
            commandLine = lfadsMakeCommandSimple(tmp, lfadsCodeDir);
            fprintf(fid, ['\n' commandLine]);
        end
    end
    
    fclose(fid);
end

