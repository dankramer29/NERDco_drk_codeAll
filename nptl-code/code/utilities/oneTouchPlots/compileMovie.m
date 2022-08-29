function compileMovie(movieName, framesDir, outDir, framePrefix, ffmpeg, frameRate)

    if ~exist('ffmpeg','var') || isempty(ffmpeg)
        ffmpeg = '/usr/local/bin/ffmpeg';
    end
    
    
    commandTemplate = '%s -r %.3f -i %s%s%%07d.png -vcodec libx264 -vpre lossless_max %s.mp4';
    tempString=[outDir movieName];
    fullCommand = sprintf(commandTemplate, ffmpeg, frameRate, framesDir, framePrefix, tempString);
    [status,result] = system(fullCommand);
    if status
        disp(result)
    end
