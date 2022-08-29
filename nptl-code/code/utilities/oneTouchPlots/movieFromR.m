function movieFromR(R, outputDir, filter)
% MOVIEFROMR    
% 
% movieFromR(R, outputDir)

% slight modification of old runGenerateMovie script

    taskDetails = R(1).taskDetails;
    blockNum = R(1).startTrialParams.blockNumber;
    disp('Making T');
    tic;
    if exist('filter','var')
    else
        Toptions = defaultTOptions();
        T = onlineTfromR(R, Toptions);
    end

    thisTask = R(1).startTrialParams.taskType;
    switch thisTask
      case cursorConstants.TASK_NEURAL_OUT_MOTOR_BACK
        modelInput.isCenterOut = true;
      case cursorConstants.TASK_CENTER_OUT
        modelInput.isCenterOut = true;
      otherwise
        modelInput.isCenterOut = false;
    end
    modelInput.binWidth = Toptions.dt;

    % [T, modelInput] = RtoT(R,taskDetails,blockNum);

    modelInput.modelID = '';
    toc;
    xTrial=TtoXtrial(T,modelInput);
    
    %mParams.p=modelInput.dt/1000;
    mParams.p = Toptions.dt/1000;
    mParams.NUM_FRAMES_SKIP=1;
    mParams.movieName=num2str(blockNum);
    mParams.outDir=outputDir;
    mParams.drawFiringRates = false;
    mParams.drawSpeeds = true;
    mParams.drawAccel = true;
    mParams.drawSingleChannelDecode = false;
    mParams.drawClickState = true;
    mParams.dt = Toptions.dt;

    mParams.frameRate = 1/mParams.p;

    mParams.taskName = R(1).taskDetails.taskName;
    %% get important task parameters for each task type
    switch mParams.taskName
      case 'cursor'
        fieldsToGet = {'targetDiameter','cursorDiameter','hmmClickLikelihoodThreshold','hmmClickSpeedMax'};
        R(1).startTrialParams.cursorDiameter = getCursorDiameter(R);
      case 'keyboard'
        fieldsToGet={'cuedTarget','keyboard','keyboardDims','hmmClickLikelihoodThreshold','hmmClickSpeedMax'};
    end
    for nf = 1:numel(fieldsToGet)
        mParams.taskParams.(fieldsToGet{nf}) = ...
            R(1).startTrialParams.(fieldsToGet{nf});
    end

    oneTouchMovie(mParams,xTrial);
    

        function Topts = defaultTOptions()

        Topts.isThresh = false;
        Topts.rmsMultOrThresh = -3;
        Topts.dt = 100;
        Topts.delayMotor = 0;
        Topts.kinematicVar = 'mouse';
        Topts.useAcaus = true;
        Topts.tSkip = 0;
        Topts.useDwell = true;
        Topts.hLFPDivisor = 2500;
        Topts.normalizeRadialVelocities = false;
        Topts.eliminateFailures = false;
        Topts.excludeLiftoffs = false;
        Topts.gaussSmoothHalfWidth = 0;
        Topts.useSqrt = false;
        Topts.eliminateDelay = false;
        Topts.skipNeuralData = true;
        end
    end
