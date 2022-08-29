function writeMovie(movDir, framePrefix, frameNum, im)
% WRITEMOVIE    
% 
% writeMovie(movDir, framePrefix, frameNum, im)

    if ~isdir(movDir)
        error([movDir ' is not a directory, create if needed'])
    end
    
    imageType = 'png';
    %imwrite(im, sprintf('%s%s%07.0f.%s', movDir, framePrefix, frameNum, imageType));
    savepng(im, sprintf('%s%s%07.0f.%s', movDir, framePrefix, frameNum, imageType));
    