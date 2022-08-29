%%
sessionList = {
    't5.2019.06.26'}; %many balanced words (1000)   

for sessionIdx=1:size(sessionList,1)
    
    sessionName = sessionList{sessionIdx, 1};
    
    %%
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));
 
    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceFormat' filesep sessionName];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep sessionName filesep];
    
    %%
    %load aligned data cube
    cubeDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'Cubes'];
    fileName = [cubeDir filesep sessionName '_warpedCube.mat'];
    dat = load(fileName);
    
    %%
    %load full data and words
    load([paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'letterSequenceTrials' filesep sessionName '_share.mat']);
    
    %%
    %unroll conditions
    unrollSpikes = zeros(1000000,size(dat.a,3));
    eventIdx = [];
    trlCodes = [];
    
    fNames = fieldnames(dat);
    fNames = fNames(1:(end-3));
    currIdx = 1;
    
    remIdx = [];
    for x=1:length(fNames)
        if strcmp(fNames{x}(end),'T')
            remIdx = [remIdx, x];
        end
    end
    fNames(remIdx) = [];
    
    for x=1:length(fNames)
        disp(fNames{x});
        for t=1:size(dat.(fNames{x}),1)
            eventIdx = [eventIdx, currIdx+50];
            trlCodes = [trlCodes, x];
            
            nSteps = size(dat.(fNames{x}),2);
            unrollSpikes(currIdx:(currIdx+nSteps-1),:) = squeeze(dat.(fNames{x})(t,:,:));
            currIdx = currIdx + nSteps;
        end
    end
    
    unrollSpikes(currIdx:end,:) = [];
    
    %%
    %apply mPCA to alphabet conditions
    codeSets = {1:26, 27:30};
    smoothSpikes_blockMean = gaussSmooth_fast(unrollSpikes, 0);
    
    timeWindow_mpca = [-500,2000];
    tw =  timeWindow_mpca/binMS;
    tw(1) = tw(1) + 1;
    tw(2) = tw(2) - 1;
    
    twWords = [-49, 800];

    margGroupings = {{1, [1 2]}, {2}};
    margNames = {'Condition-dependent', 'Condition-independent'};
    opts_m.margNames = margNames;
    opts_m.margGroupings = margGroupings;
    opts_m.nCompsPerMarg = 5;
    opts_m.makePlots = true;
    opts_m.nFolds = 10;
    opts_m.readoutMode = 'singleTrial';
    opts_m.alignMode = 'rotation';
    opts_m.plotCI = true;
    opts_m.nResamples = 10;

    mPCA_out = cell(length(codeSets),1);
    for pIdx=1:length(codeSets) 
        trlIdx = find(ismember(trlCodes, codeSets{pIdx}));
        if isempty(trlIdx)
            continue
        end
        
        mc = trlCodes(trlIdx)';
        [~,~,mc_oneStart] = unique(mc);

        if pIdx==2
            twUse = twWords;
        else
            twUse = tw;
        end
            
        mPCA_out{pIdx} = apply_mPCA_general( smoothSpikes_blockMean, eventIdx(trlIdx), ...
            mc_oneStart, twUse, binMS/1000, opts_m );
    end

    %%
    %template decoding
    %refine with a warped-template approach
    in.makePlot = true;
    in.initMode = 'warpToInitialDecode';
    in.allLabels = allLabels;
    in.uniqueCodes_noNothing = uniqueCodes_noNothing;
    in.fullCodes = fullCodes;
    in.alignDat = alignDat;
    in.smoothSpikes_align = smoothSpikes_align;
    %in.smoothSpikes_align = mPCA_out{1}.readoutZ_unroll(:,1:2);
    in.curveCodes = codeSets{2};
    in.wordCodes = codeSets{3};
    in.velInit = decVel;
    in.trlCodes = trlCodes;
    in.sessionName = sessionName;
    in.templates = allTemplates;
    in.templateCodes = allTemplateCodes;
    in.timeWindows = [allTimeWindows(:,1)+1, allTimeWindows(:,2)-1];
    in.fixTemplateSize = false;
    
    if isempty(decVel)
        %if we don't have straight line movements we can use to make an
        %initial decoder, load warped templates from a previous day
        if strcmp(sessionName,'t5.2019.05.08')
            loadDir = [paths.dataPath filesep 'Derived' filesep 'Handwriting' filesep 'allAlphabets' filesep 't5.2019.05.01'];
        end
        
        warpTemp = load([loadDir 'warpedTemplates.mat']);
        
        in_pre = in;
        in_pre.initMode = 'useLoadedWarps';
        in_pre.preWarpTemp = warpTemp.out.warpedTemplates;
        in_pre.preWarpCodes = [letterCodes, curveCodes(1:8), wordCodes(1:4)];
        out = makeTemplateDecoder( in_pre );
        
        in.velInit = out.decVel(:,1:2);
    end
        
    out = makeTemplateDecoder( in );
    close all;
    
    %iterate again for datasets that need it
    in.velInit = out.decVel(:,1:2);
    out = makeTemplateDecoder( in );
    
    save([outDir 'warpedTemplates.mat'],'out');
    close all;
    
end %all sessions