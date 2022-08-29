function runGenerateMovie(oneTouchOutputDir,participantID,sessionID,blockNum)
    inDir = ['/net/derivative/R/' participantID '/' sessionID '/'];

    R = loadvar([inDir 'R_' num2str(blockNum)],'R');
    taskDetails = loadvar([inDir 'R_' num2str(blockNum)],'taskDetails');
    disp('Making T');
    tic;
    [T, modelInput] = RtoT(R,taskDetails,blockNum);
    modelInput.modelID = '';
    toc;
    xTrial=TtoXtrial(T,modelInput);
    mParams.p=modelInput.dt/1000;
    mParams.NUM_FRAMES_SKIP=1;
    mParams.movieName=num2str(blockNum);
    mParams.outDir=[oneTouchOutputDir participantID '/' sessionID '/'];
    oneTouchMovie(mParams,xTrial);
    