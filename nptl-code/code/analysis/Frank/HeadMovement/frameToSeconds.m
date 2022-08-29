function [ seconds ] = frameToSeconds( timeCode, FPS )
    seconds = timeCode(1)*60*60 + timeCode(2)*60 + timeCode(3) + timeCode(4)/FPS;
end

