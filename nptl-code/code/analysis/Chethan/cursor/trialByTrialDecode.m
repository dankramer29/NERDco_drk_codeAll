function trialByTrialDecode(parti,sess,block)

    edir = ['/net/experiments/' parti '/' sess '/'];
    rdir = ['/net/derivative/R/' parti '/' sess '/'];

    

    R = parseBlockInSession(block,true,false,edir,rdir);
    
global modelConstants
    filterFiles = dir([edir modelConstants.filterDir '*.mat']);
    [selection, ok] = listdlg('PromptString', 'Select a filter file:', 'ListString', {filterFiles.name}, ...
                              'SelectionMode', 'Single', 'ListSize', [300 300]);

    if ~(ok)
        return
    end
    modelFile = [edir modelConstants.filterDir filterFiles(selection).name]
    load(modelFile);

    sinds = find(model.C(1:96,3));
    linds = find(model.C(96+(1:96),3));

    
    toptions.isThresh = true;
    toptions.rmsMultOrThresh = model.thresholds;
    toptions.useAcaus=true;
    toptions.delayMotor=0;
    toptions.kinematicVar = 'mouse';
    toptions.useDwell = true;
    toptions.hLFPDivisor = model.hLFPDivisor;
    toptions.dt = model.dtMS;
    toptions.tSkip = 0;
    
    T = onlineTfromR(R,toptions);
    T = applySoftNormToT(T,model.invSoftNormVals);
