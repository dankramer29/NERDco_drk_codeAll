%%
datasets = {
    't5.2018.07.30',[4:8, 10:11]
};

%%
for d=1:length(datasets)
    
    paths = getFRWPaths();
    addpath(genpath(paths.codePath));

    %%
    outDir = [paths.dataPath filesep 'Derived' filesep 'decisionMaking' filesep datasets{d,1}];
    mkdir(outDir);
    sessionPath = [paths.dataPath filesep 'BG Datasets' filesep datasets{d,1} filesep];

    %%
    %load, bin and concatenate streams
    bNums = datasets{d,2};
    movField = 'windowsMousePosition';
    filtOpts.filtFields = {'windowsMousePosition'};
    filtOpts.filtCutoff = 10/500;
    [ R, stream ] = getStanfordRAndStream( sessionPath, bNums, 4.5, bNums(1), filtOpts );
    
    binMS = 20;
    smoothWidth = 0;
    datFields = {'rigidBodyPosXYZ','currentTarget','state','stimulusCount','stimConds'};
    
    allOut = [];
    for x = 1:length(stream)
        disp(x);
        out = binStream( stream{x}, binMS, smoothWidth, datFields );
        if isempty(allOut)
            allOut = out;
        else
            fNames = fieldnames(out);
            for f=1:length(fNames)
                allOut.(fNames{f}) = [allOut.(fNames{f}); out.(fNames{f})];
            end
        end
    end
    
    movEpochs = logicalToEpochs(allOut.state==21);
    movLen = movEpochs(:,2)-movEpochs(:,1);
    
    goIdx = movEpochs(:,1);
    trlIdx = find(allOut.stimConds(goIdx,1)==3 & movLen>1);
    
    %compute RT
    rt = zeros(size(movEpochs,1),1);
    vel = diff(allOut.rigidBodyPosXYZ);
    speed = matVecMag(vel,2);
    for t=1:length(rt)
        loopIdx = (goIdx(t)):(goIdx(t)+50);
        rtIdx = find(speed(loopIdx)>0.0015,1,'first');
        if isempty(rtIdx)
            rt(t) = goIdx(t)+20;
        else
            rt(t) = goIdx(t)+rtIdx(1);
        end
    end
    
    %neural data smoothing
    zScoreSpikes = zscore(allOut.rawSpikes);
    smoothSpikes = gaussSmooth_fast(zScoreSpikes,3.0);

    %dPCA
    timeWindow = [-50,50];
    dPCA_out = apply_dPCA_simple( smoothSpikes, rt(trlIdx), ...
        allOut.stimConds(rt(trlIdx),2), timeWindow, 0.02, {'CD','CI'} );
    
    %head position
    colors = hsv(4)*0.8;
    figure
    hold on
    for t=1:4
        subTrlIdx = find(allOut.stimConds(goIdx(trlIdx),2)==t);
        for x=1:length(subTrlIdx)
            loopIdx = (rt(trlIdx(subTrlIdx(x)))-50):(rt(trlIdx(subTrlIdx(x)))+50);
            plot(vel(loopIdx,2),'Color',colors(t,:));
        end
    end
    
    %prep
    [ C, L, obj ] = simpleClassify( smoothSpikes, allOut.stimConds(goIdx(trlIdx),2), goIdx(trlIdx)-25, ...
        {'1','2','3','4'}, 25, 1, 1, true );
    
    %move
    [ C, L, obj ] = simpleClassify( smoothSpikes, allOut.stimConds(goIdx(trlIdx),2), goIdx(trlIdx)+10, ...
        {'1','2','3','4'}, 5, 1, 1, true );
   
end
