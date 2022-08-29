function writeMpegMovie( frames, name, frameRate )
    vidObj = VideoWriter(name,'MPEG-4');
    vidObj.FrameRate = frameRate;
    open(vidObj);
    for f = 1:length(frames)
        writeVideo(vidObj, frames(f));
    end
    close(vidObj);
end

