function MV = decodeMovie(mParams, varargin);
    
%DECODEMOVIE plots offline decodes given xTrial structs.
%   MOVIE = DECODEMOVIE(MPARAMS, XTRIAL1, XTRIAL2, ...) makes a movie of
%   offline decodes.  It takes in an arbitrary amount of xTrials, and puts
%   them all on the offline decode movie simultaneously.  There is a
%   constraint, which is that the xTrials must have a lowest common
%   multiple equal to the maximum bin width amongst the xTrials.  Thus, it
%   is OK to have decodes with 5ms, 10ms, 25ms, and 50ms bins, but not OK
%   to have decodes with 15ms, 35ms, and 50ms bins.  Also, the xTrial's
%   must obviously have the same trial structure.
%
%   The mParams is optional.  It is a struct with movie parameterse.
%   The fields used by the function are:
%       trials  - the trials used by the offline decode.  default: use all.
%       reset   - reset the decode to the hand per trial.  default: 1.
%       p       - the length of pause time between bin updates.
%
%   One way to save the movie as an output, is to run:
%       MOVIE2AVI(movie, 'save path', 'fps', 12, 'compression', 'none');
%       note: there is no compression here.
%
%   Copyright (c) by Jonathan C. Kao

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Preprocessing and initialization
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    assert(~isempty(varargin), 'You did not specify the inputs correctly.');

    mParams.foo = false;
    mParams = setDefault(mParams, 'drawArrows', false, true);
    mParams = setDefault(mParams, 'drawFiringRates', false, true);
    mParams = setDefault(mParams, 'drawSpeeds', false, true);
    mParams = setDefault(mParams, 'drawAccel', false, true);
    mParams = setDefault(mParams, 'drawClickState', false, true);
    mParams = setDefault(mParams, 'drawSingleChannelDecode', false, true);

    if ~isempty(mParams);       localizeFields(mParams);            end
    if ~exist('trials', 'var')  trials  = 1:length(varargin{1});    end
    if ~exist('reset', 'var')   reset   = 1;                        end
    if ~exist('p', 'var')       p   = 0;                            end
    if ~exist('NUM_FRAMES_SKIP','var')
        NUM_FRAMES_SKIP = 5;          % number of frames to skip in saved movie.
    end

    % Format the data in a way easily plottable for movies.
    trialsToKeep = ismember([1:length(varargin{1})], trials);
    for i = 1:length(varargin)
        varargin{i} = varargin{i}(trialsToKeep);
    end

    xMovie = otpBuildXMovie(varargin{:});

    %% add helpful info to xmovie struct
    [xMovie.taskParams] = deal(mParams.taskParams);
    [xMovie.taskType] = deal(mParams.taskName);
    [xMovie.dt] = deal(mParams.dt);
    

    % Parameters and initialization of the data and movie.
    totalBins = xMovie.transitions(end);
    [hf, figAxes] = blackFigure(1, mParams);
    
    % Variables for the movie
    prevT = 1;                      % Counter to keep track of which time we're plotting.
    fi = 1;                         % Counter to keep track of movie frames you're saving.    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% Generate the movie.
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % if we're writing the frames to files
    if exist('outDir','var')
        framesDir = [outDir 'movieFrames/'];
        initializeMovieDir(framesDir, 'frame_', 1, 1);
        fnout = [outDir movieName '.mp4'];
        if exist(fnout,'file')
            disp(sprintf('oneTouchMovie: warning - movie %s already exists, deleting.', fnout));
            delete(fnout);
        end
    end
    % need to notify when it's the first frame
    mParams.firstFrame = true;
    for t = 2:totalBins%130%
        % Draw a frame of the movie
        oneTouchMovieStep(xMovie, t, reset, hf, figAxes, mParams);
        % pause(p);
        drawnow('expose');
        % Save the currently drawn frame.
        if exist('outDir','var')  && mod(t,NUM_FRAMES_SKIP) == 0
            thisFrame=getScreenshot(hf);
            % for some movie encoding algorithms, image sizes must be a multiple of 2.
            if mod(size(thisFrame, 1), 2)
                thisFrame(end+1, :, :) = thisFrame(end, :, :);
            end
            writeMovie(framesDir, 'frame_', fi, thisFrame);
        elseif (nargout > 0 && mod(t,NUM_FRAMES_SKIP) == 0);
            winsize = get(hf, 'Position');
            MV(:,fi) = getframe(hf,[0 0  winsize(3:4)]);
            %MV(:,fi) = getframe(hf);
        end
        fi=fi+1;
        mParams.firstFrame = false;
        %pause(0.001);
    end
    
    if exist('outDir','var')
        fprintf('writing movie: %s\n',movieName);
        compileMovie(movieName, framesDir, outDir, 'frame_',[], mParams.frameRate);
        rmdir(framesDir,'s');
    end
end