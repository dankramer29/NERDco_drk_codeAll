function [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements_withZ( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, otherCurveCodes, makePlot )
    %%
    %makea decoder on arrow conditions
    codeDir = [1,0,0;
               1/sqrt(2), 1/sqrt(2),0;
               0,1,0;
               -1/sqrt(2),1/sqrt(2),0;
               -1,0,0;
               -1/sqrt(2),-1/sqrt(2),0;
               0,-1,0;
               1/sqrt(2),-1/sqrt(2),0;
               1,0,1;
               -1,0,1;
               0,1,1;
               0,-1,1;
               ];

    idxWindow = [20, 50];
    idxWindowPrep = [-50, 0];
    idxWindow_Z = [-50, 100];

    allDir = [];
    allNeural = [];
    
    allDir_Z = [];
    allNeural_Z = [];

    allDir_prep = [];
    allNeural_prep = [];

    for t=1:length(alignDat.eventIdx)
        [LIA,LOCB] = ismember(trlCodes(t),straightLineCodes);
        if LIA
            currDir = codeDir(LOCB,:);
            newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

            loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));
            newNeural = smoothSpikes_align(loopIdx,:);

            allDir = [allDir; newDir];
            allNeural = [allNeural; newNeural];

            %zeroing
            newDir = repmat(currDir, idxWindowPrep(2)-idxWindowPrep(1)+1, 1);
            loopIdx = (alignDat.eventIdx(t)+idxWindowPrep(1)):(alignDat.eventIdx(t)+idxWindowPrep(2));
            newNeural = smoothSpikes_align(loopIdx,:);

            allDir_prep = [allDir_prep; newDir];
            allNeural_prep = [allNeural_prep; newNeural];
        end
        
        [LIA,LOCB] = ismember(trlCodes(t),otherCurveCodes);
        if LIA
            newDir = zeros(idxWindow_Z(2)-idxWindow_Z(1)+1,1);
            loopIdx = (alignDat.eventIdx(t)+idxWindow_Z(1)):(alignDat.eventIdx(t)+idxWindow_Z(2));
            newNeural = smoothSpikes_align(loopIdx,:);

            allDir_Z = [allDir_Z; newDir];
            allNeural_Z = [allNeural_Z; newNeural];
        end
    end

    Y_mov = [allDir; zeros(size(allDir_prep))];
    X_mov = [[ones(size(allNeural,1),1), allNeural]; [ones(size(allNeural_prep,1),1), allNeural_prep]];
    [ filts_mov, featureMeans ] = buildLinFilts( Y_mov, X_mov, 'ridge', 1e3 );
    
    Y_mov_Z = [Y_mov(:,3); allDir_Z];
    X_mov_Z = [X_mov; [ones(size(allNeural_Z,1), 1), allNeural_Z]];
    filtWeights = ones(size(Y_mov_Z));
    filtWeights(length(Y_mov):end) = 5;
    [ filts_mov_Z, featureMeans ] = buildLinFilts( Y_mov_Z, X_mov_Z, 'weight_plus_ridge', 1e3, filtWeights );
    filts_mov(:,3) = filts_mov_Z;
        
    Y_prep = [allDir_prep; zeros(size(allDir))];
    X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]; [ones(size(allNeural,1),1), allNeural]];
    [ filts_prep, featureMeans ] = buildLinFilts( Y_prep, X_prep, 'ridge', 1e3 );

    decVel = [ones(size(smoothSpikes_align,1),1), smoothSpikes_align]*filts_mov;

    if makePlot
        colors = jet(length(straightLineCodes))*0.8;
        figure
        hold on
        for t=1:length(alignDat.eventIdx)
            [LIA,LOCB] = ismember(trlCodes(t),straightLineCodes(1:8));
            if LIA
                currDir = codeDir(LOCB,:);
                newDir = repmat(currDir, idxWindow(2)-idxWindow(1)+1, 1);

                loopIdx = (alignDat.eventIdx(t)+idxWindow(1)):(alignDat.eventIdx(t)+idxWindow(2));

                traj = cumsum(decVel(loopIdx,:));
                plot(cumsum(decVel(loopIdx,1)), cumsum(decVel(loopIdx,2)),'Color',colors(LOCB,:));
                plot(traj(end,1), traj(end,2),'o','Color',colors(LOCB,:),'MarkerSize',8,'MarkerFaceColor',colors(LOCB,:));
            end
        end
        axis equal;
    end
end

