function [ filts_mov, filts_prep, decVel ] = makeDecoderOnStraightMovements( smoothSpikes_align, alignDat, trlCodes, straightLineCodes, makePlot )
    %%
    %makea decoder on arrow conditions
    nCodes = length(straightLineCodes);
    theta = linspace(0,2*pi,nCodes+1);
    theta = theta(1:(end-1));
    codeDir = [cos(theta)', sin(theta)'];

    idxWindow = [20, 50];
    idxWindowPrep = [-50, 0];

    allDir = [];
    allNeural = [];

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
    end

    Y_mov = [allDir; zeros(size(allDir_prep))];
    X_mov = [[ones(size(allNeural,1),1), allNeural]; [ones(size(allNeural_prep,1),1), allNeural_prep]];
    [ filts_mov, featureMeans ] = buildLinFilts( Y_mov, X_mov, 'ridge', 1e3 );

    Y_prep = [allDir_prep; zeros(size(allDir))];
    X_prep = [[ones(size(allNeural_prep,1),1), allNeural_prep]; [ones(size(allNeural,1),1), allNeural]];
    [ filts_prep, featureMeans ] = buildLinFilts( Y_prep, X_prep, 'ridge', 1e3 );

    decVel = [ones(size(smoothSpikes_align,1),1), smoothSpikes_align]*filts_mov;

    if makePlot
        colors = jet(length(straightLineCodes))*0.8;
        figure
        hold on
        for t=1:length(alignDat.eventIdx)
            [LIA,LOCB] = ismember(trlCodes(t),straightLineCodes);
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

